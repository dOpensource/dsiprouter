from shared import debugException, debugEndpoint, stripDictVals, showError
from database import startSession, DummySession, dSIPUser
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from flask import request
import settings
import datetime
from util.security import AES_CTR


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
        roles = ''
        domains = ''
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
