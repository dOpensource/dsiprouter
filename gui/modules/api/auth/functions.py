from shared import debugException, debugEndpoint, stripDictVals, showError
from database import startSession, DummySession, dSIPUser
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from flask import request
import settings
import datetime
from util.security import AES_CTR


def formatRoleString(roles):
    """
    Normalize a roles/domains request value (list, tuple, set, dict or str)
    into a comma-separated string for storage in the dsip_user table.

    :param roles:      raw roles/domains value from request data
    :type roles:       object
    :return:           comma-separated role string
    :rtype:            str
    """
    if roles is None:
        return ''
    if isinstance(roles, str):
        return roles.strip()
    if isinstance(roles, (list, tuple, set)):
        return ','.join(str(r) for r in roles if r)
    if isinstance(roles, dict):
        names = []
        for key, val in roles.items():
            if isinstance(val, (list, tuple, set)):
                names.extend(str(r) for r in val if r)
            elif isinstance(val, dict):
                names.append(str(val.get('name') or val.get('role') or key))
            else:
                names.append(str(val or key))
        return ','.join(names)
    return str(roles)


def getUserRoles(username):
    """
    Look up a user's roles from the dsip_user table.

    :param username:    username to look up
    :type username:     str
    :return:            list of role names, or empty list if user not found
    :rtype:             list
    """
    db = DummySession()

    try:
        db = startSession()
        user = db.query(dSIPUser).filter(dSIPUser.username == username).first()
        if user is None or not user.roles:
            return []
        return [r for r in str(user.roles).split(',') if r]
    finally:
        db.close()


def addDSIPUser(data=None):
    """
    Add or Update a group of carriers
    """

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        if data is not None:
            # Set the form variables to data parameter
            form = data
        else:
            form = stripDictVals(request.form.to_dict())

        username = form['username']
        password = AES_CTR.encrypt(form['password'])
        firstname = form['firstname']
        lastname = form['lastname']
        roles = formatRoleString(form.get('roles'))
        domains = formatRoleString(form.get('domains'))
        token = ''
        token_expiration = datetime.datetime.now()

        new_user = dSIPUser(firstname, lastname, username, password, roles, domains, token, token_expiration)
        db.add(new_user)
        db.flush()
        db.commit()

        return new_user

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()
