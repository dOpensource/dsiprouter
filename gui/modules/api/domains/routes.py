# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, request, session
from werkzeug import exceptions as http_exceptions
from database import startSession, DummySession, Domain
from shared import debugEndpoint, getRequestData, StatusCodes, IO
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from modules.api.api_functions import api_security, createApiResponse, showApiError
from modules.api.licensemanager.classes import WoocommerceError
from modules.api.licensemanager.functions import getLicenseStatus
from modules.api.domains.functions import (
    DOMAIN_TYPES,
    validateDomainBody,
    serializeDomain,
    listDomains,
    createDomains,
    updateDomain,
    deleteDomain,
    getDomainAttrs,
)
import settings

domains_api = Blueprint('domains_api', __name__)

# '_' is the cache buster jQuery / DataTables adds to ajax GET requests
VALID_REQUEST_ARGS = {'type', '_'}
# roles allowed to change domains when the API is called with a GUI session
WRITE_ROLES = {'dsip_admin', 'dsip_engineer'}


def requireWriteRole():
    """Session callers need a write role, token callers keep full access like the rest of the API."""
    if session.get('logged_in'):
        user_groups = set(session.get('user_groups', []) or [])
        if not user_groups.intersection(WRITE_ROLES):
            raise http_exceptions.Forbidden('You do not have permission to change domains')


def requireMSTeamsLicense(data):
    if data.get('type') != 'msteams':
        return
    try:
        license_status = getLicenseStatus(license_tag='DSIP_MSTEAMS')
    except WoocommerceError:
        license_status = 0
    if license_status != 3:
        raise http_exceptions.Forbidden('A valid DSIP_MSTEAMS license is required for MSTeams domains')


# PUT and DELETE are listed on the no-path-arg route too so a missing id returns our 400 instead of a 405
@domains_api.route('/api/v1/domains', methods=['GET', 'POST', 'PUT', 'DELETE'])
@domains_api.route('/api/v1/domains/<int:domain_id>', methods=['GET', 'PUT', 'DELETE'])
@api_security
def handleDomains(domain_id=None):
    """
    Endpoint for Domains (domain + domain_attrs + dispatcher)

    Domain types:

    - passthru: registrations are passed through to a single PBX (exactly one endpoint id in pbxs)
    - msteams: Microsoft Teams Direct Routing (requires a DSIP_MSTEAMS license, pbxs is ignored)
    - local: users authenticate against the local subscriber table, calls go to the pbxs dispatcher set
    - realtime: users authenticate against an Asterisk Realtime DB, calls go to the pbxs dispatcher set

    Domains created by an endpoint group (FusionPBX sync) are returned with ``editable: false`` and
    can not be changed or deleted through this endpoint.

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            "domain":         "<string or list, required on POST - one name on PUT>",
            "type":           "<passthru|msteams|local|realtime, required on POST>",
            "pbxs":           "<list of endpoint ids (dr_gateways gwid)>",
            "notes":          "<string, optional>",
            "dispatcher_alg": "<int, optional - kamailio dispatcher algorithm, default 4 (round robin)>"
        }

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            "error":      "<string>",
            "msg":        "<string>",
            "kamreload":  "<bool>",
            "dsipreload": "<bool>",
            "data": [
                {
                    "id":                "<int>",
                    "domain":            "<string>",
                    "type":              "<passthru|msteams|local|realtime>",
                    "pbx_type":          "<string>",
                    "pbxs":              "<list of endpoint ids>",
                    "notes":             "<string>",
                    "dispatcher_set_id": "<int or null>",
                    "dispatcher_alg":    "<int or null>",
                    "managed_by":        "<null or {gwgroupid, name}>",
                    "editable":          "<bool>"
                }
            ]
        }
    """
    db = DummySession()
    payload = {'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()
        db = startSession()

        # ---------- GET ----------
        if request.method == 'GET':
            for arg in request.args:
                if arg not in VALID_REQUEST_ARGS:
                    raise http_exceptions.BadRequest('Request argument not recognized')

            if domain_id is not None:
                domain = db.query(Domain).filter(Domain.id == domain_id).first()
                if domain is None:
                    payload['msg'] = 'No Matching Domain Found'
                    payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
                    return createApiResponse(**payload)
                payload['data'].append(serializeDomain(db, domain))
                payload['msg'] = 'Domain Found'
                return createApiResponse(**payload)

            domain_type = request.args.get('type')
            if domain_type is not None and domain_type not in DOMAIN_TYPES:
                raise http_exceptions.BadRequest('type must be one of: {}'.format(', '.join(DOMAIN_TYPES)))
            payload['data'] = listDomains(db, domain_type)
            payload['msg'] = 'Domains Found' if payload['data'] else 'No Domains Found'
            return createApiResponse(**payload)

        requireWriteRole()

        # ---------- POST ----------
        if request.method == 'POST':
            data = validateDomainBody(getRequestData(), require_all=True)
            requireMSTeamsLicense(data)
            payload['data'] = createDomains(db, data)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Domain(s) {} created via API'.format(','.join(d['domain'] for d in payload['data'])))
            payload['msg'] = 'Domain Created' if len(payload['data']) == 1 else 'Domains Created'
            payload['kamreload'] = True
            return createApiResponse(**payload)

        if domain_id is None:
            raise http_exceptions.BadRequest('domain id is required')

        # ---------- PUT ----------
        if request.method == 'PUT':
            data = validateDomainBody(getRequestData(), require_all=False)
            requireMSTeamsLicense(data)
            if not updateDomain(db, domain_id, data):
                payload['msg'] = 'No Matching Domain Found'
                payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
                return createApiResponse(**payload)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Domain {} updated via API'.format(domain_id))
            domain = db.query(Domain).filter(Domain.id == domain_id).first()
            payload['data'].append(serializeDomain(db, domain, getDomainAttrs(db, domain.did)))
            payload['msg'] = 'Domain Updated'
            payload['kamreload'] = True
            return createApiResponse(**payload)

        # ---------- DELETE ----------
        if request.method == 'DELETE':
            if not deleteDomain(db, domain_id):
                payload['msg'] = 'No Matching Domain Found'
                payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
                return createApiResponse(**payload)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Domain {} deleted via API'.format(domain_id))
            payload['msg'] = 'Domain Deleted'
            payload['kamreload'] = True
            return createApiResponse(**payload)

        payload['msg'] = 'Invalid HTTP method for this route'
        return createApiResponse(**payload, status_code=StatusCodes.HTTP_METHOD_NOT_ALLOWED)

    except Exception as ex:
        db.rollback()
        db.flush()
        IO.logerr('/api/v1/domains failed: {}'.format(ex))
        return showApiError(ex)
    finally:
        db.close()
