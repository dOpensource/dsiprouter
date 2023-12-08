# make sure the generated source files are imported instead of the template ones
import sys

import sqlalchemy.engine

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import os, inspect
from collections import OrderedDict
from enum import Enum
from datetime import datetime, timedelta
from sqlalchemy import create_engine, MetaData, Table, Column, String, exc as sql_exceptions
from sqlalchemy.orm import registry, sessionmaker, scoped_session
from sqlalchemy.sql import text
import settings
from shared import IO, debugException, dictToStrFields, rowToDict
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

DB_ENGINE_NAME = 'global_db_engine'
SESSION_LOADER_NAME = 'global_session_loader'


class Gateways(object):
    """
    Schema for dr_gateways table\n
    Documentation: `dr_gateways table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-gateways>`_\n
    Allowed address types: SIP URI, IP address or DNS domain name\n
    The address field can be a full SIP URI, partial URI, or only host; where host portion is an IP or FQDN
    """

    def __init__(self, name, address, strip, prefix, type, gwgroup=None, addr_id=None, attrs=''):
        description = {"name": name}
        if gwgroup is not None:
            description["gwgroup"] = str(gwgroup)
        if addr_id is not None:
            description['addr_id'] = str(addr_id)

        self.type = type
        self.address = address
        self.strip = strip
        self.pri_prefix = prefix
        self.attrs = attrs
        self.description = dictToStrFields(description)

    pass


class GatewayGroups(object):
    """
    Schema for dr_gw_lists table\n
    Documentation: `dr_gw_lists table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-dr-gw-lists>`_
    """

    def __init__(self, name, gwlist=[], type=settings.FLT_CARRIER):
        self.description = "name:{},type:{}".format(name, type)
        self.gwlist = ",".join(str(gw) for gw in gwlist)

    pass


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
    Documentation: `domain table <https://kamailio.org/docs/db-tables/kamailio-db-5.5.x.html#gen-db-domain>`_
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

    def __init__(self, setid, destination, flags=None, priority=None, attrs=None, description=''):
        self.setid = setid
        self.destination = safeFormatSipUri(destination)
        self.flags = flags
        self.priority = priority
        self.attrs = attrs
        self.description = description

    pass


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


class DsipSettings(OrderedDict):
    """
    Identifies the contained data as already formatted for the table
    """
    pass


# TODO: switch to from sqlalchemy.engine.URL API
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
            caller_globals[DB_ENGINE_NAME] = db_engine
            return caller_globals[DB_ENGINE_NAME]
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
    dsip_calllimit = Table('dsip_calllimit', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_notification = Table('dsip_notification', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_hardfwd = Table('dsip_hardfwd', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_failfwd = Table('dsip_failfwd', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_cdrinfo = Table('dsip_cdrinfo', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_certificates = Table('dsip_certificates', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_dnid_enrichment = Table('dsip_dnid_enrich_lnp', mapper.metadata, autoload_replace=True, autoload_with=db_engine)
    dsip_user = Table('dsip_user', mapper.metadata, autoload_replace=True, autoload_with=db_engine)

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
    mapper.map_imperatively(dSIPCallLimits, dsip_calllimit)
    mapper.map_imperatively(dSIPNotification, dsip_notification)
    mapper.map_imperatively(dSIPHardFwd, dsip_hardfwd)
    mapper.map_imperatively(dSIPFailFwd, dsip_failfwd)
    mapper.map_imperatively(dSIPCDRInfo, dsip_cdrinfo)
    mapper.map_imperatively(dSIPCertificates, dsip_certificates)
    mapper.map_imperatively(dSIPDNIDEnrichment, dsip_dnid_enrichment)
    mapper.map_imperatively(dSIPUser, dsip_user)

    # mapper.map_imperatively(GatewayGroups, gw_join, properties={
    #     'id': [dr_groups.c.id, dr_gw_lists_alias.c.drlist_id],
    #     'description': [dr_groups.c.description, dr_gw_lists_alias.c.drlist_description],
    # })

    session_loader = scoped_session(sessionmaker(bind=db_engine))
    return db_engine, session_loader


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


def settingsToTableFormat(settings):
    # convert db specific fields
    if isinstance(settings.KAM_DB_HOST, (list, tuple)):
        kam_db_host = ','.join(settings.KAM_DB_HOST)
    else:
        kam_db_host = settings.KAM_DB_HOST

    # order matters here, as this is used to update table settings as well
    return DsipSettings([
        ('DSIP_ID', settings.DSIP_ID),
        ('DSIP_CLUSTER_ID', settings.DSIP_CLUSTER_ID),
        ('DSIP_CLUSTER_SYNC', settings.DSIP_CLUSTER_SYNC),
        ('DSIP_PROTO', settings.DSIP_PROTO),
        ('DSIP_PORT', settings.DSIP_PORT),
        ('DSIP_USERNAME', settings.DSIP_USERNAME),
        ('DSIP_PASSWORD', settings.DSIP_PASSWORD),
        ('DSIP_IPC_PASS', settings.DSIP_IPC_PASS),
        ('DSIP_API_PROTO', settings.DSIP_API_PROTO),
        ('DSIP_API_PORT', settings.DSIP_API_PORT),
        ('DSIP_PRIV_KEY', settings.DSIP_PRIV_KEY),
        ('DSIP_PID_FILE', settings.DSIP_PID_FILE),
        ('DSIP_UNIX_SOCK', settings.DSIP_UNIX_SOCK),
        ('DSIP_IPC_SOCK', settings.DSIP_IPC_SOCK),
        ('DSIP_API_TOKEN', settings.DSIP_API_TOKEN),
        ('DSIP_LOG_LEVEL', settings.DSIP_LOG_LEVEL),
        ('DSIP_LOG_FACILITY', settings.DSIP_LOG_FACILITY),
        ('DSIP_SSL_KEY', settings.DSIP_SSL_KEY),
        ('DSIP_SSL_CERT', settings.DSIP_SSL_CERT),
        ('DSIP_SSL_CA', settings.DSIP_SSL_CA),
        ('DSIP_SSL_EMAIL', settings.DSIP_SSL_EMAIL),
        ('DSIP_CERTS_DIR', settings.DSIP_CERTS_DIR),
        ('VERSION', settings.VERSION),
        ('DEBUG', settings.DEBUG),
        ('ROLE', settings.ROLE),
        ('GUI_INACTIVE_TIMEOUT', settings.GUI_INACTIVE_TIMEOUT),
        ('KAM_DB_HOST', kam_db_host),
        ('KAM_DB_DRIVER', settings.KAM_DB_DRIVER),
        ('KAM_DB_TYPE', settings.KAM_DB_TYPE),
        ('KAM_DB_PORT', settings.KAM_DB_PORT),
        ('KAM_DB_NAME', settings.KAM_DB_NAME),
        ('KAM_DB_USER', settings.KAM_DB_USER),
        ('KAM_DB_PASS', settings.KAM_DB_PASS),
        ('KAM_KAMCMD_PATH', settings.KAM_KAMCMD_PATH),
        ('KAM_CFG_PATH', settings.KAM_CFG_PATH),
        ('KAM_TLSCFG_PATH', settings.KAM_TLSCFG_PATH),
        ('RTP_CFG_PATH', settings.RTP_CFG_PATH),
        ('FLT_CARRIER', settings.FLT_CARRIER),
        ('FLT_PBX', settings.FLT_PBX),
        ('FLT_MSTEAMS', settings.FLT_MSTEAMS),
        ('FLT_OUTBOUND', settings.FLT_OUTBOUND),
        ('FLT_INBOUND', settings.FLT_INBOUND),
        ('FLT_LCR_MIN', settings.FLT_LCR_MIN),
        ('FLT_FWD_MIN', settings.FLT_FWD_MIN),
        ('DEFAULT_AUTH_DOMAIN', settings.DEFAULT_AUTH_DOMAIN),
        ('TELEBLOCK_GW_ENABLED', settings.TELEBLOCK_GW_ENABLED),
        ('TELEBLOCK_GW_IP', settings.TELEBLOCK_GW_IP),
        ('TELEBLOCK_GW_PORT', settings.TELEBLOCK_GW_PORT),
        ('TELEBLOCK_MEDIA_IP', settings.TELEBLOCK_MEDIA_IP),
        ('TELEBLOCK_MEDIA_PORT', settings.TELEBLOCK_MEDIA_PORT),
        ('FLOWROUTE_ACCESS_KEY', settings.FLOWROUTE_ACCESS_KEY),
        ('FLOWROUTE_SECRET_KEY', settings.FLOWROUTE_SECRET_KEY),
        ('FLOWROUTE_API_ROOT_URL', settings.FLOWROUTE_API_ROOT_URL),
        ('HOMER_ID', settings.HOMER_ID),
        ('HOMER_HEP_HOST', settings.HOMER_HEP_HOST),
        ('HOMER_HEP_PORT', settings.HOMER_HEP_PORT),
        ('NETWORK_MODE', settings.NETWORK_MODE),
        ('IPV6_ENABLED', settings.IPV6_ENABLED),
        ('INTERNAL_IP_ADDR', settings.INTERNAL_IP_ADDR),
        ('INTERNAL_IP_NET', settings.INTERNAL_IP_NET),
        ('INTERNAL_IP6_ADDR', settings.INTERNAL_IP6_ADDR),
        ('INTERNAL_IP6_NET', settings.INTERNAL_IP6_NET),
        ('INTERNAL_FQDN', settings.INTERNAL_FQDN),
        ('EXTERNAL_IP_ADDR', settings.EXTERNAL_IP_ADDR),
        ('EXTERNAL_IP6_ADDR', settings.EXTERNAL_IP6_ADDR),
        ('EXTERNAL_FQDN', settings.EXTERNAL_FQDN),
        ('PUBLIC_IFACE', settings.PUBLIC_IFACE),
        ('PRIVATE_IFACE', settings.PRIVATE_IFACE),
        ('UPLOAD_FOLDER', settings.UPLOAD_FOLDER),
        ('MAIL_SERVER', settings.MAIL_SERVER),
        ('MAIL_PORT', settings.MAIL_PORT),
        ('MAIL_USE_TLS', settings.MAIL_USE_TLS),
        ('MAIL_USERNAME', settings.MAIL_USERNAME),
        ('MAIL_PASSWORD', settings.MAIL_PASSWORD),
        ('MAIL_ASCII_ATTACHMENTS', settings.MAIL_ASCII_ATTACHMENTS),
        ('MAIL_DEFAULT_SENDER', settings.MAIL_DEFAULT_SENDER),
        ('MAIL_DEFAULT_SUBJECT', settings.MAIL_DEFAULT_SUBJECT),
        ('DSIP_CORE_LICENSE', settings.DSIP_CORE_LICENSE),
        ('DSIP_STIRSHAKEN_LICENSE', settings.DSIP_STIRSHAKEN_LICENSE),
        ('DSIP_TRANSNEXUS_LICENSE', settings.DSIP_TRANSNEXUS_LICENSE),
        ('DSIP_MSTEAMS_LICENSE', settings.DSIP_MSTEAMS_LICENSE),
    ])


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
            db_fields = settingsToTableFormat(settings)
            db_fields.update(fields)
        field_mapping = ', '.join([':{}'.format(x, x) for x in db_fields.keys()])

        db = startSession()
        db.execute(
            text('CALL update_dsip_settings({})'.format(field_mapping)),
            db_fields
        )
        db.commit()
    except sql_exceptions.SQLAlchemyError:
        db.rollback()
        db.flush()
        raise
    finally:
        db.close()


def getDsipSettingsTableAsDict(dsip_id):
    db = DummySession()
    try:
        db = startSession()
        return rowToDict(
            db.execute(
                text('SELECT * FROM dsip_settings WHERE DSIP_ID=:dsip_id'),
                params={'dsip_id': dsip_id}
            ).first()
        )
    except sql_exceptions.SQLAlchemyError:
        raise
    finally:
        db.close()
