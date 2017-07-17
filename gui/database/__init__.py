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



def loadSession(db_uri):
    engine = create_engine(db_uri, echo=True, pool_recycle=3600)
    metadata = MetaData(engine)
    dr_gateways = Table('dr_gateways', metadata, autoload=True)
    address = Table('address', metadata, autoload=True)
    outboundroutes = Table('dr_rules', metadata, autoload=True)
    inboundmapping = Table('dr_rules', metadata, autoload=True)
    mapper(Gateways, dr_gateways)
    mapper(Address, address)
    mapper(InboundMapping, inboundmapping)
    mapper(OutboundRoutes, outboundroutes)

    Session = sessionmaker(bind=engine)
    session = Session()
    return session

#Define the database URI
if settings.KAM_DB_TYPE != "":
    sql_uri=settings.KAM_DB_TYPE + "://" + settings.KAM_DB_USER + ":" + settings.KAM_DB_PASS + "@" + settings.KAM_DB_HOST + "/" + settings.KAM_DB_NAME
    #flask_app.config['SQLALCHEMY_DATABASE_URI'] = sql_uri
    #flask_app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = settings.SQLALCHEMY_TRACK_MODIFICATIONS
    print(sql_uri)
else:
    print("Please set KAM_DB_TYPE to the type of database you are using.  The values could be mysql, postgresql or oracle.  Also make sure the credentials are specified in the settings file")
    os._exit(1)

db = loadSession(sql_uri)
