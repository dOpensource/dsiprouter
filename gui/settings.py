import os
from datetime import datetime

# Get current time for log / backup file naming

START = datetime.strftime(datetime.now(), '%Y-%m-%d_%H-%M-%S')


### Set some Dynamic Paths for our applications to use ###

APP_NAME = "dsiprouter"
ROOT_DIR = os.path.abspath(os.sep)
PROJECT_ROOT = os.path.dirname(os.path.realpath(__file__))

# These are standard log and backup locations

LOG_DIR = os.path.join(ROOT_DIR, "var", "log", APP_NAME)
BACKUP_DIR = os.path.join(ROOT_DIR, "var", "backups", APP_NAME)

# Log locations for seperate loggers

ROOT_LOG_FILE = os.path.join(LOG_DIR, "root.{}.log".format(START))
GUI_LOG_FILE = os.path.join(LOG_DIR, "gui.{}.log".format(START))
DB_LOG_FILE = os.path.join(LOG_DIR, "db.{}.log".format(START))

# SSL cert location if used, can be system-wide or application-specific
# only the last one uncommented will take effect

# application-specific
# CERT_DIR = os.path.join(PROJECT_ROOT, "certs")
# system-wide
# the standard locations are: /etc/ssl/certs & /etc/ssl/private
# CERT_DIR = os.path.join(ROOT_DIR, "etc", "ssl", "certs")


### dSIPRouter settings ###
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings

DSIP_PORT=5000
USERNAME = 'admin'
PASSWORD = 'admin'

# dSIPRouter internal settings

VERSION = 0.34
DEBUG = 0

### MySQL settings for kamailio ###

KAM_DB_TYPE = 'mysql'
KAM_DB_HOST = 'localhost'
KAM_DB_PORT = '3306'
KAM_DB_NAME = 'kamailio'
KAM_DB_USER = 'kamailio'
KAM_DB_PASS = 'kamailiorw'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'


### SQLAlchemy Settings ###

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = False

FLT_CARRIER = 8
FLT_PBX = 9

# The domain used to create user accounts for PBX and Endpoint registrations

DOMAIN = 'sip.dsiprouter.org'

### Teleblock Settings ###

TELEBLOCK_GW_ENABLED = '0'
TELEBLOCK_GW_IP = '66.203.90.197'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''

# Specify the deployment environment
# Possible values: (DEV | TEST | PROD)
ENV = 'PROD'