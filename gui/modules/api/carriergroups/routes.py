import sys, os, importlib.util
# make sure the generated source files are imported instead of the template ones
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')
from flask import Blueprint, jsonify
from database import startSession, DummySession, GatewayGroups
from shared import debugEndpoint, StatusCodes, getRequestData, strFieldsToDict
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from util.networking import getExternalIP
from modules.api.api_functions import showApiError, api_security
from modules.api.carriergroups.functions import addUpdateCarrierGroups, addUpdateCarriers
import settings

carriergroups = Blueprint('carriergroups','__name__')


# TODO: standardize response payloads using new createApiResponse()
#       marked for implementation in v0.74


@carriergroups.route('/api/v1/carriergroups',methods=['GET'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['GET'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['DELETE'])
@api_security
def listCarrierGroups():
    """
    List all Carrier Groups\n

    ===============
    Request Payload
    ===============

    .. code-block:: json


    {}

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                carriergroups: [
                    {
                    gwgroupid: <int>,
                    name: <string>,
                    gwlist: <string>
                    }
                ]
            ]
        }
    """
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        carriergroups = db.query(GatewayGroups).filter(
            GatewayGroups.description.regexp_match(GatewayGroups.FILTER.CARRIER.value)
        ).all()

        for carriergroup in carriergroups:
            # Grap the description field, which is comma seperated key/value pair
            fields = strFieldsToDict(carriergroup.description)

            # append summary of endpoint group data
            response_payload['data'].append({
                'gwgroupid': carriergroup.id,
                'name': fields['name'],
                'gwlist': carriergroup.gwlist
            })

        response_payload['msg'] = 'Endpoint groups found'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()

@carriergroups.route('/api/v1/carriergroups/plugin/<string:plugin_name>/config',methods=['GET'])
@api_security
def getPluginMetaData(plugin_name):
    """
    Will return meta data about the plug

    ===============
    Request Payload
    ===============

    .. code-block:: json


    {}

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            authfields: [],
            config <string>,
            kamreload: <bool>,
            data: [
                carriergroups: [
                    {
                    gwgroupid: <int>,
                    name: <string>,
                    gwlist: <string>
                    }
                ]
            ]
        }
    """
    # Import plugin
    # Returns the Base directory of this file
    base_dir = os.path.dirname(__file__)
    try:
        # Use the Base Dir to specify the location of the plugin required for this domain
        spec = importlib.util.spec_from_file_location(format(plugin_name), "{}/plugin/{}/interface.py".format(base_dir,plugin_name))
        plugin  = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(plugin)
        if plugin:
            return plugin.getPluginMetaData()
        else:
            return None

    except Exception as ex:
        print(ex)

@carriergroups.route('/api/v1/carriergroups',methods=['PUT'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['PUT'])
@carriergroups.route('/api/v1/carriergroups',methods=['POST'])
@api_security
def addCarrierGroups(id=None):
    """
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
                    gwgroupid: <int>,
                    endpoints: [
                        <int>,
                        ...
                    ]
                }
            ]
        }
    """

    db = DummySession()

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # defaults.. keep data returned separate from returned metadata
        response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

        # Dictionary to store request parameters
        data = {}

        # get request data
        request_payload = getRequestData()
        data['name'] = request_payload['name']
        data['lb_enabled'] = int(request_payload['lb_enabled']) if 'lb_enabled' in request_payload else 0
        if id == None:
            data['gwgroupid'] = request_payload['gwgroupid'] if 'gwgroupid' in request_payload else ''
        else:
            data['gwgroupid'] = id
        data['strip'] = request_payload['strip'] if 'strip' in request_payload else ''
        data['prefix'] = request_payload['prefix'] if 'prefix' in request_payload else ''

        auth  = request_payload['auth'] if 'auth' in request_payload else None
        if auth:
            data['authtype'] = auth['type']
            data['r_username'] = auth['r_username'] if 'r_username' in auth else ''
            data['auth_username'] = auth['auth_username'] if 'auth_username' in auth else ''
            data['auth_password'] = auth['auth_password'] if 'auth_password' in auth else ''
            data['auth_domain'] = auth['auth_domain'] if 'auth_domain' in auth else settings.DEFAULT_AUTH_DOMAIN
            data['auth_proxy'] = auth['auth_proxy'] if 'auth_proxy' in auth  else ''

        plugin = request_payload['plugin'] if 'plugin' in request_payload else None
        plugin_made_updates = False
        if plugin is not None:
            data['plugin_name'] = plugin['name']
            data['plugin_prefix'] = plugin['plugin_prefix'] if 'plugin_prefix' in plugin else 'dsip-'
            data['plugin_account_sid'] = plugin['account_sid'] if 'account_sid' in plugin else ''
            data['plugin_account_token'] = plugin['account_token'] if 'account_token' in plugin else ''

            if data['plugin_name'] != "":
                # Import Plugin
                from modules.api.carriergroups.plugin.twilio.interface import init, createTrunk, createIPAccessControlList
                client = init(data['plugin_account_sid'], data['plugin_account_token'])

                if client:
                    trunk_name = "{}{}".format(data['plugin_prefix'], data['name'])
                    trunk_sid = createTrunk(client, trunk_name, getExternalIP())
                    if trunk_sid:
                        createIPAccessControlList(client, trunk_name, getExternalIP())
                        plugin_made_updates = True

        endpoints = request_payload['endpoints'] if 'endpoints' in request_payload else []

        # This creates the carrier group only
        gwgroupid = addUpdateCarrierGroups(data)

        # This creates the Twilio Elastic SIP Entry in the Carrier Group
        if plugin_made_updates:
            carrier_data = {}
            carrier_data['gwgroupid'] = gwgroupid
            carrier_data['name'] = trunk_name
            carrier_data['ip_addr'] = "{}.{}".format(trunk_name, "pstn.twilio.com")
            carrier_data['strip'] = ''
            carrier_data['prefix'] = ''
            addUpdateCarriers(carrier_data)

        # Add endpoints
        for endpoint in endpoints:
            #Add the gwgroupdid
            endpoint['gwgroupid'] = gwgroupid
            addUpdateCarriers(endpoint)

        gwgroup_data = {}
        gwgroup_data['gwgroupid'] = gwgroupid
        response_payload['data'].append(gwgroup_data)

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
