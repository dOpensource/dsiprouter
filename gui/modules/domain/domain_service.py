from database import loadSession, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, Gateways
from sqlalchemy import case, func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from shared import *

db = loadSession()


def getDomains():
    try:
        #sql = "select domain.id,domain.domain,dsip_domain_mapping.type,dsip_domain_mapping.pbx_id,dr_gateways.description from domain left join dsip_domain_mapping on domain.id = dsip_domain_mapping.domain_id left join dr_gateways on dsip_domain_mapping.pbx_id = dr_gateways.gwid;"

        sql = "select distinct domain.did as domain,domain.id, value as type from domain_attrs join domain on domain.did = domain_attrs.did where name='pbx_type';"
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

def getPBXLookUp():

    try:

        sql = "select did, value as pbx_id, description from domain_attrs left join dr_gateways on domain_attrs.value = dr_gateways.gwid where name='created_by'"

        res = db.execute(sql);
        pbxLookup={}
        for row in res:
            if row['description'] is not None:
                fields = strFieldsToDict(row['description'])
                name = fields['name']
            else:
                name = "Manually Created"

            pbxLookup[row['did']]=[row['pbx_id'],name]
        return pbxLookup

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()




def addDomainService(domain,authtype,pbx):
    try:
   	#Create the domain because we need the domain id
        PBXDomain = Domain(domain=domain, did=domain)
        db.add(PBXDomain)
        db.flush
        db.commit()

        # Implement Passthru authentication to the first PBX on the list.
        # because Passthru Registration only works against one PBX

        if authtype=="passthru":

            # Check if list of PBX's
            pbxs = pbx.split(',')
            if pbxs is None:
                #No list
                pass
            else:
                #Grab the first entry out of the list
                pbx=pbxs[0]
            
            PBXDomainAttr = DomainAttrs(did=domain, name='pbx_ip',value=gatewayIdToIP(pbx))
            PBXDomainAttr1 = DomainAttrs(did=domain, name='pbx_type',value="0") 
            PBXDomainAttr2 = DomainAttrs(did=domain, name='created_by',value="0") 
            db.add(PBXDomainAttr)
            db.add(PBXDomainAttr1)
            db.add(PBXDomainAttr2)
            db.flush()
            db.commit()

        # Implement external authentiction to either Realtime DB or Local Subscriber table

        else:

            # Serial folking will be used to forward registration info to multiple PBX's 
            PBXDomainAttr1 = DomainAttrs(did=domain, name='dispatcher_alg_reg',value="8")
            PBXDomainAttr2 = DomainAttrs(did=domain, name='dispatcher_alg_in',value="4")
            #Attributes to specify that the domain was created manually
            PBXDomainAttr3 = DomainAttrs(did=domain, name='pbx_type',value="0") 
            PBXDomainAttr4 = DomainAttrs(did=domain, name='created_by',value="0") 
            PBXDomainAttr5= DomainAttrs(did=domain, name='domain_auth',value=authtype) 
            
            if len(pbx) > 1:
                #Create entry in dispatcher and set dispatcher_set_id in domain_attrs
                for p in pbx.split(','):
                    dispatcher = Dispatcher(setid=PBXDomain.id,destination=gatewayIdToIP(p))
                    db.add(dispatcher)
               
                PBXDomainAttr6 = DomainAttrs(did=domain, name='dispatcher_set_id',value=PBXDomain.id)

            db.add(PBXDomainAttr1)
            db.add(PBXDomainAttr2)
            db.add(PBXDomainAttr3)
            db.add(PBXDomainAttr4)
            db.add(PBXDomainAttr5)
            db.add(PBXDomainAttr6)
            db.flush()
            db.commit()

    
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
