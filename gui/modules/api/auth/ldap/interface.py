import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import ldap
import settings

# required plugin global
METADATA = {
    'name': 'LDAP Authentication',
    'version': '1.0.0'
}

# required plugin interface
def initialize():
    """
    Validate the module settings and perform any verification needed

    :return:    None
    :rtype:     None
    :raises:    ValueError - when settings are invalid
    """

    mod_settings = settings.AUTH_MODULES['ldap']
    for req_key in ['LDAP_HOST', 'USER_ATTRIBUTE', 'USER_SEARCH_BASE']:
        if req_key not in mod_settings:
            raise ValueError(f'ldap module failed initialization: missing required setting "{req_key}"')
    if 'REQUIRED_GROUP' in mod_settings:
        if not 'GROUP_SEARCH_BASE' in mod_settings or not 'GROUP_MEMBER_ATTRIBUTE' in mod_settings:
            raise ValueError(f'ldap module failed initialization: "REQUIRED_GROUP" requires "GROUP_SEARCH_BASE" avd "GROUP_MEMBER_ATTRIBUTE" to be set')

    # TODO: validate ldap connection / store connection object

# required plugin interface
def teardown():
    """
    Cleanup any artifacts from the module

    :return:    None
    :rtype:     None
    """
    pass

# required plugin interface
def authenticate(username, password):
    """
    Authenticate a user via an external LDAP server

    :param username:        The username to authenticate with
    :type username:         str
    :param password:        The password to authenticate with
    :type password:         str
    :return:                Whether authentication was successful or not
    :rtype:                 bool
    """

    mod_settings = settings.AUTH_MODULES['ldap']

    try:
        # Enable TLS if ldaps is specified in the URI
        if mod_settings['LDAP_HOST'][0:4].lower() == "ldaps":
            ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

        connect = ldap.initialize(mod_settings['LDAP_HOST'])
        connect.set_option(ldap.OPT_REFERRALS, 0)

        ldap_bind_user = "{}={},{}".format(
            mod_settings['USER_ATTRIBUTE'],
            username,
            mod_settings['USER_SEARCH_BASE']
        )
        connect.simple_bind_s(ldap_bind_user, password)
        if settings.DEBUG:
            print(f'{METADATA["name"]} - User authenticated: {ldap_bind_user}')

        if 'REQUIRED_GROUP' in mod_settings:
            ldap_member_filter = "{}={}".format(mod_settings['GROUP_MEMBER_ATTRIBUTE'], username)
            if settings.DEBUG:
                print("LDAP Member Filter: {}".format(ldap_member_filter))

            groups = connect.search_s(
                mod_settings['GROUP_SEARCH_BASE'],
                ldap.SCOPE_SUBTREE,
                ldap_member_filter,
                ['dn']
            )
            if settings.DEBUG:
                print("List of groups found: {}".format(groups))

            for group in groups:
                if mod_settings['REQUIRED_GROUP'] in group[0]:
                    return True
            return False

        return True
    except ldap.INVALID_CREDENTIALS:
        return False
