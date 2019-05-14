from database import loadSession, Subscribers, dSIPLeases,Gateways
from datetime import datetime
from sqlalchemy import case, func, exc as sql_exceptions
from modules.api.api_routes import revokeEndpointLease
import settings

db = loadSession()

def cleanup_leases():

    Leases = db.query(dSIPLeases).filter(datetime.now() >= dSIPLeases.expiration)
    for Lease in Leases:
        try:
            # Remove the entry in the Subscribers table

            Subscriber = db.query(Subscribers).filter(Subscribers.id == Lease.sid).first()
            db.delete(Subscriber)
        
            # Remove the entry in the Gateway table

            Gateway = db.query(Gateways).filter(Gateways.gwid == Lease.gwid).first()
            db.delete(Gateway)

            # Remove the entry in the Lease table

            db.delete(Lease)

            db.commit()
        
        except sql_exceptions.SQLAlchemyError as ex:
            debugException(ex, log_ex=False, print_ex=True, showstack=False)
            error = "db"
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
            db.close()
        


def api_cron(settings):
    try:
        cleanup_leases()
    except Exception as e:
        print(e)

if __name__ == "__main__":
    api_cron(settings)
