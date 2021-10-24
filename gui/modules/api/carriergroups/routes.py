import os
from flask import Blueprint, render_template, abort, jsonify
from util.security import api_security
from database import SessionLoader, DummySession, dSIPMultiDomainMapping, GatewayGroups
from shared import showApiError,debugEndpoint,StatusCodes, getRequestData,strFieldsToDict, dictToStrFields
from enum import Enum
from werkzeug import exceptions as http_exceptions
import importlib.util
import settings, globals
from  modules.api.carriergroups.functions import *

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

@carriergroups.route('/api/v1/carriergroups',methods=['POST'])
@api_security
def addCarrierGroups():
    
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


        addUpdateCarrierGroups(data)
        return jsonify(response_payload), StatusCodes.HTTP_OK
    
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
