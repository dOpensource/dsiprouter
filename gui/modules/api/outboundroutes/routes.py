# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, request
from werkzeug import exceptions as http_exceptions
from database import startSession, DummySession, OutboundRoutes
from shared import debugEndpoint, getRequestData, StatusCodes, IO
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from modules.api.api_functions import api_security, createApiResponse, showApiError
from modules.api.outboundroutes.functions import (
    validateOutboundRouteBody,
    serializeOutboundRoute,
    createOutboundRoute,
    updateOutboundRoute,
    deleteOutboundRoute,
)
import settings

# NOTE: use the __name__ identifier, NOT the string '__name__'.
# The api / user / license_manager blueprints all use __name__;
# carriergroups has a typo ('__name__') - do NOT replicate.
outboundroutes = Blueprint('outboundroutes', __name__)

VALID_REQUEST_ARGS = {'ruleid'}


# IMPORTANT: PUT and DELETE are listed on the no-path-arg route too, otherwise
# Flask returns 405 Method Not Allowed BEFORE our handler runs and our
# "ruleid is required" 400 path is unreachable. Mirrors handleInboundMapping
# which declares all 4 methods on a single URL (gui/modules/api/api_routes.py:463).
@outboundroutes.route('/api/v1/outboundroutes',              methods=['GET', 'POST', 'PUT', 'DELETE'])
@outboundroutes.route('/api/v1/outboundroutes/<int:ruleid>', methods=['GET', 'PUT', 'DELETE'])
@api_security
def handleOutboundRoutes(ruleid=None):
    """
    Endpoint for Outbound Route Rules (dr_rules + optional dsip_lcr coupling)

    ===============
    Request Payload
    ===============

    .. code-block:: json

        {
            "name":        "<string, optional>",
            "from_prefix": "<string, optional - presence promotes to LCR>",
            "prefix":      "<string, optional - To prefix (required if from_prefix set)>",
            "timerec":     "<string, optional - Kamailio time-recurrence pattern>",
            "priority":    "<int, optional - default 0>",
            "routeid":     "<string, optional - custom Kamailio route name>",
            "gwgroupid":   "<string, required on POST - carrier group id (cannot be '0')>"
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
                    "ruleid":      "<int>",
                    "groupid":     "<string - 8000 for simple, 10000..19999 for LCR>",
                    "name":        "<string>",
                    "from_prefix": "<string or null>",
                    "prefix":      "<string>",
                    "timerec":     "<string>",
                    "priority":    "<int>",
                    "routeid":     "<string>",
                    "gwgroupid":   "<string - carrier group id, with leading '#' stripped>"
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
            rid = ruleid if ruleid is not None else request.args.get('ruleid')
            if rid is not None and not isinstance(rid, int):
                try:
                    rid = int(rid)
                except (TypeError, ValueError):
                    raise http_exceptions.BadRequest('ruleid must be an integer')

            q = db.query(OutboundRoutes).filter(
                (OutboundRoutes.groupid == settings.FLT_OUTBOUND) |
                ((OutboundRoutes.groupid >= settings.FLT_LCR_MIN) &
                 (OutboundRoutes.groupid <  settings.FLT_FWD_MIN)))
            rows = q.filter(OutboundRoutes.ruleid == rid).all() if rid is not None else q.all()

            for row in rows:
                payload['data'].append(serializeOutboundRoute(db, row))
            if rid is not None:
                payload['msg'] = 'Rule Found' if rows else 'No Matching Rule Found'
                if not rows:
                    payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
            else:
                payload['msg'] = 'Rules Found' if rows else 'No Rules Found'
            return createApiResponse(**payload)

        # ---------- POST ----------
        elif request.method == 'POST':
            data = validateOutboundRouteBody(getRequestData(), require_gwgroupid=True)
            new_ruleid = createOutboundRoute(db, data)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Outbound route {} created via API'.format(new_ruleid))
            payload['data'].append({'ruleid': new_ruleid})
            payload['msg'] = 'Rule Created'
            return createApiResponse(**payload)

        # ---------- PUT ----------
        elif request.method == 'PUT':
            if ruleid is None:
                ruleid_q = request.args.get('ruleid')
                if ruleid_q is None:
                    raise http_exceptions.BadRequest('ruleid is required')
                try:
                    ruleid = int(ruleid_q)
                except (TypeError, ValueError):
                    raise http_exceptions.BadRequest('ruleid must be an integer')
            data = validateOutboundRouteBody(getRequestData(), require_gwgroupid=False)
            if not updateOutboundRoute(db, ruleid, data):
                payload['msg'] = 'No Matching Rule Found'
                payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
                return createApiResponse(**payload)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Outbound route {} updated via API'.format(ruleid))
            payload['msg'] = 'Rule Updated'
            return createApiResponse(**payload)

        # ---------- DELETE ----------
        elif request.method == 'DELETE':
            if ruleid is None:
                ruleid_q = request.args.get('ruleid')
                if ruleid_q is None:
                    raise http_exceptions.BadRequest('ruleid is required')
                try:
                    ruleid = int(ruleid_q)
                except (TypeError, ValueError):
                    raise http_exceptions.BadRequest('ruleid must be an integer')
            if not deleteOutboundRoute(db, ruleid):
                payload['msg'] = 'No Matching Rule Found'
                payload['status_code'] = StatusCodes.HTTP_NOT_FOUND
                return createApiResponse(**payload)
            db.commit()
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            IO.loginfo('Outbound route {} deleted via API'.format(ruleid))
            payload['msg'] = 'Rule Deleted'
            return createApiResponse(**payload)

        else:
            payload['msg'] = 'Invalid HTTP method for this route'
            return createApiResponse(**payload,
                                     status_code=StatusCodes.HTTP_METHOD_NOT_ALLOWED)

    except Exception as ex:
        db.rollback()
        db.flush()
        IO.logerr('/api/v1/outboundroutes failed: {}'.format(ex))
        return showApiError(ex)
    finally:
        db.close()
