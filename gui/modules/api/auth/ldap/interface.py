import ldap



#Plugin Metadata

pluginName = "LDAP Authentication"
pluginVersion = "1.0"
pluginType = "auth"
debug = True

# Return True if the user is able to authenticate to the LDAP server
# Return False is the user is NOT able to authenticate to the LDAP server

def auth(username,password,required_group=None,group_member_attr=None):
    try:
        
        # Enable TLS if ldaps is specified in the URI
        if LDAP_HOST[0:4].lower() == "ldaps":
            ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

        connect = ldap.initialize(LDAP_HOST)
        connect.set_option(ldap.OPT_REFERRALS, 0)

        ldap_bind_user = "{}={},{}".format(LDAP_USER_ATTRIBUTE,username,LDAP_USER_SEARCH_BASE)
        connect.simple_bind_s(ldap_bind_user, password)
        if debug: print("------------------------------------\n{} - User authenticated: {}".format(pluginName,ldap_bind_user))


        if required_group is not None:
            if group_member_attr is not None:
                ldap_member_filter = "{}={}".format(LDAP_GROUP_MEMBER_ATTRIBUTE, group_member_attr)
                if debug: print("LDAP Member Filter: {}".format(ldap_member_filter))
                result = connect.search_s(LDAP_GROUP_SEARCH_BASE,
                                      ldap.SCOPE_SUBTREE,
                                      ldap_member_filter,
                                      ['dn'])

            if debug: print("List of groups found: \n{}".format(result))
            for group in result:
                if required_group in group[0]:
                    return True
            return False #If not found
        

        return True

    except ldap.INVALID_CREDENTIALS:
        return False

    except ldap.INVALID_CREDENTIALS as error:
        print("Error:", error)
        return False

def getGroups(username):
    return

# Initizize the plugin and get settings
def init():
    if settings.AUTH_LDAP is not None:
        print(settings.AUTH_LDAP)
    return

def main():
    print("In Main")
    if auth("mack","test",LDAP_REQUIRED_GROUP,"mack"):
        print("User Authenticated")
    else:
        print("User Auth Failed")

if __name__ == "__main__":
    LDAP_HOST="ldap://ldap.dopensource.com"
    #LDAP_BIND_USER="cn=manager,dc=dopensource,dc=com"
    #LDAP_BIND_PASS="flyball2015"
    #Test AD LDAP=flyBall2015
    LDAP_USER_SEARCH_BASE="ou=People,dc=dopensource,dc=com"
    LDAP_GROUP_SEARCH_BASE="dc=dopensource,dc=com"
    LDAP_GROUP_MEMBER_ATTRIBUTE="memberUid"
    LDAP_REQUIRED_GROUP="dev"
    LDAP_USER_ATTRIBUTE="cn"
    main()
else:
    import settings
    LDAP_HOST=settings.AUTH_LDAP["LDAP_HOST"]
    LDAP_USER_SEARCH_BASE=settings.AUTH_LDAP["LDAP_USER_SEARCH_BASE"]
    LDAP_GROUP_SEARCH_BASE=settings.AUTH_LDAP["LDAP_GROUP_SEARCH_BASE"]
    LDAP_GROUP_MEMBER_ATTRIBUTE=settings.AUTH_LDAP["LDAP_GROUP_MEMBER_ATTRIBUTE"]
    LDAP_REQUIRED_GROUP=settings.AUTH_LDAP["LDAP_REQUIRED_GROUP"]
    LDAP_USER_ATTRIBUTE=settings.AUTH_LDAP["LDAP_USER_ATTRIBUTE"]

