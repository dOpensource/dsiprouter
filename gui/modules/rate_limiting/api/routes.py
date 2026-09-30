import sys, os, re
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import requests
from flask import Blueprint, jsonify, render_template, request, session
from modules.api.api_functions import createApiResponse, showApiError, api_security
from modules.api.kamailio.functions import sendJsonRpcCmd
from modules.api.kamailio.errors import KamailioError
from shared import getRequestData, updateConfig, showError, debugException, debugEndpoint, IO
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
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


def _persist_pike_to_kamcfg(fields):
    """
    Persist changed pike/rate_limiting settings directly into the Kamailio config file
    on disk, so the values are correctly loaded the next time Kamailio (re)starts.

    Pike settings (sampling_time_unit, reqs_density_per_unit, remove_latency) are set
    via modparam() and are only ever read at Kamailio startup, while ipban_period is a
    plain global cfg param. Neither of these are updated by settings.py alone, and the
    RPC based hot reload only changes the running process' in-memory value, not what is
    on disk, so without this the settings would revert on the next Kamailio restart.

    :param fields: dict of PIKE_* setting names to their new int values
    :type fields:  dict
    """
    with open(settings.KAM_CFG_PATH, 'r+') as kamcfg:
        kamcfg_str = kamcfg.read()

        for key, value in fields.items():
            cfg_group = PIKE_FIELDS[key]['cfg_group']
            cfg_name = PIKE_FIELDS[key]['cfg_name']

            if cfg_group == 'pike':
                # pike settings are configured via modparam(), e.g.:
                # modparam("pike", "sampling_time_unit", 2)
                regex = r'(modparam\(\s*[\'"]pike[\'"]\s*,\s*[\'"]' + re.escape(cfg_name) + \
                        r'[\'"]\s*,\s*)\d+(\s*\))'
            else:
                # other settings are plain global cfg params, e.g.:
                # rate_limiting.ipban_period = 300 desc "..."
                regex = r'^(' + re.escape(f'{cfg_group}.{cfg_name}') + r'[ \t]*=[ \t]*)\d+([ \t]+desc[ \t]+.*)?$'

            replace_str = r'\g<1>' + str(value) + r'\g<2>'
            kamcfg_str = re.sub(regex, replace_str, kamcfg_str, flags=re.MULTILINE)

        kamcfg.seek(0)
        kamcfg.write(kamcfg_str)
        kamcfg.truncate()


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

        try:
            _persist_pike_to_kamcfg(fields)
        except Exception as ex:
            IO.logerr(f'Problem updating the {settings.KAM_CFG_PATH} configuration file: {str(ex)}')
            raise http_exceptions.InternalServerError(
                'Pike settings saved, but failed to persist them to the Kamailio config file. '
                'They may not take effect after a Kamailio restart.'
            )

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True

        response_data = _current_pike_settings()
        return createApiResponse(
            msg='Pike settings saved. A Kamailio reload is required for the changes to take effect.',
            kamreload=True,
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
