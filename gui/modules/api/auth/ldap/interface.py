import copy
from types import ModuleType
from typing import Union
from shared import debugException, IO
from modules.api.auth.ldap.classes import LdapAuthenticator


# required plugin global
METADATA = {
    'name': 'LDAP Authentication',
    'version': '1.0.0'
}

# plugin specific globals
auth_client: Union[LdapAuthenticator, None] = None
auth_debug: bool = False


# required plugin interface
def initialize(project_settings: ModuleType) -> None:
    """
    Validate the module settings and perform any verification needed

    :raises:    ValueError      -   when settings are invalid
    :raises:    ldap.LDAPError  -   when ldap connection/bind fails
    """

    global auth_client, auth_debug

    IO.loginfo('initializing ldap authentication module')
    auth_debug = project_settings.DEBUG
    if auth_debug:
        IO.printdbg('initializing ldap authentication module')
        IO.printdbg(f'metadata: {METADATA}')

    mod_settings = copy.deepcopy(project_settings.AUTH_MODULES['ldap'])

    # create the client that will be utilized later for auth
    try:
        auth_client = LdapAuthenticator(
            ldap_urls=mod_settings.pop('ldap_urls', None),
            ldap_debug=auth_debug,
            **mod_settings
        )
    except Exception as ex:
        raise ValueError(f'ldap module failed initialization: {str(ex)}')

    # make sure the client will work properly during operation
    try:
        auth_client.validateConnection()
        auth_client.validateBind()
    except Exception as ex:
        raise ValueError(f'ldap module failed initialization: {str(ex)}')

    IO.loginfo('ldap module initialized')
    if auth_debug:
        IO.printdbg(f'ldap module initialized: {dict(auth_client)}')


# required plugin interface
def teardown() -> None:
    """
    Cleanup any artifacts from the module
    """

    global auth_client

    del auth_client

# required plugin interface
def authenticate(username: str, password: str) -> bool:
    """
    Authenticate a user via an external LDAP server

    :param username:        The username to authenticate with
    :param password:        The password to authenticate with
    :return:                Whether authentication was successful or not
    """

    global auth_client, auth_debug

    if auth_client is None:
        IO.logerr('ldap module has not been initialized')
        raise RuntimeError('ldap module has not been initialized')

    try:
        auth_client.bind(username, password)
        if auth_client._required_group is not None:
            attrs = auth_client.queryUser(
                username,
                ['memberOf']
            )
            groups = attrs['memberOf']
            if auth_client._required_group not in groups:
                return False
        return True
    except Exception as ex:
        if auth_debug:
            debugException(ex)
        return False
    finally:
        auth_client.unbind()

