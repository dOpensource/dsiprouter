from datetime import datetime
from shared import debugException, IO
from database import startSession, DummySession, dSIPCDRInfo
from modules.api.api_routes import generateCDRS

def sendCdrReport(gwgroupid):
    db = DummySession()

    try:
        db = startSession()

        now = datetime.now()
        cdr_info = db.query(dSIPCDRInfo).filter(dSIPCDRInfo.gwgroupid == gwgroupid).first()
        generateCDRS(gwgroupid=gwgroupid, report_type='csv', send_email=True, dtfilter=cdr_info.last_sent, run_standalone=True)
        cdr_info.last_sent = now
        db.commit()

    except Exception as ex:
        debugException(ex)
        db.rollback()
        db.flush()
    finally:
        db.close()


def purgeCdrs():
    """Run the CDR retention / S3 archive job, returns False when it failed"""
    from modules.cdr.retention import runRetention
    from sysloginit import initSyslogLogger

    initSyslogLogger()
    try:
        result = runRetention(trigger='cron')
        return result['error'] is None
    except Exception as ex:
        IO.logerr('CDR retention failed: {}'.format(ex))
        debugException(ex)
        return False
