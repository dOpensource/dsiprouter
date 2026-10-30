# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, request, session
from werkzeug import exceptions as http_exceptions
from shared import debugEndpoint, getRequestData, IO, StatusCodes
from modules.api.api_functions import api_security, createApiResponse, showApiError
from modules.cdr.retention import (
    CdrSettingsError,
    CdrArchiveError,
    getSettings,
    saveSettings,
    testS3Connection,
    runRetention,
)
from modules.cdr.webhook import CdrWebhookError, testWebhook, runWebhook
import settings

cdr_settings_api = Blueprint('cdr_settings_api', __name__)

# roles allowed to use these endpoints with a GUI session, token callers keep full access like the rest of the API
SETTINGS_ROLES = {'dsip_admin', 'dsip_engineer'}
RUN_ROLES = {'dsip_admin'}


def requireRole(roles, action):
    if session.get('logged_in'):
        user_groups = set(session.get('user_groups', []) or [])
        if not user_groups.intersection(roles):
            raise http_exceptions.Forbidden('You do not have permission to {}'.format(action))


def toHttpError(ex):
    if isinstance(ex, CdrSettingsError):
        return http_exceptions.BadRequest(str(ex))
    if isinstance(ex, CdrArchiveError):
        return http_exceptions.BadRequest('S3 error: {}'.format(ex))
    if isinstance(ex, CdrWebhookError):
        return http_exceptions.BadRequest('Webhook error: {}'.format(ex))
    return ex


@cdr_settings_api.route('/api/v1/settings/cdr', methods=['GET', 'PUT'])
@api_security
def handleCdrSettings():
    """
    Endpoint for the CDR retention, S3 archive and webhook settings

    The settings are stored in the DB (``dsip_cdr_settings``) and shared by every node using it.
    ``CDR_RETENTION_DAYS`` = 0 keeps CDRs forever. The S3 secret key and the webhook password are write-only:
    they are never returned, leave them out (or send an empty string) to keep the saved ones, send null to
    clear them. Enabling the webhook starts it at the newest CDR, CDRs written before are not sent.
    ``CDR_STORE_CDR`` false deletes CDRs once the webhook accepted them, it requires the webhook to be enabled.

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            "CDR_RETENTION_DAYS":  "<int, 0 - 36500>",
            "CDR_ARCHIVE_ENABLED": "<bool>",
            "CDR_S3_BUCKET":       "<string>",
            "CDR_S3_PREFIX":       "<string, default cdrs/>",
            "CDR_S3_REGION":       "<string, default us-east-1>",
            "CDR_S3_ENDPOINT":     "<string, URL of an S3 compatible service, empty for AWS>",
            "CDR_S3_ACCESS_KEY":   "<string>",
            "CDR_S3_SECRET_KEY":   "<string>",
            "CDR_WEBHOOK_ENABLED":  "<bool>",
            "CDR_WEBHOOK_URL":      "<string, http(s) URL>",
            "CDR_WEBHOOK_METHOD":   "<POST|PUT>",
            "CDR_WEBHOOK_AUTH":     "<basic or empty for no auth>",
            "CDR_WEBHOOK_USERNAME": "<string>",
            "CDR_WEBHOOK_PASSWORD": "<string>",
            "CDR_STORE_CDR":        "<bool, default true>"
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            "error": "<string>",
            "msg":   "<string>",
            "data": [
                {
                    "CDR_RETENTION_DAYS":    "<int>",
                    "CDR_ARCHIVE_ENABLED":   "<bool>",
                    "CDR_S3_BUCKET":         "<string>",
                    "CDR_S3_PREFIX":         "<string>",
                    "CDR_S3_REGION":         "<string>",
                    "CDR_S3_ENDPOINT":       "<string>",
                    "CDR_S3_ACCESS_KEY":     "<string>",
                    "CDR_S3_SECRET_KEY_SET": "<bool>",
                    "CDR_LAST_RUN":          "<null or {at, result}>",
                    "CDR_WEBHOOK_ENABLED":   "<bool>",
                    "CDR_WEBHOOK_URL":       "<string>",
                    "CDR_WEBHOOK_METHOD":    "<POST|PUT>",
                    "CDR_WEBHOOK_AUTH":      "<basic or empty>",
                    "CDR_WEBHOOK_USERNAME":  "<string>",
                    "CDR_WEBHOOK_PASSWORD_SET": "<bool>",
                    "CDR_STORE_CDR":         "<bool>",
                    "CDR_WEBHOOK_LAST_CDR_ID": "<null or int, the last CDR the webhook accepted>",
                    "CDR_WEBHOOK_LAST_RUN":  "<null or {at, result}>"
                }
            ]
        }
    """
    try:
        if settings.DEBUG:
            debugEndpoint()
        requireRole(SETTINGS_ROLES, 'view or change the CDR settings')

        if request.method == 'GET':
            return createApiResponse(msg='CDR settings retrieved', data=[getSettings()])

        data = saveSettings(getRequestData() or {})
        IO.loginfo('CDR settings updated via API (retention {} days, archive {}, webhook {})'.format(
            data['CDR_RETENTION_DAYS'], 'on' if data['CDR_ARCHIVE_ENABLED'] else 'off',
            'on' if data['CDR_WEBHOOK_ENABLED'] else 'off'))
        return createApiResponse(msg='CDR settings saved', data=[data])
    except Exception as ex:
        return showApiError(toHttpError(ex))


@cdr_settings_api.route('/api/v1/settings/cdr/test-s3', methods=['POST'])
@api_security
def testCdrS3():
    """
    Check the S3 bucket by writing and deleting a small object under the prefix

    The body may hold unsaved CDR_S3_* values to test before saving them, missing values come from the
    saved settings. Returns 400 with the S3 error when the check fails.
    """
    try:
        if settings.DEBUG:
            debugEndpoint()
        requireRole(SETTINGS_ROLES, 'test the CDR archive settings')

        data = testS3Connection(getRequestData() or {})
        return createApiResponse(msg='Connected to S3 bucket {}'.format(data['bucket']), data=[data])
    except Exception as ex:
        return showApiError(toHttpError(ex))


@cdr_settings_api.route('/api/v1/settings/cdr/run', methods=['POST'])
@api_security
def runCdrRetention():
    """
    Run the CDR retention / archive job now, the same job cron runs daily

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            "error": "<string>",
            "msg":   "<string>",
            "data": [
                {
                    "trigger":        "api",
                    "skipped_locked": "<bool, another node was running it>",
                    "retention_days": "<int>",
                    "cutoff":         "<datetime, rows before it were expired>",
                    "deleted":        "<{table: rows}>",
                    "batches":        "<int>",
                    "archived_files": "<list of S3 keys>",
                    "error":          "<null or string, the archive error that stopped the run (status 502)>"
                }
            ]
        }
    """
    try:
        if settings.DEBUG:
            debugEndpoint()
        requireRole(RUN_ROLES, 'run the CDR retention job')

        result = runRetention(trigger='api')
        if result['skipped_locked']:
            msg = 'CDR retention is already running on another node'
        elif result['retention_days'] == 0:
            msg = 'CDR retention is off (CDR_RETENTION_DAYS is 0), nothing was deleted'
        elif result['error'] is not None:
            # S3 failed: 502 so callers notice, the partial result says what was archived before it failed
            return createApiResponse(error='http', status_code=StatusCodes.HTTP_BAD_GATEWAY, data=[result],
                msg='CDR archive failed, the remaining CDRs were kept: {}'.format(result['error']))
        else:
            msg = 'CDR retention finished'
        return createApiResponse(msg=msg, data=[result])
    except Exception as ex:
        return showApiError(toHttpError(ex))


@cdr_settings_api.route('/api/v1/settings/cdr/test-webhook', methods=['POST'])
@api_security
def testCdrWebhook():
    """
    Send an empty JSON array to the webhook (header ``X-DSIP-Event: test``)

    The body may hold unsaved CDR_WEBHOOK_* values to test before saving them, missing values come from the
    saved settings. Returns 400 when the webhook can not be reached or does not answer with a 2xx.
    """
    try:
        if settings.DEBUG:
            debugEndpoint()
        requireRole(SETTINGS_ROLES, 'test the CDR webhook settings')

        data = testWebhook(getRequestData() or {})
        return createApiResponse(msg='The webhook answered HTTP {}'.format(data['status']), data=[data])
    except Exception as ex:
        return showApiError(toHttpError(ex))


@cdr_settings_api.route('/api/v1/settings/cdr/run-webhook', methods=['POST'])
@api_security
def runCdrWebhook():
    """
    Send the CDRs written since the last delivery to the webhook now, the same job cron runs every minute

    Each request carries up to 100 CDRs as a JSON array of ``cdrs`` rows (header ``X-DSIP-Event: cdr``).
    CDRs are only marked as sent after a 2xx answer, a failed request is retried with the same CDRs.

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            "error": "<string>",
            "msg":   "<string>",
            "data": [
                {
                    "trigger":        "api",
                    "enabled":        "<bool>",
                    "skipped_locked": "<bool, another node was sending>",
                    "sent":           "<int, CDRs the webhook accepted>",
                    "requests":       "<int>",
                    "deleted":        "<int, sent CDRs deleted because CDR_STORE_CDR is false>",
                    "last_cdr_id":    "<int, the last CDR the webhook accepted>",
                    "error":          "<null or string, the error that stopped the run (status 502)>"
                }
            ]
        }
    """
    try:
        if settings.DEBUG:
            debugEndpoint()
        requireRole(RUN_ROLES, 'run the CDR webhook')

        result = runWebhook(trigger='api')
        if not result['enabled']:
            msg = 'The CDR webhook is off, nothing was sent'
        elif result['skipped_locked']:
            msg = 'The CDR webhook is already running on another node'
        elif result['error'] is not None:
            return createApiResponse(error='http', status_code=StatusCodes.HTTP_BAD_GATEWAY, data=[result],
                msg='CDR webhook failed, the CDRs will be sent on the next run: {}'.format(result['error']))
        else:
            msg = 'Sent {} CDR(s) to the webhook'.format(result['sent'])
        return createApiResponse(msg=msg, data=[result])
    except Exception as ex:
        return showApiError(toHttpError(ex))
