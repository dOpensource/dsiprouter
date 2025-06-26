import ldap, ldap.filter, ldapurl, sys
from typing import Any, Dict, Generator, List, Union
from shared import IO
from modules.api.auth.ldap.functions import filterValidSearchResults, filterSearchValuesByRdn


class LdapAuthenticator(object):
    """
    A wrapper around ldap connections adding support for failover between multiple LDAP servers
    """

    def __init__(self, ldap_urls: List[str], ldap_debug=False, **ldap_settings: Dict[str, Any]) -> None:
        """
        Initialize the LDAP objects

        :param ldap_urls: URLs of the LDAP servers to connect to
        """

        # all the parameter that will be initialized
        self._base_dn: str
        self._required_group: Union[str, None]
        self._referrals: int
        self._network_timeout: int
        self._search_timeout: int
        self._double_bind: bool
        self._bind_filter: Union[str, None]
        self._bind_dn: Union[str, None]
        self._bind_pass: Union[str, None]
        self._user_filter: Union[str, None]
        self._user_attr = Union[str, None]
        self._clients: List[ldap.ldapobject.ReconnectLDAPObject] = []
        self.__bind_idx: Union[int, None] = None
        self.__debug: bool = ldap_debug

        # required settings
        if not isinstance(ldap_urls, list):
            raise ValueError('"ldap_urls" must be a list of strings')
        if len(ldap_urls) == 0:
            raise ValueError('"ldap_urls" cannot be empty')

        # optional settings
        self._base_dn = ldap_settings.get('base_dn', '')
        if not ldap.dn.is_dn(self._base_dn):
            raise ValueError('"base_dn" is not a valid distinguished name')

        self._required_group = ldap_settings.get('required_group', None)
        if not isinstance(self._required_group, (str, type(None))):
            raise ValueError('"required_group" must be a string')

        referrals = ldap_settings.get('referrals', 0)
        if not isinstance(referrals, (int, bool)):
            raise ValueError('"referrals" must be an integer or boolean')
        self._referrals = int(referrals)

        self._network_timeout = ldap_settings.get('network_timeout', 3)
        if not isinstance(self._network_timeout, int):
            raise ValueError('"network_timeout" must be an integer')

        self._search_timeout = ldap_settings.get('search_timeout', 5)
        if not isinstance(self._search_timeout, int):
            raise ValueError('"search_timeout" must be an integer')
        
        # single bind auth mode
        if 'bind_filter' in ldap_settings:
            self._double_bind = False
            self._bind_filter = ldap_settings['bind_filter']
            if not isinstance(self._bind_filter, str):
                raise ValueError('"bind_filter" must be a string')
            try:
                _ = ldap.filter.filter_format(self._bind_filter, ['test_username'])
            except TypeError as ex:
                raise ValueError(f'"bind_filter" is invalid ({str(ex)})')
            self._bind_dn = None
            self._bind_pass = None
        # double bind auth mode
        elif 'bind_dn' in ldap_settings and 'bind_pass' in ldap_settings:
            self._double_bind = True
            self._bind_dn = ldap_settings['bind_dn']
            self._bind_pass = ldap_settings['bind_pass']
            # no dn validation because it could be a plain username as well
            if not isinstance(self._bind_dn, str):
                raise ValueError('"bind_dn" must be a string')
            if not isinstance(self._bind_pass, str):
                raise ValueError('"bind_pass" must be a string')
            self._bind_filter = None
        # not a valid use case
        else:
            raise ValueError('invalid combination of module settings')

        # dependent settings
        if self._double_bind is True or self._required_group is not None:
            if 'user_filter' not in ldap_settings:
                raise ValueError('missing required setting "user_filter"')
            self._user_filter = ldap_settings['user_filter']
            if not isinstance(self._user_filter, str):
                raise ValueError('"user_filter" must be a string')
            try:
                _ = ldap.filter.filter_format(self._user_filter, ['test_username'])
            except TypeError as ex:
                raise ValueError(f'"user_filter" is invalid ({str(ex)})')
            if 'user_attr' not in ldap_settings:
                raise ValueError('missing required setting "user_attr"')
            self._user_attr = ldap_settings['user_attr']
            if not isinstance(self._user_attr, str):
                raise ValueError('"user_attr" must be a string')
        else:
            self._user_filter = None
            self._user_attr = None

        # create the ldap objects
        for url in ldap_urls:
            try:
                url_obj = ldapurl.LDAPUrl(url)
            except ValueError:
                raise ValueError(f'ldap url "{url}" is not valid')

            client = ldap.ldapobject.ReconnectLDAPObject(
                uri=url_obj.initializeUrl(),
                trace_level=1 if self.__debug else 0,
                trace_file=sys.stderr if self.__debug else None,
                retry_max=1,
                retry_delay=0
            )

            client.set_option(ldap.OPT_PROTOCOL_VERSION, 3)
            if url_obj.urlscheme == 'ldaps':
                client.set_option(ldap.OPT_X_TLS, ldap.OPT_X_TLS_DEMAND)
                client.set_option(ldap.OPT_X_TLS_DEMAND, True)
                client.set_option(ldap.OPT_X_TLS_NEWCTX, 0)

            client.set_option(ldap.OPT_REFERRALS, referrals)
            client.set_option(ldap.OPT_NETWORK_TIMEOUT, self._network_timeout)

            self._clients.append(client)

    # allow passing to dict() and iterable()
    def __iter__(self) -> Generator[tuple[str, Any], Any, None]:
        for k, v in self._asDict().items():
            yield k, v

    # only return select attributes in the iterable/dict representation
    def _asDict(self) -> Dict[str, Any]:
        return {
            'base_dn': self._base_dn,
            'required_group': self._required_group,
            'referrals': self._referrals,
            'network_timeout': self._network_timeout,
            'search_timeout': self._search_timeout,
            'double_bind': self._double_bind,
            'bind_filter': self._bind_filter,
            'bind_dn': self._bind_dn,
            'bind_pass': self._bind_pass,
            'user_filter': self._user_filter,
            'user_attr': self._user_attr,
        }

    # TODO: allow updating attributes on the fly (clients would have to be recreated)

    def validateConnection(self) -> None:
        """
        Check if a connection to one of the ldap servers can be made
        """

        for client in self._clients:
            try:
                client.reconnect(
                    client._uri,
                    client._retry_max,
                    client._retry_delay
                )
                return None
            except (ldap.SERVER_DOWN, ldap.TIMEOUT):
                continue

        raise ldap.SERVER_DOWN('ldap connection(s) failed')

    def validateBind(self) -> None:
        """
        Check if the bind settings are valid
        """

        if self._double_bind is False:
            return None

        for client in self._clients:
            try:
                client.simple_bind_s(
                    self._bind_dn,
                    self._bind_pass
                )
                client.unbind_s()
                return None
            except ldap.LDAPError:
                continue

        raise ldap.LDAPError('ldap bind failed')

    def bind(self, username: str, password: str) -> None:
        """
        Bind to the ldap server
        """

        if self.__bind_idx is not None:
            self.unbind()

        for idx, client in zip(range(len(self._clients)), self._clients):
            try:
                # double bind auth mode
                if self._double_bind:
                    try:
                        client.simple_bind_s(
                            self._bind_dn,
                            self._bind_pass
                        )

                        res = filterValidSearchResults(
                            client.search_st(
                                self._base_dn,
                                ldap.SCOPE_SUBTREE,
                                ldap.filter.filter_format(self._user_filter, [username]),
                                [self._user_attr],
                                timeout=self._search_timeout
                            )
                        )
                    finally:
                        client.unbind_s()

                    if len(res) == 0:
                        raise ldap.NO_SUCH_OBJECT('user not found')
                    if len(res) > 1:
                        IO.logwarn(f'multiple records found searching attribute {self._user_attr} for user {username}')
                        if self.__debug:
                            IO.printwarn(f'multiple records found searching attribute {self._user_attr} for user {username}')

                    user_login = res[0][1][self._user_attr][0].decode('utf-8')
                    if self.__debug:
                        IO.printdbg(f'found {self._user_attr} "{user_login}" for username "{username}"')
                    client.simple_bind_s(
                        user_login,
                        password
                    )
                    self.__bind_idx = idx
                    return None

                # single bind auth mode
                client.simple_bind_s(
                    ldap.filter.filter_format(self._bind_filter, [username]),
                    password
                )
                self.__bind_idx = idx
                return None
            except (ldap.SERVER_DOWN, ldap.TIMEOUT):
                continue

        raise ldap.LDAPError('ldap bind failed')

    def unbind(self) -> None:
        """
        Bind to the ldap server
        """

        if self.__bind_idx is None:
            return None

        try:
            self._clients[self.__bind_idx].unbind_s()
            self.__bind_idx = None
            return None
        except ldap.SERVER_DOWN:
            return None

    def queryUser(self, username: str, attrs: Union[List[str], None] = None) -> Dict[str, List[str]]:
        """
        Perform an ldap query
        """

        if self.__bind_idx is None:
            raise Exception('not bound to any ldap servers')

        client = self._clients[self.__bind_idx]
        client.reconnect(
            client._uri,
            client._retry_max,
            client._retry_delay
        )

        res = filterValidSearchResults(
            client.search_st(
                self._base_dn,
                ldap.SCOPE_SUBTREE,
                ldap.filter.filter_format(self._user_filter, [username]),
                [self._user_attr],
                timeout=self._search_timeout
            )
        )

        if len(res) == 0:
            raise ldap.NO_SUCH_OBJECT('user not found')
        vals = res[0][1]

        return {
            k: filterSearchValuesByRdn(v, 'CN') for k, v in vals.items() if k in attrs
        }
