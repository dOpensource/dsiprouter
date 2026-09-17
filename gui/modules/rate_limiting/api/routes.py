import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import requests
from flask import Blueprint, jsonify, render_template, request, session
from modules.api.api_functions import createApiResponse, showApiError, api_security
from modules.api.kamailio.functions import sendJsonRpcCmd
from modules.api.kamailio.errors import KamailioError
from shared import getRequestData, updateConfig, showError, debugException, debugEndpoint
from werkzeug import exceptions as http_exceptions
import settings

rate_limiting_api = Blueprint(
    'rate_limiting',
    __name__,
    template_folder='../templates',
    static_folder='../static',
    static_url_path='/rate_limiting/static'
)


PIKE_FIELDS = {
    'PIKE_SAMPLING_TIME_UNIT': {'type': int, 'default': 2, 'cfg_group': 'pike', 'cfg_name': 'sampling_time_unit'},
    'PIKE_REQS_DENSITY_PER_UNIT': {'type': int, 'default': 50, 'cfg_group': 'pike', 'cfg_name': 'reqs_density_per_unit'},
    'PIKE_REMOVE_LATENCY': {'type': int, 'default': 30, 'cfg_group': 'pike', 'cfg_name': 'remove_latency'},
    'PIKE_IPBAN_PERIOD': {'type': int, 'default': 300, 'cfg_group': 'rate_limiting', 'cfg_name': 'ipban_period'},
}


def _current_pike_settings():
    data = {}
    for key, meta in PIKE_FIELDS.items():
        data[key] = getattr(settings, key, meta['default'])
    return data


def _coerce_pike_payload(payload):
    fields = {}
    for key, meta in PIKE_FIELDS.items():
        if key not in payload:
            continue

        value = payload[key]
        try:
            value = int(str(value).strip())
        except Exception:
            raise http_exceptions.BadRequest(f'{key} must be an integer')

        if value < 1:
            raise http_exceptions.BadRequest(f'{key} must be 1 or greater')

        fields[key] = value

    return fields


def _apply_pike_runtime(fields):
    """
    Push changed pike settings to the running Kamailio instance at runtime,
    using the cfg framework added by kamailio/pike.patch (no reload required).

    :param fields: dict of PIKE_* setting names to their new int values
    :type fields:  dict
    :return:       error message if the live-apply failed, otherwise None
    :rtype:        str|None
    """
    for key, value in fields.items():
        cfg_group = PIKE_FIELDS[key]['cfg_group']
        cfg_name = PIKE_FIELDS[key]['cfg_name']
        try:
            sendJsonRpcCmd('127.0.0.1', 'cfg.set_now_int', [cfg_group, cfg_name, value])
        except requests.exceptions.RequestException as ex:
            return f'Failed to apply pike setting "{cfg_name}" to Kamailio: {str(ex)}'
        except KamailioError as ex:
            return f'Failed to apply pike setting "{cfg_name}" to Kamailio: {str(ex)}'

    return None


def _get_banned_hosts():
    """
    Read the current contents of the live 'ipban' htable from Kamailio.

    :return: list of {'ip': <str>, 'expires': <str>} dicts
    :rtype:  list
    """
    hosts = []

    # htable.dump returns one entry per non-empty hash slot, each containing
    # a "slot" list of {"name": <key>, "value": <val>, "type": <str|int>} items
    dump_result = sendJsonRpcCmd('127.0.0.1', 'htable.dump', ['ipban'])
    for entry in dump_result or []:
        for item in entry.get('slot', []):
            ip = item.get('name')
            if not ip:
                continue

            expires = 'NEVER'
            try:
                # htable.get returns the item wrapped in {'item': {..., 'expire': <str>}}
                get_result = sendJsonRpcCmd('127.0.0.1', 'htable.get', ['ipban', ip])
                if get_result and 'item' in get_result:
                    expires = get_result['item'].get('expire', 'NEVER')
            except (requests.exceptions.RequestException, KamailioError):
                # the entry may have expired between the dump and the get, skip its expiration
                pass

            hosts.append({'ip': ip, 'expires': expires})

    return hosts


@rate_limiting_api.route('/gui/rate_limiting', methods=['GET'])
def rate_limiting_index():
    try:
        if settings.DEBUG:
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        action = request.args.get('action')
        return render_template(
            'rate_limiting.html',
            show_add_onload=action,
            pike=_current_pike_settings(),
            version=settings.VERSION
        )
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        return showError(type='server')


@rate_limiting_api.route('/api/rate_limiting/v1/pike', methods=['GET'])
@api_security
def get_pike_settings():
    try:
        return createApiResponse(msg='Pike settings retrieved', data=[_current_pike_settings()])
    except Exception as ex:
        return showApiError(ex)


@rate_limiting_api.route('/api/rate_limiting/v1/pike', methods=['PUT'])
@api_security
def update_pike_settings():
    try:
        payload = getRequestData() or {}
        fields = _coerce_pike_payload(payload)

        if not fields:
            raise http_exceptions.BadRequest('No pike settings provided')

        updateConfig(settings, fields, hot_reload=True)

        live_apply_error = _apply_pike_runtime(fields)
        response_data = _current_pike_settings()
        if live_apply_error is not None:
            response_data['live_apply_failed'] = True
            response_data['live_apply_msg'] = live_apply_error
            return createApiResponse(
                msg='Pike settings saved, but could not be applied to the running Kamailio instance. '
                    'A manual Kamailio reload/restart may be required.',
                data=[response_data]
            )

        response_data['live_apply_failed'] = False
        response_data['live_apply_msg'] = ''
        return createApiResponse(
            msg='Pike settings updated and applied to the running Kamailio instance',
            data=[response_data]
        )
    except Exception as ex:
        return showApiError(ex)


@rate_limiting_api.route('/api/rate_limiting/v1/banned_hosts', methods=['GET'])
@api_security
def get_banned_hosts():
    try:
        return createApiResponse(msg='Banned hosts retrieved', data=_get_banned_hosts())
    except (requests.exceptions.RequestException, KamailioError) as ex:
        return showApiError(
            http_exceptions.ServiceUnavailable(f'Failed to retrieve banned hosts from Kamailio: {str(ex)}')
        )
    except Exception as ex:
        return showApiError(ex)
