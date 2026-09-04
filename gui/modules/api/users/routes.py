import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, request
from database import DummySession, startSession, dSIPUserNew
from shared import debugEndpoint, StatusCodes, getRequestData
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from util.security import role_required
from modules.api.api_functions import showApiError, createApiResponse, api_security
from modules.api.users.functions import (
    addUser, updateUser, deleteUser, regenerateToken, getUserGroups
)
import settings

users = Blueprint('users', __name__)


@users.route('/api/v1/users', methods=['GET'])
@api_security
@role_required('dsip_admin')
def listUsers():
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()
    try:
        if settings.DEBUG:
            debugEndpoint()

        db = startSession()

        query = db.query(dSIPUserNew)

        # Filter by username
        username_filter = request.args.get('username')
        if username_filter:
            query = query.filter(dSIPUserNew.username == username_filter)

        user_list = query.all()
        result = []

        for u in user_list:
            groups = getUserGroups(db, u.username)
            # Filter by group if specified
            group_filter = request.args.get('group')
            if group_filter and group_filter not in groups:
                continue

            result.append({
                'username': u.username,
                'groups': groups,
                'auth_type': u.auth_type,
            })

        return createApiResponse(data=result, status_code=StatusCodes.HTTP_OK)

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@users.route('/api/v1/users', methods=['POST'])
@api_security
@role_required('dsip_admin')
def createUser():
    REQUIRED_ARGS = {'username', 'group'}
    VALID_GROUPS = {'dsip_admin', 'dsip_engineer', 'dsip_guest'}

    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        request_data = getRequestData()

        # Validate required args
        missing = REQUIRED_ARGS - set(request_data.keys())
        if missing:
            return createApiResponse(
                error='http',
                msg=f'Missing required arguments: {", ".join(missing)}',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        auth_type = request_data.get('auth_type', 'local')
        if auth_type not in ('local', 'ldap'):
            return createApiResponse(
                error='http',
                msg='Invalid auth_type. Must be "local" or "ldap"',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        # Password is only required for local auth
        if auth_type == 'local' and not request_data.get('password'):
            return createApiResponse(
                error='http',
                msg='Password is required for local auth type',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        # Validate group
        if request_data['group'] not in VALID_GROUPS:
            return createApiResponse(
                error='http',
                msg=f'Invalid group. Must be one of: {", ".join(VALID_GROUPS)}',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        new_user = addUser(request_data)

        return createApiResponse(
            data={
                'username': new_user['username'],
                'groups': new_user['groups'],
                'auth_type': new_user['auth_type'],
                'api_token': new_user['api_token'],
            },
            msg='User created successfully',
            status_code=StatusCodes.HTTP_OK
        )

    except ValueError as ex:
        return createApiResponse(
            error='http',
            msg=str(ex),
            status_code=StatusCodes.HTTP_CONFLICT
        )
    except Exception as ex:
        return showApiError(ex)


@users.route('/api/v1/users', methods=['PUT'])
@api_security
@role_required('dsip_admin')
def updateUserRoute():
    VALID_GROUPS = {'dsip_admin', 'dsip_engineer', 'dsip_guest'}

    try:
        if settings.DEBUG:
            debugEndpoint()

        request_data = getRequestData()
        username = request.args.get('username')

        if not username:
            return createApiResponse(
                error='http',
                msg='username query parameter is required',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        if 'group' in request_data and request_data['group'] not in VALID_GROUPS:
            return createApiResponse(
                error='http',
                msg=f'Invalid group. Must be one of: {", ".join(VALID_GROUPS)}',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        user = updateUser(username, request_data)

        return createApiResponse(
            data={
                'username': user['username'],
                'groups': user['groups'],
                'auth_type': user['auth_type'],
            },
            msg='User updated successfully',
            status_code=StatusCodes.HTTP_OK
        )

    except ValueError as ex:
        return createApiResponse(
            error='http',
            msg=str(ex),
            status_code=StatusCodes.HTTP_NOT_FOUND
        )
    except Exception as ex:
        return showApiError(ex)


@users.route('/api/v1/users', methods=['DELETE'])
@api_security
@role_required('dsip_admin')
def deleteUserRoute():
    try:
        if settings.DEBUG:
            debugEndpoint()

        username = request.args.get('username')

        if not username:
            return createApiResponse(
                error='http',
                msg='username query parameter is required',
                status_code=StatusCodes.HTTP_BAD_REQUEST
            )

        deleteUser(username)

        return createApiResponse(
            msg='User deleted successfully',
            status_code=StatusCodes.HTTP_OK
        )

    except ValueError as ex:
        return createApiResponse(
            error='http',
            msg=str(ex),
            status_code=StatusCodes.HTTP_NOT_FOUND
        )
    except Exception as ex:
        return showApiError(ex)


@users.route('/api/v1/users/<string:username>/token', methods=['GET'])
@api_security
@role_required('dsip_admin')
def getUserToken(username):
    try:
        if settings.DEBUG:
            debugEndpoint()

        db = DummySession()
        try:
            db = startSession()
            user = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
            if not user:
                return createApiResponse(
                    error='http',
                    msg='User not found',
                    status_code=StatusCodes.HTTP_NOT_FOUND
                )
            return createApiResponse(
                data={
                    'username': user.username,
                    'api_token': user.api_token,
                },
                status_code=StatusCodes.HTTP_OK
            )
        finally:
            db.close()

    except Exception as ex:
        return showApiError(ex)


@users.route('/api/v1/users/<string:username>/token', methods=['POST'])
@api_security
@role_required('dsip_admin')
def regenerateUserToken(username):
    try:
        if settings.DEBUG:
            debugEndpoint()

        new_token = regenerateToken(username)

        return createApiResponse(
            data={
                'username': username,
                'api_token': new_token,
            },
            msg='Token regenerated successfully',
            status_code=StatusCodes.HTTP_OK
        )

    except ValueError as ex:
        return createApiResponse(
            error='http',
            msg=str(ex),
            status_code=StatusCodes.HTTP_NOT_FOUND
        )
    except Exception as ex:
        return showApiError(ex)
