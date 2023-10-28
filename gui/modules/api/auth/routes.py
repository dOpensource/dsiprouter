# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import datetime, uuid
from flask import Blueprint, render_template, abort, jsonify
from util.security import api_security, AES_CTR
from shared import debugEndpoint, StatusCodes, getRequestData
from database import DummySession, startSession, dSIPUser
from modules.api.api_functions import showApiError, createApiResponse
from modules.api.auth.functions import addDSIPUser
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
import settings

user = Blueprint('user', __name__)


# TODO: standardize response payloads using new createApiResponse()
#       marked for implementation in v0.74


@user.route('/api/v1/auth/login', methods=['POST'])
# @api_security
def login():
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"username": str, "password": str}

    # ensure requred args are provided
    REQUIRED_ARGS = {'username', 'password'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        # get request data
        request_data = getRequestData()

        db = startSession()

        # Check for existing user
        existing_user = db.query(dSIPUser).filter(dSIPUser.username == (request_data['username'])).first()

        if existing_user:
            print("Saved Password: ", existing_user.password)
            print("Decrypted: ", AES_CTR.decrypt(existing_user.password))
            print("Provided: ", request_data['password'])

            if str(request_data['password']) == AES_CTR.decrypt(existing_user.password):
                if (not existing_user.token) or (datetime.datetime.now() > existing_user.token_expiration):
                    existing_user.token = uuid.uuid4()
                    existing_user.token_expiration = datetime.datetime.now() + datetime.timedelta(days=1)
                    db.commit()

                response_payload = {
                    'message': 'Login successful',
                    'token': existing_user.token,
                    'expiration_date': existing_user.token_expiration
                }

                return jsonify(response_payload), StatusCodes.HTTP_OK
            else:
                response_payload = {
                    "message": 'Invalid credentials',
                    'payload': request_data
                }

                return jsonify(response_payload), StatusCodes.HTTP_UNAUTHORIZED
        else:
            # If user does not exist  return an invalid credentials message
            response_payload['data'] = {
                "message": 'Invalid credentials',
                'payload': request_data
            }

            return jsonify(response_payload), StatusCodes.HTTP_UNAUTHORIZED

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@user.route('/api/v1/auth/user', methods=['POST'])
@api_security
def createUser():
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"firstname": str, "lastname": str, "username": str, "password": str, "roles": dict,
                               "domains": dict}

    # ensure requred args are provided
    REQUIRED_ARGS = {'firstname', 'lastname', 'username', 'password', 'roles', 'domains'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        # get request data
        request_data = getRequestData()

        db = startSession()

        # Check for existing user
        existing_user = db.query(dSIPUser).filter(dSIPUser.username.like(request_data['username'])).all()
        if (existing_user):
            response_payload = {'error': 'User Already Exists', 'data': request_data}
            return jsonify(response_payload), StatusCodes.HTTP_CONFLICT

        # If user does not exist proceed to creat the new user
        new_user = addDSIPUser(request_data)

        # sanity checks
        response_payload['data'] = {
            "message": 'User Created Successfully',
            'payload': request_data
        }

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@user.route('/api/v1/auth/user', methods=['GET'])
def listUsers():
    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        # Check for existing user
        user_list = db.query(dSIPUser).all()
        response_payload = []

        for the_user in user_list:
            response_payload.append(
                {
                    "id": the_user.id,
                    "username": the_user.username,
                    "firstname": the_user.firstname,
                    "lastname": the_user.lastname,
                    "roles": [],
                    "domains": []
                }
            )

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@user.route('/api/v1/auth/user/<int:id>', methods=['GET'])
# @api_security
def getUser(id=None):
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    # VALID_REQUEST_DATA_ARGS = {"firstname": str, "lastname": str, "username": str, "password": str, "roles": dict, "domains": dict}

    # ensure requred args are provided
    # REQUIRED_ARGS = {'firstname', 'lastname', 'username', 'password', 'roles', 'domains'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if id is None:
            response_payload = {'error': 'Invalid Request',
                                'msg': 'Invalid Request. You seem to be missing the ID parameter.'}
            return jsonify(response_payload), StatusCodes.HTTP_BAD_REQUEST

        db = startSession()

        # Check for existing user
        existing_user = db.query(dSIPUser).get(id)
        if (existing_user):
            response_payload = {
                "username": existing_user.username,
                "firstname": existing_user.firstname,
                "lastname": existing_user.lastname,
                "roles": [],
                "domains": []
            }
            return jsonify(response_payload), StatusCodes.HTTP_OK

        else:
            response_payload = {'error': 'User Not Found', 'msg': 'User Not Found'}
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@user.route('/api/v1/auth/user/<int:id>', methods=['PUT'])
# @api_security
def updateUser(id=None):
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"firstname": str, "lastname": str, "username": str, "password": str, "roles": dict,
                               "domains": dict}

    # ensure requred args are provided
    REQUIRED_ARGS = {'firstname', 'lastname', 'username', 'password', 'roles', 'domains'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if id is None:
            response_payload = {'error': 'Invalid Request',
                                'msg': 'Invalid Request. You seem to be missing the ID parameter.'}
            return jsonify(response_payload), StatusCodes.HTTP_BAD_REQUEST

        # get request data
        request_data = getRequestData()

        db = startSession()

        # Check for existing user
        existing_user = db.query(dSIPUser).get(id)
        if existing_user:

            existing_user.firstname = request_data['firstname']
            existing_user.lastname = request_data['lastname']
            existing_user.username = request_data['username']
            existing_user.password = AES_CTR.encrypt(request_data['password'])
            existing_user.roles = ''
            existing_user.domains = ''
            db.commit()

            response_payload = {"message": 'User updated successfully', 'data': {
                "username": existing_user.username,
                "firstname": existing_user.firstname,
                "lastname": existing_user.lastname,
                "roles": [],
                "domains": []
            }}

            return jsonify(response_payload), StatusCodes.HTTP_OK

        else:
            response_payload = {'error': 'User Not Found', 'msg': 'User Not Found'}
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@user.route('/api/v1/auth/user/<int:id>', methods=['DELETE'])
# @api_security
def deleteUser(id=None):
    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if id is None:
            response_payload = {'error': 'Invalid Request',
                                'msg': 'Invalid Request. You seem to be missing the ID parameter.'}
            return jsonify(response_payload), StatusCodes.HTTP_BAD_REQUEST

        db = startSession()

        # Check for existing user
        existing_user = db.query(dSIPUser).get(id)
        if existing_user:
            db.delete(existing_user)
            db.commit()
            response_payload = {"message": 'User deleted successfully'}
            return jsonify(response_payload), StatusCodes.HTTP_OK

        else:
            response_payload = {'error': 'User Not Found', 'msg': 'User Not Found'}
            return jsonify(response_payload), StatusCodes.HTTP_NOT_FOUND

    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()
