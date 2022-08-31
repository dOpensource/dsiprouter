from shared import updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields, allowed_file, showError, IO, objToDict, StatusCodes 
from util.networking import getInternalIP, getExternalIP, hostToIP, safeUriToHost, safeFormatSipUri, safeStripPort
from database import db_engine, SessionLoader, DummySession, Gateways, Address, InboundMapping, OutboundRoutes, \
    Subscribers, \
    dSIPLCR, UAC, GatewayGroups, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, \
    dSIPMaintModes, \
    dSIPCallLimits, dSIPHardFwd, dSIPFailFwd, dSIPUser
from sqlalchemy import func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
import settings, globals
import datetime
from util.security import AES_CTR, urandomChars, EasyCrypto, api_security


def addDSIPUser(data=None):
    """
    Add or Update a group of carriers
    """

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

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
