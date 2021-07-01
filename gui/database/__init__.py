# make sure the generated source files are imported instead of the template ones
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

import os
from enum import Enum
from datetime import datetime, timedelta
from sqlalchemy import create_engine, MetaData, Table, Column, String, func, JSON
from sqlalchemy import exc as sql_exceptions
from sqlalchemy.orm import mapper, sessionmaker, scoped_session, attributes
from sqlalchemy.ext.hybrid import hybrid_property, ExprComparator, Comparator
from sqlalchemy.util import memoized_property, update_wrapper
import settings
from shared import IO, debugException, dictToStrFields, strFieldsToDict
from util.networking import safeUriToHost, safeFormatSipUri
from util.security import AES_CTR

if settings.KAM_DB_TYPE == "mysql":
    try:
        import MySQLdb as db_driver
    except ImportError:
        try:
            import _mysql as db_driver
        except ImportError:
            try:
                import pymysql as db_driver
            except ImportError:
                raise
            except Exception as ex:
                if settings.DEBUG:
                    debugException(ex)
                raise


# TODO: not fully working yet, see if we can work with upstream devs on this
#       this SHOULD allow JSON fields to be accessed / set using d['key']='val'
# class hybrid_dict_property(hybrid_property):
#     def __init__(
#             self, fget, fset=None, fdel=None,
#             fgetitem=None, fsetitem=None, fdelitem=None,
#             expr=None, custom_comparator=None, update_expr=None,
#             item_expr=None, item_custom_comparator=None, item_update_expr=None,
#     ):
#         self.fgetitem = fgetitem
#         self.fsetitem = fsetitem
#         self.fdelitem = fdelitem
#         self.item_expr = item_expr
#         self.item_custom_comparator = item_custom_comparator
#         self.item_update_expr = item_update_expr
#         super().__init__(
#             fget, fset=fset, fdel=fdel,
#             expr=expr, custom_comparator=custom_comparator, update_expr=update_expr,
#         )
#
#     def __getitem__(self, instance, key):
#         if self.fgetitem is None:
#             return self.fget(instance)[key]
#         else:
#             return self.fgetitem(instance)
#
#     def __setitem__(self, instance, key, val):
#         if self.fsetitem is None:
#             tmp = self.fget(instance)
#             tmp[key] = val
#             return self.fset(instance, tmp)
#         else:
#             self.fsetitem(instance, key, val)
#
#     def __delitem__(self, instance, key):
#         if self.fdelitem is None:
#             tmp = self.fget(instance)
#             del (tmp[key])
#             self.fset(instance, tmp)
#         else:
#             self.fdelitem(instance, key)
#
#     def get_item(self, fgetitem):
#         return self._copy(fgetitem=fgetitem)
#
#     def set_item(self, fsetitem):
#         return self._copy(fsetitem=fsetitem)
#
#     def delete_item(self, fdelitem):
#         return self._copy(fdelitem=fdelitem)
#
#     def item_expression(self, expr):
#         return self._copy(item_expr=expr)
#
#     def item_comparator(self, comparator):
#         return self._copy(item_custom_comparator=comparator)
#
#     def item_update_expression(self, meth):
#         return self._copy(item_update_expr=meth)
#
#     @memoized_property
#     def _item_expr_comparator(self):
#         if self.item_custom_comparator is not None:
#             return self._get_item_comparator(self.item_custom_comparator)
#         elif self.item_expr is not None:
#             return self._get_item_expr(self.item_expr)
#         else:
#             return self._get_item_expr(self.fgetitem)
#
#     def _get_item_expr(self, expr):
#         def _item_expr(cls):
#             return ExprComparator(cls, expr(cls), self)
#
#         update_wrapper(_item_expr, expr)
#
#         return self._get_item_comparator(_item_expr)
#
#     def _get_item_comparator(self, comparator):
#
#         proxy_attr = attributes.create_proxied_attribute(self)
#
#         def item_expr_comparator(owner):
#             return proxy_attr(
#                 owner,
#                 self.__name__,
#                 self,
#                 comparator(owner),
#                 doc=comparator.__doc__ or self.__doc__,
#             )
#
#         return item_expr_comparator

class ObjectWithDescription(object):
    """
    Handles description field setter/getter for JSON data
    """

    @hybrid_property
    def description(self):
        return strFieldsToDict(self._description)

    @description.setter
    def description(self, val):
        self._description = dictToStrFields(val)

    @description.deleter
    def description(self):
        self._description = {}

    # @description.get_item
    # def description(self, key):
    #     return strFieldsToDict(self._description)[key]
    #
    # @description.set_item
    # def description(self, key, val):
    #     self._description[key] = val
    #
    # @description.delete_item
    # def description(self, key):
    #     del(self._description[key])

    @description.expression
    def description(cls):
        return func.json_unquote(cls.description)

    @description.update_expression
    def description(cls, val):
        return [(cls._description, dictToStrFields(val))]

    @description.comparator
    def description(cls):
        return Comparator(cls._description)

    # @description.item_expression
    # def description(cls, key):
    #     return func.json_unquote(func.json_extract(cls.description, key))
    #
    # @description.item_update_expression
    # def description(cls, key, val):
    #     tmp = strFieldsToDict(cls.description)
    #     tmp[key] = val
    #     return [(cls.description, dictToStrFields(tmp))]
    #
    # @description.item_comparator
    # def description(cls, key):
    #     return Comparator(cls.description[key])

class ObjectWithTag(object):
    """
    Handles tag field setter/getter for JSON data
    """
    @hybrid_property
    def tag(self):
        return strFieldsToDict(self._tag)

    @tag.setter
    def tag(self, value):
        self._tag = dictToStrFields(value)

    @tag.deleter
    def tag(self):
        self._tag = {}

    @tag.expression
    def tag(cls):
        return func.json_unquote(cls.tag)

    @tag.update_expression
    def description(cls, value):
        return [(cls.tag, dictToStrFields(value))]



class Gateways(ObjectWithDescription):
    """
    Schema for dr_gateways table\n
    Documentation: `dr_gateways table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-gateways>`_\n
    Allowed address types: SIP URI, IP address or DNS domain name\n
    The address field can be a full SIP URI, partial URI, or only host; where host portion is an IP or FQDN
    """

    def __init__(self, name, address, strip, prefix, type, gwgroup=None, addr_list=None, attrs=''):
        desc_fields = {'name': name}
        if gwgroup is not None:
            desc_fields['gwgroup'] = gwgroup
        if addr_list is not None:
            desc_fields['addr_list'] = addr_list

        self.type = type
        self.address = address
        self.strip = strip
        self.pri_prefix = prefix
        self.attrs = attrs
        self.description = desc_fields

    pass

class GatewayGroups(ObjectWithDescription):
    """
    Schema for dr_gw_lists table\n
    Documentation: `dr_gw_lists table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-gw-lists>`_
    """

    def __init__(self, name, gwlist=[], type=settings.FLT_CARRIER):
        self.description = {'name': name, 'type': type}
        self.gwlist = ",".join(str(gw) for gw in gwlist)

    pass

class Address(ObjectWithTag):
    """
    Schema for address table\n
    Documentation: `address table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-address>`_\n
    Allowed address types: exact IP address, subnet IP address or DNS domain name\n
    The ip_addr field is either an IP address or DNS domain name; mask field is for subnet
    """

    def __init__(self, name, ip_addr, mask, type, gwgroup=None, port=0):
        tag_fields = {"name": name}
        if gwgroup is not None:
            tag_fields["gwgroup"] = gwgroup

        self.grp = type
        self.ip_addr = ip_addr
        self.mask = mask
        self.port = port
        self.tag = tag_fields

    pass

class InboundMapping(ObjectWithDescription):
    """
    Partial Schema for modified version of dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-rules>`_
    """

    gwname = Column(String)

    def __init__(self, groupid, prefix, gwlist, description={}):
        self.groupid = groupid
        self.prefix = prefix
        self.gwlist = gwlist
        self.description = description
        self.timerec = ''
        self.routeid = ''

    pass

class OutboundRoutes(ObjectWithDescription):
    """
    Schema for dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-rules>`_
    """

    def __init__(self, groupid, prefix, timerec, priority, routeid, gwlist, description={}):
        self.groupid = groupid
        self.prefix = prefix
        self.timerec = timerec
        self.priority = priority
        self.routeid = routeid
        self.gwlist = gwlist
        self.description = description

    pass

class CustomRouting(ObjectWithDescription):
    """
    Schema for dr_custom_rules table\n
    """

    def __init__(self, locality, ppm, description={}):
        self.locality = locality
        self.ppm = ppm
        self.description = description

    pass

class dSIPLCR(object):
    """
    Schema for LCR lookup\n
    Mapped to db table: dsip_lcr
    The pattern field contains a complex key that includes FROM XNPA and TO NPA\n
    There the pattern field looks like this XNPA-NPA\n
    The dr_groupid field contains a dynamic routing group that maps to a gateway
    """

    def __init__(self, pattern, from_prefix, dr_groupid, cost=0.00):
        self.pattern = pattern
        self.from_prefix = from_prefix
        self.dr_groupid = dr_groupid
        self.cost = cost

    pass

class dSIPMultiDomainMapping(object):
    """
    Schema for Multi-Tenant PBX\n
    Mapped to db table: dsip_multidomain_mapping
    """

    class FLAGS(Enum):
        DOMAIN_DISABLED = 0
        DOMAIN_ENABLED = 1
        TYPE_UNKNOWN = 0
        TYPE_FUSIONPBX = 1
        TYPE_FUSIONPBX_CLUSTER = 2
        TYPE_FREEPBX = 3


    def __init__(self, pbx_id, db_host, db_username, db_password, domain_list=None, attr_list=None, type=0, enabled=1):
        self.pbx_id = pbx_id
        self.db_host = db_host
        self.db_username = db_username
        self.db_password = db_password
        self.domain_list = ",".join(str(domain_id) for domain_id in domain_list) if domain_list else ''
        self.attr_list = ",".join(str(attr_id) for attr_id in attr_list) if attr_list else ''
        self.type = type
        self.enabled = enabled

    pass

class dSIPDomainMapping(object):
    """
    Schema for Single-Tenant PBX domain mapping\n
    Mapped to db table: dsip_domain_mapping
    """

    class FLAGS(Enum):
        DOMAIN_DISABLED = 0
        DOMAIN_ENABLED = 1
        TYPE_UNKNOWN = 0
        TYPE_ASTERISK = 1
        TYPE_SIPFOUNDRY = 2
        TYPE_ELASTIX = 3
        TYPE_FREESWITCH = 4
        TYPE_OPENPBX = 5
        TYPE_FREEPBX = 6
        TYPE_PBXINAFLASH = 7
        TYPE_3CX = 8

    def __init__(self, pbx_id, domain_id, attr_list, type=0, enabled=1):
        self.pbx_id = pbx_id
        self.domain_id = domain_id
        self.attr_list = ",".join(str(attr_id) for attr_id in attr_list)
        self.type = type
        self.enabled = enabled

    pass

class Subscribers(object):
    """
    Schema for subscriber table\n
    Documentation: `subscriber table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-subscriber>`_
    """

    def __init__(self, username, password, domain, gwid, email_address=None):
        self.username = username
        self.password = password
        self.domain = domain
        self.ha1 = ''
        self.ha1b = ''
        self.rpid = gwid
        self.email_address = email_address

    pass

class dSIPLeases(object):
    """
    Schema for dsip_endpoint_leases table\n
    maintains a list of active leases based on seconds
    """

    def __init__(self, gwid, sid, ttl):
        self.gwid = gwid
        self.sid = sid
        now = datetime.now() + timedelta(seconds=ttl)
        self.expiration = now.strftime('%Y-%m-%d %H:%M:%S')

    pass

class dSIPMaintModes(object):
    """
    Schema for dsip_maintmode table\n
    maintains a list of endpoints and carriers that are in maintenance mode
    """

    def __init__(self, ipaddr, gwid, status=1):
        self.ipaddr = ipaddr
        self.gwid = gwid
        self.status = status
        self.createdate = datetime.now()

    pass

class dSIPCallLimits(object):
    """
    Schema for dsip_calllimit table\n
    """

    def __init__(self, gwgroupid, limit, status=1):
        self.gwgroupid = gwgroupid
        self.limit = limit
        self.status = status
        self.createdate = datetime.now()

    pass

class dSIPNotification(object):
    """
    Schema for dsip_notification table\n
    maintains the list of notifications
    """

    class FLAGS(Enum):
        METHOD_EMAIL = 0
        METHOD_SLACK = 1
        TYPE_OVERLIMIT = 0
        TYPE_GWFAILURE = 1

    def __init__(self, gwgroupid, type, method, value):
        self.gwgroupid = gwgroupid
        self.type = type
        self.method = method
        self.value = value
        self.createdate = datetime.now()

    pass

class dSIPHardFwd(object):
    """
    Schema for dsip_hardfwd table\n
    """

    def __init__(self, dr_ruleid, did, dr_groupid):
        self.dr_ruleid = dr_ruleid
        self.did = did
        self.dr_groupid = dr_groupid

    pass

class dSIPCDRInfo(object):
    """
    Schema for dsip_cdrinfo table\n
    """

    def __init__(self, gwgroupid, email, send_interval):
        self.gwgroupid = gwgroupid
        self.email = email
        self.send_interval = send_interval
        self.last_sent = datetime.now()

    pass

class dSIPFailFwd(object):
    """
    Schema for dsip_failfwd table\n
    """

    def __init__(self, dr_ruleid, did, dr_groupid):
        self.dr_ruleid = dr_ruleid
        self.did = did
        self.dr_groupid = dr_groupid

    pass

class dSIPCertificates(object):
    """
    Schema for dsip_certificates table\n
    """

    def __init__(self, domain, type, email, cert, key):
        self.domain = domain
        self.type = type
        self.email = email
        self.cert = cert
        self.key = key

    pass

class dSIPDNIDEnrichment(ObjectWithDescription):
    """
    Schema for dsip_dnid_enrich_lnp table\n
    """

    def __init__(self, dnid, country_code='', routing_number='', rule_name=''):
        self.dnid = dnid
        self.country_code = country_code
        self.routing_number = routing_number
        self.description = {'name': rule_name}

    pass

class UAC(object):
    """
    Schema for uacreg table\n
    Documentation: `uacreg table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-uacreg>`_
    """

    class FLAGS(Enum):
        REG_ENABLED = 0
        REG_DISABLED = 1
        REG_IN_PROGRESS = 2
        REG_SUCCEEDED = 4
        REG_IN_PROGRESS_AUTH = 8
        REG_INITIALIZED = 16

    def __init__(self, uuid, username="", password="", realm="", auth_username="",auth_proxy="", local_domain="", remote_domain="", flags=0):
        self.l_uuid = uuid
        self.l_username = username
        self.l_domain = local_domain
        if flags == self.FLAGS.REG_DISABLED.value:
            self.r_username = ""
            self.auth_username = ""
        else:
            self.r_username = username
            self.auth_username = auth_username

        self.r_domain = remote_domain
        self.realm = realm
        self.auth_password = password
        self.auth_ha1 = ""
        self.auth_proxy = auth_proxy
        self.expires = 60
        self.flags = flags
        self.reg_delay = 0
        self.socket = ''

    pass

class Domain(object):
    """
    Schema for domain table\n
    Documentation: `domain table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-domain>`_
    """

    def __init__(self, domain, did=None, last_modified=datetime.utcnow()):
        self.domain = domain
        if did is None:
            did = domain
        self.did = did
        self.last_modified = last_modified

    pass

class DomainAttrs(object):
    """
    Schema for domain_attrs table\n
    Documentation: `domain_attrs table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-domain-attrs>`_
    """

    class FLAGS(Enum):
        TYPE_INTEGER = 0
        TYPE_STRING = 2

    def __init__(self, did, name="pbx_ip", type=2, value=None, last_modified=datetime.utcnow()):
        self.did = did
        self.name = name
        self.type = type
        self.last_modified = last_modified
        temp_value = value if value is not None else safeUriToHost(did)
        self.value = temp_value if temp_value is not None else did

    pass

class Dispatcher(ObjectWithDescription):
    """
    Schema for dispatcher table\n
    Documentation: `dispatcher table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dispatcher>`_
    """

    def __init__(self, setid, destination, flags=None, priority=None, attrs=None, description={}):
        self.setid = setid
        self.destination = safeFormatSipUri(destination)
        self.flags = flags
        self.priority = priority
        self.attrs = attrs
        self.description = description

    pass

# TODO: create class for dsip_settings table


def getDBURI():
    """
    Get any and all DB Connection URI's
    Facilitates HA DB Server connections through multiple host's defined in settings
    :return:    list of DB URI connection strings
    """
    uri_list = []

    # check environment vars if in debug mode
    if settings.DEBUG:
        settings.KAM_DB_DRIVER = os.getenv('KAM_DB_DRIVER', settings.KAM_DB_DRIVER)
        settings.KAM_DB_HOST = os.getenv('KAM_DB_HOST', settings.KAM_DB_HOST)
        settings.KAM_DB_TYPE = os.getenv('KAM_DB_TYPE', settings.KAM_DB_TYPE)
        settings.KAM_DB_PORT = os.getenv('KAM_DB_PORT', settings.KAM_DB_PORT)
        settings.KAM_DB_NAME = os.getenv('KAM_DB_NAME', settings.KAM_DB_NAME)
        settings.KAM_DB_USER = os.getenv('KAM_DB_USER', settings.KAM_DB_USER)
        settings.KAM_DB_PASS = os.getenv('KAM_DB_PASS', settings.KAM_DB_PASS)

    # need to decrypt password
    if isinstance(settings.KAM_DB_PASS, bytes):
        kampass = AES_CTR.decrypt(settings.KAM_DB_PASS).decode('utf-8')
    else:
        kampass = settings.KAM_DB_PASS

    if settings.KAM_DB_TYPE != "":
        sql_uri = settings.KAM_DB_TYPE + "{driver}" + "://" + settings.KAM_DB_USER + ":" + kampass + "@" + "{host}" + "/" + settings.KAM_DB_NAME + "?charset=utf8mb4"

        driver = ""
        if len(settings.KAM_DB_DRIVER) > 0:
            driver = '+{}'.format(settings.KAM_DB_DRIVER)

        if isinstance(settings.KAM_DB_HOST, list):
            for host in settings.KAM_DB_HOST:
                uri_list.append(sql_uri.format(host=host, driver=driver))
        else:
            uri_list.append(sql_uri.format(host=settings.KAM_DB_HOST, driver=driver))

    if settings.DEBUG:
        IO.printdbg('getDBURI() returned: [{}]'.format(','.join('"{0}"'.format(uri) for uri in uri_list)))

    return uri_list

def createValidEngine(uri_list):
    """
    Create DB engine if connection is valid
    Attempts each uri in the list until a valid connection is made
    This method uses a singleton pattern and returns db_engine if created
    :param uri_list:    list of connection uri's
    :return:            DB engine object
    :raise:             SQLAlchemyError if all connections fail
    """

    if 'db_engine' in globals():
        return globals()['db_engine']

    errors = []

    for conn_uri in uri_list:
        try:
            db_engine = create_engine(conn_uri, echo=True, pool_recycle=300, pool_size=10,
                isolation_level="READ UNCOMMITTED",
                connect_args={"connect_timeout": 5})
            # test connection
            _ = db_engine.connect()
            # conn good return it
            return db_engine
        except Exception as ex:
            errors.append(ex)

    # we failed to return good connection raise exceptions
    if settings.DEBUG:
        for ex in errors:
            debugException(ex)

    try:
        raise sql_exceptions.SQLAlchemyError(errors)
    except:
        raise Exception(errors)

def createSessionMaker():
    """
    This method uses a singleton pattern and returns SessionLoader if created
    :return:    SessionMaker() object
    """

    if 'SessionLoader' in globals():
        return globals()['SessionLoader']
    if not 'db_engine' in globals():
        db_engine = createValidEngine(getDBURI())
    else:
        db_engine = globals()['db_engine']

    metadata = MetaData(db_engine)

    dr_gateways = Table('dr_gateways', metadata, autoload=True)
    address = Table('address', metadata, autoload=True)
    outboundroutes = Table('dr_rules', metadata, autoload=True)
    inboundmapping = Table('dr_rules', metadata, autoload=True)
    subscriber = Table('subscriber', metadata, autoload=True)
    dsip_domain_mapping = Table('dsip_domain_mapping', metadata, autoload=True)
    dsip_multidomain_mapping = Table('dsip_multidomain_mapping', metadata, autoload=True)
    # fusionpbx_mappings = Table('dsip_fusionpbx_mappings', metadata, autoload=True)
    dsip_lcr = Table('dsip_lcr', metadata, autoload=True)
    uacreg = Table('uacreg', metadata, autoload=True)
    dr_gw_lists = Table('dr_gw_lists', metadata, autoload=True)
    # dr_groups = Table('dr_groups', metadata, autoload=True)
    domain = Table('domain', metadata, autoload=True)
    domain_attrs = Table('domain_attrs', metadata, autoload=True)
    dispatcher = Table('dispatcher', metadata, autoload=True)
    dsip_endpoint_lease = Table('dsip_endpoint_lease', metadata, autoload=True)
    dsip_maintmode = Table('dsip_maintmode', metadata, autoload=True)
    dsip_calllimit = Table('dsip_calllimit', metadata, autoload=True)
    dsip_notification = Table('dsip_notification', metadata, autoload=True)
    dsip_hardfwd = Table('dsip_hardfwd', metadata, autoload=True)
    dsip_failfwd = Table('dsip_failfwd', metadata, autoload=True)
    dsip_cdrinfo = Table('dsip_cdrinfo', metadata, autoload=True)
    dsip_certificates = Table('dsip_certificates', metadata, autoload=True)
    dsip_dnid_enrichment = Table('dsip_dnid_enrich_lnp', metadata, autoload=True)

    # dr_gw_lists_alias = select([
    #     dr_gw_lists.c.id.label("drlist_id"),
    #     dr_gw_lists.c.gwlist,
    #     dr_gw_lists.c.description.label("drlist_description"),
    # ]).correlate(None).alias()
    # gw_join = join(dr_gw_lists_alias, dr_groups,
    #                dr_gw_lists_alias.c.drlist_id == dr_groups.c.id,
    #                dr_gw_lists_alias.c.drlist_description == dr_groups.c.description)

    mapper(Gateways, dr_gateways, properties={'_description': dr_gateways.c.description})
    mapper(Address, address, properties={'_description': address.c.tag})
    mapper(InboundMapping, inboundmapping, properties={'_description': inboundmapping.c.description})
    mapper(OutboundRoutes, outboundroutes, properties={'_description': outboundroutes.c.description})
    mapper(dSIPDomainMapping, dsip_domain_mapping)
    mapper(dSIPMultiDomainMapping, dsip_multidomain_mapping)
    mapper(Subscribers, subscriber)
    # mapper(CustomRouting, customrouting, properties={'_description': customrouting.c.description})
    mapper(dSIPLCR, dsip_lcr)
    mapper(UAC, uacreg)
    mapper(GatewayGroups, dr_gw_lists, properties={'_description': dr_gw_lists.c.description})
    mapper(Domain, domain)
    mapper(DomainAttrs, domain_attrs)
    mapper(Dispatcher, dispatcher, properties={'_description': dispatcher.c.description})
    mapper(dSIPLeases, dsip_endpoint_lease)
    mapper(dSIPMaintModes, dsip_maintmode)
    mapper(dSIPCallLimits, dsip_calllimit)
    mapper(dSIPNotification, dsip_notification)
    mapper(dSIPHardFwd, dsip_hardfwd)
    mapper(dSIPFailFwd, dsip_failfwd)
    mapper(dSIPCDRInfo, dsip_cdrinfo)
    mapper(dSIPCertificates, dsip_certificates)
    mapper(dSIPDNIDEnrichment, dsip_dnid_enrichment, properties={'_description': dsip_dnid_enrichment.c.description})

    # mapper(GatewayGroups, gw_join, properties={
    #     'id': [dr_groups.c.id, dr_gw_lists_alias.c.drlist_id],
    #     'description': [dr_groups.c.description, dr_gw_lists_alias.c.drlist_description],
    # })

    loadSession = scoped_session(sessionmaker(bind=db_engine))
    return loadSession

class DummySession():
    """
    Sole purpose is to avoid exceptions when SessionLoader fails
    This allows us to handle exceptions later in the try blocks
    We also avoid exceptions in the except blocks by using dummy sesh
    """

    @staticmethod
    def noop(*args, **kwargs):
        return None
    def __contains__(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def __iter__(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def add(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def add_all(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def begin(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def begin_nested(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def close(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def commit(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def connection(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def delete(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def execute(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def expire(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def expire_all(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def expunge(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def expunge_all(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def flush(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def get_bind(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def is_modified(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def bulk_save_objects(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def bulk_insert_mappings(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def bulk_update_mappings(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def merge(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def query(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def refresh(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def rollback(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def scalar(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def remove(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def configure(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)
    def query_property(self, *args, **kwargs):
        DummySession.noop(*args, **kwargs)

# TODO: we should be creating a queue of the valid db_engines
# from there we can perform round robin connections and more advanced clustering
# this does have the requirement of new session instancing per request

# Make the engine and session maker global
db_engine = createValidEngine(getDBURI())
SessionLoader = createSessionMaker()
