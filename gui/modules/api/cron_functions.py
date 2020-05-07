from datetime import datetime
from shared import debugException
from database import SessionLoader, DummySession, Subscribers, dSIPLeases, Gateways

def cleanupLeases():
    db = DummySession()

    try:
        db = SessionLoader()

        Leases = db.query(dSIPLeases).filter(datetime.now() >= dSIPLeases.expiration).all()
        for Lease in Leases:
            # Remove the entry in the Subscribers table
            db.query(Subscribers).filter(Subscribers.id == Lease.sid).delete(synchronize_session=False)

            # Remove the entry in the Gateway table
            db.query(Gateways).filter(Gateways.gwid == Lease.gwid).delete(synchronize_session=False)

            # Remove the entry in the Lease table
            db.delete(Lease)

        db.commit()

    except Exception as ex:
        debugException(ex)
        db.rollback()
        db.flush()
    finally:
        db.close()
