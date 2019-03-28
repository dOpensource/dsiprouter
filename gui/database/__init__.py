from enum import Enum
from datetime import datetime
from sqlalchemy import create_engine, MetaData, Table, Column, String, join, Integer, ForeignKey, select
from sqlalchemy.orm import mapper, sessionmaker
from sqlalchemy import exc as sql_exceptions
import settings
from shared import IO, debugException, hostToIP
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
                    debugException(ex, log_ex=False, print_ex=True, showstack=False)
                raise


class Gateways(object):
    """
    Schema for dr_gateways table\n
    Documentation: `dr_gateways table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-gateways>`_
    """

    def __init__(self, name, ip_addr, strip, prefix, type, gwgroup=None):
        self.description = "name:" + name
        if gwgroup is not None:
            self.description += ",gwgroup:" + gwgroup
        self.address = ip_addr
        self.strip = strip
        self.pri_prefix = prefix
        self.type = type
        self.attrs = ""

    pass


class GatewayGroups(object):
    """
    Schema for dr_gw_lists table\n
    Documentation: `dr_gw_lists table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-gw-lists>`_
    """

    def __init__(self, name, gwlist=[]):
        self.description = "name:" + name
        self.gwlist = ",".join(str(gw) for gw in gwlist)

    pass


class Address(object):
    """
    Schema for address table\n
    Documentation: `address table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-address>`_
    """

    def __init__(self, name, ip_addr, mask, type, gwgroup=None):
        self.tag = "name:" + name
        if gwgroup is not None:
            self.tag += ",gwgroup:" + gwgroup
        self.ip_addr = ip_addr
        self.mask = mask
        self.grp = type

    pass


class InboundMapping(object):
    """
    Partial Schema for modified version of dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-rules>`_
    """

    gwname = Column(String)

    def __init__(self, groupid, prefix, gwlist, notes=''):
        self.groupid = groupid
        self.prefix = prefix
        self.gwlist = gwlist
        self.description = notes
        self.timerec = ''
        self.routeid = ''

    pass


class OutboundRoutes(object):
    """
    Schema for dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dr-rules>`_
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

    def __init__(self, username, password, domain, gwid):
        self.username = username
        self.password = password
        self.domain = domain
        self.ha1 = ''
        self.ha1b = ''
        self.rpid = gwid

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

    def __init__(self, uuid, username="", password="", realm="", proxy="", local_domain="", remote_domain="", flags=0):
        self.l_uuid = uuid
        self.l_username = username
        self.l_domain = local_domain
        self.r_username = username
        self.r_domain = remote_domain
        self.realm = realm
        self.auth_username = username
        self.auth_password = password
        self.auth_ha1 = ""
        self.auth_proxy = proxy
        self.expires = 60
        self.flags = flags
        self.reg_delay = 0

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
        temp_value = value if value is not None else hostToIP(did)
        self.value = temp_value if temp_value is not None else did

    pass

class Dispatcher(object):
    """
    Schema for dispatcher table\n
    Documentation: `dispatcher table <https://kamailio.org/docs/db-tables/kamailio-db-5.1.x.html#gen-db-dispatcher>`_
    """


    def __init__(self, setid, destination, flags=None, priority=None, attrs=None, description=''):
        self.setid = setid
        self.destination = "sip:{}".format(destination)
        self.flags = flags
        self.priority = priority
        self.attrs = attrs
        self.description = description

    pass

def getDBURI():
    """
    Get any and all DB Connection URI's
    Facilitates HA DB Server connections through multiple host's defined in settings
    :return:    list of DB URI connection strings
    """
    uri_list = []

    if settings.KAM_DB_TYPE != "":
        sql_uri = settings.KAM_DB_TYPE + "{driver}" + "://" + settings.KAM_DB_USER + ":" + settings.KAM_DB_PASS + "@" + "{host}" + "/" + settings.KAM_DB_NAME

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
    :param uri_list:    list of connection uri's
    :return:            DB engine object
    :raise:             SQLAlchemyError if all connections fail
    """
    errors = []

    for conn_uri in uri_list:
        try:
            db_engine = create_engine(conn_uri, echo=True, pool_recycle=10, isolation_level="READ UNCOMMITTED",
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
            debugException(ex, log_ex=False, print_ex=True, showstack=False)

    try:
        raise sql_exceptions.SQLAlchemyError(errors)
    except:
        raise Exception(errors)

# TODO: we should be creating a queue of the valid db_engines
# from there we can perform round connections and more advanced clustering
# this does have the requirement of new session instancing per request

# Make the engine global
engine = createValidEngine(getDBURI())
session = None

def loadSession():
    global session
    
    # Return a DB session if one already exists
    if session:
        return session
    
    metadata = MetaData(engine)

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

    # dr_gw_lists_alias = select([
    #     dr_gw_lists.c.id.label("drlist_id"),
    #     dr_gw_lists.c.gwlist,
    #     dr_gw_lists.c.description.label("drlist_description"),
    # ]).correlate(None).alias()
    # gw_join = join(dr_gw_lists_alias, dr_groups,
    #                dr_gw_lists_alias.c.drlist_id == dr_groups.c.id,
    #                dr_gw_lists_alias.c.drlist_description == dr_groups.c.description)

    mapper(Gateways, dr_gateways)
    mapper(Address, address)
    mapper(InboundMapping, inboundmapping)
    mapper(OutboundRoutes, outboundroutes)
    mapper(dSIPDomainMapping, dsip_domain_mapping)
    mapper(dSIPMultiDomainMapping, dsip_multidomain_mapping)
    mapper(Subscribers, subscriber)
    # mapper(CustomRouting, customrouting)
    mapper(dSIPLCR, dsip_lcr)
    mapper(UAC, uacreg)
    mapper(GatewayGroups, dr_gw_lists)
    mapper(Domain, domain)
    mapper(DomainAttrs, domain_attrs)
    mapper(Dispatcher, dispatcher)

    # mapper(GatewayGroups, gw_join, properties={
    #     'id': [dr_groups.c.id, dr_gw_lists_alias.c.drlist_id],
    #     'description': [dr_groups.c.description, dr_gw_lists_alias.c.drlist_description],
    # })

    Session = sessionmaker(bind=engine)
    session = Session()

    return session

