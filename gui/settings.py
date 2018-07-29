# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings

DSIP_HOST = '0.0.0.0'
DSIP_PORT = 5000
USERNAME = 'admin'
PASSWORD = 'admin'

# ssl key / cert paths
SSL_KEY = ""
SSL_CERT = ""

# dSIPRouter internal settings

VERSION = 0.41
DEBUG = True

# MySQL settings for kamailio

KAM_DB_TYPE = 'mysql'
KAM_DB_HOST = 'localhost'
KAM_DB_PORT = '3306'
KAM_DB_NAME = 'kamailio'
KAM_DB_USER = 'kamailio'
KAM_DB_PASS = 'kamailiorw'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'


# SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = False

FLT_CARRIER = 8
FLT_PBX = 9

# The domain used to create user accounts for PBX and Endpoint registrations
# defaults to this domain if not provided with username
DOMAIN = 'sip.dsiprouter.org'

# Teleblock Settings
TELEBLOCK_GW_ENABLED = 0
TELEBLOCK_GW_IP = '66.203.90.197'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''


# Network Settings

# updated dynamically! ONLY set here if you need static values
INTERNAL_IP_ADDR = ""
INTERNAL_IP_NET = ""
EXTERNAL_IP_ADDR = ""
