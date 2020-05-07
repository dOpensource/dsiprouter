from datetime import datetime
from shared import debugException
from database import SessionLoader, DummySession, dSIPCDRInfo
from modules.api.api_routes import generateCDRS

def sendCdrReport(gwgroupid):
    db = DummySession()

    try:
        db = SessionLoader()

        now = datetime.now()
        cdr_info = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
        generateCDRS(gwgroupid=gwgroupid, type='csv', email=True, dtfilter=cdr_info.last_sent)
        cdr_info.last_sent = now
        db.commit()

    except Exception as ex:
        debugException(ex)
        db.rollback()
        db.flush()
    finally:
        db.close()
