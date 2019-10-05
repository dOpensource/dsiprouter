from shared import debugException, IO
from database import SessionLoader, DummySession, Subscribers, dSIPLeases,Gateways
from datetime import datetime
from sqlalchemy import case, func, exc as sql_exceptions
from modules.api.api_routes import revokeEndpointLease
import settings

def cleanup_leases():

    db = DummySession()

    try:
        db = SessionLoader()

        Leases = db.query(dSIPLeases).filter(datetime.now() >= dSIPLeases.expiration)
        for Lease in Leases:

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
        debugException(ex)
        db.rollback()
        db.flush()
    except Exception as ex:
        debugException(ex)
        db.rollback()
        db.flush()
    finally:
        SessionLoader.remove()


def api_cron(settings):
    try:
        cleanup_leases()
    except Exception as ex:
        IO.printerr(str(ex))

if __name__ == "__main__":
    api_cron(settings)
