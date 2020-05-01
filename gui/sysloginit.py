import logging
import settings
from logging.handlers import SysLogHandler
from copy import copy

def initSyslogLogger():
    """
    Configure syslog loggers
    :return:    syslog log handler
    """
    # close any zombie handlers for root logger
    for handler in copy(logging.getLogger().handlers):
        logging.getLogger().removeHandler(handler)
        handler.close()

    # create our own custom formatter and handler for syslog
    log_formatter = logging.Formatter('[%(asctime)s] [%(process)d->%(thread)d] [%(levelname)s]: %(message)s',
                                      datefmt='%Y-%m-%d %H:%M:%S')
    log_handler = logging.handlers.SysLogHandler(address="/dev/log", facility=settings.DSIP_LOG_FACILITY)
    log_handler.setLevel(settings.DSIP_LOG_LEVEL)
    log_handler.setFormatter(log_formatter)

    # set log handler for our dsiprouter app
    logging.getLogger().setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger().addHandler(log_handler)

    # redirect stderr and stdout to syslog
    # if not settings.DEBUG:
    #     sys.stderr = StreamLogger(level=logging.WARNING)
    #     sys.stdout = StreamLogger(level=logging.DEBUG)

    return log_handler

# import this file to setup logging
# syslog handler created globally
# syslog_handler = initSyslogLogger()
