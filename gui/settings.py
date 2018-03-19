# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - execept for Teleblock settings

DSIP_PORT = 5001
USERNAME = 'admin'
PASSWORD = 'admin'

# dSIPRouter internal settings

VERSION = 0.34
DEBUG = 0

# MySQL settings for kamailio

KAM_DB_TYPE = 'mysql'
KAM_DB_HOST = 'localhost'
KAM_DB_PORT = '3306'
KAM_DB_NAME = 'kamailio'
KAM_DB_USER = 'kamailio'
KAM_DB_PASS = 'kamailiorw'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'


#SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = False

FLT_CARRIER = 8
FLT_PBX = 9

# The domain used to create user accounts for PBX and Endpoint registrations

DOMAIN = 'sip.dsiprouter.org'

# Teleblock Settings
TELEBLOCK_GW_ENABLED = '1'
TELEBLOCK_GW_IP = '66.203.90.197'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''
