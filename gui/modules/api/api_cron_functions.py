from shared import debugException, IO
from database import SessionLoader, DummySession, Subscribers, dSIPLeases, Gateways, dSIPCDRInfo
from datetime import datetime
from sqlalchemy import case, func, exc as sql_exceptions,or_
from modules.api.api_routes import revokeEndpointLease, generateCDRS
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
        db.close()

def send_monthly_cdrs():
    db = DummySession()

    try:
        db = SessionLoader()

        now = datetime.now()
        day = now.strftime("%d")
        date = now.strftime('%Y-%m-%d')

        CDRReports = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.send_date == day).filter(or_(dSIPCDRInfo.last_sent < date, dSIPCDRInfo.last_sent == None))
        for CDRReport in CDRReports:
            generateCDRS(gwgroupid=CDRReport.gwgroupid,type='csv',email="True")
            db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == CDRReport.gwgroupid).update({"last_sent":date})
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
        db.close()

def api_cron():
    try:
        cleanup_leases()
        send_monthly_cdrs()
    except Exception as ex:
        debugException(ex)

if __name__ == "__main__":
    api_cron()
