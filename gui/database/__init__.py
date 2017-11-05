from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine, MetaData, Table,Column,String
from sqlalchemy.orm import mapper, sessionmaker
import settings

class Gateways(object):
    def __init__(self,name,ip_addr,strip,prefix,type):
        self.description="name:" + name 
        self.address=ip_addr
        self.strip=strip
        self.pri_prefix=prefix
        self.type=type            
    pass

class Address(object):
    def __init__(self,name,ip_addr,mask,type):
       self.tag="name:" + name
       self.ip_addr=ip_addr
       self.mask=mask
       self.grp=type
    pass

class InboundMapping(object):
    gwname = Column(String)
    
    def __init__(self,groupid,prefix,gateway):
       self.groupid=groupid
       self.prefix=prefix
       self.gwlist=gateway
       self.timerec=''
       self.routeid=''
    pass

class OutboundRoutes(object):
    pass

class dSIPFusionPBXDB(object):
    def __init__(self,pbx_id,db_ip,db_username,db_password,db_enabled):
        self.pbx_id=pbx_id
        self.db_ip=db_ip
        self.db_username=db_username
        self.db_password=db_password
        self.enabled=db_enabled
    pass

class dSIPFusionPBXMapping(object):
    def __init__(self,pbx_id,domain,excluded):
        self.pbx_id=pbx_id
        self.domain=domain
        self.excluded=excluded
    pass


def getDBURI():
#Define the database URI
    if settings.KAM_DB_TYPE != "":
        sql_uri=settings.KAM_DB_TYPE + "://" + settings.KAM_DB_USER + ":" + settings.KAM_DB_PASS + "@" + settings.KAM_DB_HOST + "/" + settings.KAM_DB_NAME
        print(sql_uri)
        return sql_uri
    else:
       return None

#Make the engine global
engine = create_engine(getDBURI(), echo=True, pool_recycle=10)

def loadSession():
    metadata = MetaData(engine)
    dr_gateways = Table('dr_gateways', metadata, autoload=True)
    address = Table('address', metadata, autoload=True)
    outboundroutes = Table('dr_rules', metadata, autoload=True)
    inboundmapping = Table('dr_rules', metadata, autoload=True)
    fusionpbx_mappings = Table('dsip_fusionpbx_mappings', metadata, autoload=True)
    fusionpbx_db = Table('dsip_fusionpbx_db', metadata, autoload=True)
    mapper(Gateways, dr_gateways)
    mapper(Address, address)
    mapper(InboundMapping, inboundmapping)
    mapper(OutboundRoutes, outboundroutes)
    mapper(dSIPFusionPBXMapping,fusionpbx_mappings)
    mapper(dSIPFusionPBXDB,fusionpbx_db)

    Session = sessionmaker(bind=engine)
    session = Session()
    
    return session
