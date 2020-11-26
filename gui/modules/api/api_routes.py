import os, time, json, random, subprocess, requests, csv, base64
import urllib.parse as parse
from collections import OrderedDict
from functools import wraps
from datetime import datetime
from flask import Blueprint, jsonify, render_template, request, session, send_file, Response
from sqlalchemy import exc as sql_exceptions, and_
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import secure_filename
from database import SessionLoader, DummySession, Address, dSIPNotification, Domain, DomainAttrs, dSIPDomainMapping, \
    dSIPMultiDomainMapping, Dispatcher, Gateways, GatewayGroups, Subscribers, dSIPLeases, dSIPMaintModes, \
    dSIPCallLimits, InboundMapping, dSIPCDRInfo, dSIPCertificates
from shared import allowed_file, dictToStrFields, getExternalIP, hostToIP, isCertValid, rowToDict, showApiError, \
    debugEndpoint, StatusCodes, strFieldsToDict, IO, getRequestData, safeUriToHost, safeStripPort
from util.notifications import sendEmail
from util.security import AES_CTR, urandomChars
from util.file_handling import isValidFile, change_owner
from util.kamtls import *
from util.cron import getTaggedCronjob, addTaggedCronjob, updateTaggedCronjob, deleteTaggedCronjob, \
    cronIntervalToDescription
from util.letsencrypt import *
import settings, globals

api = Blueprint('api', __name__)


# TODO: we need to standardize our response payload, preferably we can create a custom response class
#       proposed format:    { 'error': '', 'msg': '', 'kamreload': True/False, 'data': [] }
#                           error:      error string if one occurred (db|http|server)
#                           msg:        response message string
#                           kamreload:  bool, whether kam requires a reload
#                           data:       dict of data returned, if any
#       currently all the formats are different for each endpoint, we need to change this!!
# TODO: this is almost impossible to work on...
#       we need to abstract out common code between gui and api and standardize routes!

class APIToken:
    token = None

    def __init__(self, request):
        if 'Authorization' in request.headers:
            auth_header = request.headers.get('Authorization', None)
            if auth_header is not None:
                header_values = auth_header.split(' ')
                if len(header_values) == 2:
                    self.token = header_values[1]

    def isValid(self):
        try:
            if self.token:
                # Get Environment Variables if in debug mode
                # This is the only case we allow plain text token comparison
                if settings.DEBUG:
                    settings.DSIP_API_TOKEN = os.getenv('DSIP_API_TOKEN', settings.DSIP_API_TOKEN)

                # need to decrypt token
                if isinstance(settings.DSIP_API_TOKEN, bytes):
                    tokencheck = AES_CTR.decrypt(settings.DSIP_API_TOKEN).decode('utf-8')
                else:
                    tokencheck = settings.DSIP_API_TOKEN

                return tokencheck == self.token

            return False
        except:
            return False


def api_security(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        apiToken = APIToken(request)

        if not session.get('logged_in') and not apiToken.isValid():
            accept_header = request.headers.get('Accept', '')

            if 'text/html' in accept_header:
                return render_template('index.html', version=settings.VERSION), StatusCodes.HTTP_UNAUTHORIZED
            else:
                payload = {'error': 'http', 'msg': 'Unauthorized', 'kamreload': globals.reload_required, 'data': []}
                return jsonify(payload), StatusCodes.HTTP_UNAUTHORIZED
        return func(*args, **kwargs)

    return wrapper


@api.route("/api/v1/kamailio/stats", methods=['GET'])
@api_security
def getKamailioStats():
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    stats_data = {'current': 0}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        jsonrpc_payload = {"jsonrpc": "2.0", "method": "tm.stats", "id": 1}
        r = requests.get('http://127.0.0.1:5060/api/kamailio', json=jsonrpc_payload)
        if r.status_code >= 400:
            ex = http_exceptions.HTTPException(r.reason)
            ex.code = r.status_code
            raise ex

        response_payload['msg'] = 'Successfully retrieved kamailio stats'
        response_payload['data'].append(r.json()['result'])
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@api.route("/api/v1/kamailio/reload", methods=['GET'])
@api_security
def reloadKamailio():
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        # format some settings for kam config
        dsip_api_url = settings.DSIP_API_PROTO + '://' + '127.0.0.1' + ':' + str(settings.DSIP_API_PORT)
        if isinstance(settings.DSIP_API_TOKEN, bytes):
            dsip_api_token = AES_CTR.decrypt(settings.DSIP_API_TOKEN).decode('utf-8')
        else:
            dsip_api_token = settings.DSIP_API_TOKEN

        # Pulled tls.reload out of the reload process due to issues
        #{'method': 'tls.reload', 'jsonrpc': '2.0', 'id': 1},

        reload_cmds = [
            {"method": "permissions.addressReload", "jsonrpc": "2.0", "id": 1},
            {'method': 'drouting.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'domain.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'tls.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'dispatcher.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["tofromprefix"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["maintmode"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["calllimit"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["gw2gwgroup"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_hardfwd"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_failfwd"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_prefixmap"]},
            {'method': 'uac.reg_reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'cfg.seti', 'jsonrpc': '2.0', 'id': 1,
             'params': ['teleblock', 'gw_enabled', str(settings.TELEBLOCK_GW_ENABLED)]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'role', settings.ROLE]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'api_server', dsip_api_url]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'api_token', dsip_api_token]}
        ]

        if settings.TELEBLOCK_GW_ENABLED:
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'gw_ip', str(settings.TELEBLOCK_GW_IP)]})
            reload_cmds.append(
                {'method': 'cfg.seti', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'gw_port', str(settings.TELEBLOCK_GW_PORT)]})
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'media_ip', str(settings.TELEBLOCK_MEDIA_IP)]})
            reload_cmds.append(
                {'method': 'cfg.seti', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'media_port', str(settings.TELEBLOCK_MEDIA_PORT)]})

        for cmdset in reload_cmds:
            print("Cmd: {}".format(cmdset))
            r = requests.get('http://127.0.0.1:5060/api/kamailio', json=cmdset)
            if r.status_code >= 400:
                try:
                    msg = r.json()['error']['message']
                except:
                    msg = r.reason
                ex = http_exceptions.HTTPException(msg)
                ex.code = r.status_code
                raise ex

        response_payload['msg'] = 'Kamailio reload succeeded'
        globals.reload_required = False
        response_payload['kamreload'] = False
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


# TODO: this func actually adds an endpoint lease
#       it should be renamed and changed to use POST method
# TODO: the last lease id/username generated must be tracked (just query DB)
#       and used to determine next lease id, otherwise conflicts may occur
@api.route("/api/v1/endpoint/lease", methods=['GET'])
@api_security
def getEndpointLease():
    db = DummySession()

    DEF_PASSWORD_LEN = 32

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    lease_data = {}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        email = request.args.get('email')
        if not email:
            raise Exception("email parameter is missing")

        ttl = request.args.get('ttl', None)
        if ttl is None:
            raise http_exceptions.BadRequest("time to live (ttl) parameter is missing")

        # Generate some values
        rand_num = random.randint(1, 200)
        name = "lease" + str(rand_num)
        auth_username = name
        auth_password = urandomChars(DEF_PASSWORD_LEN)
        auth_domain = settings.DOMAIN

        # Set some defaults
        host_addr = ''
        strip = ''
        prefix = ''

        # Add the Gateways table
        Gateway = Gateways(name, host_addr, strip, prefix, settings.FLT_PBX)
        db.add(Gateway)
        db.flush()

        # Add the Subscribers table
        Subscriber = Subscribers(auth_username, auth_password, auth_domain, Gateway.gwid, email)
        db.add(Subscriber)
        db.flush()

        # Add to the Leases table
        Lease = dSIPLeases(Gateway.gwid, Subscriber.id, int(ttl))
        db.add(Lease)
        db.flush()

        lease_data['leaseid'] = Lease.id
        lease_data['username'] = auth_username
        lease_data['password'] = auth_password
        lease_data['domain'] = auth_domain
        lease_data['ttl'] = ttl

        db.commit()
        response_payload['data'].append(lease_data)
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/endpoint/lease/<int:leaseid>/revoke", methods=['DELETE'])
@api_security
def revokeEndpointLease(leaseid):
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # Query the Lease ID
        Lease = db.query(dSIPLeases).filter(dSIPLeases.id == leaseid).first()

        # Remove the entry in the Subscribers table
        Subscriber = db.query(Subscribers).filter(Subscribers.id == Lease.sid).first()
        db.delete(Subscriber)

        # Remove the entry in the Gateway table
        Gateway = db.query(Gateways).filter(Gateways.gwid == Lease.gwid).first()
        db.delete(Gateway)

        # Remove the entry in the Lease table
        db.delete(Lease)

        db.commit()
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: is this endpoint still used?
@api.route("/api/v1/endpoint/<int:id>", methods=['POST'])
@api_security
def updateEndpoint(id):
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # Covert JSON message to Dictionary Object
        request_payload = getRequestData()

        # Only handling the maintmode attribute on this release
        if 'maintmode' not in request_payload:
            raise http_exceptions.BadRequest('maintmode attribute missing')

        if request_payload['maintmode'] == 0:
            MaintMode = db.query(dSIPMaintModes).filter(dSIPMaintModes.gwid == id).first()
            if MaintMode:
                db.delete(MaintMode)
        elif request_payload['maintmode'] == 1:
            # Lookup Gateway ip adddess
            Gateway = db.query(Gateways).filter(Gateways.gwid == id).first()
            if Gateway != None:
                MaintMode = dSIPMaintModes(Gateway.address, id)
                db.add(MaintMode)

        db.commit()
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except sql_exceptions.IntegrityError as ex:
        db.rollback()
        db.flush()
        response_payload['msg'] = "endpoint {} is already in maintmode".format(id)
        return showApiError(ex, response_payload)
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: we should optimize this and cleanup reused code
@api.route("/api/v1/inboundmapping", methods=['GET', 'POST', 'PUT', 'DELETE'])
@api_security
def handleInboundMapping():
    """
    Endpoint for Inbound DID Rule Mapping
    """

    db = DummySession()

    # use a whitelist to avoid possible SQL Injection vulns
    VALID_REQUEST_ARGS = {'ruleid', 'did'}

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {'did', 'servers', 'name'}

    # defaults.. keep data returned separate from returned metadata
    payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # =========================================
        # get rule for DID mapping or list of rules
        # =========================================
        if request.method == "GET":
            # sanity check
            for arg in request.args:
                if arg not in VALID_REQUEST_ARGS:
                    raise http_exceptions.BadRequest("Request argument not recognized")

            # get single rule by ruleid
            rule_id = request.args.get('ruleid')
            if rule_id is not None:
                res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                    InboundMapping.ruleid == rule_id).first()
                if res is not None:
                    data = rowToDict(res)
                    data = {'ruleid': data['ruleid'], 'did': data['prefix'],
                            'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(data['description']) else '',
                            'servers': data['gwlist'].split(',')}
                    payload['data'].append(data)
                    payload['msg'] = 'Rule Found'
                else:
                    payload['msg'] = 'No Matching Rule Found'

            # get single rule by did
            else:
                did_pattern = request.args.get('did')
                if did_pattern is not None:
                    res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                        InboundMapping.prefix == did_pattern).first()
                    if res is not None:
                        data = rowToDict(res)
                        data = {'ruleid': data['ruleid'], 'did': data['prefix'],
                                'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(data['description']) else '',
                                'servers': data['gwlist'].split(',')}
                        payload['data'].append(data)
                        payload['msg'] = 'DID Found'
                    else:
                        payload['msg'] = 'No Matching DID Found'

                # get list of rules
                else:
                    res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).all()
                    if len(res) > 0:
                        for row in res:
                            data = rowToDict(row)
                            data = {'ruleid': data['ruleid'], 'did': data['prefix'],
                                    'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(data['description']) else '',
                                    'servers': data['gwlist'].split(',')}
                            payload['data'].append(data)
                        payload['msg'] = 'Rules Found'
                    else:
                        payload['msg'] = 'No Rules Found'

            return jsonify(payload), StatusCodes.HTTP_OK

        # ===========================
        # create rule for DID mapping
        # ===========================
        elif request.method == "POST":
            data = getRequestData()

            # sanity checks
            for arg in data:
                if arg not in VALID_REQUEST_DATA_ARGS:
                    raise http_exceptions.BadRequest("Request data argument not recognized")

            if 'servers' not in data:
                raise http_exceptions.BadRequest('Servers to map DID to are required')
            elif len(data['servers']) < 1 or len(data['servers']) > 2:
                raise http_exceptions.BadRequest('Primary Server missing or More than 2 Servers Provided')
            elif 'did' not in data:
                raise http_exceptions.BadRequest('DID is required')

            # TODO: we should be checking dr_gateways table to make sure the servers exist
            for i in range(0, len(data['servers'])):
                try:
                    data['servers'][i] = str(data['servers'][i])
                    #_ = int(data['servers'][i])
                except:
                    raise http_exceptions.BadRequest('Invalid Server ID')
            for c in data['did']:
                if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                    raise http_exceptions.BadRequest(
                        'DID improperly formatted. Allowed characters: {}'.format(','.join(settings.DID_PREFIX_ALLOWED_CHARS)))

            gwlist = ','.join(data['servers'])
            prefix = data['did']
            description = 'name:{}'.format(data['name']) if 'name' in data else ''

            # don't allow duplicate entries
            if db.query(InboundMapping).filter(InboundMapping.prefix == prefix).filter(
                    InboundMapping.groupid == settings.FLT_INBOUND).scalar():
                raise http_exceptions.BadRequest("Duplicate DID's are not allowed")
            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
            db.add(IMap)

            db.commit()
            globals.reload_required = True
            payload['kamreload'] = globals.reload_required
            payload['msg'] = 'Rule Created'
            return jsonify(payload), StatusCodes.HTTP_OK

        # ===========================
        # update rule for DID mapping
        # ===========================
        elif request.method == "PUT":
            # sanity check
            for arg in request.args:
                if arg not in VALID_REQUEST_ARGS:
                    raise http_exceptions.BadRequest("Request argument not recognized")

            data = getRequestData()
            updates = {}

            # sanity checks
            for arg in data:
                if arg not in VALID_REQUEST_DATA_ARGS:
                    raise http_exceptions.BadRequest("Request data argument not recognized")

            if 'did' not in data and 'servers' not in data and 'name' not in data:
                raise http_exceptions.BadRequest("No data args supplied, {did, and servers} is required")
            # TODO: we should be checking dr_gateways table to make sure the servers exist
            if 'servers' in data:
                if len(data['servers']) < 1 or len(data['servers']) > 2:
                    raise http_exceptions.BadRequest('Primary Server missing or More than 2 Servers Provided')
                else:
                    for i in range(0, len(data['servers'])):
                        try:
                            data['servers'][i] = str(data['servers'][i])
                            #_ = int(data['servers'][i])
                        except:
                            raise http_exceptions.BadRequest('Invalid Server ID')
                updates['gwlist'] = ','.join(data['servers'])
            if 'did' in data:
                for c in data['did']:
                    if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                        raise http_exceptions.BadRequest(
                            'DID improperly formatted. Allowed characters: {}'.format(','.join(settings.DID_PREFIX_ALLOWED_CHARS)))
                updates['prefix'] = data['did']
            if 'name' in data:
                updates['description'] = 'name:{}'.format(data['name'])

            # update single rule by ruleid
            rule_id = request.args.get('ruleid')
            if rule_id is not None:
                res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                    InboundMapping.ruleid == rule_id).update(
                    updates, synchronize_session=False)
                if res > 0:
                    payload['msg'] = 'Rule Updated'
                else:
                    payload['msg'] = 'No Matching Rule Found'

            # update single rule by did
            else:
                did_pattern = request.args.get('did')
                if did_pattern is not None:
                    res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                        InboundMapping.prefix == did_pattern).update(
                        updates, synchronize_session=False)
                    if res > 0:
                        payload['msg'] = 'Rule Updated'
                    else:
                        payload['msg'] = 'No Matching Rule Found'

                # no other options
                else:
                    raise http_exceptions.BadRequest('One of the following is required: {ruleid, or did}')

            db.commit()
            globals.reload_required = True
            payload['kamreload'] = globals.reload_required
            return jsonify(payload), StatusCodes.HTTP_OK

        # ===========================
        # delete rule for DID mapping
        # ===========================
        elif request.method == "DELETE":
            # sanity check
            for arg in request.args:
                if arg not in VALID_REQUEST_ARGS:
                    raise http_exceptions.BadRequest("Request argument not recognized")

            # delete single rule by ruleid
            rule_id = request.args.get('ruleid')
            if rule_id is not None:
                rule = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                    InboundMapping.ruleid == rule_id)
                rule.delete(synchronize_session=False)

            # delete single rule by did
            else:
                did_pattern = request.args.get('did')
                if did_pattern is not None:
                    rule = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                        InboundMapping.prefix == did_pattern)
                    rule.delete(synchronize_session=False)

                # no other options
                else:
                    raise http_exceptions.BadRequest('One of the following is required: {ruleid, or did}')

            db.commit()
            globals.reload_required = True
            payload['kamreload'] = True
            payload['msg'] = 'Rule Deleted'
            return jsonify(payload), StatusCodes.HTTP_OK

        # not possible
        else:
            raise Exception('Unknown Error Occurred')

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/notification/gwgroup", methods=['POST'])
@api_security
def handleNotificationRequest():
    """
    Endpoint for Sending Notifications
    """

    db = DummySession()

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {'gwgroupid': int, 'type': int, 'text_body': str,
                               'gwid': int, 'subject': str, 'sender': str}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # ============================
        # create and send notification
        # ============================

        data = getRequestData()

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))
        if 'gwgroupid' not in data:
            raise http_exceptions.BadRequest('Gateway Group ID is required')
        elif 'type' not in data:
            raise http_exceptions.BadRequest('Notification Type is required')
        elif 'text_body' not in data:
            raise http_exceptions.BadRequest('Text Body is required')

        # lookup recipients
        gwgroupid = data.pop('gwgroupid')
        notif_type = data.pop('type')
        notification_row = db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid).filter(
            dSIPNotification.type == notif_type).first()
        if notification_row is None:
            raise sql_exceptions.SQLAlchemyError('DB Entry Missing for {}'.format(str(gwgroupid)))

        # customize message based on type
        gwid = data.pop('gwid', None)
        gw_row = db.query(Gateways).filter(Gateways.gwid == gwid).first() if gwid is not None else None
        gw_name = strFieldsToDict(gw_row.description)['name'] if gw_row is not None else ''
        gwgroup_row = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        gwgroup_name = strFieldsToDict(gwgroup_row.description)['name'] if gwgroup_row is not None else ''
        if notif_type == dSIPNotification.FLAGS.TYPE_OVERLIMIT.value:
            data['html_body'] = (
                '<html><head><style>.error{{border: 1px solid; margin: 10px 0px; padding: 15px 10px 15px 50px; background-color: #FF5555;}}</style></head>'
                '<body><div class="error"><strong>Call Limit Exceeded in Endpoint Group [{}] on Endpoint [{}]</strong></div></body>').format(
                gwgroup_name, gw_name)
        elif notif_type == dSIPNotification.FLAGS.TYPE_GWFAILURE.value:
            data['html_body'] = (
                '<html><head><style>.error{{border: 1px solid; margin: 10px 0px; padding: 15px 10px 15px 50px; background-color: #FF5555;}}</style></head>'
                '<body><div class="error"><strong>Failure Detected in Endpoint Group [{}] on Endpoint [{}]</strong></div></body>').format(
                gwgroup_name, gw_name)

        # # get attachments if any uploaded
        # data['attachments'] = []
        # if len(request.files) > 0:
        #     for upload in request.files:
        #         if upload.filename != '' and isValidFile(upload.filename):
        #             data['attachments'].append(upload)

        # TODO: we only support email at this time, add support for slack
        if notification_row.method == dSIPNotification.FLAGS.METHOD_EMAIL.value:
            data['recipients'] = [notification_row.value]
            sendEmail(**data)
        elif notification_row.method == dSIPNotification.FLAGS.METHOD_SLACK.value:
            pass

        response_payload['msg'] = 'Email Sent'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/endpointgroups/<int:gwgroupid>", methods=['DELETE'])
@api_security
def deleteEndpointGroup(gwgroupid):
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        endpointgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid)
        if endpointgroup is not None:
            endpointgroup.delete(synchronize_session=False)
        else:
            raise http_exceptions.NotFound("The endpoint group doesn't exist")

        calllimit = db.query(dSIPCallLimits).filter(dSIPCallLimits.gwgroupid == str(gwgroupid))
        if calllimit is not None:
            calllimit.delete(synchronize_session=False)

        subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid)
        if subscriber is not None:
            subscriber.delete(synchronize_session=False)

        typeFilter = "%gwgroup:{}%".format(gwgroupid)
        endpoints = db.query(Gateways).filter(Gateways.description.like(typeFilter))
        if endpoints is not None:
            address_ids = []
            for endpoint in endpoints:
                description_dict = strFieldsToDict(endpoint.description)
                if 'addr_id' in description_dict:
                    address_ids.append(description_dict['addr_id'])
            db.query(Address).filter(Address.id.in_(address_ids)).delete(synchronize_session=False)
            endpoints.delete(synchronize_session=False)

        notifications = db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid)
        if notifications is not None:
            notifications.delete(synchronize_session=False)

        cdrinfo = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid)
        if cdrinfo is not None:
            cdrinfo.delete(synchronize_session=False)
            deleteTaggedCronjob(gwgroupid)
            # if not deleteTaggedCronjob(gwgroupid):
            #    raise Exception('Crontab entry could not be deleted')

        domainmapping = db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwgroupid)
        if domainmapping is not None:
            domainmapping.delete(synchronize_session=False)

        db.commit()
        response_payload['status'] = 200
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/endpointgroups/<int:gwgroupid>", methods=['GET'])
@api_security
def getEndpointGroup(gwgroupid):
    db = DummySession()

    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    gwgroup_data = {}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        endpointgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if endpointgroup is not None:
            gwgroup_data['name'] = strFieldsToDict(endpointgroup.description)['name']
        else:
            raise http_exceptions.NotFound("Endpoint Group Does Not Exist")

        # Send back the gateway groupid that was requested
        gwgroup_data['gwgroupid'] = gwgroupid

        calllimit = db.query(dSIPCallLimits).filter(dSIPCallLimits.gwgroupid == str(gwgroupid)).first()
        if calllimit is not None:
            gwgroup_data['calllimit'] = calllimit.limit

        # Check to see if a subscriber record exists.  If so, auth is userpwd
        auth = {}
        subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid).first()
        if subscriber is not None:
            auth['type'] = "userpwd"
            auth['user'] = subscriber.username
            auth['pass'] = subscriber.password
            auth['domain'] = subscriber.domain
        else:
            auth['type'] = "ip"

        gwgroup_data['auth'] = auth

        gwgroup_data['endpoints'] = []

        endpointList = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if endpointList is not None:
            endpointGatewayList = endpointList.gwlist.split(',')
            endpoints = db.query(Gateways).filter(Gateways.gwid.in_(endpointGatewayList))

            for endpoint in endpoints:
                ep = {}
                ep['gwid'] = endpoint.gwid
                ep['hostname'] = endpoint.address
                ep['description'] = strFieldsToDict(endpoint.description)['name']
                ep['maintmode'] = ""

                gwgroup_data['endpoints'].append(ep)
                gwgroup_data['strip'] = endpoint.strip
                gwgroup_data['prefix'] = endpoint.pri_prefix

        # Notifications
        notifications = {}
        n = db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid)
        for notification in n:
            # if notification.type == dSIPNotification.FLAGS.TYPE_MAXCALLLIMIT.value:
            if notification.type == 0:
                notifications['overmaxcalllimit'] = notification.value
            # if notification.type == dSIPNotification.FLAGS.TYPE_ENDPOINTFAILURE.value:
            if notification.type == 1:
                notifications['endpointfailure'] = notification.value

        gwgroup_data['notifications'] = notifications

        gwgroup_data['fusionpbx'] = {}
        domainmapping = db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwgroupid).first()
        if domainmapping is not None:
            gwgroup_data['fusionpbx']['enabled'] = "1"
            gwgroup_data['fusionpbx']['dbhost'] = domainmapping.db_host
            gwgroup_data['fusionpbx']['dbuser'] = domainmapping.db_username
            gwgroup_data['fusionpbx']['dbpass'] = domainmapping.db_password

        # CDR info
        gwgroup_data['cdr'] = {}
        cdrinfo = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
        if cdrinfo is not None:
            gwgroup_data['cdr']['cdr_email'] = cdrinfo.email
            gwgroup_data['cdr']['cdr_send_interval'] = cdrinfo.send_interval

        response_payload['data'].append(gwgroup_data)
        response_payload['msg'] = 'Endpoint group found'

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: should reuse getEndpointGroup() function and return all settings for each gwgroup
@api.route("/api/v1/endpointgroups", methods=['GET'])
@api_security
def listEndpointGroups():
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    typeFilter = "%type:{}%".format(str(settings.FLT_PBX))

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        endpointgroups = db.query(GatewayGroups).filter(GatewayGroups.description.like(typeFilter)).all()

        for endpointgroup in endpointgroups:
            # Grap the description field, which is comma seperated key/value pair
            fields = strFieldsToDict(endpointgroup.description)

            # append summary of endpoint group data
            response_payload['data'].append({
                'gwgroupid': endpointgroup.id,
                'name': fields['name'],
                'gwlist': endpointgroup.gwlist
            })

        response_payload['msg'] = 'Endpoint groups found'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/endpointgroups", methods=['PUT'])
@api.route("/api/v1/endpointgroups/<int:gwgroupid>", methods=['PUT'])
@api_security
def updateEndpointGroups(gwgroupid=None):
    """
    Update a single Endpoint Group\n
    The gwgroupid can be provided in url path or payload

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            name: <string>,
            calllimit: <int>,
            auth: {
                type: "ip"|"userpwd",
                user: <string>
                pass: <string>
                domain: <string>
            },
            endpoints [
                {
                    gwid:<int>,
                    hostname:<string>,
                    description:<string>
                },
                ...
            ],
            strip: <int>,
            prefix: <string>,
            notifications: {
                overmaxcalllimit: <string>,
                endpointfailure: <string>
            },
            cdr: {
                cdr_email: <string>,
                cdr_send_interval: <string>
            }
            fusionpbx: {
                enabled: <bool>,
                dbhost: <string>,
                dbuser: <string>,
                dbpass: <string>
            }
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

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"gwgroupid": int, "name": str, "calllimit": int, "auth": dict,
                               "strip": int, "prefix": str, "notifications": dict, "cdr": dict,
                               "fusionpbx": dict, "endpoints": list}

    # ensure requred args are provided
    REQUIRED_ARGS = {'gwgroupid'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    gwgroup_data = {}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # get request data
        request_payload = getRequestData()

        if gwgroupid is not None:
            gwgroupid = int(gwgroupid)
            gwgroupid_str = str(gwgroupid)
            request_payload['gwgroupid'] = gwgroupid
        else:
            if 'gwgroupid' in request_payload:
                gwgroupid = int(request_payload['gwgroupid'])
                request_payload['gwgroupid'] = gwgroupid
            gwgroupid_str = str(gwgroupid)

        # sanity checks
        for k, v in request_payload.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                try:
                    request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                    continue
                except:
                    raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
        for k in REQUIRED_ARGS:
            if k not in REQUIRED_ARGS:
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))
        if 'prefix' in request_payload:
            for c in request_payload['prefix']:
                if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                    raise http_exceptions.BadRequest(
                        "Request argument 'prefix' not valid. Allowed characters: {}".format(
                            ','.join(settings.DID_PREFIX_ALLOWED_CHARS)))

        # Update gateway group name
        Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if Gwgroup is None:
            raise http_exceptions.NotFound('gwgroup does not exist')
        gwgroup_data['gwgroupid'] = gwgroupid
        gwgroup_desc_dict = strFieldsToDict(Gwgroup.description)
        gwgroup_desc_dict['name'] = request_payload['name'] if 'name' in request_payload else ''
        Gwgroup.description = dictToStrFields(gwgroup_desc_dict)
        db.flush()

        # Update concurrent call limit
        calllimit = request_payload['calllimit'] if 'calllimit' in request_payload else None
        if calllimit is not None and calllimit > -1:
            if db.query(dSIPCallLimits).filter(dSIPCallLimits.gwgroupid == gwgroupid).update(
                    {'limit': calllimit}, synchronize_session=False):
                pass
            else:
                CallLimit = dSIPCallLimits(gwgroupid_str, str(calllimit))
                db.add(CallLimit)
        else:
            Calllimit = db.query(dSIPCallLimits).filter(dSIPCallLimits.gwgroupid == gwgroupid)
            if Calllimit is not None:
                Calllimit.delete(synchronize_session=False)

        # runtime defaults for this route
        strip = request_payload['strip'] if 'strip' in request_payload else 0
        prefix = request_payload['prefix'] if 'prefix' in request_payload else ""
        authtype = request_payload['auth']['type'] \
            if 'auth' in request_payload and 'type' in request_payload['auth'] else ""

        # Update the AuthType userpwd settings
        if authtype == "userpwd":
            authuser = request_payload['auth']['user'] \
                if 'user' in request_payload['auth'] and len(request_payload['auth']['user']) > 0 else None
            authpass = request_payload['auth']['pass'] \
                if 'pass' in request_payload['auth'] and len(request_payload['auth']['pass']) > 0 else None
            authdomain = request_payload['auth']['domain'] \
                if 'domain' in request_payload['auth'] and len(
                request_payload['auth']['domain']) > 0 else settings.DOMAIN
            authdomain = safeUriToHost(authdomain)

            if authuser is None or authpass is None:
                raise http_exceptions.BadRequest("Auth username or password invalid")
            if authdomain is None:
                raise http_exceptions.BadRequest("Auth domain is malformed")

            # Get the existing username and domain_name if it exists
            currentSubscriberInfo = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid).first()
            if currentSubscriberInfo is not None:
                if authuser == currentSubscriberInfo.username and authpass == currentSubscriberInfo.password \
                        and authdomain == currentSubscriberInfo.domain:
                    pass  # The subscriber info is the same - no need to update
                # Check if the new username and domain is unique
                else:
                    if db.query(Subscribers).filter(Subscribers.username == authuser,
                                                    Subscribers.domain == authdomain).scalar():
                        raise http_exceptions.BadRequest("Subscriber username already taken")
                    # Update the Subscriber Info
                    else:
                        currentSubscriberInfo.username = authuser
                        currentSubscriberInfo.password = authpass
                        currentSubscriberInfo.domain = authdomain
            # Create a new Suscriber entry
            else:
                Subscriber = Subscribers(authuser, authpass, authdomain, gwgroupid_str)
                db.add(Subscriber)

        # Delete the Subscriber info if IP is selected
        elif authtype == "ip":
            subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid)
            if subscriber is not None:
                subscriber.delete(synchronize_session=False)

        # Update endpoints
        # Get List of existing endpoints
        # If endpoint sent over is not in the existing endpoint list then remove it
        gwgroup_filter = "%gwgroup:{}%".format(gwgroupid_str)
        current_endpoints_lut = {
            x.gwid: {'address': x.address, 'description_dict': strFieldsToDict(x.description)} \
            for x in db.query(Gateways).filter(Gateways.description.like(gwgroup_filter)).all()
        }
        updated_endpoints = request_payload['endpoints'] if "endpoints" in request_payload else []
        unprocessed_endpoints_lut = {}
        gwlist = []

        # endpoints to add unconditionally
        for endpoint in updated_endpoints:
            gwid = endpoint['gwid'] if 'gwid' in endpoint else None

            # If gwid is empty then this is a new endpoint
            if gwid is None:
                hostname = endpoint['hostname'] if 'hostname' in endpoint else ''
                name = endpoint['description'] if 'description' in endpoint else ''
                if len(hostname) == 0:
                    raise http_exceptions.BadRequest("Endpoint hostname/address is required")

                sip_addr = safeUriToHost(hostname, default_port=5060)
                if sip_addr is None:
                    raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

                # add gateway info for each endpoint
                if authtype == "ip":
                    # for ip auth we must create address records for the endpoint
                    host_addr = safeStripPort(sip_addr)

                    Addr = Address(name, host_addr, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                    db.add(Addr)
                    db.flush()
                    Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid,
                                       addr_id=Addr.id)
                else:
                    # we know this a new endpoint so we don't have to check for any address records here
                    Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid)

                db.add(Gateway)
                db.flush()
                gwlist.append(Gateway.gwid)

            # Process separately
            else:
                unprocessed_endpoints_lut[gwid] = {
                    'hostname': endpoint['hostname'],
                    'name': endpoint['description']
                }

        # conditionally adding/updating/deleting endpoints (using set theory)
        # generally endpoints won't be added with gwid specified but its possible
        current_gwids = set(current_endpoints_lut.keys())
        updated_gwids = set(unprocessed_endpoints_lut.keys())
        add_gwids = updated_gwids - current_gwids
        upd_gwids = current_gwids & updated_gwids
        del_gwids = current_gwids - updated_gwids

        # conditional endpoints to add
        for gwid in add_gwids:
            endpoint = unprocessed_endpoints_lut[gwid]

            hostname = endpoint['hostname'] if 'hostname' in endpoint else ''
            name = endpoint['name'] if 'name' in endpoint else ''
            if len(hostname) == 0:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            sip_addr = safeUriToHost(hostname, default_port=5060)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                # for ip auth we must create address records for the endpoint
                host_addr = safeStripPort(sip_addr)

                Addr = Address(name, host_addr, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                db.add(Addr)
                db.flush()
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, addr_id=Addr.id)
            else:
                # we know this a new endpoint so we don't have to check for any address records here
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid)

            # we ignore the given gwid and allow DB to assign one instead
            db.add(Gateway)
            db.flush()
            gwlist.append(Gateway.gwid)

        # conditional endpoints to update
        for gwid in upd_gwids:
            endpoint = unprocessed_endpoints_lut[gwid]
            current_endpoint = current_endpoints_lut[gwid]

            # allow updating single fields (if not provided set to current value)
            endpoint_fields = current_endpoint['description_dict']
            hostname = endpoint['hostname'] if 'hostname' in endpoint else current_endpoint['address']
            name = endpoint['name'] if 'name' in endpoint else endpoint_fields['name']
            endpoint_fields['name'] = name
            if len(hostname) == 0:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            sip_addr = safeUriToHost(hostname, default_port=5060)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                # for ip auth we must create address records for the endpoint
                host_addr = safeStripPort(sip_addr)

                # if address exists update, otherwise create it
                address_exists = False
                if 'addr_id' in endpoint_fields and len(endpoint_fields['addr_id']) > 0:
                    Addr = db.query(Address).filter(Address.id == endpoint_fields['addr_id']).first()

                    if Addr is not None:
                        address_exists = True

                        Addr.ip_addr = host_addr
                        addr_fields = strFieldsToDict(Addr.tag)
                        addr_fields['name'] = name
                        addr_fields['gwgroup'] = gwgroupid_str
                        Addr.tag = dictToStrFields(addr_fields)

                if not address_exists:
                    Addr = Address(name, host_addr, 32, settings.FLT_PBX, gwgroup=gwgroupid)

                    db.add(Addr)
                    db.flush()
                    endpoint_fields['addr_id'] = str(Addr.id)
            else:
                # if not using ip auth make sure we delete any old address records for the endpoint
                if 'addr_id' in endpoint_fields and len(endpoint_fields['addr_id']) > 0:
                    Addr = db.query(Address).filter(Address.id == endpoint_fields['addr_id'])
                    if Addr is not None:
                        Addr.delete(synchronize_session=False)
                    # remove addr_id field from endpoint description
                    endpoint_fields.pop("addr_id", None)

            # update the endpoint
            db.query(Gateways).filter(Gateways.gwid == gwid).update(
                {"description": dictToStrFields(endpoint_fields), "address": sip_addr, "strip": strip,
                 "pri_prefix": prefix}, synchronize_session=False)

            gwlist.append(gwid)

        # conditional endpoints to delete
        # we also cleanup house here in case of stray entries
        del_gateways = db.query(Gateways).filter(Gateways.gwid.in_(del_gwids))
        del_gateways_cleanup = db.query(Gateways).filter(Gateways.description.like(gwgroup_filter)).filter(Gateways.gwid.notin_(gwlist))
        # make sure we delete any associated address entries
        del_addr_ids = []
        for gateway in del_gateways.union(del_gateways_cleanup):
            description_dict = strFieldsToDict(gateway.description)
            if 'addr_id' in description_dict:
                del_addr_ids.append(description_dict['addr_id'])
        db.query(Address).filter(Address.id.in_(del_addr_ids)).delete(synchronize_session=False)
        del_gateways.delete(synchronize_session=False)
        del_gateways_cleanup.delete(synchronize_session=False)

        # set return gwlist and update the endpoint group's gwlist
        gwgroup_data['endpoints'] = gwlist
        gwlist_str = ','.join([str(gw) for gw in gwlist])
        db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).update(
            {"gwlist": gwlist_str}, synchronize_session=False)

        # Update notifications
        if 'notifications' in request_payload:
            overmaxcalllimit = request_payload['notifications']['overmaxcalllimit'] \
                if 'overmaxcalllimit' in request_payload['notifications'] else None
            endpointfailure = request_payload['notifications']['endpointfailure'] \
                if 'endpointfailure' in request_payload['notifications'] else None

            if overmaxcalllimit is not None:
                # Try to update
                if db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid).filter(
                        dSIPNotification.type == 0).update({"value": overmaxcalllimit}, synchronize_session=False):
                    pass
                # Otherwise Add
                else:
                    notif_type = 0
                    notification = dSIPNotification(gwgroupid, notif_type, 0, overmaxcalllimit)
                    db.add(notification)
            # Remove
            else:
                db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid).filter(
                    dSIPNotification.type == 0).delete(synchronize_session=False)

            if endpointfailure is not None:
                # Try to update
                if db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid).filter(
                        dSIPNotification.type == 1).update({"value": endpointfailure}, synchronize_session=False):
                    pass
                # Otherwise Add
                else:
                    notif_type = 1
                    notification = dSIPNotification(gwgroupid, notif_type, 0, endpointfailure)
                    db.add(notification)
            # Remove
            else:
                db.query(dSIPNotification).filter(dSIPNotification.gwgroupid == gwgroupid).filter(
                    dSIPNotification.type == 1).delete(synchronize_session=False)

        # Update CDR
        if 'cdr' in request_payload:
            cdr_email = request_payload['cdr']['cdr_email'] \
                if 'cdr_email' in request_payload['cdr'] else None
            cdr_send_interval = request_payload['cdr']['cdr_send_interval'] \
                if 'cdr_send_interval' in request_payload['cdr'] else None

            if len(cdr_email) > 0 and len(cdr_send_interval) > 0:
                # Try to update
                if db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).update(
                        {"email": cdr_email, "send_interval": cdr_send_interval},
                        synchronize_session=False):
                    if not updateTaggedCronjob(gwgroupid, cdr_send_interval):
                        raise Exception('Crontab entry could not be updated')
                else:
                    cdrinfo = dSIPCDRInfo(gwgroupid, cdr_email, cdr_send_interval)
                    db.add(cdrinfo)
                    cron_cmd = '{} cdr sendreport {}'.format((settings.DSIP_PROJECT_DIR + '/gui/dsiprouter_cron.py'),
                                                             gwgroupid_str)
                    if not addTaggedCronjob(gwgroupid, cdr_send_interval, cron_cmd):
                        raise Exception('Crontab entry could not be created')
            else:
                # Remove CDR Info
                cdrinfo = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
                if cdrinfo is not None:
                    db.delete(cdrinfo)
                    if not deleteTaggedCronjob(gwgroupid):
                        raise Exception('Crontab entry could not be deleted')

        # Update FusionPBX
        if 'fusionpbx' in request_payload:
            fusionpbxenabled = request_payload['fusionpbx']['enabled'] \
                if 'enabled' in request_payload['fusionpbx'] else None
            fusionpbxdbhost = request_payload['fusionpbx']['dbhost'] \
                if 'dbhost' in request_payload['fusionpbx'] else None
            fusionpbxdbuser = request_payload['fusionpbx']['dbuser'] \
                if 'dbuser' in request_payload['fusionpbx'] else None
            fusionpbxdbpass = request_payload['fusionpbx']['dbpass'] \
                if 'dbpass' in request_payload['fusionpbx'] else None

            # Convert fusionpbxenabled variable to int
            if isinstance(fusionpbxenabled, str):
                fusionpbxenabled = int(fusionpbxenabled)
            # Update
            if fusionpbxenabled == 1:
                # Update
                if db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwgroupid).update(
                        {"pbx_id": gwgroupid, "db_host": fusionpbxdbhost, "db_username": fusionpbxdbuser,
                         "db_password": fusionpbxdbpass}, synchronize_session=False):
                    pass
                else:
                    # Create new record
                    domainmapping = dSIPMultiDomainMapping(gwgroupid, fusionpbxdbhost, fusionpbxdbuser, fusionpbxdbpass,
                                                           type=dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value)
                    db.add(domainmapping)
            # Delete
            elif fusionpbxenabled == 0:
                db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwgroupid).delete(
                    synchronize_session=False)

        db.commit()

        response_payload['msg'] = 'Endpoint group updated'
        response_payload['data'].append(gwgroup_data)
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: fix up like updateEnpointGroups()
@api.route("/api/v1/endpointgroups", methods=['POST'])
@api_security
def addEndpointGroups(data=None, endpointGroupType=None, domain=None):
    """
    Add a single Endpoint Group

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            name: <string>,
            calllimit: <int>,
            auth: {
                type: "ip"|"userpwd",
                user: <string>
                pass: <string>
                domain: <string>
            },
            endpoints [
                {
                    hostname:<string>,
                    description:<string>
                },
                ...
            ],
            strip: <int>,
            prefix: <string>,
            notifications: {
                overmaxcalllimit: <string>,
                endpointfailure: <string>
            },
            cdr: {
                cdr_email: <string>,
                cdr_send_interval: <string>
            }
            fusionpbx: {
                enabled: <bool>,
                dbhost: <string>,
                dbuser: <string>,
                dbpass: <string>
            }
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

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {
        "name": str, "calllimit": int, "auth": dict, "strip": int, "prefix": str,
        "notifications": dict, "cdr": dict, "fusionpbx": dict, "endpoints": list
    }

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    gwgroup_data = {}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        if data == None:
            # Convert Request message to Dictionary Object
            request_payload = getRequestData()
        else:
            # Use the data parameter as the payload
            request_payload = data

        # sanity checks
        for k, v in request_payload.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                try:
                    request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                    continue
                except:
                    raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
        if 'prefix' in request_payload:
            for c in request_payload['prefix']:
                if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                    raise http_exceptions.BadRequest(
                        "Request argument 'prefix' not valid. Allowed characters: {}".format(
                            ','.join(settings.DID_PREFIX_ALLOWED_CHARS)))

        # Process Gateway Name
        name = request_payload['name']
        Gwgroup = GatewayGroups(name, type=settings.FLT_PBX)
        db.add(Gwgroup)
        db.flush()
        gwgroupid = Gwgroup.id
        gwgroup_data['gwgroupid'] = gwgroupid

        calllimit = request_payload['calllimit'] if 'calllimit' in request_payload else None
        if calllimit is not None and calllimit > -1:
            CallLimit = dSIPCallLimits(gwgroupid, calllimit)
            db.add(CallLimit)

        # runtime defaults for this route
        strip = request_payload['strip'] if 'strip' in request_payload else 0
        prefix = request_payload['prefix'] if 'prefix' in request_payload else ""
        authtype = request_payload['auth']['type'] \
            if 'auth' in request_payload and 'type' in request_payload['auth'] else ""

        if authtype == "userpwd":
            # Store Endpoint IP's in address tables
            authuser = request_payload['auth']['user'] \
                if 'user' in request_payload['auth'] \
                   and len(request_payload['auth']['user']) > 0 else None
            authpass = request_payload['auth']['pass'] \
                if 'pass' in request_payload['auth'] \
                   and len(request_payload['auth']['pass']) > 0 else None
            authdomain = request_payload['auth']['domain'] \
                if 'domain' in request_payload['auth'] \
                   and len(request_payload['auth']['domain']) > 0 else settings.DOMAIN
            authdomain = safeUriToHost(authdomain)

            if authuser is None or authpass is None:
                raise http_exceptions.BadRequest("Auth username or password invalid")
            if authdomain is None:
                raise http_exceptions.BadRequest("Auth domain is malformed")

            if db.query(Subscribers).filter(Subscribers.username == authuser,
                                            Subscribers.domain == authdomain).scalar():
                raise sql_exceptions.SQLAlchemyError(
                    'DB Entry Taken for Username {} in Domain {}'.format(authuser, authdomain))
            else:
                Subscriber = Subscribers(authuser, authpass, authdomain, gwgroupid)
                db.add(Subscriber)

        # Enable FusionPBX Support for the Endpoint Group
        if 'fusionpbx' in request_payload:
            fusionpbxenabled = request_payload['fusionpbx']['enabled'] \
                if 'enabled' in request_payload['fusionpbx'] else None
            fusionpbxdbonly = request_payload['fusionpbx']['dbonly'] \
                if 'dbonly' in request_payload['fusionpbx'] else None
            fusionpbxdbhost = request_payload['fusionpbx']['dbhost'] \
                if 'dbhost' in request_payload['fusionpbx'] else None
            fusionpbxdbuser = request_payload['fusionpbx']['dbuser'] \
                if 'dbuser' in request_payload['fusionpbx'] else None
            fusionpbxdbpass = request_payload['fusionpbx']['dbpass'] \
                if 'dbpass' in request_payload['fusionpbx'] else None

            # Convert fusionpbxenabled variable to int
            if isinstance(fusionpbxenabled, str):
                fusionpbxenabled = int(fusionpbxenabled)

            if fusionpbxenabled == 1:
                domainmapping = dSIPMultiDomainMapping(gwgroupid, fusionpbxdbhost, fusionpbxdbuser, fusionpbxdbpass,
                                                       type=dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value)
                db.add(domainmapping)

                # Add the FusionPBX server as an Endpoint if it's not just the DB server
                if fusionpbxdbonly is None or fusionpbxdbonly == False:
                    endpoint = {}
                    endpoint['hostname'] = fusionpbxdbhost
                    endpoint['description'] = "FusionPBX Server"
                    if "endpoints" not in request_payload:
                        request_payload['endpoints'] = []
                    request_payload['endpoints'].append(endpoint)

        # Setup Endpoints
        endpoints = request_payload['endpoints'] if "endpoints" in request_payload else []
        gwlist = []

        # endpoints to add unconditionally
        for endpoint in endpoints:
            hostname = endpoint['hostname'] if 'hostname' in endpoint else ''
            name = endpoint['description'] if 'description' in endpoint else ''
            if len(hostname) == 0:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            # For MSTeams the third attrs field contains the Domain it relates too
            # the first two fields are always stripped and replaced by our triggers
            if endpointGroupType == "msteams" and domain is not None:
                attrs = '0,0,{}'.format(domain)
            else:
                attrs = ''

            sip_addr = safeUriToHost(hostname, default_port=5060)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                host_addr = safeStripPort(sip_addr)

                Addr = Address(name, host_addr, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                db.add(Addr)
                db.flush()
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, addr_id=Addr.id,
                                   attrs=attrs)
            else:
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, attrs=attrs)

            db.add(Gateway)
            db.flush()
            gwlist.append(Gateway.gwid)

        # set return gwlist and update the endpoint group's gwlist
        gwgroup_data['endpoints'] = gwlist
        gwlist_str = ','.join([str(gw) for gw in gwlist])

        # Update the GatewayGroup with the lists of gateways
        db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).update(
            {'gwlist': gwlist_str}, synchronize_session=False)

        # Setup notifications
        if 'notifications' in request_payload:
            overmaxcalllimit = request_payload['notifications']['overmaxcalllimit'] \
                if 'overmaxcalllimit' in request_payload['notifications'] else None
            endpointfailure = request_payload['notifications']['endpointfailure'] \
                if 'endpointfailure' in request_payload['notifications'] else None

            if overmaxcalllimit is not None:
                notif_type = dSIPNotification.FLAGS.TYPE_OVERLIMIT.value
                method = dSIPNotification.FLAGS.METHOD_EMAIL.value
                notification = dSIPNotification(gwgroupid, notif_type, method, overmaxcalllimit)
                db.add(notification)

            if endpointfailure is not None:
                notif_type = dSIPNotification.FLAGS.TYPE_GWFAILURE.value
                method = dSIPNotification.FLAGS.METHOD_EMAIL.value
                notification = dSIPNotification(gwgroupid, notif_type, method, endpointfailure)
                db.add(notification)

        # Enable CDR
        if 'cdr' in request_payload:
            cdr_email = request_payload['cdr']['cdr_email'] \
                if 'cdr_email' in request_payload['cdr'] else ''
            cdr_send_interval = request_payload['cdr']['cdr_send_interval'] \
                if 'cdr_send_interval' in request_payload['cdr'] else ''

            if len(cdr_email) > 0 and len(cdr_send_interval) > 0:
                # create DB entry
                cdrinfo = dSIPCDRInfo(gwgroupid, cdr_email, cdr_send_interval)
                db.add(cdrinfo)

                # create crontab entry
                cron_cmd = '{} cdr sendreport {}'.format((settings.DSIP_PROJECT_DIR + '/gui/dsiprouter_cron.py'),
                                                         gwgroupid)
                if not addTaggedCronjob(gwgroupid, cdr_send_interval, cron_cmd):
                    raise Exception('Crontab entry could not be created')

        db.commit()

        response_payload['msg'] = 'Endpoint group created'
        response_payload['data'].append(gwgroup_data)
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: standardize response payload (use data param)
# TODO: stop shadowing builtin functions! -> type == builtin
# return value should be used in an http/flask context
def generateCDRS(gwgroupid, type=None, email=False, dtfilter=datetime.min, cdrfilter=''):
    """
    Generate CDRs Report for a gwgroup

    :param gwgroupid:       gwgroup to generate cdr's for
    :type gwgroupid:        int|str
    :param type:            type of report (json|csv)
    :type type:             str
    :param email:           whether the report should be emailed
    :type email:            bool
    :param dtfilter:        time before which cdr's are not returned
    :type dtfilter:         datetime
    :param cdrfilter:       comma seperated cdr id's to include
    :type cdrfilter:        str
    :return:                returns a json response or file
    :rtype:                 flask.Response
    """
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}
    # define here so we can cleanup in finally statement
    csv_file = ''

    try:
        db = SessionLoader()

        if isinstance(gwgroupid, int):
            gwgroupid = str(gwgroupid)
        type = type.lower()

        gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if gwgroup is not None:
            gwgroupName = strFieldsToDict(gwgroup.description)['name']
        else:
            response_payload['status'] = "0"
            response_payload['message'] = "Endpont group doesn't exist"
            return jsonify(response_payload)

        if len(cdrfilter) > 0:
            query = (
                """SELECT t1.cdr_id, t1.call_start_time, t1.duration AS call_duration, t1.calltype AS call_direction,
                          t2.id AS src_gwgroupid, substring_index(substring_index(t2.description, 'name:', -1), ',', 1) AS src_gwgroupname,
                          t3.id AS dst_gwgroupid, substring_index(substring_index(t3.description, 'name:', -1), ',', 1) AS dst_gwgroupname,
                          t1.src_username, t1.dst_username, t1.src_ip AS src_address, t1.dst_domain AS dst_address, t1.sip_call_id AS call_id
                FROM cdrs t1
                JOIN dr_gw_lists t2 ON (t1.src_gwgroupid = t2.id)
                JOIN dr_gw_lists t3 ON (t1.dst_gwgroupid = t3.id)
                WHERE (t2.id = '{gwgroupid}' OR t3.id = '{gwgroupid}') AND t1.call_start_time >= '{dtfilter}' AND t1.cdr_id IN ({cdrfilter})
                ORDER BY t1.call_start_time DESC;"""
            ).format(gwgroupid=gwgroupid, dtfilter=dtfilter, cdrfilter=cdrfilter)
        else:
            query = (
                """SELECT t1.cdr_id, t1.call_start_time, t1.duration AS call_duration, t1.calltype AS call_direction,
                          t2.id AS src_gwgroupid, substring_index(substring_index(t2.description, 'name:', -1), ',', 1) AS src_gwgroupname,
                          t3.id AS dst_gwgroupid, substring_index(substring_index(t3.description, 'name:', -1), ',', 1) AS dst_gwgroupname,
                          t1.src_username, t1.dst_username, t1.src_ip AS src_address, t1.dst_domain AS dst_address, t1.sip_call_id AS call_id
                FROM cdrs t1
                JOIN dr_gw_lists t2 ON (t1.src_gwgroupid = t2.id)
                JOIN dr_gw_lists t3 ON (t1.dst_gwgroupid = t3.id)
                WHERE (t2.id = '{gwgroupid}' OR t3.id = '{gwgroupid}') AND t1.call_start_time >= '{dtfilter}'
                ORDER BY t1.call_start_time DESC;"""
            ).format(gwgroupid=gwgroupid, dtfilter=dtfilter)

        rows = db.execute(query)
        cdrs = [OrderedDict(row.items()) for row in rows]

        response_payload['status'] = "200"
        response_payload['cdrs'] = cdrs
        response_payload['recordCount'] = len(cdrs)

        # Convert array of dicts to csv format
        if type == "csv":
            now = time.strftime('%Y%m%d-%H%M%S')
            filename = secure_filename('{}_{}.csv'.format(gwgroupName, now))
            csv_file = '/tmp/{}'.format(filename)
            with open(csv_file, 'w', newline='') as csv_fp:
                dict_writer = csv.DictWriter(csv_fp, fieldnames=cdrs[0].keys())
                dict_writer.writeheader()
                dict_writer.writerows(cdrs)

            if email:
                # recipients required
                cdr_info = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
                if cdr_info is not None:
                    # Setup the parameters to send the email
                    data = {}
                    data['html_body'] = "<html>CDR Report for {}</html>".format(gwgroupName)
                    data['text_body'] = "CDR Report for {}".format(gwgroupName)
                    data['subject'] = "CDR Report for {}".format(gwgroupName)
                    data['attachments'] = []
                    data['attachments'].append(csv_file)
                    data['recipients'] = cdr_info.email.split(',')
                    sendEmail(**data)
                    # Remove CDR's from the payload thats being returned
                    response_payload.pop('cdrs')
                    response_payload['format'] = 'csv'
                    response_payload['type'] = 'email'
                    return jsonify(response_payload)

            return send_file(csv_file, attachment_filename=filename, as_attachment=True), StatusCodes.HTTP_OK
        else:
            return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
        if os.path.exists(csv_file):
            os.remove(csv_file)


@api.route("/api/v1/cdrs/endpointgroups/<int:gwgroupid>", methods=['GET'])
@api_security
def getGatewayGroupCDRS(gwgroupid=None, type=None, email=None, filter=None):
    """
    Purpose

    Getting the cdrs for a gatewaygroup

    """
    if (settings.DEBUG):
        debugEndpoint()

    if type is None:
        type = request.args.get('type', 'json')
    if email is None:
        email = bool(request.args.get('email', False))
    if filter is None:
        filter = request.args.get('filter', '')

    return generateCDRS(gwgroupid, type, email, cdrfilter=filter)


# TODO: standardize response payload (use data param)
@api.route("/api/v1/cdrs/endpoint/<int:gwid>", methods=['GET'])
@api_security
def getGatewayCDRS(gwid=None):
    """
    Purpose

    Getting the cdrs for a gateway thats part of a gateway group

    """
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        db = SessionLoader()

        if (settings.DEBUG):
            debugEndpoint()

        query = "select cdr_id, gwid, call_start_time, calltype as direction, dst_username as number,src_ip, dst_domain, duration,sip_call_id \
         from dr_gateways,cdrs where cdrs.src_ip = dr_gateways.address and gwid={} order by call_start_time DESC;".format(
            gwid)

        cdrs = db.execute(query)
        rows = []
        for cdr in cdrs:
            row = {}
            row['cdr_id'] = cdr[0]
            row['gwid'] = cdr[1]
            row['call_start_time'] = str(cdr[2])
            row['calltype'] = cdr[3]
            row['number'] = cdr[4]
            row['src_ip'] = cdr[5]
            row['dst_domain'] = cdr[6]
            row['duration'] = cdr[7]
            row['sip_call_id'] = cdr[8]

            rows.append(row)

            response_payload['cdrs'] = rows
            response_payload['recordCount'] = len(rows)
            response_payload['status'] = "200"

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/backupandrestore/backup", methods=['GET'])
@api_security
def createBackup():
    """
    Generate a backup of the database
    """

    # define here so we can cleanup in finally statement
    backup_path = ''

    try:
        if (settings.DEBUG):
            debugEndpoint()

        backup_name = time.strftime('%Y%m%d-%H%M%S') + ".sql"
        backup_path = os.path.join(settings.BACKUP_FOLDER, backup_name)
        # need to decrypt password
        if isinstance(settings.KAM_DB_PASS, bytes):
            kampass = AES_CTR.decrypt(settings.KAM_DB_PASS).decode('utf-8')
        else:
            kampass = settings.KAM_DB_PASS

        dumpcmd = ['/usr/bin/mysqldump', '--single-transaction', '--opt', '--routines', '--triggers', '--hex-blob',
                   '-h', settings.KAM_DB_HOST, '-u',
                   settings.KAM_DB_USER, '-p{}'.format(kampass), '-B', settings.KAM_DB_NAME]
        with open(backup_path, 'wb') as fp:
            dump = subprocess.Popen(dumpcmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).communicate()[0]
            dump = re.sub(rb'''DEFINER=[`"\'][a-zA-Z0-9_%]*[`"\']@[`"\'][a-zA-Z0-9_%]*[`"\']''', b'', dump,
                          flags=re.MULTILINE)
            dump = re.sub(rb'ENGINE=MyISAM', b'ENGINE=InnoDB', dump, flags=re.MULTILINE)
            fp.write(dump)

        # lines = "It wrote the backup"
        # attachment = "attachment; filename=dsiprouter_{}_{}.sql".format(settings.VERSION,backupDateTime)
        # headers={"Content-disposition":attachment}
        # return Response(lines, mimetype="text/plain",headers=headers)
        return send_file(backup_path, attachment_filename=backup_name, as_attachment=True), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)
    finally:
        if os.path.exists(backup_path):
            os.remove(backup_path)


@api.route("/api/v1/backupandrestore/restore", methods=['POST'])
@api_security
def restoreBackup():
    """
    Restore backup of the database
    """

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        data = getRequestData()

        KAM_DB_USER = settings.KAM_DB_USER
        KAM_DB_PASS = settings.KAM_DB_PASS

        if 'db_username' in data.keys():
            KAM_DB_USER = str(data.get('db_username'))
            if KAM_DB_USER != '':
                KAM_DB_PASS = str(data.get('db_password'))

        if 'file' not in request.files:
            raise http_exceptions.BadRequest("No file was sent")

        file = request.files['file']

        if file.filename == '':
            raise http_exceptions.BadRequest("No file name was sent")

        if file and allowed_file(file.filename, ALLOWED_EXTENSIONS={'sql'}):
            filename = secure_filename(file.filename)
            restore_path = os.path.join(settings.BACKUP_FOLDER, filename)
            file.save(restore_path)
        else:
            raise http_exceptions.BadRequest("Improper file upload")

        if len(KAM_DB_PASS) == 0:
            restorecmd = ['/usr/bin/mysql', '-h', settings.KAM_DB_HOST, '-u', KAM_DB_USER, '-D', settings.KAM_DB_NAME]
        else:
            restorecmd = ['/usr/bin/mysql', '-h', settings.KAM_DB_HOST, '-u', KAM_DB_USER, '-p{}'.format(KAM_DB_PASS),
                          '-D', settings.KAM_DB_NAME]

        with open(restore_path, 'rb') as fp:
            subprocess.Popen(restorecmd, stdin=fp, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).communicate()

        response_payload['msg'] = "The restore was successful"
        globals.reload_required = True
        response_payload['kamreload'] = True
        return response_payload, StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex, response_payload)


@api.route("/api/v1/sys/generatepassword", methods=['GET'])
@api_security
def generatePassword():
    """
    Generate a random password
    """

    DEF_PASSWORD_LEN = 32

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        response_payload['data'].append(urandomChars(DEF_PASSWORD_LEN))
        response_payload['msg'] = 'Succesfully generated password'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex, response_payload)


# TODO:  The response coming back from Kamailio Command Line
#        is not in proper JSON format.  The field and Attributes
#        are missing double quotes.  So, we need to fix the JSON
#        payload and loop thru the result vs doing a find.
#        Or if we do a JSONRPC call instead we will get proper JSON
def getOptionMessageStatus(domain):
    """
    Check if Domain is receiving replies from OPTION Messages
    :param domain:  domain to check
    :type domain:   str
    :return:        whether domain handled OPTION message correctly
    :rtype:         bool
    """

    response = subprocess.check_output(['kamcmd', 'dispatcher.list'])

    if not response:
        return False

    response_formatted = response.decode('utf8').replace("'", '"')
    found_domain = response_formatted.find(domain)

    if not found_domain:
        return False
    else:
        found_inactive = response_formatted.find("FLAGS: IP", found_domain)
        if found_inactive > 0:
            return False

    return True


@api.route("/api/v1/domains/msteams/test/<string:domain>", methods=['GET'])
@api_security
def testConnectivity(domain):
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        test_data = {"hostname_check": False, "tls_check": False, "option_check": False}

        external_ip_addr = getExternalIP()
        internal_ip_address = hostToIP(domain)

        # Check the external ip matchs the ip set on the server
        if external_ip_addr == internal_ip_address:
            test_data['hostname_check'] = True
        # Try again, but use Google DNS resolver if the check fails with local DNS
        else:
            # Does the IP address of this server resolve to the domain
            import dns.resolver

            # Get the IP address of the domain from Google  DNS
            resolver = dns.resolver.Resolver()
            resolver.nameservers = ['8.8.8.8']
            try:
                answers = resolver.query(domain, 'A')
                for a in answers:
                    # If the External IP and IP from DNS match then it passes the check
                    if a.to_text() == external_ip_addr:
                        test_data['hostname_check'] = True
            except:
                pass

        # Check if Domain is the root of the CN
        # GoDaddy Certs Don't work with Microsoft Direct routing
        certInfo = isCertValid(domain, external_ip_addr, 5061)
        if certInfo:
            test_data['tls_check'] = certInfo

        # check if domain can process OPTIONS messages
        if getOptionMessageStatus(domain):
            test_data['option_check'] = True

        response_payload['msg'] = 'Tests ran without error'
        response_payload['data'].append(test_data)
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


# TODO: implement GET for single domain
@api.route("/api/v1/certificates", methods=['GET'])
@api.route("/api/v1/certificates/<string:domain>", methods=['GET'])
@api_security
def getCertificates(domain=None):
    db = DummySession()

    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        # if domain is not None:
        #     domain_configs = getCustomTLSConfigs(domain)
        # else:
        #domain_configs = getCustomTLSConfigs()
        if domain == None:
            certificates = db.query(dSIPCertificates).all()
        else:
            certificates = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).all()

        for certificate in certificates:
            # append summary of endpoint group data
            response_payload['data'].append({
                'id': certificate.id,
                'domain': certificate.domain,
                'type': certificate.type,
                'assigned_domains': ''
            })

        db.commit()
        response_payload['msg'] = 'Certificates found' if len(certificates) > 0 else 'No Certificates'
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/certificates", methods=['POST','PUT'])
@api_security
def createCertificate():
    """
    Create TLS cert for a domain

    ===============
    Request Payload
    ===============

    .. code-block:: json

    {
        domain: <string>,
        ip: <int>,
        port: <int>
        server_name_mode: <int>
    }
    """

    db = DummySession()

    CERT_TYPE_GENERATED = "generated"
    CERT_TYPE_UPLOADED = "uploaded"

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    # Check parameters and raise exception if missing required parameters
    requiredParameters = ['domain']

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        request_payload = getRequestData()

        for parameter in requiredParameters:
            if parameter not in request_payload:
                raise http_exceptions.BadRequest("Request Argument '{}' is Required".format(parameter))
            elif request_payload[parameter] is None or len(request_payload[parameter]) == 0:
                raise http_exceptions.BadRequest("Value for Request Argument '{}' is Not Valid".format(parameter))

        # Process Request
        domain = request_payload['domain']
        ip = request_payload['ip'] if 'ip' in request_payload else settings.EXTERNAL_IP_ADDR
        port = request_payload['port'] if 'port' in request_payload else 5061
        server_name_mode = request_payload['server_name_mode'] \
            if 'server_name_mode' in request_payload else KAM_TLS_SNI_ALL
        key =  request_payload['key'] if 'key' in request_payload else None
        replace_default_cert =  request_payload['replace_default_cert'] if 'replace_default_cert' in request_payload else None
        cert = request_payload['cert'] if 'cert' in request_payload else None
        email = request_payload['email'] if 'email'in request_payload else "admin@" + settings.DOMAIN

        # Request Certificate via Let's Encrypt
        if key is None and cert is None:
            type = CERT_TYPE_GENERATED
            try:
                if settings.DEBUG:
                    # Use the LetsEncrypt Staging Server

                    key,cert=generateCertificate(domain,email,debug=True,default=replace_default_cert)

                else:
                    # Use the LetsEncrypt Prod Server
                    key,cert=generateCertificate(domain,email,default=replace_default_cert)

            except Exception as ex:
                globals.reload_required = False
                raise http_exceptions.BadRequest("Issue with validating ownership of the domain.  Please add a DNS record for this domain and try again")


        # Convert Certificate and key to base64 so that they can be stored in the database
        cert_base64 = base64.b64encode(cert.encode('ascii'))
        key_base64 = base64.b64encode(key.encode('ascii'))


        #Check if the domain exists.  If so, update versus writing new
        certificate = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).first()
        if certificate is not None:
            #Update
            db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).update({'email':email,'type':type,'cert':cert_base64,'key':key_base64})
            db.commit()
            # Update the Kamailio TLS Configuration
            if not updateCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')

        else:
            # Store a new Certificate in dSIPCertificate Table
            certificate = dSIPCertificates(domain, type, email, cert_base64, key_base64)
            db.add(certificate)
            db.commit()
            # Write the Kamailio TLS Configuration
            if not addCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')


        response_payload['msg'] = "Certificate creation succeeded"
        response_payload['data'].append({"id": certificate.id})
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()

@api.route("/api/v1/certificates/<string:domain>", methods=['DELETE'])
@api_security
def deleteCertificates(domain=None):
    db = DummySession()

    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = SessionLoader()

        # if domain is not None:
        #     domain_configs = getCustomTLSConfigs(domain)
        # else:
        #domain_configs = getCustomTLSConfigs()

        Certificates = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain)
        Certificates.delete(synchronize_session=False)

        # Remove the certificate from the file system
        deleteCertificate(domain)

        # Remove from Kamailio TLS
        deleteCustomTLSConfig(domain)

        db.commit()

        response_payload['msg'] = 'Certificate Deleted'
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()

@api.route("/api/v1/certificates/upload/<string:domain>", methods=['POST'])
@api_security
def uploadCertificates(domain=None):
    db = DummySession()

    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    try:
        if (settings.DEBUG):

            debugEndpoint()

        db = SessionLoader()

        data = getRequestData()

        if 'domain' in data.keys():
            domain = data['domain'][0]
            print(domain)
        else:
            domain = "default"

        if 'replace_default_cert' in data.keys():
            replace_default_cert =  data['replace_default_cert'][0]
        else:
            replace_default_cert = None
        
        ip = settings.EXTERNAL_IP_ADDR
        port = 5061
        server_name_mode = KAM_TLS_SNI_ALL
        email = None
        cert = None
        key = None

        cert_dir = settings.DSIP_CERTS_DIR
        if replace_default_cert == "true":
            # Replacing the default cert
            cert_domain_dir = "{}".format(cert_dir)
        else:
            # Adding a another domain cert
            cert_domain_dir = "{}/{}".format(cert_dir,domain)

        # Create a directory for the domain
        if not os.path.exists(cert_domain_dir):
            os.makedirs(cert_domain_dir)

        f = request.files.getlist("certandkey")


        for file in f:
          if not allowed_file(file.filename, ALLOWED_EXTENSIONS={'crt','key','cert','pem'}):
              raise http_exceptions.BadRequest("Only files ending in .cert, .crt, .key, .pem are allowed")
          filename = secure_filename(file.filename)
          if re.search('crt|cert',filename):
              filename = "dsiprouter.crt"
              file.save(os.path.join(cert_domain_dir, filename))
              file.seek(0,0)
              cert = ''.join(map(str,file.readlines()))
          elif re.search('key|pem',filename):
              filename = "dsiprouter.key"
              file.save(os.path.join(cert_domain_dir, filename))
              file.seek(0,0)
              key= ''.join(map(str,file.readlines()))


        if key is None or cert is None:
            raise http_exceptions.BadRequest("A certificate and key file must be provided")

        key_file = "{}/dsiprouter.key".format(cert_domain_dir)
        cert_file = "{}/dsiprouter.crt".format(cert_domain_dir)

        # Change owner to root:kamailio so that Kamailio can load the configurations
        change_owner(cert_domain_dir,"root","kamailio")
        change_owner(key_file,"root","kamailio")
        change_owner(cert_file,"root","kamailio")

        # Convert Certificate and key to base64 so that they can be stored in the database
        cert_base64 = base64.b64encode(bytes(cert,'utf-8'))
        key_base64 = base64.b64encode(bytes(key,'utf-8'))

        # Store Certificate in dSIPCertificate Table
        certificate = dSIPCertificates(domain, "uploaded", None, cert_base64, key_base64)
        db.add(certificate)

        if not replace_default_cert:
            # Write the Kamailio TLS Configuration if it's not the default
            if not addCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')

        db.commit()

        response_payload['msg'] = "Certificate and Key were uploaded"
        response_payload['data'].append({"id": certificate.id})
        globals.reload_required = True
        response_payload['kamreload'] = True
        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
