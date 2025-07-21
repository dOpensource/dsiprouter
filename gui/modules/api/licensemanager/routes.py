import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, jsonify, request
from werkzeug import exceptions as http_exceptions
from shared import debugEndpoint, debugException, StatusCodes, getRequestData, updateConfig
from modules.api.api_functions import showApiError, api_security
from modules.api.licensemanager.classes import WoocommerceLicense, WoocommerceError
from modules.api.licensemanager.functions import searchLicenses, addToLicenseStore, removeFromLicenseStore
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
import settings

license_manager = Blueprint('licensing', '__name__')

#=================================================================================
# api standard response format
#=================================================================================
# {
#     "error": str,
#     "msg": str,
#     "kamreload": bool,
#     "data": list
# }
#=================================================================================
# error:      error if one occurred (db|http|server|other) or empty string
# msg:        response message (human readable)
# kamreload:  whether kamailio settings need reloaded or not
# data:       data returned, if any
#=================================================================================
# TODO: standardize response payloads using new createApiResponse()
#       marked for implementation in v0.76
#=================================================================================

def showWoocommerceError(ex):
    debugException(ex)
    payload = {
        'error': 'woocommerce',
        'msg': str(ex),
        'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'],
        'data': []
    }
    return jsonify(payload), ex.response.status_code


def validateRequestArgs(data, allowed_args=dict(), required_args=set(), strict_mode=False, extra_checks=dict()):
    # whitelist of extra params allowed if strict mode is disabled
    # typically used with clientside-app-specific args that we ignore in our serverside code
    # for example; the '_' request arg is used by jquery for enabling/disabling caching
    if not strict_mode:
        ignored_args = {'_'}
    else:
        ignored_args = set()

    # validate required args (by key)
    for arg in required_args:
        if arg not in data.keys():
            raise http_exceptions.BadRequest("Missing required request argument: {}".format(arg))

    # validate whitelisted args (key -> value dict)
    for k, v in data.items():
        # is the arg provided in the ignore list
        if k in ignored_args:
            continue
        # is the arg provided in the whitelist
        if k not in allowed_args.keys():
            raise http_exceptions.BadRequest("Invalid request argument provided: {}".format(k))
        # is the arg provided the right type
        if not type(v) == allowed_args[k]:
            # in strict mode we do not attempt casting
            if strict_mode:
                raise http_exceptions.BadRequest("Invalid request argument '{}' wrong type".format(k))
            # try casting to correct type in case the query arg was parsed as the wrong type
            # this typically only happens with query args in the url (they are usually set to str by Flask)
            try:
                data[k] = allowed_args[k](v)
            except ValueError:
                raise http_exceptions.BadRequest("Invalid request argument '{}' wrong type".format(k))

        # does this argument have extra constraints to follow?
        try:
            if not extra_checks[k](v):
                raise http_exceptions.BadRequest("Invalid request argument '{}' failed constraint checks".format(k))
        except KeyError:
            pass


@license_manager.route('/api/v1/licensing/validate', methods=['GET'])
@api_security
def validateLicense():
    """
    Validate a License

    =================
    Request Arguments
    =================

    .. code-block:: text

        license_key=<string>
        key_encrypted=<bool>

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                <bool>
            ]
        }
    """
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        data = request.args.to_dict()

        # sanity checks (whitelist of acceptable args in the request body)
        validateRequestArgs(data, allowed_args={'license_key': str, 'key_encrypted': bool}, required_args={'license_key'})

        # retrieve the license
        if data.get('key_encrypted', False):
            matches = searchLicenses(key_combo=data['license_key'], decrypt=True)
        else:
            matches = searchLicenses(data['license_key'])

        if len(matches) == 0:
            response_payload['data'].append(False)
            response_payload['msg'] = 'license does not exist'
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND

        lc = matches[0]
        if not lc.active:
            response_payload['data'].append(False)
            response_payload['msg'] = 'license has not been activated'
            return jsonify(response_payload), StatusCodes.HTTP_OK

        if not lc.machine_match:
            response_payload['data'].append(False)
            response_payload['msg'] = 'license is not registered to this node'
            return jsonify(response_payload), StatusCodes.HTTP_OK

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except WoocommerceError as ex:
        return showWoocommerceError(ex)
    except Exception as ex:
        return showApiError(ex)


@license_manager.route('/api/v1/licensing/retrieve', methods=['GET'])
@api_security
def retrieveLicense():
    """
    Retrieve details about a License

    =================
    Request Arguments
    =================

    .. code-block:: text

        license_key=<string>
        key_encrypted=<bool>


    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                {
                    license_key: <string>
                    type: <string>
                    expires: <string>
                    active: <bool>
                    valid: <bool>
                }
            ]
        }
    """
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        data = request.args.to_dict()

        # sanity checks (whitelist of acceptable args in the request body)
        validateRequestArgs(data, allowed_args={'license_key': str, 'key_encrypted': bool}, required_args={'license_key'})

        if data.get('key_encrypted', False):
            matches = searchLicenses(key_combo=data['license_key'], decrypt=True)
        else:
            matches = searchLicenses(data['license_key'])

        if len(matches) == 0:
            response_payload['data'].append({})
            response_payload['msg'] = 'license does not exist'
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND

        response_payload['data'].append(dict(matches[0]))
        response_payload['msg'] = 'successfully retrieved license'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except WoocommerceError as ex:
        return showWoocommerceError(ex)
    except Exception as ex:
        return showApiError(ex)


@license_manager.route('/api/v1/licensing/list', methods=['GET'])
@api_security
def listLicenses():
    """
    Retrieve details about all License's associated to this node

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                {
                    license_key: <string>
                    type: <string>
                    expires: <string>
                    active: <bool>
                    valid: <bool>
                },
                ...
            ]
        }
    """
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        response_payload['data'] = [dict(lc) for lc in searchLicenses()]
        response_payload['msg'] = 'successfully retrieved licenses'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except WoocommerceError as ex:
        return showWoocommerceError(ex)
    except Exception as ex:
        return showApiError(ex)


@license_manager.route('/api/v1/licensing/activate', methods=['PUT'])
@api_security
def activateLicense():
    """
    Activate a License

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            license_key: <string>,
            key_encrypted: <bool>
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                {
                    license_key: <string>
                    type: <string>
                    expires: <string>
                    active: <bool>
                    valid: <bool>
                }
            ]
        }
    """
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        data = getRequestData()

        # sanity checks (whitelist of acceptable args in the request body)
        validateRequestArgs(data, allowed_args={'license_key': str, 'key_encrypted': bool}, required_args={'license_key'})

        if data.get('key_encrypted', False):
            args = dict(key_combo=data['license_key'], decrypt=True)
        else:
            args = dict(license_key=data['license_key'])

        matches = searchLicenses(**args)
        if len(matches) == 0:
            lc = WoocommerceLicense(**args)
        else:
            lc = matches[0]

        lc.activate()
        addToLicenseStore(lc)

        response_payload['data'].append(dict(lc))
        response_payload['msg'] = 'activation succeeded'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except WoocommerceError as ex:
        return showWoocommerceError(ex)
    except Exception as ex:
        return showApiError(ex)


@license_manager.route('/api/v1/licensing/deactivate', methods=['PUT'])
@api_security
def deactivateLicense():
    """
    Deactivate a License

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            license_key: <string>,
            key_encrypted: <bool>
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: []
        }
    """
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        data = getRequestData()

        # sanity checks (whitelist of acceptable args in the request body)
        validateRequestArgs(data, allowed_args={'license_key': str, 'key_encrypted': bool}, required_args={'license_key'})

        if data.get('key_encrypted', False):
            args = dict(key_combo=data['license_key'], decrypt=True)
        else:
            args = dict(license_key=data['license_key'])

        matches = searchLicenses(**args)
        if len(matches) == 0:
            response_payload['error'] = 'other'
            response_payload['msg'] = 'submitted key does not exist on this system'
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND
        else:
            lc = matches[0]

        lc.deactivate()
        removeFromLicenseStore(lc)

        response_payload['msg'] = 'deactivation succeeded'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except WoocommerceError as ex:
        return showWoocommerceError(ex)
    except Exception as ex:
        return showApiError(ex)
