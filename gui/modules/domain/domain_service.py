from database import loadSession, dSIPDomainMapping
from sqlalchemy import case, func, exc as sql_exceptions
from shared import *

db = loadSession()

def addDomain(data):
    return data

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

