import logging, sys, functools
import settings
from logging.handlers import SysLogHandler
from copy import copy

class StreamLogger():
    """
    Redirect stream to logger
    Inspired from the following:
    <https://stackoverflow.com/questions/19425736/how-to-redirect-stdout-and-stderr-to-logger-in-python>
    <http://techies-world.com/how-to-redirect-stdout-and-stderr-to-a-logger-in-python/>
    """
    def __init__(self, logger=logging.getLogger(), level=logging.getLogger().level):
        self.logger = logger
        self.level = level
        self.buff = ""

    def write(self, message):
        if message != '\n':
            self.buff += message.strip()

    def flush(self):
        self.logger.log(self.level, '{}\n'.format(self.buff))
        self.buff = ""

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
    log_formatter = logging.Formatter('[%(asctime)s] [%(levelname)s] [%(pathname)s->%(lineno)d]: %(message)s',
                                      datefmt='%Y-%m-%d %H:%M:%S')
    log_handler = logging.handlers.SysLogHandler(address="/dev/log", facility=settings.DSIP_LOG_FACILITY)
    log_handler.setLevel(settings.DSIP_LOG_LEVEL)
    log_handler.setFormatter(log_formatter)

    # set log handler for our dsiprouter app
    logging.getLogger().setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger().addHandler(log_handler)

    # redirect stderr and stdout to syslog
    if settings.DEBUG:
        sys.stderr = StreamLogger(level=logging.WARNING)
        sys.stdout = StreamLogger(level=logging.DEBUG)

    return log_handler

# import this file to setup logging
# syslog handler created globally
syslog_handler = initSyslogLogger()

# change print to default unbuffered
# set if your redirecting stdout or stderr to syslog
if settings.DEBUG:
    print = functools.partial(print, flush=True)
