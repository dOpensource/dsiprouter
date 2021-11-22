import os
from flask import Blueprint, render_template, abort, jsonify
from util.security import api_security
from database import SessionLoader, DummySession, dSIPMultiDomainMapping, GatewayGroups
from shared import getExternalIP,showApiError,debugEndpoint,StatusCodes, getRequestData,strFieldsToDict, dictToStrFields
from enum import Enum
from werkzeug import exceptions as http_exceptions
import importlib.util
import settings, globals
from modules.api.carriergroups.functions import *

carriergroups = Blueprint('carriergroups','__name__')

@carriergroups.route('/api/v1/carriergroups',methods=['GET'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['GET'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['DELETE'])
@carriergroups.route('/api/v1/carriergroups/<string:id>',methods=['PUT'])
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
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    typeFilter = "%type:{}%".format(str(settings.FLT_CARRIER))

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        carriergroups = db.query(GatewayGroups).filter(GatewayGroups.description.like(typeFilter)).all()

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

@carriergroups.route('/api/v1/carriergroups',methods=['POST'])
@api_security
def addCarrierGroups():
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

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()
    
        # defaults.. keep data returned separate from returned metadata
        response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
        
        # Dictionary to store request parameters
        data = {}

        # get request data
        request_payload = getRequestData()
        data['name'] = request_payload['name']
        data['gwgroup'] = ""
        auth  = request_payload['auth'] if 'auth' in request_payload else ''
        if auth:
            data['authtype'] = auth['type']
            data['r_username'] = auth['r_username'] if 'r_username' in auth else ''
            data['auth_username'] = auth['auth_username'] if 'auth_username' in auth else ''
            data['auth_password'] = auth['auth_password'] if 'auth_password' in auth else ''
            data['auth_domain'] = auth['auth_domain'] if 'auth_domain' in auth else settings.DEFAULT_AUTH_DOMAIN
            data['auth_proxy'] = auth['auth_proxy'] if 'auth_proxy' in auth  else ''

        plugin = request_payload['plugin'] if 'plugin' in request_payload else ''
        if plugin:
            data['plugin_name'] = plugin['name']
            data['plugin_prefix'] = plugin['prefix'] if 'prefix' in plugin else ''
            data['plugin_account_sid'] = plugin['account_sid'] if 'account_sid' in plugin else ''
            data['plugin_account_token'] = plugin['account_token'] if 'account_token' in plugin else ''
        
        endpoints = request_payload['endpoints'] if 'endpoints' in request_payload else ''

        if plugin:
            # Import Plugin
            #from "modules.api.carriergroups.plugin.{}".format(lower(plugin_name)) import init, createTrunk
            from modules.api.carriergroups.plugin.twilio.interface import init, createTrunk, createIPAccessControlList
            client=init(data['plugin_account_sid'],data['plugin_account_token'])
            if client:
                if (len(data['plugin_prefix']) == 0):
                    plugin_prefix = "dsip"

                trunk_name = "{}{}".format(plugin_prefix,data['name']) 
                trunk_sid = createTrunk(client,trunk_name, getExternalIP())
                if trunk_sid:
                    createIPAccessControlList(client,trunk_name,getExternalIP())

        gwgroupid = addUpdateCarrierGroups(data)
        print("*****:{}".format(gwgroupid))
        if gwgroupid:
            carrier_data = {}
            carrier_data['gwgroup'] = gwgroup
            carrier_data['name'] = trunk_name
            carrier_data['ip_addr'] = "{}.{}".format(trunk_name, "pstn.twilio.com")
            carrier_data['strip'] = ''
            carrier_data['prefix'] = ''
            addUpdateCarriers(carrier_data)

        gwgroup_data['gwgroupid'] = gwgroupid
        response_payload['data'].append(gwgroup_data)

        return jsonify(response_payload), StatusCodes.HTTP_OK
    
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
