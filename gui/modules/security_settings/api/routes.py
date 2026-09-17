import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, jsonify, render_template, request, session
from modules.api.api_functions import createApiResponse, showApiError, api_security
from shared import getRequestData, updateConfig, showError, debugException, debugEndpoint
from werkzeug import exceptions as http_exceptions
import settings

security_settings_api = Blueprint(
    'security_settings',
    __name__,
    template_folder='../templates',
    static_folder='../static',
    static_url_path='/security_settings/static'
)


PIPELIMIT_FIELDS = {
    'PIPELIMIT_HASH_SIZE': {'type': int, 'default': 6},
    'PIPELIMIT_DB_URL': {'type': str, 'default': 'mysql://kamailio:kamailiorw@localhost/kamailio'},
    'PIPELIMIT_PLP_TABLE_NAME': {'type': str, 'default': 'pl_pipes'},
    'PIPELIMIT_PLP_PIPEID_COLUMN': {'type': str, 'default': 'pipeid'},
    'PIPELIMIT_PLP_LIMIT_COLUMN': {'type': str, 'default': 'plimit'},
    'PIPELIMIT_PLP_ALGORITHM_COLUMN': {'type': str, 'default': 'algorithm'},
    'PIPELIMIT_TIMER_INTERVAL': {'type': int, 'default': 10},
    'PIPELIMIT_TIMER_MODE': {'type': int, 'default': 0},
    'PIPELIMIT_LOAD_FETCH': {'type': int, 'default': 1},
    'PIPELIMIT_REPLY_CODE': {'type': int, 'default': 503},
    'PIPELIMIT_REPLY_REASON': {'type': str, 'default': 'Server Unavailable'},
    'PIPELIMIT_CLEAN_UNUSED': {'type': int, 'default': 0},
}


def _current_pipelimit_settings():
    data = {}
    for key, meta in PIPELIMIT_FIELDS.items():
        data[key] = getattr(settings, key, meta['default'])
    return data


def _coerce_pipelimit_payload(payload):
    fields = {}
    for key, meta in PIPELIMIT_FIELDS.items():
        if key not in payload:
            continue

        value = payload[key]
        if meta['type'] is int:
            try:
                value = int(str(value).strip())
            except Exception:
                raise http_exceptions.BadRequest(f'{key} must be an integer')
        else:
            value = str(value).strip()

        fields[key] = value

    if 'PIPELIMIT_TIMER_MODE' in fields and fields['PIPELIMIT_TIMER_MODE'] not in (0, 1):
        raise http_exceptions.BadRequest('PIPELIMIT_TIMER_MODE must be 0 or 1')

    if 'PIPELIMIT_LOAD_FETCH' in fields and fields['PIPELIMIT_LOAD_FETCH'] not in (0, 1):
        raise http_exceptions.BadRequest('PIPELIMIT_LOAD_FETCH must be 0 or 1')

    if 'PIPELIMIT_REPLY_CODE' in fields and (fields['PIPELIMIT_REPLY_CODE'] < 100 or fields['PIPELIMIT_REPLY_CODE'] > 699):
        raise http_exceptions.BadRequest('PIPELIMIT_REPLY_CODE must be between 100 and 699')

    if 'PIPELIMIT_HASH_SIZE' in fields and fields['PIPELIMIT_HASH_SIZE'] < 0:
        raise http_exceptions.BadRequest('PIPELIMIT_HASH_SIZE must be 0 or greater')

    if 'PIPELIMIT_TIMER_INTERVAL' in fields and fields['PIPELIMIT_TIMER_INTERVAL'] < 1:
        raise http_exceptions.BadRequest('PIPELIMIT_TIMER_INTERVAL must be 1 or greater')

    if 'PIPELIMIT_CLEAN_UNUSED' in fields and fields['PIPELIMIT_CLEAN_UNUSED'] < 0:
        raise http_exceptions.BadRequest('PIPELIMIT_CLEAN_UNUSED must be 0 or greater')

    return fields


@security_settings_api.route('/gui/security_settings', methods=['GET'])
def security_settings_index():
    try:
        if settings.DEBUG:
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        action = request.args.get('action')
        return render_template(
            'security_settings.html',
            show_add_onload=action,
            pipelimit=_current_pipelimit_settings(),
            version=settings.VERSION
        )
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        return showError(type='server')


@security_settings_api.route('/api/security_settings/v1/pipelimit', methods=['GET'])
@api_security
def get_pipelimit_settings():
    try:
        return createApiResponse(msg='Pipelimit settings retrieved', data=[_current_pipelimit_settings()])
    except Exception as ex:
        return showApiError(ex)


@security_settings_api.route('/api/security_settings/v1/pipelimit', methods=['PUT'])
@api_security
def update_pipelimit_settings():
    try:
        payload = getRequestData() or {}
        fields = _coerce_pipelimit_payload(payload)

        if not fields:
            raise http_exceptions.BadRequest('No pipelimit settings provided')

        updateConfig(settings, fields, hot_reload=True)

        return createApiResponse(msg='Pipelimit settings updated', data=[_current_pipelimit_settings()])
    except Exception as ex:
        return showApiError(ex)
