import logging
import os
from flask import Blueprint, render_template, abort, jsonify
from util.security import api_security, AES_CTR
from database import SessionLoader, DummySession, dSIPMultiDomainMapping
from shared import showApiError, debugEndpoint, StatusCodes, getRequestData
from enum import Enum
from werkzeug import exceptions as http_exceptions
import importlib.util
import settings, globals
from database import dSIPUser
from modules.api.auth.functions import *
import uuid
import datetime

user = Blueprint('user', __name__)


@user.route('/api/v1/auth/user', methods=['POST'])
@api_security
def postUser():
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"firstname": str, "lastname": str, "username": str, "password": str, "roles": dict,
                               "domains": dict}

    # ensure requred args are provided
    REQUIRED_ARGS = {'firstname', 'lastname', 'username', 'password', 'roles', 'domains'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        # get request data
        request_data = getRequestData()

        db = SessionLoader()

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


@user.route('/api/v1/auth/login', methods=['POST'])
# @api_security
def login():
    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"username": str, "password": str}

    # ensure requred args are provided
    REQUIRED_ARGS = {'username', 'password'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': globals.reload_required, 'data': []}

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        # get request data
        request_data = getRequestData()

        db = SessionLoader()

        # Check for existing user
        existing_user = db.query(dSIPUser).filter(dSIPUser.username == (request_data['username'])).all()



        if existing_user:
            response_payload = {'error': 'User Already Exists', 'data': request_data}

            print("Saved Password: ", (existing_user['password']))
            print("Decrypted: ", (AES_CTR.decrypt(existing_user['password'])))
            print("Provided: ", (request_data['password']))

            if str(request_data['password']) == AES_CTR.decrypt(existing_user['password']):

                existing_user['token'] = uuid.uuid4()
                existing_user['token_expiration'] = datetime.datetime.now() + datetime.timedelta(days=1)
                db.update(existing_user)
                db.flush()
                db.commit()

                response_payload['data'] = {
                    'message': 'Login successful',
                    'token': existing_user['token'],
                    'expiration_date': existing_user['token_expiration']
                }

                return jsonify(response_payload), StatusCodes.HTTP_OK

            else:
                response_payload['data'] = {
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
