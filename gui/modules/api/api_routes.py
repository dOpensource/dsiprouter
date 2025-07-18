# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import os, time, random, subprocess, requests, csv, base64, codecs, re, socket, json
from contextlib import closing
from datetime import datetime
from flask import Blueprint, jsonify, request, send_file, g
from sqlalchemy import exc as sql_exceptions, and_, or_
from sqlalchemy.sql import text
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import secure_filename
from database import startSession, DummySession, Address, dSIPNotification, dSIPMultiDomainMapping, Gateways, \
    GatewayGroups, Subscribers, dSIPLeases, dSIPMaintModes, dSIPCallSettings, InboundMapping, dSIPCDRInfo, \
    dSIPCertificates, Dispatcher, dSIPDNIDEnrichment
from shared import allowed_file, dictToStrFields, isCertValid, rowToDict, debugEndpoint, StatusCodes, \
    strFieldsToDict, getRequestData, IO
from util.pyasync import daemonize
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from modules.api.api_functions import createApiResponse, showApiError, api_security
from modules.api.kamailio.functions import reloadKamailio
from util.networking import getExternalIP, hostToIP, safeUriToHost, safeStripPort
from util.notifications import sendEmail
from util.security import AES_CTR, urandomChars, KeyCertPair
from util.file_handling import change_owner
from util import kamtls, letsencrypt
from util.cron import addTaggedCronjob, updateTaggedCronjob, deleteTaggedCronjob
from sysloginit import initSyslogLogger
import settings

api = Blueprint('api', __name__)


# TODO: we need to abstract out common code between gui and api


@api.route("/api/v1/kamailio/stats", methods=['GET'])
@api_security
def getKamailioStats():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        jsonrpc_payload = {"jsonrpc": "2.0", "method": "tm.stats", "id": 1}
        r = requests.get('http://127.0.0.1:5060/api/kamailio', json=jsonrpc_payload)
        if r.status_code >= 400:
            ex = http_exceptions.HTTPException(r.reason)
            ex.code = r.status_code
            raise ex

        return createApiResponse(
            msg='Successfully retrieved kamailio stats',
            data=[r.json()['result']],
        )

    except Exception as ex:
        return showApiError(ex)


@api.route("/api/v1/reload/kamailio", methods=['POST'])
@api_security
def handleReloadKamailio():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        reloadKamailio()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = False
        return createApiResponse(
            msg='Kamailio reload succeeded',
            kamreload=False,
        )

    except Exception as ex:
        return showApiError(ex)

# TODO: state file is not thread/process safe, move to shared memory manager
@api.route("/api/v1/reload/dsiprouter", methods=['GET', 'POST'])
@api_security
def handleReloadDsiprouter():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        # check on a current reload
        if request.method == 'GET':
            if getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_ongoing']:
                return createApiResponse(
                    msg='dSIPRouter reload in progress',
                    data=[False],
                    status_code=StatusCodes.HTTP_ACCEPTED,
                )

            return createApiResponse(
                msg='dSIPRouter reload complete',
                data=[True],
            )
        # try the reload
        elif request.method == 'POST':
            if getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_ongoing']:
                return createApiResponse(
                    msg='dSIPRouter reload in progress',
                    status_code=StatusCodes.HTTP_ACCEPTED,
                )

            # update globals before we reload so server stores them on teardown
            getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_ongoing'] = True
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = False
            getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_required'] = False

            daemonize(['sudo', 'dsiprouter', 'restart', '-all', '-daemonize'])

            return createApiResponse(
                msg='dSIPRouter reload started',
            )
        # method not allowed
        else:
            return createApiResponse(
                msg='Invalid HTTP method for this route',
                status_code=StatusCodes.HTTP_METHOD_NOT_ALLOWED,
            )

    except Exception as ex:
        return showApiError(ex)


# TODO: this func actually adds an endpoint lease
#       it should be renamed and changed to use POST method
# TODO: the last lease id/username generated must be tracked (just query DB)
#       and used to determine next lease id, otherwise conflicts may occur
@api.route("/api/v1/lease/endpoint", methods=['GET'])
@api_security
def getEndpointLease():
    db = DummySession()

    DEF_PASSWORD_LEN = 32

    lease_data = {}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        email = request.args.get('email')
        if not email:
            raise Exception("email parameter is missing")

        ttl = request.args.get('ttl', None)
        if ttl is None:
            raise http_exceptions.BadRequest("time to live (ttl) parameter is missing")

        # Convert TTL to Seconds
        r = re.compile('\d*m|M')
        if r.match(ttl):
            ttl = 60 * int(ttl[0:(len(ttl) - 1)])

        # Generate some values
        rand_num = random.randint(1, 200)
        name = "lease" + str(rand_num)
        auth_username = name
        auth_password = urandomChars(DEF_PASSWORD_LEN)
        auth_domain = settings.DEFAULT_AUTH_DOMAIN

        # Set some defaults
        host_addr = ''
        strip = 0
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

        # Install Cron job to clean up the leases
        #cron_cmd = '{} cleanleases'.format(settings.DSIP_PROJECT_DIR + '/gui/dsiprouter_cron.py')
        #if not addTaggedCronjob("lease_management", "* * * * *", cron_cmd):
        #    raise Exception('Crontab entry could not be created')

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Lease created',
            data=[lease_data],
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/lease/endpoint/<int:leaseid>/revoke", methods=['DELETE'])
@api_security
def revokeEndpointLease(leaseid):
    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Lease revoked',
            kamreload=True,
        )

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

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Endpoint updated',
            kamreload=True,
        )

    except sql_exceptions.IntegrityError as ex:
        db.rollback()
        db.flush()
        payload = {'msg': "endpoint {} is already in maintmode".format(id)}
        return showApiError(ex, payload)
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

    payload = {'data': []}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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
                            'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(
                                data['description']) else '',
                            'servers': data['gwlist'].split(',')}
                    payload['data'].append(data)
                    payload['msg'] = 'Rule Found'
                else:
                    payload['msg'] = 'No Matching Rule Found'
                    payload['status_code'] = StatusCodes.HTTP_NOT_FOUND

            # get single rule by did
            else:
                did_pattern = request.args.get('did')
                if did_pattern is not None:
                    res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                        InboundMapping.prefix == did_pattern).first()
                    if res is not None:
                        data = rowToDict(res)
                        data = {'ruleid': data['ruleid'], 'did': data['prefix'],
                                'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(
                                    data['description']) else '',
                                'servers': data['gwlist'].split(',')}
                        payload['data'].append(data)
                        payload['msg'] = 'DID Found'
                    else:
                        payload['msg'] = 'No Matching DID Found'
                        payload['status_code'] = StatusCodes.HTTP_NOT_FOUND

                # get list of rules
                else:
                    res = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).all()
                    if len(res) > 0:
                        for row in res:
                            data = rowToDict(row)
                            data = {'ruleid': data['ruleid'], 'did': data['prefix'],
                                    'name': strFieldsToDict(data['description'])['name'] if 'name' in strFieldsToDict(
                                        data['description']) else '',
                                    'servers': data['gwlist'].split(',')}
                            payload['data'].append(data)
                        payload['msg'] = 'Rules Found'
                    else:
                        payload['msg'] = 'No Rules Found'

            return createApiResponse(**payload)

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
                    # _ = int(data['servers'][i])
                except:
                    raise http_exceptions.BadRequest('Invalid Server ID')
            for c in data['did']:
                if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                    raise http_exceptions.BadRequest(
                        'DID improperly formatted. Allowed characters: {}'.format(
                            ','.join(settings.DID_PREFIX_ALLOWED_CHARS)))

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
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            payload['kamreload'] = getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required']
            payload['msg'] = 'Rule Created'
            return createApiResponse(**payload)

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
                            # _ = int(data['servers'][i])
                        except:
                            raise http_exceptions.BadRequest('Invalid Server ID')
                updates['gwlist'] = ','.join(data['servers'])
            if 'did' in data:
                for c in data['did']:
                    if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                        raise http_exceptions.BadRequest(
                            'DID improperly formatted. Allowed characters: {}'.format(
                                ','.join(settings.DID_PREFIX_ALLOWED_CHARS)))
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
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            payload['kamreload'] = getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required']
            return createApiResponse(**payload)

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
                if rule.delete(synchronize_session=False) == 0:
                    payload['msg'] = 'No Rules Found'
                    payload['status_code'] = StatusCodes.HTTP_NOT_FOUND

            # delete single rule by did
            else:
                did_pattern = request.args.get('did')
                if did_pattern is not None:
                    rule = db.query(InboundMapping).filter(InboundMapping.groupid == settings.FLT_INBOUND).filter(
                        InboundMapping.prefix == did_pattern)
                    if rule.delete(synchronize_session=False) == 0:
                        payload['msg'] = 'No Rules Found'
                        payload['status_code'] = StatusCodes.HTTP_NOT_FOUND

                # no other options
                else:
                    raise http_exceptions.BadRequest('One of the following is required: {ruleid, or did}')

            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            payload['kamreload'] = True
            payload['msg'] = 'Rule Deleted'
            return createApiResponse(**payload)

        # not possible
        else:
            payload['msg'] = 'Invalid HTTP method for this route'
            return createApiResponse(
                **payload,
                status_code=StatusCodes.HTTP_METHOD_NOT_ALLOWED
            )

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

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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

        return createApiResponse(msg='Email Sent')

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

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        endpointgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid)
        if endpointgroup is not None:
            endpointgroup.delete(synchronize_session=False)
        else:
            raise http_exceptions.NotFound("The endpoint group doesn't exist")

        call_settings = db.query(dSIPCallSettings).filter(dSIPCallSettings.gwgroupid == gwgroupid)
        if call_settings is not None:
            call_settings.delete(synchronize_session=False)

        subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid)
        if subscriber is not None:
            subscriber.delete(synchronize_session=False)

        endpoints = db.query(Gateways).filter(
            Gateways.description.regexp_match(f'gwgroup:{gwgroupid}(,|$)')
        )
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
        if domainmapping.count() > 0:
            # Get list of all domains managed by the endpoint group
            did_list = db.execute(
                text("SELECT DISTINCT did FROM domain_attrs WHERE name = 'created_by' AND value=:gwgroupid"),
                {'gwgroupid': gwgroupid}
            ).all()

            # Delete all domains
            db.execute(
                text("DELETE FROM domain WHERE did IN (SELECT did FROM domain_attrs WHERE name='created_by' AND value=:gwgroupid)"),
                {'gwgroupid': gwgroupid}
            )

            # Delete all domains_attrs
            if len(did_list) > 0:
                for did in did_list:
                    db.execute(
                        text("DELETE FROM domain_attrs WHERE did IN (:dids)"),
                        {'dids': str(did[0])}
                    )

            # Delete domain mapping, which will stop the fusionpbx sync
            domainmapping.delete(synchronize_session=False)

        dispatcher = db.query(Dispatcher).filter(
            (Dispatcher.setid == gwgroupid) |
            (Dispatcher.setid == int(gwgroupid) + 1000)
        )

        if dispatcher is not None:
            dispatcher.delete(synchronize_session=False)

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(msg='EndpointGroup deleted', kamreload=True)

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

    gwgroup_data = {}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        gwgroupid = int(gwgroupid)

        endpointgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if endpointgroup is not None:
            gwgroup_data['name'] = strFieldsToDict(endpointgroup.description)['name']
        else:
            raise http_exceptions.NotFound("Endpoint Group Does Not Exist")

        # Send back the gateway groupid that was requested
        gwgroup_data['gwgroupid'] = gwgroupid

        call_settings = db.query(dSIPCallSettings).filter(dSIPCallSettings.gwgroupid == gwgroupid).first()
        if call_settings is not None:
            gwgroup_data['call_settings'] = {
                'limit': call_settings.limit,
                'timeout': call_settings.timeout
            }
        else:
            gwgroup_data['call_settings'] = {}

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
        endpoint_weights = {}
        endpoint_keepalives = {}
        endpoints = db.query(Gateways).filter(
            Gateways.gwid.in_(endpointgroup.gwlist.split(','))
        ).all()
        dispatcher_rows = db.query(Dispatcher).filter(
            (Dispatcher.setid == gwgroupid) |
            (Dispatcher.setid == gwgroupid + 1000)
        ).all()
        if dispatcher_rows is not None:
            for row in dispatcher_rows:
                dst_host = row.destination.split(':', maxsplit=1)[1]
                attrs = row.attrsToDict()
                if attrs.get('rweight', None) is not None:
                    endpoint_weights[dst_host] = attrs['rweight']
                # TODO: make this check part of the DB object methods
                if Dispatcher.FLAGS['KEEP_ALIVE'] & row.flags:
                    endpoint_keepalives[dst_host] = 1
                else:
                    endpoint_keepalives[dst_host] = 0
        for endpoint in endpoints:
            host_split = endpoint.address.split(':')
            attrs_dict = endpoint.attrsToDict()
            gwgroup_data['endpoints'].append({
                'gwid': endpoint.gwid,
                'host': host_split[0],
                'port': int(host_split[1]) if len(host_split) > 1 else 5060,
                'signalling': attrs_dict['signalling'],
                'media': attrs_dict['media'],
                'description': strFieldsToDict(endpoint.description)['name'],
                'rweight': endpoint_weights[endpoint.address] if endpoint.address in endpoint_weights else 0,
                'keepalive': endpoint_keepalives[endpoint.address] if endpoint.address in endpoint_keepalives else 0,
                'maintmode': ''
            })
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

        return createApiResponse(
            msg='Endpoint group found',
            data=[gwgroup_data],
        )

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

    response_data = []

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        endpointgroups = db.query(GatewayGroups).filter(
            GatewayGroups.description.regexp_match(GatewayGroups.FILTER.ENDPOINT.value)
        ).all()

        for endpointgroup in endpointgroups:
            # Grap the description field, which is comma seperated key/value pair
            fields = strFieldsToDict(endpointgroup.description)

            # append summary of endpoint group data
            response_data.append({
                'gwgroupid': endpointgroup.id,
                'name': fields['name'],
                'gwlist': endpointgroup.gwlist
            })

        return createApiResponse(
            msg='Endpoint groups found',
            data=response_data,
        )

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
            call_settings: {
                limit: <int>,
                timeout: <int>
            },
            auth: {
                type: "ip"|"userpwd",
                user: <string>
                pass: <string>
                domain: <string>
            },
            endpoints [
                {
                    gwid:<int>,
                    host:<string>,
                    port:<int>,
                    signalling:<string>,
                    media:<string>,
                    description:<string>,
                    rweight:<int>,
                    keepalive:<int>
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
    VALID_REQUEST_DATA_ARGS = {"gwgroupid": int, "name": str, "call_settings": dict, "auth": dict,
                               "strip": int, "prefix": str, "notifications": dict, "cdr": dict,
                               "fusionpbx": dict, "endpoints": list}

    # ensure requred args are provided
    REQUIRED_ARGS = {'gwgroupid'}

    gwgroup_data = {}

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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

        # Update the gateway group call settings
        call_settings_data = request_payload['call_settings'] if 'call_settings' in request_payload else {}
        if db.query(dSIPCallSettings).filter(dSIPCallSettings.gwgroupid == gwgroupid).update({
            'limit': call_settings_data['limit'],
            'timeout': call_settings_data['timeout']
        }, synchronize_session=False):
            pass
        else:
            call_settings = dSIPCallSettings(gwgroupid, **call_settings_data)
            db.add(call_settings)

        # runtime defaults for this route
        strip = request_payload['strip'] if 'strip' in request_payload else 0
        prefix = request_payload['prefix'] if 'prefix' in request_payload else ""
        authtype = request_payload['auth']['type'] \
            if 'auth' in request_payload and 'type' in request_payload['auth'] else ""

        if 'fusionpbx' in request_payload:
            fusionpbxenabled = int(request_payload['fusionpbx']['enabled']) \
                if 'enabled' in request_payload['fusionpbx'] else 0
            fusionpbxdbhost = request_payload['fusionpbx']['dbhost'] \
                if 'dbhost' in request_payload['fusionpbx'] else None
            fusionpbxdbuser = request_payload['fusionpbx']['dbuser'] \
                if 'dbuser' in request_payload['fusionpbx'] else None
            fusionpbxdbpass = request_payload['fusionpbx']['dbpass'] \
                if 'dbpass' in request_payload['fusionpbx'] else None
        else:
            fusionpbxenabled = 0

        # Update the AuthType userpwd settings
        if authtype == "userpwd":
            authuser = request_payload['auth']['user'] \
                if 'user' in request_payload['auth'] and len(request_payload['auth']['user']) > 0 else None
            authpass = request_payload['auth']['pass'] \
                if 'pass' in request_payload['auth'] and len(request_payload['auth']['pass']) > 0 else None
            authdomain = request_payload['auth']['domain'] \
                if 'domain' in request_payload['auth'] and len(
                request_payload['auth']['domain']) > 0 else settings.DEFAULT_AUTH_DOMAIN
            authdomain = safeUriToHost(authdomain)

            if authuser is None or authpass is None:
                raise http_exceptions.BadRequest("Auth username or password invalid")
            if authdomain is None:
                raise http_exceptions.BadRequest("Auth domain is malformed")

            # Get the existing username and domain_name if it exists
            currentSubscriberInfo = db.query(Subscribers).filter(Subscribers.rpid == gwgroupid).first()
            if currentSubscriberInfo is not None:
                # Check if the new username and domain is unique
                if db.query(Subscribers).filter(
                    Subscribers.username == authuser,
                    Subscribers.domain == authdomain,
                    Subscribers.id != currentSubscriberInfo.id
                ).scalar():
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
        gwgroup_filter = f'gwgroup:{gwgroupid_str}(,|$)'
        current_endpoints_lut = {
            x.gwid: {
                'address': x.address,
                'type': x.type,
                'description_dict': strFieldsToDict(x.description),
                'attrs_dict': x.attrsToDict()
            } \
            for x in db.query(Gateways).filter(
                Gateways.description.regexp_match(gwgroup_filter)
            ).all()
        }
        updated_endpoints = request_payload['endpoints'] if "endpoints" in request_payload else []
        unprocessed_endpoints_lut = {}
        gwlist = []

        # endpoints to add unconditionally
        for endpoint in updated_endpoints:
            gwid = endpoint['gwid'] if 'gwid' in endpoint else None

            # If gwid is empty then this is a new endpoint
            if gwid is None:
                if 'host' not in endpoint:
                    raise http_exceptions.BadRequest("Endpoint hostname/address is required")

                host = endpoint['host']
                port = int(endpoint['port']) if endpoint.get('port', None) is not None else 5060
                signalling = endpoint['signalling'] if 'signalling' in endpoint else 'proxy'
                media = endpoint['media'] if 'media' in endpoint else 'proxy'
                name = endpoint['description'] if 'description' in endpoint else ''
                rweight = int(endpoint['rweight']) if endpoint.get('rweight', '') != '' else 1
                keepalive = int(endpoint['keepalive']) if endpoint.get('keepalive', '') != '' else 0

                flags = 0
                if keepalive > 0:
                    flags += Dispatcher.FLAGS['KEEP_ALIVE']
                if rweight == 0:
                    flags += Dispatcher.FLAGS['DISABLED_DST']

                sip_addr = safeUriToHost(host, default_port=port)
                if sip_addr is None:
                    raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

                if authtype == "ip":
                    # for ip auth we must create address records for the endpoint
                    host_ip = hostToIP(host)

                    # TODO: address entries should include port user specified
                    Addr = Address(name, host_ip, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                    db.add(Addr)
                    db.flush()
                    Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, addr_id=Addr.id,
                        signalling=signalling, media=media)
                else:
                    # we know this a new endpoint so we don't have to check for any address records here
                    Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid,
                        signalling=signalling, media=media)

                db.add(Gateway)
                db.flush()

                # Create dispatcher group with the set id being the gateway group id
                sip_uri = f'sip:{sip_addr}'
                dispatcher = Dispatcher(setid=gwgroupid, destination=sip_uri, flags=flags, rweight=rweight,
                    signalling=signalling, media=media, name=name, gwid=gwid)
                db.add(dispatcher)

                # Create dispatcher for FusionPBX external interface if FusionPBX feature is enabled
                if fusionpbxenabled:
                    sip_uri_ext = f'sip:{safeStripPort(sip_addr)}:5080'
                    setid_ext = gwgroupid + 1000
                    # Add 1000 to the gwgroupid so that the setid for the FusionPBX external interface is 1000 apart
                    dispatcher = Dispatcher(setid=setid_ext, destination=sip_uri_ext, flags=flags, rweight=rweight,
                        signalling=signalling, media=media, name=name, gwid=gwid)
                    db.add(dispatcher)

                gwlist.append(Gateway.gwid)

            # Process separately
            else:
                unprocessed_endpoints_lut[gwid] = endpoint

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

            if 'host' not in endpoint:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            host = endpoint['host']
            port = int(endpoint['port']) if endpoint.get('port', None) is not None else 5060
            signalling = endpoint['signalling'] if 'signalling' in endpoint else 'proxy'
            media = endpoint['media'] if 'media' in endpoint else 'proxy'
            name = endpoint['description'] if 'description' in endpoint else ''
            rweight = int(endpoint['rweight']) if endpoint.get('rweight', '') != '' else 1
            keepalive = int(endpoint['keepalive']) if endpoint.get('keepalive', '') != '' else 0

            flags = 0
            if keepalive > 0:
                flags += Dispatcher.FLAGS['KEEP_ALIVE']
            if rweight == 0:
                flags += Dispatcher.FLAGS['DISABLED_DST']

            sip_addr = safeUriToHost(host, default_port=port)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                # for ip auth we must create address records for the endpoint
                host_ip = hostToIP(host)

                # TODO: address entries should include port user specified
                Addr = Address(name, host_ip, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                db.add(Addr)
                db.flush()
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, addr_id=Addr.id,
                    signalling=signalling, media=media)
            else:
                # we know this a new endpoint so we don't have to check for any address records here
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid,
                    signalling=signalling, media=media)

            db.add(Gateway)
            db.flush()

            # Create dispatcher group with the set id being the gateway group id
            sip_uri = f'sip:{sip_addr}'
            dispatcher = Dispatcher(setid=gwgroupid, destination=sip_uri, flags=flags, rweight=rweight,
                signalling=signalling, media=media, name=name, gwid=gwid)
            db.add(dispatcher)

            # Create dispatcher for FusionPBX external interface if FusionPBX feature is enabled
            if fusionpbxenabled:
                sip_uri_ext = f'sip:{safeStripPort(sip_addr)}:5080'
                setid_ext = gwgroupid + 1000
                # Add 1000 to the gwgroupid so that the setid for the FusionPBX external interface is 1000 apart
                dispatcher = Dispatcher(setid=setid_ext, destination=sip_uri_ext, flags=flags, rweight=rweight,
                    signalling=signalling, media=media, name=name, gwid=gwid)
                db.add(dispatcher)

            # we ignore the given gwid and allow DB to assign one instead
            gwlist.append(Gateway.gwid)

        # conditional endpoints to update
        for gwid in upd_gwids:
            endpoint = unprocessed_endpoints_lut[gwid]
            current_endpoint = current_endpoints_lut[gwid]
            endpoint_fields = current_endpoint['description_dict']
            endpoint_attrs = current_endpoint['attrs_dict']

            # allow updating single fields (if not provided set to current value)
            host = endpoint['host'] if 'host' in endpoint else current_endpoint['address'].split(':')[0]
            if 'port' in endpoint and endpoint['port'] is not None:
                port = int(endpoint['port'])
            else:
                tmp = current_endpoint['address'].split(':')
                port = int(tmp[1]) if len(tmp) > 1 else 5060
            signalling = endpoint['signalling'] if 'signalling' in endpoint else endpoint_attrs['signalling']
            media = endpoint['media'] if 'media' in endpoint else endpoint_attrs['media']
            name = endpoint['description'] if 'description' in endpoint else endpoint_fields['name']
            endpoint_fields['name'] = name

            # fields not in dr_gateways attributes we set to None if not updated and check it after querying dispatcher
            rweight = int(endpoint['rweight']) if endpoint.get('rweight', None) is not None else None
            keepalive = int(endpoint['keepalive']) if endpoint.get('keepalive', None) is not None else None

            if len(host) == 0:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            sip_addr = safeUriToHost(host, default_port=port)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                # for ip auth we must create address records for the endpoint
                host_ip = hostToIP(host)

                # if address exists update, otherwise create it
                address_exists = False
                if 'addr_id' in endpoint_fields and len(endpoint_fields['addr_id']) > 0:
                    Addr = db.query(Address).filter(Address.id == endpoint_fields['addr_id']).first()

                    if Addr is not None:
                        address_exists = True

                        Addr.ip_addr = host_ip
                        addr_fields = strFieldsToDict(Addr.tag)
                        addr_fields['name'] = name
                        addr_fields['gwgroup'] = gwgroupid_str
                        Addr.tag = dictToStrFields(addr_fields)

                if not address_exists:
                    Addr = Address(name, host_ip, 32, settings.FLT_PBX, gwgroup=gwgroupid)

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

            # find the current entry in dr_gateways
            ep_gateway = db.query(Gateways).filter(Gateways.gwid == gwid).first()

            # find the current dispatcher entry (load balancing one is always there and has same params as other "feature" sets)
            ep_dispatcher = db.query(Dispatcher).filter(
                (Dispatcher.setid == gwgroupid) &
                Dispatcher.description.regexp_match(f'gwid={gwid}(;|$)')
            ).first()
            if ep_dispatcher is not None:
                if rweight is None:
                    rweight = ep_dispatcher.attrsToDict()['rweight']
                if keepalive is None:
                    keepalive = 8 & ep_dispatcher.flags
            else:
                if rweight is None:
                    rweight = 0
                if keepalive is None:
                    keepalive = 0

            flags = 0
            if keepalive > 0:
                flags += Dispatcher.FLAGS['KEEP_ALIVE']
            if rweight == 0:
                flags += Dispatcher.FLAGS['DISABLED_DST']

            # update the endpoint in dispatcher
            sip_uri = f'sip:{sip_addr}'
            if ep_dispatcher is not None:
                ep_dispatcher.destination = sip_uri
                ep_dispatcher.flags = flags
                ep_dispatcher.attrs = Dispatcher.buildAttrs(rweight, signalling, media)
                ep_dispatcher.description = Dispatcher.buildDescription(name, gwid)
            else:
                ep_dispatcher = Dispatcher(setid=gwgroupid, destination=sip_uri, flags=flags,
                    rweight=rweight, signalling=signalling, media=media, name=name, gwid=gwid)
                db.add(ep_dispatcher)

            # update the fusionpbx dispatcher entries for the endpoint
            sip_uri_ext = f'sip:{safeStripPort(sip_addr)}:5080'
            setid_ext = int(gwgroupid) + 1000
            if fusionpbxenabled:
                ep_dispatcher_ext = db.query(Dispatcher).filter(
                    (Dispatcher.setid == setid_ext) &
                    Dispatcher.description.regexp_match(f'gwid={gwid}(;|$)')
                ).first()
                if ep_dispatcher_ext is not None:
                    ep_dispatcher_ext.destination = sip_uri_ext
                    ep_dispatcher_ext.flags = flags
                    ep_dispatcher_ext.attrs = Dispatcher.buildAttrs(rweight, signalling, media)
                    ep_dispatcher_ext.description = Dispatcher.buildDescription(name, gwid)
                else:
                    ep_dispatcher_ext = Dispatcher(setid=setid_ext, destination=sip_uri_ext, flags=flags,
                        rweight=rweight, signalling=signalling, media=media, name=name, gwid=gwid)
                    db.add(ep_dispatcher_ext)
            else:
                # remove the entries if fusionpbx integration is now disabled
                db.query(Dispatcher).filter(
                    (Dispatcher.setid == setid_ext) &
                    Dispatcher.description.regexp_match(f'gwid={gwid}(;|$)')
                ).delete(synchronize_session=False)

            # update the endpoint in dr_gateways
            ep_gateway.description = dictToStrFields(endpoint_fields)
            ep_gateway.address = sip_addr
            ep_gateway.strip = strip
            ep_gateway.pri_prefix = prefix
            ep_gateway.attrs = Gateways.buildAttrs(gwid=gwid, type=current_endpoint['type'], signalling=signalling, media=media)

            gwlist.append(gwid)

        # conditional endpoints to delete
        # we also cleanup house here in case of stray entries
        del_gateways = db.query(Gateways).filter(
            Gateways.gwid.in_(del_gwids) &
            (Gateways.address != "localhost")
        )
        del_gateways_cleanup = db.query(Gateways).filter(
            Gateways.description.regexp_match(gwgroup_filter) &
            Gateways.gwid.notin_(gwlist) &
            (Gateways.address != "localhost")
        )
        # make sure we delete any associated address entries
        del_addr_ids = []
        for gateway in del_gateways.union(del_gateways_cleanup):
            description_dict = strFieldsToDict(gateway.description)
            if 'addr_id' in description_dict:
                del_addr_ids.append(description_dict['addr_id'])
        db.query(Address).filter(Address.id.in_(del_addr_ids)).delete(synchronize_session=False)

        # delete the dispatcher entries that correspond to the endpoints/gateways that was Deleted
        del_gw_filters = [
            f'gwid={gateway.gwid}(;|$)' for gateway in del_gateways.union(del_gateways_cleanup)
        ]
        # the default match for REGEXP is true, make sure we actually have gwids to match against
        if len(del_gw_filters) > 0:
            db.query(Dispatcher).filter(
                (Dispatcher.setid == gwgroupid) &
                Dispatcher.description.regexp_match('|'.join(del_gw_filters))
            ).delete(synchronize_session=False)

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
                cron_cmd = '{} cdr sendreport {}'.format(
                    (settings.DSIP_PROJECT_DIR + '/gui/dsiprouter_cron.py'),
                    gwgroupid_str
                )
                # Try to update
                if db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).update(
                    {"email": cdr_email, "send_interval": cdr_send_interval},
                    synchronize_session=False):
                    if not updateTaggedCronjob(gwgroupid, cdr_send_interval):
                        # in-case the entry was modified elsewhere we can just create it again
                        if not addTaggedCronjob(gwgroupid, cdr_send_interval, cron_cmd):
                            raise Exception('Crontab entry could not be updated')
                else:
                    cdrinfo = dSIPCDRInfo(gwgroupid, cdr_email, cdr_send_interval)
                    db.add(cdrinfo)

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Endpoint group updated',
            data=[gwgroup_data],
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


# TODO: fix up like updateEnpointGroups()
# TODO: this is the only route that has the proper updated documentation format
#       use this route as an example to populate the other route docstings
@api.route("/api/v1/endpointgroups", methods=['POST'])
@api_security
def addEndpointGroups(data=None, endpointGroupType=None, domain=None):
    """
    Add a single Endpoint Group

    :<json string name: the endpoint group name
    :<json integer calllimit: limit concurrent calls to this endpoint group (0=unlimited)
    :<json object auth: authentication settings for this endpoint group
    :reqheader Accept: optional, assumed to be application/json
    :reqheader Authorization: required, dSIPRouter API Bearer token
    :resheader Content-Type: required, should always be application/json
    :status 200: on success
    :status 401: on auth failure
    :status 500: on unhandled application server error
    :status 502: when application server is down but reverse proxy is still up

    Example Request:

    .. code-block:: json

        {
            "name": "example",
            "call_settings": {
                limit: 5,
                timeout: 3600
            },
            "auth": {
                "type": "userpwd",
                "user": "example",
                "pass": "example",
                "domain": "example.com"
            },
            "endpoints": [
                {
                    "host": "www.example.com",
                    "port": 5060,
                    "signalling": "proxy",
                    "media": "proxy",
                    "description": "example",
                    "rweight": 1,
                    "keepalive": 1
                }
            ],
            "strip": 0,
            "prefix": "",
            "notifications": {
                "overmaxcalllimit": "email@example.com",
                "endpointfailure": "email@example.com"
            },
            "cdr": {
                "cdr_email": "email@example.com",
                "cdr_send_interval": "email@example.com"
            },
            "fusionpbx": {
                "enabled": true,
                "dbhost": "example",
                "dbuser": "example",
                "dbpass": "example"
            }
        }

    Example Response:

    .. code-block:: json

        {
            "error": "",
            "msg": "Endpoint group created",
            "kamreload": true,
            "dsipreload": false,
            "data": [
                {
                    "gwgroupid": 101,
                    "gwlist": "375",
                    "name": "example"
                }
            ]
        }
    """

    db = DummySession()
    fusionpbxenabled = 0

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {
        "name": str, "call_settings": dict, "auth": dict, "strip": int, "prefix": str,
        "notifications": dict, "cdr": dict, "fusionpbx": dict, "endpoints": list
    }

    gwgroup_data = {}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

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

        # create the call settings for the new gateway group
        call_settings_data = request_payload['call_settings'] if 'call_settings' in request_payload else {}
        call_settings = dSIPCallSettings(gwgroupid, **call_settings_data)
        db.add(call_settings)

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
                   and len(request_payload['auth']['domain']) > 0 else settings.DEFAULT_AUTH_DOMAIN
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
            fusionpbxclustersupport = request_payload['fusionpbx']['clustersupport'] \
                if 'clustersupport' in request_payload['fusionpbx'] else None
            fusionpbxdbhost = request_payload['fusionpbx']['dbhost'] \
                if 'dbhost' in request_payload['fusionpbx'] else None
            fusionpbxdbuser = request_payload['fusionpbx']['dbuser'] \
                if 'dbuser' in request_payload['fusionpbx'] else None
            fusionpbxdbpass = request_payload['fusionpbx']['dbpass'] \
                if 'dbpass' in request_payload['fusionpbx'] else None

            # Convert fusionpbxenabled variable to int
            if isinstance(fusionpbxenabled, str):
                fusionpbxenabled = int(fusionpbxenabled)

            # Convert fusionclustersupport variable to int
            if isinstance(fusionpbxclustersupport, str):
                fusionpbxclustersupport = int(fusionpbxclustersupport)

            if fusionpbxenabled:
                if fusionpbxclustersupport == 1:
                    domainType = dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX_CLUSTER.value
                else:
                    domainType = dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value

                domainmapping = dSIPMultiDomainMapping(gwgroupid, fusionpbxdbhost, fusionpbxdbuser, fusionpbxdbpass,
                    type=domainType)
                db.add(domainmapping)

                # Add the FusionPBX server as an Endpoint if it's not just the DB server
                if fusionpbxclustersupport is None or fusionpbxclustersupport == False:
                    endpoint = {}
                    endpoint['host'] = fusionpbxdbhost
                    endpoint['description'] = "FusionPBX Server"
                    if "endpoints" not in request_payload:
                        request_payload['endpoints'] = []
                    request_payload['endpoints'].append(endpoint)

        msteams_domain = domain if domain is not None else ''

        # Setup Endpoints
        endpoints = request_payload['endpoints'] if "endpoints" in request_payload else []
        gwlist = []

        # endpoints to add unconditionally
        for endpoint in endpoints:
            if 'host' not in endpoint:
                raise http_exceptions.BadRequest("Endpoint hostname/address is required")

            host = endpoint['host']
            port = int(endpoint['port']) if endpoint.get('port', None) is not None else 5060
            signalling = endpoint['signalling'] if 'signalling' in endpoint else 'proxy'
            media = endpoint['media'] if 'media' in endpoint else 'proxy'
            name = endpoint['description'] if 'description' in endpoint else ''
            rweight = int(endpoint['rweight']) if endpoint.get('rweight', '') != '' else 1
            keepalive = int(endpoint['keepalive']) if endpoint.get('keepalive', '') != '' else 0

            flags = 0
            if keepalive > 0:
                flags += Dispatcher.FLAGS['KEEP_ALIVE']
            if rweight == 0:
                flags += Dispatcher.FLAGS['DISABLED_DST']

            sip_addr = safeUriToHost(host, default_port=port)
            if sip_addr is None:
                raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")

            if authtype == "ip":
                host_ip = hostToIP(host)

                # TODO: address entries should include port user specified
                Addr = Address(name, host_ip, 32, settings.FLT_PBX, gwgroup=gwgroupid)
                db.add(Addr)
                db.flush()
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid, addr_id=Addr.id,
                    msteams_domain=msteams_domain, signalling=signalling, media=media)
            else:
                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_PBX, gwgroup=gwgroupid,
                    msteams_domain=msteams_domain, signalling=signalling, media=media)

            db.add(Gateway)
            db.flush()

            # Create dispatcher group with the set id being the gateway group id
            # Don't create a dispatcher set for endpoint groups that was created for MSTeams domains    
            if endpointGroupType != "msteams":
                dispatcher = Dispatcher(setid=gwgroupid, destination=sip_addr, flags=flags, rweight=rweight,
                    signalling=signalling, media=media, name=name, gwid=Gateway.gwid)
                db.add(dispatcher)

            # Create dispatcher for FusionPBX external interface if FusionPBX feature is enabled
            if fusionpbxenabled:
                sip_uri_ext = f'sip:{safeStripPort(sip_addr)}:5080'
                setid_ext = gwgroupid + 1000
                # Add 1000 to the gwgroupid so that the setid for the FusionPBX external interface is 1000 apart
                dispatcher = Dispatcher(setid=setid_ext, destination=sip_uri_ext, flags=flags, rweight=rweight,
                    signalling=signalling, media=media, name=name, gwid=Gateway.gwid)
                db.add(dispatcher)


            gwlist.append(Gateway.gwid)

        # set return gwlist and update the endpoint group's gwlist
        gwgroup_data['endpoints'] = gwlist
        gwlist_str = ','.join([str(gw) for gw in gwlist])

        # Update Gateway group with the Dispatcher ID.  It's denoted with the LB field
        fields = strFieldsToDict(Gwgroup.description)
        # Don't add a load balancing group if the domain is a MSTeams domain
        if endpointGroupType != "msteams":
            fields['lb'] = gwgroupid
        if fusionpbxenabled:
            fields['lb_ext'] = gwgroupid + 1000

        # Update the GatewayGroup with the lists of gateways
        Gwgroup.gwlist = gwlist_str
        Gwgroup.description = dictToStrFields(fields)

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Endpoint group created',
            data=[gwgroup_data],
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/numberenrichment", methods=['GET'])
@api.route("/api/v1/numberenrichment/<int:rule_id>", methods=['GET'])
@api_security
def getNumberEnrichment(rule_id=None):
    """
    Get one or multiple number enrichment rules

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <str>,
            msg: <str>,
            kamreload: <bool>,
            data: [
                {
                    rule_id: <int>,
                    dnid: <str>,
                    country_code: <str>,
                    routing_number: <str>,
                    rule_name: <str>
                },
                ...
            ]
        }
    """
    db = DummySession()

    response_data = []

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # get a single enrichment rule
        if rule_id is not None:
            rule = db.query(dSIPDNIDEnrichment).filter(dSIPDNIDEnrichment.id == rule_id).first()
            if rule is not None:
                response_data.append({
                    'rule_id': rule.id,
                    'dnid': rule.dnid,
                    'country_code': rule.country_code,
                    'routing_number': rule.routing_number,
                    'rule_name': strFieldsToDict(rule.description)['name']
                })
            else:
                raise http_exceptions.NotFound("Enrichment Rule Does Not Exist")
        # get all enrichment rules
        else:
            rules = db.query(dSIPDNIDEnrichment).all()

            for rule in rules:
                response_data.append({
                    'rule_id': rule.id,
                    'dnid': rule.dnid,
                    'country_code': rule.country_code,
                    'routing_number': rule.routing_number,
                    'rule_name': strFieldsToDict(rule.description)['name']
                })

        return createApiResponse(
            msg='Enrichment Rule(s) found',
            data=response_data,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/numberenrichment", methods=['POST'])
@api_security
def addNumberEnrichment(request_payload=None):
    """
    Add a one or multiple enrichment rules

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            data: [
                {
                    dnid: <str>,
                    country_code: <str>,
                    routing_number: <str>,
                    rule_name: <str>
                },
                ...
            ]
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <str>,
            msg: <str>,
            kamreload: <bool>,
            data: [
                {
                    rule_id: <int>
                },
                ...
            ]
        }
    """

    db = DummySession()

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {
        "dnid": str, "country_code": str, "routing_number": str, "rule_name": str
    }

    # ensure requred args are provided
    REQUIRED_REQUEST_DATA_ARGS = {'dnid'}

    response_data = []

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # allow calling function with payload data
        if request_payload is None:
            request_payload = getRequestData()

        # sanity checks
        if 'data' not in request_payload or len(request_payload['data']) == 0:
            raise http_exceptions.BadRequest("Request argument 'data' is required and must be non-zero length")
        for data in request_payload['data']:
            if not isinstance(data, dict):
                raise http_exceptions.BadRequest("Request argument 'data' not valid")
            for k, v in data.items():
                if k not in VALID_REQUEST_DATA_ARGS.keys():
                    raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
                if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                    try:
                        request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                        continue
                    except:
                        raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
            for k in REQUIRED_REQUEST_DATA_ARGS:
                if k not in data:
                    raise http_exceptions.BadRequest("Required argument '{}' missing in data entry".format(k))

        # don't allow duplicate dnid's
        new_dnid_list = [x['dnid'] for x in request_payload['data']]
        if db.query(dSIPDNIDEnrichment).filter(dSIPDNIDEnrichment.dnid.in_(new_dnid_list)).scalar():
            raise http_exceptions.BadRequest("Duplicate DNID's are not allowed")

        for rule_data in request_payload['data']:
            rule = dSIPDNIDEnrichment(**rule_data)
            db.add(rule)
            db.flush()
            response_data.append({'rule_id': rule.id})

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Enrichment Rule(s) created',
            data=response_data,
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/numberenrichment", methods=['PUT'])
@api.route("/api/v1/numberenrichment/<int:rule_id>", methods=['PUT'])
@api_security
def updateNumberEnrichment(rule_id=None, request_payload=None):
    """
    Update one or multiple enrichment rules\n
    The rule_id can be provided in url path or payload

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            data: [
                {
                    rule_id: <int>
                    dnid: <str>,
                    country_code: <str>,
                    routing_number: <str>,
                    rule_name: <str>
                },
                ...
            ]
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <str>,
            msg: <str>,
            kamreload: <bool>,
            data: [
                {
                    rule_id: <int>
                },
                ...
            ]
        }
    """

    db = DummySession()

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {
        "rule_id": int, "dnid": str, "country_code": str, "routing_number": str, "rule_name": str
    }

    # ensure requred args are provided
    REQUIRED_REQUEST_DATA_ARGS = {'dnid'}

    response_data = []

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        # allow calling function with payload data
        if request_payload is None:
            request_payload = getRequestData()

        # sanity checks
        if 'data' not in request_payload or len(request_payload['data']) == 0:
            raise http_exceptions.BadRequest("Request argument 'data' is required and must be non-zero length")
        else:
            if rule_id is not None and isinstance(request_payload['data'][0], dict):
                request_payload['data'][0]['rule_id'] = int(rule_id)
        for data in request_payload['data']:
            if not isinstance(data, dict):
                raise http_exceptions.BadRequest("Request argument 'data' not valid")
            for k, v in data.items():
                if k not in VALID_REQUEST_DATA_ARGS.keys():
                    raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
                if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                    try:
                        request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                        continue
                    except:
                        raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
            for k in REQUIRED_REQUEST_DATA_ARGS:
                if k not in data:
                    raise http_exceptions.BadRequest("Required argument '{}' missing in data entry".format(k))

        # don't allow duplicate dnid's
        upd_ruleids = [x['rule_id'] for x in request_payload['data'] if 'rule_id' in x]
        old_dnids = set(x.dnid for x in db.query(dSIPDNIDEnrichment).all() if x.id not in upd_ruleids)
        add_dnids = set(x['dnid'] for x in request_payload['data'] if not 'rule_id' in x)
        upd_dnids = set(x['dnid'] for x in request_payload['data'] if 'rule_id' in x)
        if len(list(add_dnids) + list(upd_dnids) + list(old_dnids)) > len(set.union(add_dnids, upd_dnids, old_dnids)):
            raise http_exceptions.BadRequest("Duplicate DNID's are not allowed")

        for rule_data in request_payload['data']:
            # adding new rules
            if not 'rule_id' in rule_data:
                rule = dSIPDNIDEnrichment(**rule_data)
                db.add(rule)
                db.flush()
                response_data.append({'rule_id': rule.id})
            # updating existing rules
            else:
                rule_id = rule_data.pop('rule_id')
                description = {'name': rule_data.pop('rule_name')}
                rule_data['description'] = dictToStrFields(description)

                if not db.query(dSIPDNIDEnrichment).filter(dSIPDNIDEnrichment.id == rule_id).update(
                    rule_data, synchronize_session=False):
                    raise http_exceptions.BadRequest("Enrichment Rule with id '{}' does not exist".format(str(rule_id)))
                response_data.append({'rule_id': rule_id})

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Enrichment Rule(s) updated',
            data=response_data,
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/numberenrichment", methods=['DELETE'])
@api.route("/api/v1/numberenrichment/<int:rule_id>", methods=['DELETE'])
@api_security
def deleteNumberEnrichment(rule_id, request_payload=None):
    """
    Delete one or multiple enrichment rules\n
    The rule_id can be provided in url path or payload

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            data: [
                {
                    rule_id: <int>
                },
                ...
            ]
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <str>,
            msg: <str>,
            kamreload: <bool>,
            data: []
        }
    """

    db = DummySession()

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"rule_id": int}

    # ensure requred args are provided
    REQUIRED_REQUEST_DATA_ARGS = {'rule_id'}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # allow calling function with payload data
        if request_payload is None:
            request_payload = getRequestData()

        # sanity checks
        if rule_id is not None:
            request_payload['data'] = [{'rule_id': int(rule_id)}]
        elif 'data' not in request_payload or len(request_payload['data']) == 0:
            raise http_exceptions.BadRequest("Request argument 'data' is required and must be non-zero length")
        for data in request_payload['data']:
            if not isinstance(data, dict):
                raise http_exceptions.BadRequest("Request argument 'data' not valid")
            for k, v in data.items():
                if k not in VALID_REQUEST_DATA_ARGS.keys():
                    raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
                if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                    try:
                        request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                        continue
                    except:
                        raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
            for k in REQUIRED_REQUEST_DATA_ARGS:
                if k not in data:
                    raise http_exceptions.BadRequest("Required argument '{}' missing in data entry".format(k))

        rule_ids = [x['rule_id'] for x in request_payload['data']]
        rules = db.query(dSIPDNIDEnrichment).filter(dSIPDNIDEnrichment.id.in_(rule_ids))
        if rules is not None:
            rules.delete(synchronize_session=False)
        else:
            raise http_exceptions.NotFound("The enrichment rule(s) do not exist")

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Enrichment Rule(s) deleted',
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/numberenrichment/fetch", methods=['POST'])
@api_security
def fetchNumberEnrichment(request_payload=None):
    """
    Fetch a CSV to import from an external server\n
    Updates and adds rules by default\n
    If replace_rules is True then current rules are replaced

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            data: [
                {
                    url: <str>
                },
                ...
            ],
            replace_rules: <bool>
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <str>,
            msg: <str>,
            kamreload: <bool>,
            data: [
                {
                    rule_id: <int>,
                    dnid: <str>,
                    country_code: <str>,
                    routing_number: <str>,
                    rule_name: <str>
                },
                ...
            ]
        }
    """

    # for validation of request args
    VALID_REQUEST_ARGS = {"data": list, "replace_rules": bool}

    # for validation of data args
    VALID_REQUEST_DATA_ARGS = {"url": str}

    # ensure required args are provided
    REQUIRED_REQUEST_DATA_ARGS = {'url'}

    response_payload = {'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # allow calling function with payload data
        if request_payload is None:
            request_payload = getRequestData()

        # sanity checks
        if len(request_payload['data']) == 0:
            raise http_exceptions.BadRequest("Request argument 'data' must be non-zero length")
        for k, v in request_payload.items():
            if k not in VALID_REQUEST_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_ARGS[k]:
                try:
                    request_payload[k] = VALID_REQUEST_ARGS[k](v)
                    continue
                except:
                    raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
        for data in request_payload['data']:
            for k, v in data.items():
                if k not in VALID_REQUEST_DATA_ARGS.keys():
                    raise http_exceptions.BadRequest("Request argument '{}' not recognized".format(k))
                if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                    try:
                        request_payload[k] = VALID_REQUEST_DATA_ARGS[k](v)
                        continue
                    except:
                        raise http_exceptions.BadRequest("Request argument '{}' not valid".format(k))
            for k in REQUIRED_REQUEST_DATA_ARGS:
                if k not in data:
                    raise http_exceptions.BadRequest("Required argument '{}' missing in data entry".format(k))

        # prep for gathering data from csv
        new_rules = []
        resource_urls = [x['url'] for x in request_payload['data']]

        # TODO: we should not blindly download the file, we need to some security checks here
        # TODO: we should be doing downloads in separate threads
        for url in resource_urls:
            with closing(requests.get(url, stream=True)) as resp:
                # iterator for csv stream lines
                iter_lines = codecs.iterdecode(resp.iter_lines(), 'utf-8')

                # lines for sniffer to detect csv type
                line_1 = next(iter_lines, None)
                if line_1 is None:
                    raise http_exceptions.BadRequest("File at fetch URL is invalid")
                line_2 = next(iter_lines, None)

                # detect csv dialect and if header is present
                sniffer_lines = line_1 + '\n' + line_2 if line_2 is not None else line_1
                dialect = csv.Sniffer().sniff(sniffer_lines, delimiters=',;|')
                has_header = csv.Sniffer().has_header(sniffer_lines)

                # add valid values from sniffer lines to rules
                start_lines = []
                if not has_header:
                    start_lines.append(line_1)
                if line_2 is not None:
                    start_lines.append(line_2)
                for row in csv.reader((line for line in start_lines), dialect):
                    new_rules.append({
                        "dnid": row[0],
                        "country_code": row[1],
                        "routing_number": row[2],
                        "rule_name": row[3]
                    })

                # read rest of csv stream and add to rules
                for row in csv.reader(iter_lines, dialect):
                    new_rules.append({
                        "dnid": row[0],
                        "country_code": row[1],
                        "routing_number": row[2],
                        "rule_name": row[3]
                    })

        # if replacing rules delete all then add
        # if updating rules merge based on dnid (must be unique still)
        replace_rules = request_payload['replace_rules'] if 'replace_rules' in request_payload else False
        if replace_rules:
            db.query(dSIPDNIDEnrichment).delete(synchronize_session=False)
            db.flush()

            ret = addNumberEnrichment(request_payload={'data': new_rules})
            if ret[1] != StatusCodes.HTTP_OK:
                resp = ret[0].get_json(force=True)
                response_payload['error'] = resp['error']
                response_payload['msg'] = resp['msg']
                return createApiResponse(**response_payload, status_code=ret[1])
            response_payload['msg'] = "Enrichment Rule(s) replaced"
        else:
            current_rules_lut = {
                x.dnid: {'rule_id': x.id}
                for x in db.query(dSIPDNIDEnrichment).all()
            }
            current_dnids = set(current_rules_lut.keys())
            new_rules_lut = {
                x['dnid']: {'dnid': x['dnid'], 'country_code': x['country_code'],
                            'routing_number': x['routing_number'], 'rule_name': x['rule_name']}
                for x in new_rules
            }
            new_dnids = set(new_rules_lut.keys())

            add_dnids = new_dnids - current_dnids
            upd_dnids = current_dnids & new_dnids

            updated_rules = []
            for dnid in add_dnids:
                updated_rules.append(new_rules_lut[dnid])
            for dnid in upd_dnids:
                updated_rules.append({'rule_id': current_rules_lut[dnid]['rule_id'], **new_rules_lut[dnid]})

            ret = updateNumberEnrichment(request_payload={'data': updated_rules})
            if ret[1] != StatusCodes.HTTP_OK:
                resp = ret[0].get_json(force=True)
                response_payload['error'] = resp['error']
                response_payload['msg'] = resp['msg']
                return createApiResponse(**response_payload, status_code=ret[1])
            response_payload['msg'] = "Enrichment Rule(s) updated"

        # let requestor know what rules are now available
        rules = db.query(dSIPDNIDEnrichment).all()
        for rule in rules:
            response_payload['data'].append({
                'rule_id': rule.id,
                'dnid': rule.dnid,
                'country_code': rule.country_code,
                'routing_number': rule.routing_number,
                'rule_name': strFieldsToDict(rule.description)['name']
            })

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            **response_payload,
            kamreload=True,
        )

    except Exception as ex:
        return showApiError(ex, response_payload)


# TODO: standardize response payload (use data param)
# TODO: stop shadowing builtin functions -> type == builtin
# TODO: too manu use cases in this one function, split it up into constituent pieces
def generateCDRS(
    gwgroupid,
    report_type=None,
    send_email=None,
    dtfilter=None,
    cdrfilter=None,
    nonCompletedCalls=None,
    run_standalone=False,
    filter_params=None,
):
    """
    Generate CDRs Report for a gwgroup

    :param gwgroupid:       gwgroup to generate cdr's for
    :type gwgroupid:        int|str
    :param report_type:            type of report (json|csv)
    :type report_type:             str
    :param send_email:           whether the report should be emailed
    :type send_email:            bool
    :param dtfilter:        time before which cdr's are not returned
    :type dtfilter:         datetime
    :param cdrfilter:       comma seperated cdr id's to include
    :type cdrfilter:        str
    :return:                returns a json response or file
    :rtype:                 flask.Response
    """

    # if run in standalone mode we need to setup logging
    initSyslogLogger()

    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}
    # define here so we can cleanup in finally statement
    csv_file = ''

    try:
        db = startSession()

        if isinstance(gwgroupid, int):
            gwgroupid = str(gwgroupid)
        if report_type is None:
            report_type = 'json'
        else:
            report_type = report_type.lower()
        if send_email is None:
            send_email = False
        if dtfilter is None:
            dtfilter = datetime.min
        if cdrfilter is None:
            cdrfilter = tuple()
        else:
            cdrfilter = tuple(cdrfilter.split(','))
        if nonCompletedCalls is None:
            nonCompletedCalls = True
        if filter_params is None:
            filter_params = {'paging': False, 'searching': False, 'ordering': False}

        gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).first()
        if gwgroup is not None:
            gwgroupName = strFieldsToDict(gwgroup.description)['name']
        else:
            response_payload['status'] = "0"
            response_payload['message'] = "Endpont group doesn't exist"
            if run_standalone:
                IO.logerr(f'Endpont group {gwgroupid} does not exist')
                return None
            return jsonify(response_payload)

        if len(cdrfilter) > 0:
            sql_params = {"gwgroupid": gwgroupid, "dtfilter": dtfilter, "cdrfilter": cdrfilter}
            query1 = (
                """SELECT t1.cdr_id, t1.call_start_time, t1.duration AS call_duration, t1.calltype AS call_direction,
                          t2.id AS src_gwgroupid, substring_index(substring_index(t2.description, 'name:', -1), ',', 1) AS src_gwgroupname,
                          t3.id AS dst_gwgroupid, substring_index(substring_index(t3.description, 'name:', -1), ',', 1) AS dst_gwgroupname,
                          t1.src_username, t1.dst_username, t1.src_ip AS src_address, t1.dst_domain AS dst_address, t1.sip_call_id AS call_id
                FROM cdrs t1
                JOIN dr_gw_lists t2 ON (t1.src_gwgroupid = t2.id)
                JOIN dr_gw_lists t3 ON (t1.dst_gwgroupid = t3.id)
                WHERE (t2.id = :gwgroupid OR t3.id = :gwgroupid) AND t1.call_start_time >= :dtfilter AND t1.cdr_id IN :cdrfilter
                ORDER BY t1.call_start_time DESC"""
            )
        else:
            sql_params = {"gwgroupid": gwgroupid, "dtfilter": dtfilter}
            query1 = (
                """SELECT t1.cdr_id, t1.call_start_time, t1.duration AS call_duration, t1.calltype AS call_direction,
                          t2.id AS src_gwgroupid, substring_index(substring_index(t2.description, 'name:', -1), ',', 1) AS src_gwgroupname,
                          t3.id AS dst_gwgroupid, substring_index(substring_index(t3.description, 'name:', -1), ',', 1) AS dst_gwgroupname,
                          t1.src_username, t1.dst_username, t1.src_ip AS src_address, t1.dst_domain AS dst_address, t1.sip_call_id AS call_id
                FROM cdrs t1
                JOIN dr_gw_lists t2 ON (t1.src_gwgroupid = t2.id)
                JOIN dr_gw_lists t3 ON (t1.dst_gwgroupid = t3.id)
                WHERE (t2.id = :gwgroupid OR t3.id = :gwgroupid) AND t1.call_start_time >= :dtfilter
                ORDER BY t1.call_start_time DESC"""
            )

        if nonCompletedCalls:
            query2 = (
                """SELECT acc.id AS cdr_id, acc.time, 0, acc.calltype,
                acc.src_gwgroupid, SUBSTRING_INDEX(SUBSTRING_INDEX(t2.description, 'name:', -1), ',', 1) AS src_gwgroupname,
                acc.dst_gwgroupid, SUBSTRING_INDEX(SUBSTRING_INDEX(t3.description, 'name:', -1), ',', 1) AS dst_gwgroupname,
                acc.src_user,acc.dst_user,acc.src_ip,acc.dst_domain,acc.callid
                FROM acc
                JOIN dr_gw_lists t2 ON (acc.src_gwgroupid = t2.id)
                LEFT JOIN dr_gw_lists t3 ON (acc.dst_gwgroupid = t3.id)
                WHERE (t2.id = :gwgroupid OR t3.id = :gwgroupid) AND acc.time >= :dtfilter
                ORDER BY acc.time DESC"""
            )
            sql = f'SELECT SQL_CALC_FOUND_ROWS * FROM (({query1}) UNION ({query2})) t_all'
        else:
            sql = f'SELECT SQL_CALC_FOUND_ROWS * FROM ({query1}) t_all'

        if filter_params['searching']:
            if filter_params['search_regex']:
                sql_params['search_val'] = filter_params['search_val']
                sql = sql + ' WHERE ' + '''
                `cdr_id` REGEXP :search_val
                OR `call_start_time` REGEXP :search_val
                OR `call_duration` REGEXP :search_val
                OR `call_direction` REGEXP :search_val
                OR `src_gwgroupname` REGEXP :search_val
                OR `dst_gwgroupname` REGEXP :search_val
                OR `src_username` REGEXP :search_val
                OR `dst_username` REGEXP :search_val
                OR `src_address` REGEXP :search_val
                OR `dst_address` REGEXP :search_val
                OR `call_id` REGEXP :search_val
                '''
            else:
                sql_params['search_val'] = f"%{filter_params['search_val']}%"
                sql = sql + ' WHERE ' + '''
                `cdr_id` LIKE :search_val
                OR `call_start_time` LIKE :search_val
                OR `call_duration` LIKE :search_val
                OR `call_direction` LIKE :search_val
                OR `src_gwgroupname` LIKE :search_val
                OR `dst_gwgroupname` LIKE :search_val
                OR `src_username` LIKE :search_val
                OR `dst_username` LIKE :search_val
                OR `src_address` LIKE :search_val
                OR `dst_address` LIKE :search_val
                OR `call_id` LIKE :search_val
                '''
        if filter_params['ordering']:
            sql_params['order_col'] = filter_params['order_col']
            if filter_params['order_dir'] == 'desc':
                sql = sql + ' ORDER BY :order_col DESC'
            else:
                sql = sql + ' ORDER BY :order_col ASC'
        if filter_params['paging']:
            sql_params['page_start'] = filter_params['page_start']
            sql_params['page_len'] = filter_params['page_len']
            sql = sql + ' LIMIT :page_len OFFSET :page_start'
        sql = text(sql)

        rows = db.execute(sql, sql_params).all()
        total_rows = db.execute(text('SELECT FOUND_ROWS()')).scalar()
        # TODO: does not work as described by datatables, clientside JS expects the count before limiting
        # only effects the text displayed on the bottom left (filter shown when searching)
        #filtered_rows = len(rows)
        filtered_rows = total_rows

        cdrs = []
        dataFields = [
            'cdr_id', 'call_start_time', 'call_duration', 'call_direction', 'src_gwgroupid',
            'src_gwgroupname', 'dst_gwgroupid', 'dst_gwgroupname', 'src_username',
            'dst_username', 'src_address', 'dst_address', 'call_id'
        ]
        for row in rows:
            data = {}
            data['cdr_id'] = int(row[0])
            data['call_start_time'] = row[1]
            data['call_duration'] = str(row[2])
            data['call_direction'] = row[3]
            data['src_gwgroupid'] = row[4]
            data['src_gwgroupname'] = row[5]
            data['dst_gwgroupid'] = row[6]
            data['dst_gwgroupname'] = row[7]
            data['src_username'] = row[8]
            data['dst_username'] = row[9]
            data['src_address'] = row[10]
            data['dst_address'] = row[11]
            data['call_id'] = row[12]
            cdrs.append(data)

        response_payload['status'] = "200"
        response_payload['data'] = cdrs
        response_payload['total_rows'] = total_rows
        response_payload['filtered_rows'] = filtered_rows

        # Convert array of dicts to csv format
        if report_type == "csv":
            now = time.strftime('%Y%m%d-%H%M%S')
            filename = secure_filename('{}_{}.csv'.format(gwgroupName, now))
            csv_file = '/tmp/{}'.format(filename)
            with open(csv_file, 'w', newline='') as csv_fp:
                if len(cdrs) > 0:
                    dict_writer = csv.DictWriter(csv_fp, fieldnames=cdrs[0].keys())
                    dict_writer.writeheader()
                    dict_writer.writerows(cdrs)
                else:
                    dict_writer = csv.DictWriter(csv_fp, fieldnames=dataFields)
                    dict_writer.writeheader()

            if send_email:
                # recipients required
                cdr_info = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
                if cdr_info is not None:
                    # Setup the parameters to send the email
                    data = {}
                    data['html_body'] = "<html>CDR Report for {}</html>".format(gwgroupName)
                    data['text_body'] = "CDR Report for {}".format(gwgroupName)
                    data['subject'] = "CDR Report for {}".format(gwgroupName)
                    data['attachments'] = [csv_file]
                    data['recipients'] = cdr_info.email.split(',')
                    sendEmail(**data)
                    # remove CDRs from the payload that is being returned
                    response_payload.pop('data')
                    response_payload['format'] = 'csv'
                    response_payload['type'] = 'email'
                    if run_standalone:
                        IO.loginfo(f'Sent CDR report for endpoint group {gwgroupid}')
                        return None
                    return jsonify(response_payload)

            if run_standalone:
                IO.logerr(f'Nowhere to send CDR report for endpoint group {gwgroupid} run in standalone mode')
                return None
            return send_file(csv_file, as_attachment=True), StatusCodes.HTTP_OK

        if run_standalone:
            IO.logerr(f'Nowhere to send CDR report for endpoint group {gwgroupid} run in standalone mode')
            return None
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
def getGatewayGroupCDRS(gwgroupid=None):
    """
    Purpose

    Getting the cdrs for a gatewaygroup

    """
    if (settings.DEBUG):
        debugEndpoint()

    report_type = request.args.get('type', 'json')
    if 'email' in request.args:
        send_email = json.loads(request.args['email'])
    else:
        send_email = False
    cdrfilter = request.args.get('filter', None)
    if 'dtfilter' in request.args:
        dtfilter = datetime.strptime(request.args['dtfilter'], "%Y-%m-%d")
    else:
        dtfilter = None
    if 'nonCompletedCalls' in request.args:
        nonCompletedCalls = json.loads(request.args['nonCompletedCalls'])
    else:
        nonCompletedCalls = True

    if 'start' in request.args or 'length' in request.args:
        page_start = int(request.args.get('start', 0))
        page_len = int(request.args.get('length', 100))
        filter_params = {
            'paging': True,
            'page_start': page_start,
            'page_len': page_len,
        }
    else:
        filter_params = {
            'paging': False,
        }
    if 'search[value]' in request.args and len(request.args['search[value]']) > 0:
        filter_params['searching'] = True
        filter_params['search_val'] = request.args['search[value]']
        if 'search[regex]' in request.args:
            filter_params['search_regex'] = json.loads(request.args['search[regex]'])
        else:
            filter_params['search_regex'] = False
    else:
        filter_params['searching'] = False
    if 'order[0][column]' in request.args:
        filter_params['ordering'] = True
        filter_params['order_col'] = int(request.args['order[0][column]']) + 1
        filter_params['order_dir'] = request.args['order[0][dir]']
    else:
        filter_params['ordering'] = False

    return generateCDRS(gwgroupid, report_type, send_email, dtfilter, cdrfilter, nonCompletedCalls, filter_params=filter_params)


# TODO: standardize response payload (use createApiResponse())
@api.route("/api/v1/cdrs/endpoint/<int:gwid>", methods=['GET'])
@api_security
def getGatewayCDRS(gwid=None):
    """
    Purpose

    Getting the cdrs for a gateway thats part of a gateway group

    """
    db = DummySession()

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': None, 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        db = startSession()

        if (settings.DEBUG):
            debugEndpoint()

        query = text(
            "SELECT cdr_id, gwid, call_start_time, calltype AS direction, dst_username AS number,src_ip, dst_domain, duration,sip_call_id "
            "FROM dr_gateways, cdrs "
            "WHERE cdrs.src_ip=dr_gateways.address AND gwid=:gwid "
            "ORDER BY call_start_time DESC"
        )
        cdrs = db.execute(query, {'gwid':gwid})

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

    # in case we error early make sure the variable is set
    backup_path = ''

    try:
        if (settings.DEBUG):
            debugEndpoint()

        backup_path = os.path.join(settings.BACKUP_FOLDER, f'{time.strftime("%s")}-db.sql')

        dumpcmd = ['sudo', 'dsiprouter', 'backup', '-f', backup_path]
        proc = subprocess.run(
            dumpcmd,
            capture_output=True,
            text=True
        )
        proc.check_returncode()

        return send_file(backup_path, as_attachment=True), StatusCodes.HTTP_OK

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

    # in case we error early make sure the variable is set
    restore_path = ''

    try:
        if (settings.DEBUG):
            debugEndpoint()

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

        restorecmd = ['sudo', 'dsiprouter', 'restore', '-f', restore_path]
        proc = subprocess.run(
            restorecmd,
            capture_output=True,
            text=True
        )
        proc.check_returncode()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='The restore was successful',
            kamreload=True,
        )

    except Exception as ex:
        return showApiError(ex)
    finally:
        if os.path.exists(restore_path):
            os.remove(restore_path)


@api.route("/api/v1/sys/generatepassword", methods=['GET'])
@api_security
def generatePassword():
    """
    Generate a random password
    """

    DEF_PASSWORD_LEN = 32

    try:
        return createApiResponse(
            msg='Successfully generated password',
            data=[urandomChars(DEF_PASSWORD_LEN)],
        )
    except Exception as ex:
        return showApiError(ex)


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

    domain_active = False
    cmdset = {"method": "dispatcher.list", "jsonrpc": "2.0", "id": 1}

    r = requests.get('http://127.0.0.1:5060/api/kamailio', json=cmdset)
    if r.status_code >= 400:
        try:
            msg = r.json()['error']['message']
        except:
            msg = r.reason
        ex = http_exceptions.HTTPException(msg)
        ex.code = r.status_code
        raise ex
    else:
        response = r.json()
        records = response['result']['RECORDS']

    if not response:
        return False

    try:
        # Loop thru each record in the dispatcher list
        for record in range(0, len(records)):
            sets = records[record]
            # Loop thru each set
            for set in sets:
                # print("{},{}".format(sets[set]['ID'],domain))
                # Loop thru each target
                targets = sets[set]['TARGETS']
                # Loop thru each destination within a target
                for dest in range(0, len(targets)):
                    # Grab the destination body and flags
                    # The Body contains the domain name of the destionation
                    dest_body = format(targets[dest]['DEST']['ATTRS']['BODY'])
                    # The Flags specify is the destionation is sending and recieving option messages
                    dest_flags = format(targets[dest]['DEST']['FLAGS'])
                    if domain in dest_body:
                        if dest_flags == "AP":
                            domain_active = True
                            continue
    except Exception as ex:
        raise ex

    if not domain_active:
        return False

    return True


@api.route("/api/v1/domains/msteams/test/<string:domain>", methods=['GET'])
@api_security
def testConnectivity(domain):
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

            # Get the IP address of the domain from Google DNS
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

        return createApiResponse(
            msg='Tests ran without error',
            data=[test_data],
        )

    except Exception as ex:
        return showApiError(ex)


# TODO: implement GET for single domain
@api.route("/api/v1/certificates", methods=['GET'])
@api.route("/api/v1/certificates/<string:domain>", methods=['GET'])
@api_security
def getCertificates(domain=None):
    db = DummySession()

    response_data = []

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # if domain is not None:
        #     domain_configs = getCustomTLSConfigs(domain)
        # else:
        # domain_configs = getCustomTLSConfigs()
        if domain == None:
            certificates = db.query(dSIPCertificates).all()
        else:
            certificates = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).all()

        for certificate in certificates:
            # append summary of endpoint group data
            response_data.append({
                'id': certificate.id,
                'domain': certificate.domain,
                'type': certificate.type,
                'assigned_domains': ''
            })

        db.commit()

        return createApiResponse(
            msg='Certificates found' if len(certificates) > 0 else 'No Certificates',
            data=response_data,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@api.route("/api/v1/certificates", methods=['POST', 'PUT'])
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

    # Check parameters and raise exception if missing required parameters
    requiredParameters = ['domain']

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        request_payload = getRequestData()

        for parameter in requiredParameters:
            if parameter not in request_payload:
                raise http_exceptions.BadRequest("Request Argument '{}' is Required".format(parameter))
            elif request_payload[parameter] is None or len(request_payload[parameter]) == 0:
                raise http_exceptions.BadRequest("Value for Request Argument '{}' is Not Valid".format(parameter))

        # Process Request
        domain = request_payload['domain']
        if domain == "default":
            domain = socket.gethostname()
        ip = request_payload['ip'] if 'ip' in request_payload else settings.EXTERNAL_IP_ADDR
        port = request_payload['port'] if 'port' in request_payload else 5061
        server_name_mode = request_payload['server_name_mode'] \
            if 'server_name_mode' in request_payload else kamtls.KAM_TLS_SNI_ALL
        key = request_payload['key'] if 'key' in request_payload else None
        replace_default_cert = request_payload[
            'replace_default_cert'] if 'replace_default_cert' in request_payload else None
        cert = request_payload['cert'] if 'cert' in request_payload else None
        email = request_payload['email'] if 'email' in request_payload else "admin@" + settings.DEFAULT_AUTH_DOMAIN

        # Request Certificate via Let's Encrypt
        if key is None and cert is None:
            type = CERT_TYPE_GENERATED
            try:
                if settings.DEBUG:
                    # Use the LetsEncrypt Staging Server
                    key, cert = letsencrypt.generateCertificate(domain, email, debug=True, default=replace_default_cert)

                else:
                    # Use the LetsEncrypt Prod Server
                    key, cert = letsencrypt.generateCertificate(domain, email, default=replace_default_cert)

            except Exception as ex:
                getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = False
                raise http_exceptions.BadRequest(
                    "Issue with validating ownership of the domain.  Please add a DNS record for this domain and try again")

        # Convert Certificate and key to base64 so that they can be stored in the database
        cert_base64 = base64.b64encode(cert.encode('ascii'))
        key_base64 = base64.b64encode(key.encode('ascii'))

        # Check if the domain exists.  If so, update versus writing new
        certificate = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).first()
        if certificate is not None:
            # Update
            db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain).update(
                {'email': email, 'type': type, 'cert': cert_base64, 'key': key_base64})
            db.commit()
            # Update the Kamailio TLS Configuration
            if not kamtls.updateCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')

        else:
            # Store a new Certificate in dSIPCertificate Table
            certificate = dSIPCertificates(domain, type, email, cert_base64, key_base64)
            db.add(certificate)
            db.commit()
            # Write the Kamailio TLS Configuration
            if not kamtls.addCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg="Certificate creation succeeded",
            data=[{"id": certificate.id}],
            kamreload=True,
        )

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

    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        # if domain is not None:
        #     domain_configs = getCustomTLSConfigs(domain)
        # else:
        # domain_configs = getCustomTLSConfigs()

        Certificates = db.query(dSIPCertificates).filter(dSIPCertificates.domain == domain)
        Certificates.delete(synchronize_session=False)

        # Remove the certificate from the file system
        letsencrypt.deleteCertificate(domain)

        # Remove from Kamailio TLS
        kamtls.deleteCustomTLSConfig(domain)

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg='Certificate Deleted',
            kamreload=True,
        )

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

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        data = getRequestData()

        if 'domain' in data.keys():
            domain = data['domain'][0]
            print(domain)
        else:
            domain = "default"

        if 'replace_default_cert' in data.keys():
            replace_default_cert = data['replace_default_cert'][0]
        else:
            replace_default_cert = None

        ip = settings.EXTERNAL_IP_ADDR
        port = 5061
        server_name_mode = kamtls.KAM_TLS_SNI_ALL

        if replace_default_cert == "true":
            # Replacing the default cert
            cert_domain_dir = settings.DSIP_CERTS_DIR
        else:
            # Adding a another domain cert
            cert_domain_dir = os.path.join(settings.DSIP_CERTS_DIR, domain)

        # Create a directory for the domain
        if not os.path.exists(cert_domain_dir):
            os.makedirs(cert_domain_dir)
            os.chmod(cert_domain_dir, 0o770)

        files = request.files.getlist("certandkey")
        try:
            keycert_pair = KeyCertPair(files)
            keycert_pair.validateKeyCertPair()
            pkey_bytes = keycert_pair.dumpPkey()
            cert_bytes = keycert_pair.dumpCerts()
        except Exception as ex:
            raise http_exceptions.BadRequest(str(ex))

        key_file = os.path.join(cert_domain_dir, 'dsiprouter-key.pem')
        cert_file = os.path.join(cert_domain_dir, 'dsiprouter-cert.pem')

        with open(key_file, 'wb') as newfile:
            newfile.write(pkey_bytes)
        with open(cert_file, 'wb') as newfile:
            newfile.write(cert_bytes)

        # Change owner to dsiprouter:kamailio so that Kamailio can load the configurations
        change_owner(cert_domain_dir, "dsiprouter", "kamailio")
        change_owner(key_file, "dsiprouter", "kamailio")
        change_owner(cert_file, "dsiprouter", "kamailio")

        # Convert Certificate and key to base64 so that they can be stored in the database
        key_base64 = base64.b64encode(pkey_bytes)
        cert_base64 = base64.b64encode(cert_bytes)

        # Store Certificate in dSIPCertificate Table
        certificate = dSIPCertificates(domain, "uploaded", None, cert_base64, key_base64)
        db.add(certificate)

        if not replace_default_cert:
            # Write the Kamailio TLS Configuration if it's not the default
            if not kamtls.addCustomTLSConfig(domain, ip, port, server_name_mode):
                raise Exception('Failed to add Certificate to Kamailio')

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        return createApiResponse(
            msg="Certificate and Key were uploaded",
            data=[{"id": certificate.id}],
            kamreload=True,
        )

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
