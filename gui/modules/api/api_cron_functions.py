from datetime import datetime
from shared import debugException, monthdelta
from database import SessionLoader, DummySession, Subscribers, dSIPLeases, Gateways, dSIPCDRInfo
from modules.api.api_routes import revokeEndpointLease, generateCDRS

def cleanup_leases():

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

def send_monthly_cdrs():
    db = DummySession()

    try:
        db = SessionLoader()

        now = datetime.now()
        today = datetime(now.year, now.month, now.day)
        prev_month = monthdelta(today, -1)

        CDRReports = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.send_date == now.day).filter((dSIPCDRInfo.last_sent < today) | (dSIPCDRInfo.last_sent == None)).all()
        for CDRReport in CDRReports:
            generateCDRS(gwgroupid=CDRReport.gwgroupid, type='csv', email=True, dtfilter=prev_month)
            db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == CDRReport.gwgroupid).update({"last_sent":now}, synchronize_session=False)
        db.commit()

    except Exception as ex:
        debugException(ex)
        db.rollback()
        db.flush()
    finally:
        db.close()

def api_cron():
    cleanup_leases()
    send_monthly_cdrs()

if __name__ == "__main__":
    api_cron()
