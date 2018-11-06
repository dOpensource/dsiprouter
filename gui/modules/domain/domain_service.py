from database import loadSession, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, Gateways
from sqlalchemy import case, func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from shared import *

db = loadSession()


def getDomains():
    try:
        sql = "select domain.id,domain.domain,dsip_domain_mapping.type,dsip_domain_mapping.pbx_id,dr_gateways.description from domain left join dsip_domain_mapping on domain.id = dsip_domain_mapping.domain_id left join dr_gateways on dsip_domain_mapping.pbx_id = dr_gateways.gwid;"

        res = db.execute(sql);
        return res 

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False
        db.close()


def addDomainService(domain,authtype,pbx):
    try:
   	#Create the domain because we need the domain id
        PBXDomain = Domain(domain=domain, did=domain)
        db.add(PBXDomain)
        db.flush
        db.commit()

        # Serial folking will be used to forward registration info to multiple PBX's 
        PBXDomainAttr1 = DomainAttrs(did=domain, name='dispatcher_alg_reg',value="8")
        PBXDomainAttr2 = DomainAttrs(did=domain, name='dispatcher_alg_in',value="4")
        if len(pbx) > 1:
            #Create entry in dispatcher and set dispatcher_set_id in domain_attrs
            for p in pbx.split(','):
                dispatcher = Dispatcher(setid=PBXDomain.id,destination=gatewayIdToIP(p))
                db.add(dispatcher)
           
            PBXDomainAttr3 = DomainAttrs(did=domain, name='dispatcher_set_id',value=PBXDomain.id)
        else:
            #Store the pbx_host if this is a single PBX 
            PBXDomainAttr3 = DomainAttrs(did=domain, name='pbx_host',value=gatewayIdToIP(pbx))

        db.add(PBXDomainAttr1)
        db.add(PBXDomainAttr2)
        db.add(PBXDomainAttr3)
        db.flush()
        db.commit()

        #PBXMapping = dSIPDomainMapping(Gateway.gwid, PBXDomain.id, [PBXDomainAttr.id],
        #                                       enabled=dSIPDomainMapping.FLAGS.DOMAIN_DISABLED.value) 
    
    except sql_exceptions.SQLAlchemyError as ex:
        debugsException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)

def deleteDomainService(domainid,domainname):
    try:

        dispatcherEntry = db.query(Dispatcher).filter(Dispatcher.setid == domainid)
        domainAttrs = db.query(DomainAttrs).filter(DomainAttrs.did == domainname)
        domainEntry = db.query(Domain).filter(Domain.did == domainname)
        
        dispatcherEntry.delete(synchronize_session=False)
        domainAttrs.delete(synchronize_session=False)
        domainEntry.delete(synchronize_session=False)
        db.flush()
        db.commit()


    except sql_exceptions.SQLAlchemyError as ex:
        debugsException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)

# Gateway to IP - A gateway can be a carrier or PBX
def gatewayIdToIP(pbxid):
    gw =  db.query(Gateways).filter(Gateways.gwid == pbxid).first()
    if gw is not None:
        return gw.address
