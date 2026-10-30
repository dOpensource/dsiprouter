# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import csv, gzip, json, os, re, tempfile, uuid
from datetime import datetime, timedelta
from sqlalchemy import text, bindparam
from database import startSession
from shared import IO
from util.security import AES_CTR

# MySQL named lock, only one node sharing the DB runs the job at a time
RETENTION_LOCK_NAME = 'dsip_cdr_retention'
# rows deleted per statement, each batch is committed so live tables are never locked for long
DELETE_BATCH_SIZE = 10000
MAX_RETENTION_DAYS = 36500
MAX_SECRET_LEN = 256

# tables purged by the job: (table, primary key, time column)
# missed_calls is optional, it only exists when the kamailio acc schema was loaded
CDR_TABLES = (
    ('cdrs', 'cdr_id', 'call_start_time'),
    ('acc', 'id', 'time'),
    ('missed_calls', 'id', 'time'),
)

# API field name -> dsip_cdr_settings column
SETTINGS_COLUMNS = {
    'CDR_RETENTION_DAYS': 'retention_days',
    'CDR_ARCHIVE_ENABLED': 'archive_enabled',
    'CDR_S3_BUCKET': 's3_bucket',
    'CDR_S3_PREFIX': 's3_prefix',
    'CDR_S3_REGION': 's3_region',
    'CDR_S3_ENDPOINT': 's3_endpoint',
    'CDR_S3_ACCESS_KEY': 's3_access_key',
    'CDR_S3_SECRET_KEY': 's3_secret_key',
    'CDR_WEBHOOK_ENABLED': 'webhook_enabled',
    'CDR_WEBHOOK_URL': 'webhook_url',
    'CDR_WEBHOOK_METHOD': 'webhook_method',
    'CDR_WEBHOOK_AUTH': 'webhook_auth',
    'CDR_WEBHOOK_USERNAME': 'webhook_username',
    'CDR_WEBHOOK_PASSWORD': 'webhook_password',
    'CDR_STORE_CDR': 'store_cdr',
}
# write-only settings, stored encrypted and never returned by the API
SECRET_SETTINGS = ('CDR_S3_SECRET_KEY', 'CDR_WEBHOOK_PASSWORD')
BOOL_SETTINGS = ('CDR_ARCHIVE_ENABLED', 'CDR_WEBHOOK_ENABLED', 'CDR_STORE_CDR')
DEFAULT_SETTINGS = {
    'CDR_RETENTION_DAYS': 0,
    'CDR_ARCHIVE_ENABLED': False,
    'CDR_S3_BUCKET': '',
    'CDR_S3_PREFIX': 'cdrs/',
    'CDR_S3_REGION': '',
    'CDR_S3_ENDPOINT': '',
    'CDR_S3_ACCESS_KEY': '',
    'CDR_S3_SECRET_KEY': '',
    'CDR_WEBHOOK_ENABLED': False,
    'CDR_WEBHOOK_URL': '',
    'CDR_WEBHOOK_METHOD': 'POST',
    'CDR_WEBHOOK_AUTH': '',
    'CDR_WEBHOOK_USERNAME': '',
    'CDR_WEBHOOK_PASSWORD': '',
    'CDR_STORE_CDR': True,
}
WEBHOOK_METHODS = ('POST', 'PUT')
WEBHOOK_AUTH_TYPES = ('', 'basic')

S3_BUCKET_REGEX = re.compile(r'^[a-z0-9][a-z0-9.\-]{1,61}[a-z0-9]$')
S3_REGION_REGEX = re.compile(r'^[a-z0-9\-]{0,64}$')
S3_ENDPOINT_REGEX = re.compile(r'^https?://[A-Za-z0-9.\-]+(:[0-9]{1,5})?(/[^\s]*)?$')
WEBHOOK_URL_REGEX = re.compile(r'^https?://(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9.\-]+)(:[0-9]{1,5})?(/[^\s]*)?$')


class CdrSettingsError(ValueError):
    """Invalid CDR settings, the message is safe to show to the user"""
    pass


class CdrArchiveError(Exception):
    """An S3 upload or connection failed, nothing was deleted"""
    pass


def _engine():
    db = startSession()
    try:
        return db.get_bind()
    finally:
        db.close()


def _toBool(key, value):
    if isinstance(value, bool):
        return value
    if isinstance(value, int) and value in (0, 1):
        return bool(value)
    if isinstance(value, str) and value.strip().lower() in ('true', '1', 'yes', 'on'):
        return True
    if isinstance(value, str) and value.strip().lower() in ('false', '0', 'no', 'off', ''):
        return False
    raise CdrSettingsError('{} must be true or false'.format(key))


def _toStr(key, value, max_len=255):
    if value is None:
        value = ''
    if not isinstance(value, str):
        raise CdrSettingsError('{} must be a string'.format(key))
    value = value.strip()
    if len(value) > max_len:
        raise CdrSettingsError('{} can be at most {} characters'.format(key, max_len))
    return value


def coerceSettings(data):
    """
    Validate and convert a (partial) settings payload

    :param data:    API field names to values, CDR_S3_SECRET_KEY is only changed when it is a non empty
                    string (or null to clear it)
    :type data:     dict
    :return:        API field names to typed values
    :rtype:         dict
    :raises CdrSettingsError: on invalid input
    """
    if not isinstance(data, dict):
        raise CdrSettingsError('request body must be an object')
    unknown = set(data.keys()) - set(SETTINGS_COLUMNS.keys())
    if unknown:
        raise CdrSettingsError('unknown setting(s): {}'.format(', '.join(sorted(unknown))))

    fields = {}
    if 'CDR_RETENTION_DAYS' in data:
        value = data['CDR_RETENTION_DAYS']
        if isinstance(value, bool) or (isinstance(value, float) and not value.is_integer()):
            raise CdrSettingsError('CDR_RETENTION_DAYS must be a whole number of days')
        try:
            value = int(str(value).strip()) if not isinstance(value, float) else int(value)
        except ValueError:
            raise CdrSettingsError('CDR_RETENTION_DAYS must be a whole number of days')
        if value < 0 or value > MAX_RETENTION_DAYS:
            raise CdrSettingsError('CDR_RETENTION_DAYS must be between 0 and {}'.format(MAX_RETENTION_DAYS))
        fields['CDR_RETENTION_DAYS'] = value
    for key in BOOL_SETTINGS:
        if key in data:
            fields[key] = _toBool(key, data[key])
    if 'CDR_S3_BUCKET' in data:
        value = _toStr('CDR_S3_BUCKET', data['CDR_S3_BUCKET'], 63)
        if value != '' and S3_BUCKET_REGEX.match(value) is None:
            raise CdrSettingsError('CDR_S3_BUCKET is not a valid bucket name')
        fields['CDR_S3_BUCKET'] = value
    if 'CDR_S3_PREFIX' in data:
        value = _toStr('CDR_S3_PREFIX', data['CDR_S3_PREFIX']).lstrip('/')
        if value != '' and not value.endswith('/'):
            value += '/'
        fields['CDR_S3_PREFIX'] = value
    if 'CDR_S3_REGION' in data:
        value = _toStr('CDR_S3_REGION', data['CDR_S3_REGION'], 64)
        if S3_REGION_REGEX.match(value) is None:
            raise CdrSettingsError('CDR_S3_REGION is not a valid region name')
        fields['CDR_S3_REGION'] = value
    if 'CDR_S3_ENDPOINT' in data:
        value = _toStr('CDR_S3_ENDPOINT', data['CDR_S3_ENDPOINT']).rstrip('/')
        if value != '' and S3_ENDPOINT_REGEX.match(value) is None:
            raise CdrSettingsError('CDR_S3_ENDPOINT must be an http(s) URL, such as https://nyc3.digitaloceanspaces.com')
        fields['CDR_S3_ENDPOINT'] = value
    if 'CDR_S3_ACCESS_KEY' in data:
        fields['CDR_S3_ACCESS_KEY'] = _toStr('CDR_S3_ACCESS_KEY', data['CDR_S3_ACCESS_KEY'])
    if 'CDR_WEBHOOK_URL' in data:
        value = _toStr('CDR_WEBHOOK_URL', data['CDR_WEBHOOK_URL'], 2048)
        if value != '' and WEBHOOK_URL_REGEX.match(value) is None:
            raise CdrSettingsError('CDR_WEBHOOK_URL must be an http(s) URL, such as https://example.com/cdrs')
        fields['CDR_WEBHOOK_URL'] = value
    if 'CDR_WEBHOOK_METHOD' in data:
        value = _toStr('CDR_WEBHOOK_METHOD', data['CDR_WEBHOOK_METHOD'], 8).upper() or 'POST'
        if value not in WEBHOOK_METHODS:
            raise CdrSettingsError('CDR_WEBHOOK_METHOD must be POST or PUT')
        fields['CDR_WEBHOOK_METHOD'] = value
    if 'CDR_WEBHOOK_AUTH' in data:
        value = _toStr('CDR_WEBHOOK_AUTH', data['CDR_WEBHOOK_AUTH'], 16).lower()
        value = '' if value == 'none' else value
        if value not in WEBHOOK_AUTH_TYPES:
            raise CdrSettingsError('CDR_WEBHOOK_AUTH must be basic or empty (no auth)')
        fields['CDR_WEBHOOK_AUTH'] = value
    if 'CDR_WEBHOOK_USERNAME' in data:
        value = _toStr('CDR_WEBHOOK_USERNAME', data['CDR_WEBHOOK_USERNAME'])
        if ':' in value:
            raise CdrSettingsError('CDR_WEBHOOK_USERNAME can not contain a colon')
        fields['CDR_WEBHOOK_USERNAME'] = value
    for key in SECRET_SETTINGS:
        if key in data:
            value = data[key]
            if value is None:
                fields[key] = ''
            else:
                value = _toStr(key, value, MAX_SECRET_LEN)
                # an empty secret means "keep the saved one", the form never receives it back
                if value != '':
                    fields[key] = value
    return fields


def validateSettings(cfg):
    """
    Check a complete settings dict (saved values merged with the changes)

    :raises CdrSettingsError: when the combination can not work
    """
    if cfg['CDR_ARCHIVE_ENABLED']:
        if cfg['CDR_RETENTION_DAYS'] == 0:
            raise CdrSettingsError('S3 archiving needs CDR_RETENTION_DAYS above 0, CDRs are archived when they expire')
        missing = [key for key in ('CDR_S3_BUCKET', 'CDR_S3_ACCESS_KEY', 'CDR_S3_SECRET_KEY') if cfg[key] == '']
        if missing:
            raise CdrSettingsError('S3 archiving needs {}'.format(', '.join(missing)))
    if cfg['CDR_WEBHOOK_ENABLED']:
        validateWebhookTarget(cfg, 'the CDR webhook')
    if not cfg['CDR_STORE_CDR'] and not cfg['CDR_WEBHOOK_ENABLED']:
        raise CdrSettingsError('CDR_STORE_CDR can only be false while the webhook is enabled, '
                               'otherwise CDRs would be deleted without being sent anywhere')


def validateWebhookTarget(cfg, what):
    """
    Check the values needed to call the webhook

    :raises CdrSettingsError: when the URL or the basic auth credentials are missing
    """
    if cfg['CDR_WEBHOOK_URL'] == '':
        raise CdrSettingsError('{} needs CDR_WEBHOOK_URL'.format(what))
    if cfg['CDR_WEBHOOK_AUTH'] == 'basic':
        missing = [key for key in ('CDR_WEBHOOK_USERNAME', 'CDR_WEBHOOK_PASSWORD') if cfg[key] == '']
        if missing:
            raise CdrSettingsError('basic auth needs {}'.format(', '.join(missing)))


def _readSettingsRow(conn):
    row = conn.execute(text(
        'SELECT {}, last_run_at, last_run_result, webhook_last_cdr_id, webhook_last_run_at, webhook_last_result '
        'FROM dsip_cdr_settings WHERE id = 1'.format(', '.join(SETTINGS_COLUMNS.values()))
    )).mappings().first()
    return row


def getSettings(conn=None, include_secret=False):
    """
    Read the CDR settings

    :param include_secret:  return the decrypted secret key (only for the job itself, never the API)
    :return:                API field names to typed values, plus <secret>_SET for each secret, CDR_LAST_RUN,
                            CDR_WEBHOOK_LAST_RUN and CDR_WEBHOOK_LAST_CDR_ID
    :rtype:                 dict
    """
    if conn is None:
        with _engine().connect() as conn:
            return getSettings(conn, include_secret)

    cfg = dict(DEFAULT_SETTINGS)
    cfg['CDR_LAST_RUN'] = None
    cfg['CDR_WEBHOOK_LAST_RUN'] = None
    cfg['CDR_WEBHOOK_LAST_CDR_ID'] = None
    row = _readSettingsRow(conn)
    if row is not None:
        for key, col in SETTINGS_COLUMNS.items():
            if key in SECRET_SETTINGS:
                secret = row[col] or b''
                cfg[key] = AES_CTR.decrypt(secret) if (include_secret and len(secret) > 0) else (
                    '********' if len(secret) > 0 else '')
            elif key in BOOL_SETTINGS:
                cfg[key] = bool(row[col])
            elif key == 'CDR_RETENTION_DAYS':
                cfg[key] = int(row[col])
            else:
                cfg[key] = row[col]
        cfg['CDR_LAST_RUN'] = _lastRun(row['last_run_at'], row['last_run_result'])
        cfg['CDR_WEBHOOK_LAST_RUN'] = _lastRun(row['webhook_last_run_at'], row['webhook_last_result'])
        if row['webhook_last_cdr_id'] is not None:
            cfg['CDR_WEBHOOK_LAST_CDR_ID'] = int(row['webhook_last_cdr_id'])

    for key in SECRET_SETTINGS:
        cfg[key + '_SET'] = cfg[key] != ''
        if not include_secret:
            del cfg[key]
    return cfg


def _lastRun(at, result):
    if at is None:
        return None
    try:
        result = json.loads(result) if result else {}
    except ValueError:
        result = {}
    return {'at': at.strftime('%Y-%m-%d %H:%M:%S'), 'result': result}


def mergeSettings(conn, fields):
    """Return the saved settings (with the decrypted secret) with the coerced changes applied"""
    cfg = getSettings(conn, include_secret=True)
    for key in [k + '_SET' for k in SECRET_SETTINGS] + ['CDR_LAST_RUN', 'CDR_WEBHOOK_LAST_RUN', 'CDR_WEBHOOK_LAST_CDR_ID']:
        del cfg[key]
    cfg.update(fields)
    return cfg


def saveSettings(data):
    """
    Validate and store a (partial) settings payload

    :return:    the stored settings, as returned by getSettings()
    :raises CdrSettingsError: on invalid input
    """
    fields = coerceSettings(data)
    with _engine().connect() as conn:
        was_enabled = getSettings(conn)['CDR_WEBHOOK_ENABLED']
        cfg = mergeSettings(conn, fields)
        validateSettings(cfg)

        values = {SETTINGS_COLUMNS[key]: cfg[key] for key in SETTINGS_COLUMNS}
        for key in BOOL_SETTINGS:
            values[SETTINGS_COLUMNS[key]] = 1 if cfg[key] else 0
        for key in SECRET_SETTINGS:
            values[SETTINGS_COLUMNS[key]] = AES_CTR.encrypt(cfg[key]) if cfg[key] != '' else b''

        columns = list(values.keys())
        conn.execute(text(
            'INSERT INTO dsip_cdr_settings (id, {cols}) VALUES (1, {params}) ON DUPLICATE KEY UPDATE {updates}'.format(
                cols=', '.join(columns),
                params=', '.join(':' + col for col in columns),
                updates=', '.join('{0} = VALUES({0})'.format(col) for col in columns),
            )
        ), values)
        if cfg['CDR_WEBHOOK_ENABLED'] and not was_enabled:
            # the webhook starts with the CDRs written from now on, existing ones are not sent
            conn.execute(text(
                'UPDATE dsip_cdr_settings SET webhook_last_cdr_id = (SELECT COALESCE(MAX(cdr_id), 0) FROM cdrs) '
                'WHERE id = 1'
            ))
        conn.commit()
        return getSettings(conn)


def _s3Client(cfg):
    try:
        import boto3
        from botocore.config import Config
    except ImportError:
        raise CdrArchiveError('the boto3 python package is not installed, run: pip install boto3')

    return boto3.client(
        's3',
        region_name=cfg['CDR_S3_REGION'] or 'us-east-1',
        endpoint_url=cfg['CDR_S3_ENDPOINT'] or None,
        aws_access_key_id=cfg['CDR_S3_ACCESS_KEY'],
        aws_secret_access_key=cfg['CDR_S3_SECRET_KEY'],
        config=Config(connect_timeout=10, read_timeout=60, retries={'max_attempts': 3}),
    )


def _s3ErrorMessage(ex):
    response = getattr(ex, 'response', None)
    if isinstance(response, dict) and 'Error' in response:
        error = response['Error']
        return '{} {}'.format(error.get('Code', ''), error.get('Message', '')).strip() or str(ex)
    return str(ex)


def testS3Connection(data=None):
    """
    Check that the bucket is reachable and writable with the saved settings, or with the
    (unsaved) values in data, by writing and deleting a small object under the prefix

    :raises CdrSettingsError: on invalid input
    :raises CdrArchiveError: when S3 rejects the request
    """
    fields = coerceSettings(data or {})
    with _engine().connect() as conn:
        cfg = mergeSettings(conn, fields)
    missing = [key for key in ('CDR_S3_BUCKET', 'CDR_S3_ACCESS_KEY', 'CDR_S3_SECRET_KEY') if cfg[key] == '']
    if missing:
        raise CdrSettingsError('testing S3 needs {}'.format(', '.join(missing)))

    key = '{}.dsiprouter-test-{}'.format(cfg['CDR_S3_PREFIX'], uuid.uuid4().hex)
    try:
        client = _s3Client(cfg)
        client.head_bucket(Bucket=cfg['CDR_S3_BUCKET'])
        client.put_object(Bucket=cfg['CDR_S3_BUCKET'], Key=key, Body=b'dsiprouter s3 test')
        client.delete_object(Bucket=cfg['CDR_S3_BUCKET'], Key=key)
    except CdrArchiveError:
        raise
    except Exception as ex:
        raise CdrArchiveError(_s3ErrorMessage(ex))
    return {'bucket': cfg['CDR_S3_BUCKET'], 'prefix': cfg['CDR_S3_PREFIX']}


def _existingTables(conn):
    names = {row[0] for row in conn.execute(text(
        'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN :names'
    ).bindparams(bindparam('names', expanding=True)), {'names': [t[0] for t in CDR_TABLES]})}
    return [t for t in CDR_TABLES if t[0] in names]


def _deleteBatches(conn, table, where, params, result):
    """Delete matching rows DELETE_BATCH_SIZE at a time, committing each batch"""
    deleted = 0
    while True:
        res = conn.execute(text('DELETE FROM {} WHERE {} LIMIT {}'.format(table, where, DELETE_BATCH_SIZE)), params)
        conn.commit()
        deleted += res.rowcount
        result['batches'] += 1
        if res.rowcount < DELETE_BATCH_SIZE:
            break
    result['deleted'][table] = result['deleted'].get(table, 0) + deleted


def _uniqueKey(client, bucket, key):
    """Never overwrite an earlier archive of the same day, add a .N suffix instead"""
    from botocore.exceptions import ClientError

    base, ext = key[:-len('.csv.gz')], '.csv.gz'
    candidate, n = key, 1
    while True:
        try:
            client.head_object(Bucket=bucket, Key=candidate)
        except ClientError as ex:
            if ex.response.get('Error', {}).get('Code') in ('404', 'NoSuchKey', 'NotFound'):
                return candidate
            raise
        n += 1
        candidate = '{}.{}{}'.format(base, n, ext)


def _undeliveredFilter(table, cfg):
    """While the webhook is on, CDRs it has not sent yet are never expired"""
    if table == 'cdrs' and cfg['CDR_WEBHOOK_ENABLED'] and cfg['CDR_WEBHOOK_LAST_CDR_ID'] is not None:
        return ' AND cdr_id <= {:d}'.format(cfg['CDR_WEBHOOK_LAST_CDR_ID'])
    return ''


def _archiveDay(conn, client, cfg, tables, day, result):
    """
    Export one day of every CDR table to S3, then delete exactly the exported rows

    Rows are selected up to the highest id seen when the export starts, so a row written for that day
    while the export runs is left for the next run instead of being deleted without an archive.
    """
    start = datetime.combine(day, datetime.min.time())
    end = start + timedelta(days=1)
    params = {'start': start, 'end': end}

    exports = []
    try:
        for table, id_col, time_col in tables:
            where = '{0} >= :start AND {0} < :end'.format(time_col) + _undeliveredFilter(table, cfg)
            max_id = conn.execute(text('SELECT MAX({}) FROM {} WHERE {}'.format(id_col, table, where)), params).scalar()
            if max_id is None:
                continue

            fd, path = tempfile.mkstemp(prefix='dsiprouter-{}-'.format(table), suffix='.csv.gz')
            os.close(fd)
            exports.append({'table': table, 'id_col': id_col, 'time_col': time_col, 'max_id': max_id, 'path': path})

            rows = conn.execute(text(
                'SELECT * FROM {} WHERE {} AND {} <= :max_id ORDER BY {}'.format(table, where, id_col, id_col)
            ).execution_options(stream_results=True), dict(params, max_id=max_id))
            with gzip.open(path, 'wt', newline='', encoding='utf-8') as fp:
                writer = csv.writer(fp)
                writer.writerow(rows.keys())
                for row in rows:
                    writer.writerow(['' if v is None else v for v in row])

        # upload everything for the day before anything is deleted
        for export in exports:
            key = '{}{:%Y/%m}/{}-{:%Y-%m-%d}.csv.gz'.format(cfg['CDR_S3_PREFIX'], start, export['table'], start)
            try:
                key = _uniqueKey(client, cfg['CDR_S3_BUCKET'], key)
                client.upload_file(export['path'], cfg['CDR_S3_BUCKET'], key,
                    ExtraArgs={'ContentType': 'text/csv', 'ContentEncoding': 'gzip'})
            except Exception as ex:
                raise CdrArchiveError('uploading {} failed: {}'.format(key, _s3ErrorMessage(ex)))
            result['archived_files'].append(key)

        for export in exports:
            _deleteBatches(conn, export['table'],
                '{0} >= :start AND {0} < :end AND {1} <= :max_id'.format(export['time_col'], export['id_col']),
                dict(params, max_id=export['max_id']), result)
    finally:
        for export in exports:
            try:
                os.remove(export['path'])
            except OSError:
                pass


def _saveLastRun(conn, result):
    summary = {k: result[k] for k in ('trigger', 'retention_days', 'cutoff', 'deleted', 'archived_files', 'error')}
    payload = json.dumps(summary, default=str)
    if len(payload) > 2048:
        summary['archived_files'] = summary['archived_files'][:5] + ['... {} more'.format(len(summary['archived_files']) - 5)]
        payload = json.dumps(summary, default=str)[:2048]
    conn.execute(text(
        'INSERT INTO dsip_cdr_settings (id, last_run_at, last_run_result) VALUES (1, NOW(), :result) '
        'ON DUPLICATE KEY UPDATE last_run_at = VALUES(last_run_at), last_run_result = VALUES(last_run_result)'
    ), {'result': payload})
    conn.commit()


def runRetention(trigger='cron'):
    """
    Delete CDRs older than CDR_RETENTION_DAYS, archiving them to S3 first when CDR_ARCHIVE_ENABLED is set

    Whole days are expired: with 7 days on the 30th everything before the 23rd 00:00 (DB time) goes.
    When archiving, a day is only deleted after all of its files were uploaded, a failed upload stops
    the run and leaves the rest for the next run.

    :param trigger:     cron|api, recorded with the result
    :return:            {trigger, skipped_locked, retention_days, cutoff, deleted: {table: rows},
                         batches, archived_files, error}
    :rtype:             dict
    """
    result = {
        'trigger': trigger, 'skipped_locked': False, 'retention_days': 0, 'cutoff': None,
        'deleted': {}, 'batches': 0, 'archived_files': [], 'error': None,
    }

    with _engine().connect() as conn:
        # the lock belongs to this connection, so the whole run uses it
        locked = conn.execute(text('SELECT GET_LOCK(:name, 0)'), {'name': RETENTION_LOCK_NAME}).scalar()
        conn.commit()
        if locked != 1:
            result['skipped_locked'] = True
            IO.loginfo('CDR retention skipped, another node is running it')
            return result

        try:
            cfg = getSettings(conn, include_secret=True)
            days = cfg['CDR_RETENTION_DAYS']
            result['retention_days'] = days
            if days == 0:
                return result

            cutoff = conn.execute(text('SELECT DATE_SUB(CURDATE(), INTERVAL :days DAY)'), {'days': days}).scalar()
            cutoff = datetime.combine(cutoff, datetime.min.time()) if not isinstance(cutoff, datetime) else cutoff
            result['cutoff'] = cutoff.strftime('%Y-%m-%d %H:%M:%S')
            tables = _existingTables(conn)

            try:
                if cfg['CDR_ARCHIVE_ENABLED']:
                    validateSettings(cfg)
                    client = _s3Client(cfg)
                    day_rows = conn.execute(text(' UNION '.join(
                        'SELECT DISTINCT DATE({0}) AS day FROM {1} WHERE {0} < :cutoff{2}'.format(
                            time_col, table, _undeliveredFilter(table, cfg))
                        for table, _, time_col in tables
                    ) + ' ORDER BY day'), {'cutoff': cutoff})
                    for day in [row[0] for row in day_rows]:
                        _archiveDay(conn, client, cfg, tables, day, result)
                else:
                    for table, _, time_col in tables:
                        _deleteBatches(conn, table, '{} < :cutoff'.format(time_col) + _undeliveredFilter(table, cfg),
                            {'cutoff': cutoff}, result)
            except (CdrArchiveError, CdrSettingsError) as ex:
                conn.rollback()
                result['error'] = str(ex)
                IO.logerr('CDR archive failed, the remaining CDRs were kept: {}'.format(ex))

            IO.loginfo('CDR retention ({} days) deleted {} and archived {} file(s)'.format(
                days, result['deleted'], len(result['archived_files'])))
            _saveLastRun(conn, result)
            return result
        finally:
            conn.execute(text('SELECT RELEASE_LOCK(:name)'), {'name': RETENTION_LOCK_NAME})
            conn.commit()
