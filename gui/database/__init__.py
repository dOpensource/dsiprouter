from enum import Enum
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine, MetaData, Table, Column, String, join, Integer, ForeignKey, select
from sqlalchemy.orm import mapper, sessionmaker
import settings


class Gateways(object):
    """
    Schema for dr_gateways table\n
    Documentation: `dr_gateways table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-dr-gateways>`_
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
    Documentation: `dr_gw_lists table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-dr-gw-lists>`_
    """

    def __init__(self, name, gwlist=[]):
        self.description = "name:" + name
        self.gwlist = ",".join(str(gw) for gw in gwlist)

    pass


class Address(object):
    """
    Schema for address table\n
    Documentation: `address table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-address>`_
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
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-dr-rules>`_
    """

    gwname = Column(String)

    def __init__(self, groupid, prefix, gateway):
        self.groupid = groupid
        self.prefix = prefix
        self.gwlist = gateway
        self.timerec = ''
        self.routeid = ''

    pass


class OutboundRoutes(object):
    """
    Schema for dr_rules table\n
    Documentation: `dr_rules table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-dr-rules>`_
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
    The pattern field contains a complex key that includes FROM XNPA and TO NPA\n
    There the pattern field looks like this XNPA-NPA\n
    The dr_groupid field contains a dynamic routing group that maps to a gateway\n
    """

    def __init__(self, pattern, from_prefix, dr_groupid, cost=0.00):
        self.pattern = pattern
        self.from_prefix = from_prefix
        self.dr_groupid = dr_groupid
        self.cost = cost

    pass


class dSIPFusionPBXDB(object):
    def __init__(self, pbx_id, db_ip, db_username, db_password, db_enabled):
        self.pbx_id = pbx_id
        self.db_ip = db_ip
        self.db_username = db_username
        self.db_password = db_password
        self.enabled = db_enabled

    pass


class dSIPFusionPBXMapping(object):
    def __init__(self, pbx_id, domain, excluded):
        self.pbx_id = pbx_id
        self.domain = domain
        self.excluded = excluded

    pass


class Subscribers(object):
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
    Documentation: `uacreg table <https://kamailio.org/docs/db-tables/kamailio-db-4.4.x.html#gen-db-uacreg>`_
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


def getDBURI():
    # Define the database URI
    if settings.KAM_DB_TYPE != "":
        sql_uri = settings.KAM_DB_TYPE + "://" + settings.KAM_DB_USER + ":" + settings.KAM_DB_PASS + "@" + settings.KAM_DB_HOST + "/" + settings.KAM_DB_NAME
        print(sql_uri)
        return sql_uri
    else:
        return None


# Make the engine global
engine = create_engine(getDBURI(), echo=True, pool_recycle=10,isolation_level="READ UNCOMMITTED")


def loadSession():
    metadata = MetaData(engine)

    dr_gateways = Table('dr_gateways', metadata, autoload=True)
    address = Table('address', metadata, autoload=True)
    outboundroutes = Table('dr_rules', metadata, autoload=True)
    inboundmapping = Table('dr_rules', metadata, autoload=True)
    subscriber = Table('subscriber', metadata, autoload=True)
    #fusionpbx_mappings = Table('dsip_fusionpbx_mappings', metadata, autoload=True)
    fusionpbx_db = Table('dsip_fusionpbx_db', metadata, autoload=True)
    dsip_lcr  = Table('dsip_lcr', metadata, autoload=True)
    uacreg = Table('uacreg', metadata, autoload=True)
    dr_gw_lists = Table('dr_gw_lists', metadata, autoload=True)
    # dr_groups = Table('dr_groups', metadata, autoload=True)

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
    #mapper(dSIPFusionPBXMapping,fusionpbx_mappings)
    mapper(dSIPFusionPBXDB, fusionpbx_db)
    mapper(Subscribers, subscriber)
    #mapper(CustomRouting, customrouting)
    mapper(dSIPLCR, dsip_lcr)
    mapper(UAC, uacreg)
    # mapper(GatewayGroups, gw_join, properties={
    #     'id': [dr_groups.c.id, dr_gw_lists_alias.c.drlist_id],
    #     'description': [dr_groups.c.description, dr_gw_lists_alias.c.drlist_description],
    # })
    mapper(GatewayGroups, dr_gw_lists)

    Session = sessionmaker(bind=engine)
    session = Session()

    return session
