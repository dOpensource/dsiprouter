# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import re
from functools import wraps
from flask import jsonify, render_template, request, session
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from shared import debugException, StatusCodes
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from util.security import APIToken
from modules.api.licensemanager.functions import getLicenseStatus
import settings


def createApiResponse(error=None, msg=None, kamreload=None, dsipreload=None, data=None,
                     status_code=StatusCodes.HTTP_OK, **kwargs):
    """
    Standardize a response from the API

    :param error:       Type of error if one occurred (db|http|server|other)
    :type error:        str
    :param msg:         response message string
    :type msg:          str
    :param kamreload:   if kamailio requires a reload for latest changes to be live
    :type kamreload:    bool
    :param dsipreload:  if the entire dsiprouter platform requires a reload
    :type dsipreload:   bool
    :param data:        requested data to be returned, if any
    :type data:         list
    :param status_code: HTTP status code
    :type status_code:  int
    :param kwargs:      eats any extra parameters
    :type kwargs:       None
    :return:            a response flask can serve to the user
    :rtype:             (:class:`~flask.Response`, int)
    """

    if error is None:
        error = ''
    if msg is None:
        msg = ''
    if kamreload is None:
        kamreload = getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required']
    if dsipreload is None:
        dsipreload = getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_required']
    if data is None:
        data = []
    return jsonify({
        'error': error,
        'msg': msg,
        'kamreload': kamreload,
        'dsipreload': dsipreload,
        'data': data,
    }), status_code

def showApiError(ex, payload=None):
    debugException(ex)

    if payload is None:
        payload = {}

    if isinstance(ex, sql_exceptions.SQLAlchemyError):
        payload['error'] = "db"
        if len(str(ex)) > 0:
            payload['msg'] = str(ex)
        else:
            payload['msg'] = "Unknown DB Error Occurred"
        status_code = StatusCodes.HTTP_INTERNAL_SERVER_ERROR
    elif isinstance(ex, http_exceptions.HTTPException):
        payload['error'] = "http"
        if len(ex.description) > 0:
            payload['msg'] = ex.description
        else:
            payload['msg'] = "Unknown HTTP Error Occurred"
        status_code = ex.code or StatusCodes.HTTP_INTERNAL_SERVER_ERROR
    else:
        payload['error'] = "server"
        if len(str(ex)) > 0:
            payload['msg'] = str(ex)
        else:
            payload['msg'] = "Unknown Error Occurred"
        status_code = StatusCodes.HTTP_INTERNAL_SERVER_ERROR

    return createApiResponse(**payload, status_code=status_code)

def api_security(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        apiToken = APIToken(request)
        accept_header = request.headers.get('Accept', '')

        # If user is logged into a session return right away
        if session.get('logged_in'):
            return func(*args, **kwargs)
        else:
            if 'text/html' in accept_header:
                return render_template('index.html', version=settings.VERSION), StatusCodes.HTTP_UNAUTHORIZED

        # If API Request check for license
        if not re.match('text/html|text/css', accept_header, flags=re.IGNORECASE):
            flask_rule = request.url_rule.rule if request.url_rule is not None else ''
            # Check if they have a Core Subscription
            if flask_rule[:17] != '/api/v1/licensing' and getLicenseStatus(license_tag='DSIP_CORE') != 3:
                return createApiResponse(
                    error='http',
                    msg='Unauthorized - Core Subscription Required. Purchase from https://dopensource.com/product/dsiprouter-core/',
                    status_code=StatusCodes.HTTP_UNAUTHORIZED
                )
            # Check if token is valid
            if not apiToken.isValid():
                return createApiResponse(
                    error='http',
                    msg='Unauthorized',
                    status_code=StatusCodes.HTTP_UNAUTHORIZED
                )
            # checks succeeded allow the request
            return func(*args, **kwargs)

    return wrapper
