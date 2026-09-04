import uuid
from database import startSession, DummySession, dSIPUserNew, dSIPGroup, dSIPUserGroup
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from shared import debugException, debugEndpoint
from util.security import Credentials, AES_CTR
import settings


def getUserGroups(db, username):
    """
    Get group names for a user.

    :param db:          database session
    :param username:    the username
    :return:            list of group names
    """
    groups = db.query(dSIPGroup.name).join(
        dSIPUserGroup, dSIPGroup.id == dSIPUserGroup.group_id
    ).filter(dSIPUserGroup.username == username).all()
    return [g[0] for g in groups]


def setUserGroups(db, username, group_names):
    """
    Set groups for a user (replaces existing).

    :param db:          database session
    :param username:    the username
    :param group_names: list of group names
    """
    # Remove existing group assignments
    db.query(dSIPUserGroup).filter(dSIPUserGroup.username == username).delete()

    # Add new group assignments
    for group_name in group_names:
        group = db.query(dSIPGroup).filter(dSIPGroup.name == group_name).first()
        if group is not None:
            user_group = dSIPUserGroup(username, group.id)
            db.add(user_group)


def generateApiToken():
    """Generate a new API token (UUID4)."""
    return str(uuid.uuid4())


def getOrCreateAdminToken(db):
    """
    Ensure a dsip_users entry exists for the settings-based admin user
    (DSIP_USERNAME / DSIP_PASSWORD from dsip_settings) and return its api_token.

    Used so both GUI login and the login API can hand the admin a working
    per-user API token on fresh installs (the upgrade migration covers
    existing installs via SQL).

    :param db:          active database session
    :return:            the admin's api_token
    :rtype:             str
    """
    username = settings.DSIP_USERNAME

    user = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
    if user is None:
        hashed_password = None
        if isinstance(settings.DSIP_PASSWORD, bytes):
            hashed_password = settings.DSIP_PASSWORD
        elif isinstance(settings.DSIP_PASSWORD, str):
            hashed_password = Credentials.hashCreds(settings.DSIP_PASSWORD)
        token = generateApiToken()
        user = dSIPUserNew(username, hashed_password, token, 'local')
        db.add(user)
        db.flush()
        setUserGroups(db, username, ['dsip_admin'])
    elif not user.api_token:
        user.api_token = generateApiToken()

    groups = getUserGroups(db, username)
    if 'dsip_admin' not in groups:
        setUserGroups(db, username, groups + ['dsip_admin'])

    db.commit()
    return user.api_token


def addUser(data):
    """
    Create a new user in dsip_users.

    :param data:    dict with keys: username, password, group (single string)
    :return:        dict with user data (avoids detached ORM object after commit)
    :rtype:         dict
    """
    db = DummySession()
    try:
        db = startSession()

        username = data['username']
        password = data.get('password')
        group_name = data.get('group', 'dsip_guest')
        auth_type = data.get('auth_type', 'local')

        # Check if user already exists
        existing = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
        if existing:
            raise ValueError('User already exists')

        # Hash password if local auth
        hashed_password = None
        if auth_type == 'local' and password:
            hashed_password = Credentials.hashCreds(password)
        elif auth_type == 'ldap':
            hashed_password = None

        token = generateApiToken()

        new_user = dSIPUserNew(username, hashed_password, token, auth_type)
        db.add(new_user)
        db.flush()

        # Set groups
        setUserGroups(db, username, [group_name])
        db.commit()

        return {
            'username': username,
            'groups': [group_name],
            'auth_type': auth_type,
            'api_token': token,
        }
    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        db.rollback()
        raise
    except Exception as ex:
        debugException(ex)
        db.rollback()
        raise
    finally:
        db.close()


def updateUser(username, data):
    """
    Update an existing user.

    :param username:    current username
    :param data:        dict with optional keys: password, group, auth_type
    :return:            dict with updated user data (avoids detached ORM object after commit)
    :rtype:             dict
    """
    db = DummySession()
    try:
        db = startSession()

        user = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
        if not user:
            raise ValueError('User not found')

        if 'password' in data and data['password']:
            if user.auth_type == 'local':
                user.password = Credentials.hashCreds(data['password'])

        if 'auth_type' in data:
            user.auth_type = data['auth_type']
            if data['auth_type'] == 'ldap':
                user.password = None

        if 'group' in data:
            setUserGroups(db, username, [data['group']])

        db.commit()
        groups = getUserGroups(db, username)
        return {
            'username': username,
            'groups': groups,
            'auth_type': user.auth_type,
        }
    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        db.rollback()
        raise
    except Exception as ex:
        debugException(ex)
        db.rollback()
        raise
    finally:
        db.close()


def deleteUser(username):
    """
    Delete a user.

    :param username:    the username to delete
    :return:            True if deleted
    """
    db = DummySession()
    try:
        db = startSession()

        user = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
        if not user:
            raise ValueError('User not found')

        db.delete(user)
        db.commit()
        return True
    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        db.rollback()
        raise
    except Exception as ex:
        debugException(ex)
        db.rollback()
        raise
    finally:
        db.close()


def regenerateToken(username):
    """
    Regenerate a user's API token.

    :param username:    the username
    :return:            new token string
    """
    db = DummySession()
    try:
        db = startSession()

        user = db.query(dSIPUserNew).filter(dSIPUserNew.username == username).first()
        if not user:
            raise ValueError('User not found')

        new_token = generateApiToken()
        user.api_token = new_token
        db.commit()
        return new_token
    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        db.rollback()
        raise
    except Exception as ex:
        debugException(ex)
        db.rollback()
        raise
    finally:
        db.close()
