# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import json
from datetime import date, datetime
from decimal import Decimal
from sqlalchemy import text, bindparam
from shared import IO
from modules.cdr.retention import (
    CdrSettingsError,
    _engine,
    coerceSettings,
    getSettings,
    mergeSettings,
    validateWebhookTarget,
)

# MySQL named lock, only one node sharing the DB sends the CDRs
WEBHOOK_LOCK_NAME = 'dsip_cdr_webhook'
# CDRs per request, and requests per run (the cron job runs every minute)
WEBHOOK_BATCH_SIZE = 100
WEBHOOK_MAX_BATCHES = 50
# (connect, read) timeout in seconds
WEBHOOK_TIMEOUT = (5, 15)


class CdrWebhookError(Exception):
    """The webhook could not be reached or did not answer with a 2xx, nothing was marked as sent"""
    pass


def _jsonValue(value):
    if isinstance(value, (datetime, date)):
        return value.strftime('%Y-%m-%d %H:%M:%S') if isinstance(value, datetime) else value.isoformat()
    if isinstance(value, Decimal):
        return int(value) if value == value.to_integral_value() else float(value)
    if isinstance(value, bytes):
        return value.decode('utf-8', errors='replace')
    return value


def _send(cfg, payload, event):
    """
    Send one request to the webhook

    :param payload:     list of CDR dicts, sent as the JSON body
    :param event:       cdr|test, sent in the X-DSIP-Event header
    :return:            the HTTP status code
    :raises CdrWebhookError: on a connection error or a non 2xx answer
    """
    import requests

    auth = None
    if cfg['CDR_WEBHOOK_AUTH'] == 'basic':
        auth = (cfg['CDR_WEBHOOK_USERNAME'], cfg['CDR_WEBHOOK_PASSWORD'])
    try:
        res = requests.request(
            cfg['CDR_WEBHOOK_METHOD'], cfg['CDR_WEBHOOK_URL'],
            data=json.dumps(payload), auth=auth, timeout=WEBHOOK_TIMEOUT, allow_redirects=False,
            headers={'Content-Type': 'application/json', 'User-Agent': 'dSIPRouter', 'X-DSIP-Event': event},
        )
    except requests.RequestException as ex:
        raise CdrWebhookError('{} {} failed: {}'.format(cfg['CDR_WEBHOOK_METHOD'], cfg['CDR_WEBHOOK_URL'], ex))
    if res.status_code < 200 or res.status_code >= 300:
        raise CdrWebhookError('{} {} returned HTTP {}'.format(
            cfg['CDR_WEBHOOK_METHOD'], cfg['CDR_WEBHOOK_URL'], res.status_code))
    return res.status_code


def testWebhook(data=None):
    """
    Send an empty JSON array (X-DSIP-Event: test) to the webhook with the saved settings, or with the
    (unsaved) values in data

    :raises CdrSettingsError: on invalid input
    :raises CdrWebhookError: when the webhook does not answer with a 2xx
    """
    fields = coerceSettings(data or {})
    with _engine().connect() as conn:
        cfg = mergeSettings(conn, fields)
    validateWebhookTarget(cfg, 'testing the webhook')
    status = _send(cfg, [], 'test')
    return {'url': cfg['CDR_WEBHOOK_URL'], 'method': cfg['CDR_WEBHOOK_METHOD'], 'status': status}


def _saveLastRun(conn, result):
    payload = json.dumps({k: result[k] for k in ('trigger', 'sent', 'deleted', 'last_cdr_id', 'error')}, default=str)
    conn.execute(text(
        'UPDATE dsip_cdr_settings SET webhook_last_run_at = NOW(), webhook_last_result = :result WHERE id = 1'
    ), {'result': payload[:2048]})
    conn.commit()


def runWebhook(trigger='cron'):
    """
    Send the CDRs written since the last delivery to the webhook

    CDRs are sent oldest first as a JSON array of cdrs rows, WEBHOOK_BATCH_SIZE per request. The position
    (CDR_WEBHOOK_LAST_CDR_ID) only moves forward after a 2xx answer, so a failed request is retried with the
    same CDRs on the next run. With CDR_STORE_CDR false the sent CDRs (and their acc rows) are deleted
    once the webhook accepted them.

    :param trigger:     cron|api, recorded with the result
    :return:            {trigger, enabled, skipped_locked, sent, requests, deleted, last_cdr_id, error}
    :rtype:             dict
    """
    result = {
        'trigger': trigger, 'enabled': False, 'skipped_locked': False, 'sent': 0, 'requests': 0,
        'deleted': 0, 'last_cdr_id': None, 'error': None,
    }

    with _engine().connect() as conn:
        cfg = getSettings(conn, include_secret=True)
        if not cfg['CDR_WEBHOOK_ENABLED']:
            return result
        result['enabled'] = True

        # the lock belongs to this connection, so the whole run uses it
        locked = conn.execute(text('SELECT GET_LOCK(:name, 0)'), {'name': WEBHOOK_LOCK_NAME}).scalar()
        conn.commit()
        if locked != 1:
            result['skipped_locked'] = True
            return result

        try:
            # re-read under the lock, another node may have moved the position meanwhile
            cfg = getSettings(conn, include_secret=True)
            if not cfg['CDR_WEBHOOK_ENABLED']:
                result['enabled'] = False
                return result
            last_id = cfg['CDR_WEBHOOK_LAST_CDR_ID']
            if last_id is None:
                last_id = conn.execute(text('SELECT COALESCE(MAX(cdr_id), 0) FROM cdrs')).scalar()
                conn.execute(text('UPDATE dsip_cdr_settings SET webhook_last_cdr_id = :id WHERE id = 1'), {'id': last_id})
                conn.commit()
            result['last_cdr_id'] = int(last_id)

            try:
                validateWebhookTarget(cfg, 'the CDR webhook')
                for _ in range(WEBHOOK_MAX_BATCHES):
                    rows = conn.execute(text(
                        'SELECT * FROM cdrs WHERE cdr_id > :id ORDER BY cdr_id LIMIT {:d}'.format(WEBHOOK_BATCH_SIZE)
                    ), {'id': result['last_cdr_id']}).mappings().all()
                    conn.commit()
                    if len(rows) == 0:
                        break

                    payload = [{k: _jsonValue(v) for k, v in row.items()} for row in rows]
                    _send(cfg, payload, 'cdr')
                    result['requests'] += 1

                    ids = [int(row['cdr_id']) for row in rows]
                    conn.execute(text('UPDATE dsip_cdr_settings SET webhook_last_cdr_id = :id WHERE id = 1'),
                        {'id': ids[-1]})
                    if not cfg['CDR_STORE_CDR']:
                        conn.execute(text('DELETE FROM acc WHERE cdr_id IN :ids').bindparams(
                            bindparam('ids', expanding=True)), {'ids': ids})
                        res = conn.execute(text('DELETE FROM cdrs WHERE cdr_id IN :ids').bindparams(
                            bindparam('ids', expanding=True)), {'ids': ids})
                        result['deleted'] += res.rowcount
                    conn.commit()
                    result['sent'] += len(ids)
                    result['last_cdr_id'] = ids[-1]

                    if len(rows) < WEBHOOK_BATCH_SIZE:
                        break
            except (CdrWebhookError, CdrSettingsError) as ex:
                conn.rollback()
                result['error'] = str(ex)
                IO.logerr('CDR webhook failed, the CDRs will be sent on the next run: {}'.format(ex))

            # an idle run is only recorded when it clears an earlier error, not every minute
            last_error = (cfg['CDR_WEBHOOK_LAST_RUN'] or {}).get('result', {}).get('error')
            if result['requests'] > 0 or result['error'] is not None or last_error is not None or trigger != 'cron':
                if result['requests'] > 0:
                    IO.loginfo('CDR webhook sent {} CDR(s) in {} request(s)'.format(result['sent'], result['requests']))
                _saveLastRun(conn, result)
            return result
        finally:
            conn.execute(text('SELECT RELEASE_LOCK(:name)'), {'name': WEBHOOK_LOCK_NAME})
            conn.commit()
