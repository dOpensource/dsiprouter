# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import base64, bson, inspect, os
from collections import OrderedDict
from enum import Enum
from datetime import datetime, timedelta
from sqlalchemy import create_engine, MetaData, Table, Column, String, exc as sql_exceptions, Integer, event
from sqlalchemy.orm import registry, sessionmaker, scoped_session, validates
from sqlalchemy.sql import text
import settings
from shared import IO, debugException, dictToStrFields, rowToDict, objToDict
from util.networking import safeUriToHost, safeFormatSipUri, encodeSipUser
from util.security import AES_CTR

# DB specific settings
UnsignedInt = Integer()
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
    from sqlalchemy.dialects.mysql import INTEGER

    UnsignedInt = UnsignedInt.with_variant(INTEGER(unsigned=True), 'mysql', 'mariadb')

# global constants
DB_ENGINE_NAME = 'global_db_engine'
SESSION_LOADER_NAME = 'global_session_loader'


class Gateways(object):
    """
    Schema for dr_gateways table\n
    Documentation: `dr_gateways table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-gateways>`_\n
    Allowed address types: SIP URI, IP address or DNS domain name\n
    The address field can be a full SIP URI, partial URI, or only host; where host portion is an IP or FQDN
    """

    gwid = Column(UnsignedInt, primary_key=True, autoincrement=True, nullable=False)

    def __init__(self, name, address, strip, prefix, type=0, gwgroup=None, addr_id=None,
                 msteams_domain='', signalling='proxy', media='proxy'):
        description = {"name": name}
        if gwgroup is not None:
            description["gwgroup"] = str(gwgroup)
        if addr_id is not None:
            description['addr_id'] = str(addr_id)

        self.type = type
        self.address = address
        self.strip = strip
        self.pri_prefix = prefix
        self.attrs = Gateways.buildAttrs(0, type, msteams_domain, signalling, media)
        self.description = dictToStrFields(description)

    @staticmethod
    def buildAttrs(gwid=0, type=0, msteams_domain='', signalling='proxy', media='proxy'):
        # gwid in dr_attrs is updated via trigger before insert/update
        return ','.join([str(gwid), str(type), msteams_domain, signalling, media])

    def attrsToDict(self):
        attrs_dict = {}
        attrs_list = self.attrs.split(',')
        try:
            attrs_dict['gwid'] = int(attrs_list[0])
        except IndexError:
            attrs_dict['gwid'] = 0
        try:
            attrs_dict['type'] = int(attrs_list[1])
        except IndexError:
            attrs_dict['type'] = 0
        try:
            attrs_dict['msteams_domain'] = attrs_list[2]
        except IndexError:
            attrs_dict['msteams_domain'] = ''
        try:
            attrs_dict['signalling'] = attrs_list[3]
        except IndexError:
            attrs_dict['signalling'] = 'proxy'
        try:
            attrs_dict['media'] = attrs_list[4]
        except IndexError:
            attrs_dict['media'] = 'proxy'
        return attrs_dict


class GatewayGroups(object):
    """
    Schema for dr_gw_lists table\n
    Documentation: `dr_gw_lists table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-gw-lists>`_
    """

    id = Column(UnsignedInt, primary_key=True, autoincrement=True, nullable=False)

    class FILTER(Enum):
        ENDPOINT = f'type:{settings.FLT_PBX}(,|$)'
        CARRIER = f'type:{settings.FLT_CARRIER}(,|$)'
        MSTEAMS = f'type:{settings.FLT_MSTEAMS}(,|$)'
        ENDPOINT_OR_CARRIER = f'type:({settings.FLT_PBX}|{settings.FLT_CARRIER})(,|$)'

    def __init__(self, name, gwlist=[], type=settings.FLT_CARRIER, dlg_timeout=None):
        description = {'name': name, 'type': type}
        if dlg_timeout is not None:
            description['dlg_timeout'] = dlg_timeout

        self.description = dictToStrFields(description)
        self.gwlist = ",".join(str(gw) for gw in gwlist)


class Address(object):
    """
    Schema for address table\n
    Documentation: `address table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-address>`_\n
    Allowed address types: exact IP address, subnet IP address or DNS domain name\n
    The ip_addr field is either an IP address or DNS domain name; mask field is for subnet
    """

    def __init__(self, name, ip_addr, mask, type, gwgroup=None, port=0):
        tag = {"name": name}
        if gwgroup is not None:
            tag["gwgroup"] = str(gwgroup)

        self.grp = type
        self.ip_addr = ip_addr
        self.mask = mask
        self.port = port
        self.tag = dictToStrFields(tag)

    pass


class InboundMapping(object):
    """
    Partial Schema for modified version of dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-rules>`_
    """

    gwname = Column(String)

    def __init__(self, groupid, prefix, gwlist, description=''):
        self.groupid = groupid
        self.prefix = prefix
        self.gwlist = gwlist
        self.description = description
        self.timerec = ''
        self.routeid = ''

    pass


class OutboundRoutes(object):
    """
    Schema for dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-rules>`_
    """

    def __init__(self, groupid, prefix, timerec, priority, routeid, gwlist, description):
        self.groupid = groupid
        self.prefix = prefix
        self.timerec = timerec
        self.priority = priority
        self.routeid = routeid
        self.gwlist = gwlist
        self.description = description

    pass


class CustomRouting(object):
    """
    Schema for dr_custom_rules table\n
    """

    def __init__(self, locality, ppm, description):
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
    Documentation: `subscriber table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-subscriber>`_
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
        t = datetime.now() + timedelta(seconds=ttl)
        self.expiration = t.strftime('%Y-%m-%d %H:%M:%S')

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


class dSIPCallSettings(object):
    """
    Schema for dsip_call_settings table\n
    """

    def __init__(self, gwgroupid, limit=None, timeout=None):
        self.gwgroupid = gwgroupid
        self.limit = limit
        self.timeout = timeout

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


class dSIPDNIDEnrichment(object):
    """
    Schema for dsip_dnid_enrich_lnp table\n
    """

    def __init__(self, dnid, country_code='', routing_number='', rule_name=''):
        description = {'name': rule_name}

        self.dnid = dnid
        self.country_code = country_code
        self.routing_number = routing_number
        self.description = dictToStrFields(description)

    pass


class UAC(object):
    """
    Schema for uacreg table\n
    Documentation: `uacreg table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-uacreg>`_
    """

    class FLAGS(Enum):
        REG_ENABLED = 0
        REG_DISABLED = 1
        REG_IN_PROGRESS = 2
        REG_SUCCEEDED = 4
        REG_IN_PROGRESS_AUTH = 8
        REG_INITIALIZED = 16

    def __init__(self, uuid, username="", password="", realm="", auth_username="", auth_proxy="", local_domain="", remote_domain="", flags=0):
        self.l_uuid = uuid
        self.l_username = username
        self.l_domain = local_domain
        self.r_username = encodeSipUser(username)
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

def uacMapperEventHandler(mapper, connection, target):
    target.r_username = encodeSipUser(target.r_username)

event.listen(UAC, 'before_insert', uacMapperEventHandler)
event.listen(UAC, 'before_update', uacMapperEventHandler)


class Domain(object):
    """
    Schema for domain table\n
    Documentation: `domain table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-domain>`_
    """

    def __init__(self, domain, did=None, last_modified=datetime.utcnow()):
        self.domain = domain
        if did is None:
            did = domain
        self.did = did
        self.last_modified = last_modified

    @validates("domain")
    def __validateDomain(self, key, domain):
        if domain == '':
            raise ValueError('empty string is an invalid domain')
        return domain


class DomainAttrs(object):
    """
    Schema for domain_attrs table\n
    Documentation: `domain_attrs table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-domain-attrs>`_
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


class Dispatcher(object):
    """
    Schema for dispatcher table\n
    Documentation: `dispatcher table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dispatcher>`_
    """

    DST_ALG = {
        'ROUND_ROBIN': 4,
        'PRIORITY_BASED': 8,
        'WEIGHT_BASED': 9,
        'LOAD_DISTRIBUTION': 10,
        'RELATIVE_WEIGHT': 11,
        'PARALLEL_FORKING': 12
    }
    FLAGS = {
        'INACTIVE_DST': 1,
        'TRYING_DST': 2,
        'DISABLED_DST': 4,
        'KEEP_ALIVE': 8,
        'SKIP_DNS': 16
    }

    # TODO: setting attrs directly will be removed in the future and each possible attribute identified
    def __init__(self, setid, destination, flags=None, priority=None, attrs=None, rweight=0, signalling='proxy', media='proxy',
                 name=None, gwid=None):
        self.setid = setid
        self.destination = safeFormatSipUri(destination)
        self.flags = flags
        self.priority = priority
        if attrs is not None:
            self.attrs = attrs
        else:
            self.attrs = Dispatcher.buildAttrs(rweight, signalling, media)
        self.description = Dispatcher.buildDescription(name, gwid)

    @staticmethod
    def buildAttrs(rweight=0, signalling='proxy', media='proxy'):
        attrs = {'signalling': signalling, 'media': media, 'rweight': str(rweight)}
        return dictToStrFields(attrs, delims=(';', '='))

    @staticmethod
    def buildDescription(name=None, gwid=None):
        description = {}
        if name is not None:
            description['name'] = name
        if gwid is not None:
            description['gwid'] = str(gwid)
        return dictToStrFields(description, delims=(';', '='))

    def attrsToDict(self):
        attrs = {}
        for attr in self.attrs.split(';'):
            attr = attr.split('=', maxsplit=1)
            if len(attr) != 2 or attr[1] == '':
                continue
            if attr[1].isnumeric():
                attrs[attr[0]] = int(attr[1])
            else:
                attrs[attr[0]] = attr[1]
        return attrs


# TODO: create class for dsip_settings table

class dSIPUser(object):
    """
    Schema for the dSIPROuter User table
    """

    def __init__(self, firstname, lastname, username, password, roles, domains, token, token_expiration):
        self.firstname = firstname
        self.lastname = lastname
        self.username = username
        self.password = password
        self.roles = roles
        self.domains = domains
        self.token = token
        self.token_expiration = token_expiration

    pass


# TODO: this is temporary and will be refactored
class DsipGwgroup2LB(object):
    pass

class DsipSettings(OrderedDict):
    """
    Identifies the contained data as already formatted for the table
    """
    pass


# TODO: switch to sqlalchemy.engine.URL API
def createDBURI(db_driver=None, db_type=None, db_user=None, db_pass=None, db_host=None, db_port=None, db_name=None, db_charset='utf8mb4'):
    """
    Get any and all DB Connection URI's
    Facilitates HA DB Server connections through multiple host's defined in settings
    :return:    list of DB URI connection strings
    """
    uri_list = []

    # URI is built from the following by order of precedence:
    # 1: function arguments
    # 2: environment variables (debug mode only)
    # 3: settings file
    if db_driver is None:
        db_driver = os.getenv('KAM_DB_DRIVER', settings.KAM_DB_DRIVER) if settings.DEBUG else settings.KAM_DB_DRIVER
    if db_type is None:
        db_type = os.getenv('KAM_DB_TYPE', settings.KAM_DB_TYPE) if settings.DEBUG else settings.KAM_DB_TYPE
    if db_user is None:
        db_user = os.getenv('KAM_DB_USER', settings.KAM_DB_USER) if settings.DEBUG else settings.KAM_DB_USER
    if db_pass is None:
        db_pass = os.getenv('KAM_DB_PASS', settings.KAM_DB_PASS) if settings.DEBUG else settings.KAM_DB_PASS
    if db_host is None:
        db_host = os.getenv('KAM_DB_HOST', settings.KAM_DB_HOST) if settings.DEBUG else settings.KAM_DB_HOST
    if db_port is None:
        db_port = os.getenv('KAM_DB_PORT', settings.KAM_DB_PORT) if settings.DEBUG else settings.KAM_DB_PORT
    if db_name is None:
        db_name = os.getenv('KAM_DB_NAME', settings.KAM_DB_NAME) if settings.DEBUG else settings.KAM_DB_NAME

    # need to decrypt password
    if isinstance(db_pass, bytes):
        db_pass = AES_CTR.decrypt(db_pass)
    # formatting for driver
    if len(db_driver) > 0:
        db_driver = '+{}'.format(db_driver)
    # string template
    db_uri_str = db_type + db_driver + "://" + db_user + ":" + db_pass + "@" + "{host}" + ":" + db_port + "/" + db_name + "?charset=" + db_charset
    # for cluster of DB add all hosts
    if isinstance(db_host, list):
        for host in db_host:
            uri_list.append(db_uri_str.format(host=host))
    else:
        uri_list.append(db_uri_str.format(host=db_host))

    if settings.DEBUG:
        IO.printdbg('createDBURI() returned: [{}]'.format(','.join('"{0}"'.format(uri) for uri in uri_list)))

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

    # globals from the top-level module
    caller_globals = dict(inspect.getmembers(inspect.stack()[-1][0]))["f_globals"]

    if DB_ENGINE_NAME in caller_globals:
        return caller_globals[DB_ENGINE_NAME]

    errors = []

    for conn_uri in uri_list:
        try:
            db_engine = create_engine(conn_uri,
                echo=settings.DEBUG,
                echo_pool=settings.DEBUG,
                pool_recycle=300,
                pool_size=10,
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


def startSession():
    """
    This method uses a singleton pattern to grab the global session loader and start a session
    """

    # globals from the top-level module
    caller_globals = dict(inspect.getmembers(inspect.stack()[-1][0]))["f_globals"]

    if SESSION_LOADER_NAME in caller_globals:
        return caller_globals[SESSION_LOADER_NAME]()

    db_engine, session_loader = createSessionObjects()
    return session_loader()


def createSessionObjects():
    """
    Create the DB engine and session factory

    :return:    Session factory and DB Engine
    :rtype:     (:class:`sqlalchemy.orm.Session`,:class:`sqlalchemy.engine.Engine`)
    """

    db_engine = createValidEngine(createDBURI())

    mapper = registry(metadata=MetaData(schema=db_engine.url.database))

    dr_gateways = Table('dr_gateways', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    address = Table('address', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    outboundroutes = Table('dr_rules', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    inboundmapping = Table('dr_rules', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    subscriber = Table('subscriber', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_domain_mapping = Table('dsip_domain_mapping', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_multidomain_mapping = Table('dsip_multidomain_mapping', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    # fusionpbx_mappings = Table('dsip_fusionpbx_mappings', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_lcr = Table('dsip_lcr', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    uacreg = Table('uacreg', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dr_gw_lists = Table('dr_gw_lists', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    # dr_groups = Table('dr_groups', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    domain = Table('domain', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    domain_attrs = Table('domain_attrs', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dispatcher = Table('dispatcher', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_endpoint_lease = Table('dsip_endpoint_lease', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_maintmode = Table('dsip_maintmode', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_call_settings = Table('dsip_call_settings', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_notification = Table('dsip_notification', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_hardfwd = Table('dsip_hardfwd', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_failfwd = Table('dsip_failfwd', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_cdrinfo = Table('dsip_cdrinfo', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_certificates = Table('dsip_certificates', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_dnid_enrichment = Table('dsip_dnid_enrich_lnp', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_user = Table('dsip_user', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    # TODO: this is temporary and will be refactored
    dsip_gwgroup2lb = Table('dsip_gwgroup2lb', mapper.metadata, autoload_replace=True, autoload_with=db_engine)

    # dr_gw_lists_alias = select([
    #     dr_gw_lists.c.id.label("drlist_id"),
    #     dr_gw_lists.c.gwlist,
    #     dr_gw_lists.c.description.label("drlist_description"),
    # ]).correlate(None).alias()
    # gw_join = join(dr_gw_lists_alias, dr_groups,
    #                dr_gw_lists_alias.c.drlist_id == dr_groups.c.id,
    #                dr_gw_lists_alias.c.drlist_description == dr_groups.c.description)

    mapper.map_imperatively(Gateways, dr_gateways)
    mapper.map_imperatively(Address, address)
    mapper.map_imperatively(InboundMapping, inboundmapping)
    mapper.map_imperatively(OutboundRoutes, outboundroutes)
    mapper.map_imperatively(dSIPDomainMapping, dsip_domain_mapping)
    mapper.map_imperatively(dSIPMultiDomainMapping, dsip_multidomain_mapping)
    mapper.map_imperatively(Subscribers, subscriber)
    # mapper.map_imperatively(CustomRouting, customrouting)
    mapper.map_imperatively(dSIPLCR, dsip_lcr)
    mapper.map_imperatively(UAC, uacreg)
    mapper.map_imperatively(GatewayGroups, dr_gw_lists)
    mapper.map_imperatively(Domain, domain)
    mapper.map_imperatively(DomainAttrs, domain_attrs)
    mapper.map_imperatively(Dispatcher, dispatcher)
    mapper.map_imperatively(dSIPLeases, dsip_endpoint_lease)
    mapper.map_imperatively(dSIPMaintModes, dsip_maintmode)
    mapper.map_imperatively(dSIPCallSettings, dsip_call_settings)
    mapper.map_imperatively(dSIPNotification, dsip_notification)
    mapper.map_imperatively(dSIPHardFwd, dsip_hardfwd)
    mapper.map_imperatively(dSIPFailFwd, dsip_failfwd)
    mapper.map_imperatively(dSIPCDRInfo, dsip_cdrinfo)
    mapper.map_imperatively(dSIPCertificates, dsip_certificates)
    mapper.map_imperatively(dSIPDNIDEnrichment, dsip_dnid_enrichment)
    mapper.map_imperatively(dSIPUser, dsip_user)
    # TODO: this is temporary and will be refactored
    mapper.map_imperatively(DsipGwgroup2LB, dsip_gwgroup2lb)

    # mapper.map_imperatively(GatewayGroups, gw_join, properties={
    #     'id': [dr_groups.c.id, dr_gw_lists_alias.c.drlist_id],
    #     'description': [dr_groups.c.description, dr_gw_lists_alias.c.drlist_description],
    # })

    session_loader = scoped_session(sessionmaker(bind=db_engine))

    # load them into the top level module global namespace
    caller_globals = dict(inspect.getmembers(inspect.stack()[-1][0]))["f_globals"]
    caller_globals[DB_ENGINE_NAME] = db_engine
    caller_globals[SESSION_LOADER_NAME] = session_loader

    # return references for the calling function
    return caller_globals[DB_ENGINE_NAME], caller_globals[SESSION_LOADER_NAME]


# TODO: change to the global define pattern instead of instantiating dummy objects
class DummySession():
    """
    Sole purpose is to avoid exceptions when startSession fails
    This allows us to handle exceptions later in the try blocks
    We also avoid exceptions in the except blocks by using dummy sesh
    """

    @staticmethod
    def __contains__(self, *args, **kwargs):
        pass

    def __iter__(self, *args, **kwargs):
        pass

    def add(self, *args, **kwargs):
        pass

    def add_all(self, *args, **kwargs):
        pass

    def begin(self, *args, **kwargs):
        pass

    def begin_nested(self, *args, **kwargs):
        pass

    def close(self, *args, **kwargs):
        pass

    def commit(self, *args, **kwargs):
        pass

    def connection(self, *args, **kwargs):
        pass

    def delete(self, *args, **kwargs):
        pass

    def execute(self, *args, **kwargs):
        pass

    def expire(self, *args, **kwargs):
        pass

    def expire_all(self, *args, **kwargs):
        pass

    def expunge(self, *args, **kwargs):
        pass

    def expunge_all(self, *args, **kwargs):
        pass

    def flush(self, *args, **kwargs):
        pass

    def get_bind(self, *args, **kwargs):
        pass

    def is_modified(self, *args, **kwargs):
        pass

    def bulk_save_objects(self, *args, **kwargs):
        pass

    def bulk_insert_mappings(self, *args, **kwargs):
        pass

    def bulk_update_mappings(self, *args, **kwargs):
        pass

    def merge(self, *args, **kwargs):
        pass

    def query(self, *args, **kwargs):
        pass

    def refresh(self, *args, **kwargs):
        pass

    def rollback(self, *args, **kwargs):
        pass

    def scalar(self, *args, **kwargs):
        pass

    def remove(self, *args, **kwargs):
        pass

    def configure(self, *args, **kwargs):
        pass

    def query_property(self, *args, **kwargs):
        pass


def settingsToTableFormat(settings, updates=None):
    data = objToDict(settings)
    if updates is not None:
        data.update(updates)

    # translate db specific fields
    if isinstance(data['KAM_DB_HOST'], (list, tuple)):
        data['KAM_DB_HOST'] = ','.join(data['KAM_DB_HOST'])
    data['DSIP_LICENSE_STORE'] = base64.b64encode(bson.dumps(data['DSIP_LICENSE_STORE']))

    # order matters here, as this is used to update table settings as well
    return DsipSettings([
        ('DSIP_ID', data['DSIP_ID']),
        ('DSIP_CLUSTER_ID', data['DSIP_CLUSTER_ID']),
        ('DSIP_CLUSTER_SYNC', data['DSIP_CLUSTER_SYNC']),
        ('DSIP_PROTO', data['DSIP_PROTO']),
        ('DSIP_PORT', data['DSIP_PORT']),
        ('DSIP_USERNAME', data['DSIP_USERNAME']),
        ('DSIP_PASSWORD', data['DSIP_PASSWORD']),
        ('DSIP_IPC_PASS', data['DSIP_IPC_PASS']),
        ('DSIP_API_PROTO', data['DSIP_API_PROTO']),
        ('DSIP_API_PORT', data['DSIP_API_PORT']),
        ('DSIP_PRIV_KEY', data['DSIP_PRIV_KEY']),
        ('DSIP_PID_FILE', data['DSIP_PID_FILE']),
        ('DSIP_UNIX_SOCK', data['DSIP_UNIX_SOCK']),
        ('DSIP_IPC_SOCK', data['DSIP_IPC_SOCK']),
        ('DSIP_API_TOKEN', data['DSIP_API_TOKEN']),
        ('DSIP_LOG_LEVEL', data['DSIP_LOG_LEVEL']),
        ('DSIP_LOG_FACILITY', data['DSIP_LOG_FACILITY']),
        ('DSIP_SSL_KEY', data['DSIP_SSL_KEY']),
        ('DSIP_SSL_CERT', data['DSIP_SSL_CERT']),
        ('DSIP_SSL_CA', data['DSIP_SSL_CA']),
        ('DSIP_SSL_EMAIL', data['DSIP_SSL_EMAIL']),
        ('DSIP_CERTS_DIR', data['DSIP_CERTS_DIR']),
        ('VERSION', data['VERSION']),
        ('DEBUG', data['DEBUG']),
        ('ROLE', data['ROLE']),
        ('GUI_INACTIVE_TIMEOUT', data['GUI_INACTIVE_TIMEOUT']),
        ('KAM_DB_HOST', data['KAM_DB_HOST']),
        ('KAM_DB_DRIVER', data['KAM_DB_DRIVER']),
        ('KAM_DB_TYPE', data['KAM_DB_TYPE']),
        ('KAM_DB_PORT', data['KAM_DB_PORT']),
        ('KAM_DB_NAME', data['KAM_DB_NAME']),
        ('KAM_DB_USER', data['KAM_DB_USER']),
        ('KAM_DB_PASS', data['KAM_DB_PASS']),
        ('KAM_KAMCMD_PATH', data['KAM_KAMCMD_PATH']),
        ('KAM_CFG_PATH', data['KAM_CFG_PATH']),
        ('KAM_TLSCFG_PATH', data['KAM_TLSCFG_PATH']),
        ('RTP_CFG_PATH', data['RTP_CFG_PATH']),
        ('FLT_CARRIER', data['FLT_CARRIER']),
        ('FLT_PBX', data['FLT_PBX']),
        ('FLT_MSTEAMS', data['FLT_MSTEAMS']),
        ('FLT_OUTBOUND', data['FLT_OUTBOUND']),
        ('FLT_INBOUND', data['FLT_INBOUND']),
        ('FLT_LCR_MIN', data['FLT_LCR_MIN']),
        ('FLT_FWD_MIN', data['FLT_FWD_MIN']),
        ('DEFAULT_AUTH_DOMAIN', data['DEFAULT_AUTH_DOMAIN']),
        ('TELEBLOCK_GW_ENABLED', data['TELEBLOCK_GW_ENABLED']),
        ('TELEBLOCK_GW_IP', data['TELEBLOCK_GW_IP']),
        ('TELEBLOCK_GW_PORT', data['TELEBLOCK_GW_PORT']),
        ('TELEBLOCK_MEDIA_IP', data['TELEBLOCK_MEDIA_IP']),
        ('TELEBLOCK_MEDIA_PORT', data['TELEBLOCK_MEDIA_PORT']),
        ('FLOWROUTE_ACCESS_KEY', data['FLOWROUTE_ACCESS_KEY']),
        ('FLOWROUTE_SECRET_KEY', data['FLOWROUTE_SECRET_KEY']),
        ('FLOWROUTE_API_ROOT_URL', data['FLOWROUTE_API_ROOT_URL']),
        ('HOMER_ID', data['HOMER_ID']),
        ('HOMER_HEP_HOST', data['HOMER_HEP_HOST']),
        ('HOMER_HEP_PORT', data['HOMER_HEP_PORT']),
        ('NETWORK_MODE', data['NETWORK_MODE']),
        ('IPV6_ENABLED', data['IPV6_ENABLED']),
        ('INTERNAL_IP_ADDR', data['INTERNAL_IP_ADDR']),
        ('INTERNAL_IP_NET', data['INTERNAL_IP_NET']),
        ('INTERNAL_IP6_ADDR', data['INTERNAL_IP6_ADDR']),
        ('INTERNAL_IP6_NET', data['INTERNAL_IP6_NET']),
        ('INTERNAL_FQDN', data['INTERNAL_FQDN']),
        ('EXTERNAL_IP_ADDR', data['EXTERNAL_IP_ADDR']),
        ('EXTERNAL_IP6_ADDR', data['EXTERNAL_IP6_ADDR']),
        ('EXTERNAL_FQDN', data['EXTERNAL_FQDN']),
        ('PUBLIC_IFACE', data['PUBLIC_IFACE']),
        ('PRIVATE_IFACE', data['PRIVATE_IFACE']),
        ('UPLOAD_FOLDER', data['UPLOAD_FOLDER']),
        ('MAIL_SERVER', data['MAIL_SERVER']),
        ('MAIL_PORT', data['MAIL_PORT']),
        ('MAIL_USE_TLS', data['MAIL_USE_TLS']),
        ('MAIL_USERNAME', data['MAIL_USERNAME']),
        ('MAIL_PASSWORD', data['MAIL_PASSWORD']),
        ('MAIL_ASCII_ATTACHMENTS', data['MAIL_ASCII_ATTACHMENTS']),
        ('MAIL_DEFAULT_SENDER', data['MAIL_DEFAULT_SENDER']),
        ('MAIL_DEFAULT_SUBJECT', data['MAIL_DEFAULT_SUBJECT']),
        ('DSIP_LICENSE_STORE', data['DSIP_LICENSE_STORE']),
        ('RTPENGINE_URI', data['RTPENGINE_URI']),
    ])


def settingsTableToDict(table_values, updates=None):
    if updates is not None:
        table_values.update(updates)

    if ',' in table_values['KAM_DB_HOST']:
        table_values['KAM_DB_HOST'] = table_values['KAM_DB_HOST'].split(',')
    table_values['DSIP_LICENSE_STORE'] = bson.loads(base64.b64decode(table_values['DSIP_LICENSE_STORE']))
    return table_values


def updateDsipSettingsTable(fields):
    """
    Update the dsip_settings table using our stored procedure

    :param fields:  columns/values to update
    :type fields:   dict
    :return:        None
    :rtype:         None
    :raises:        sql_exceptions.SQLAlchemyError
    """

    db = DummySession()
    try:
        if isinstance(fields, DsipSettings):
            db_fields = fields
        else:
            db_fields = settingsToTableFormat(settings, updates=fields)
        field_mapping = ', '.join([':{}'.format(x, x) for x in db_fields.keys()])

        db = startSession()
        db.execute(
            text('CALL update_dsip_settings({})'.format(field_mapping)),
            params=db_fields
        )
        db.commit()
    except sql_exceptions.SQLAlchemyError:
        db.rollback()
        db.flush()
        raise
    finally:
        db.close()


def getDsipSettingsTableAsDict(dsip_id, updates=None):
    db = DummySession()
    try:
        db = startSession()
        data = rowToDict(
            db.execute(
                text('SELECT * FROM dsip_settings WHERE DSIP_ID=:dsip_id'),
                params={'dsip_id': dsip_id}
            ).first()
        )
        # translate db specific fields
        return settingsTableToDict(data, updates=updates)
    except sql_exceptions.SQLAlchemyError:
        raise
    finally:
        db.close()
