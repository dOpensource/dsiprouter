'''
@Summary: Contains methods for handling loggers and logging
@Author: `devopsec <https://github.com/devopsec>`_
'''

import os, logging, settings
from copy import copy
from logging.handlers import TimedRotatingFileHandler
from util.common import *

def init_loggers():
    if not os.path.exists(settings.LOG_DIR):
        os.makedirs(settings.LOG_DIR)

    # default level
    log_level = logging.CRITICAL

    # set logging level
    if settings.ENV == 'DEV':
        log_level = logging.DEBUG
    elif settings.ENV == 'TEST':
        log_level = logging.WARNING
    elif settings.ENV == 'PROD':
        log_level = logging.ERROR

    # close current file handlers
    for handler in copy(logging.getLogger().handlers):
        logging.getLogger().removeHandler(handler)
        handler.close()
    for handler in copy(logging.getLogger('werkzeug').handlers):
        logging.getLogger('werkzeug').removeHandler(handler)
        handler.close()
    for handler in copy(logging.getLogger('sqlalchemy').handlers):
        logging.getLogger('sqlalchemy').removeHandler(handler)
        handler.close()


    # create our own custom handlers
    log_formatter = logging.Formatter("[%(asctime)s] [%(levelname)s] {%(pathname)s (%(lineno)d)}: %(message)s")

    root_handler = TimedRotatingFileHandler(
            settings.ROOT_LOG_FILE,
            when='midnight',
            backupCount=10
        )
    root_handler.setLevel(log_level)
    root_handler.setFormatter(log_formatter)
    logging.getLogger().setLevel(log_level)
    logging.getLogger().addHandler(root_handler)

    gui_handler = TimedRotatingFileHandler(
            settings.GUI_LOG_FILE,
            when='midnight',
            backupCount=10
        )
    gui_handler.setLevel(log_level)
    gui_handler.setFormatter(log_formatter)
    logging.getLogger('werkzeug').setLevel(log_level)
    logging.getLogger('werkzeug').addHandler(gui_handler)


    db_handler = TimedRotatingFileHandler(
            settings.DB_LOG_FILE,
            when='midnight',
            backupCount=10
        )
    db_handler.setLevel(log_level)
    db_handler.setFormatter(log_formatter)
    logging.getLogger('sqlalchemy.engine').addHandler(db_handler)
    logging.getLogger('sqlalchemy.engine').setLevel(log_level)
    logging.getLogger('sqlalchemy.dialects').addHandler(db_handler)
    logging.getLogger('sqlalchemy.dialects').setLevel(log_level)
    logging.getLogger('sqlalchemy.pool').addHandler(db_handler)
    logging.getLogger('sqlalchemy.pool').setLevel(log_level)
    logging.getLogger('sqlalchemy.orm').addHandler(db_handler)
    logging.getLogger('sqlalchemy.orm').setLevel(log_level)


def logc(text, color=WHITE, logger=logging.getLogger(), level=logging.NOTSET):
    """
    Log text with color, if available, to out
    :param text:        str
    :param color:       int
    :param logger:      logging.Logger()
    :param level:       int
    """

    if has_colors(sys.stdout):
        string = strfc(text, color)
        logger.log(level, string)
    else:
        string = str(text).strip()
        logger.log(level, string)

# some common use cases

def logcrit(message):
    logc(message, RED, level=logging.CRITICAL)

def logerror(message):
    logc(message, RED, level=logging.ERROR)

def loginfo(message):
    logc(message, CYAN, level=logging.INFO)

def logwarn(message):
    logc(message, YELLOW, level=logging.WARNING)

def logdebug(message):
    logc(message, GREEN, level=logging.DEBUG)

def lognolvl(message):
    logc(message, WHITE)
