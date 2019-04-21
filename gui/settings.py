# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings

DSIP_PROTO = 'http'
DSIP_HOST = '0.0.0.0'
DSIP_PORT = 5000
USERNAME = 'admin'
PASSWORD = 'admin'

# dsiprouter logging settings
# syslog level and facility values based on:
# <http://www.nightmare.com/squirl/python-ext/misc/syslog.py>
DSIP_LOG_LEVEL = 3
DSIP_LOG_FACILITY = 18

# ssl key / cert paths
# email for re-certification (must match certs)
DSIP_SSL_KEY = ''
DSIP_SSL_CERT = ''
DSIP_SSL_EMAIL = ''

# dSIPRouter internal settings

VERSION = 0.521
DEBUG = True
# '' = default behavior - handle inbound with domain mapping from endpoints, inbound from carriers and outbound to carriers
# outbound = act as an outbound proxy only 
ROLE = ''  

# MySQL settings for kamailio

# Database cluster
#KAM_DB_HOST = ['64.129.84.11','64.129.84.12','50.237.20.11','50.237.20.12']
# Single Host
KAM_DB_HOST = 'localhost'
# Database Engine Driver to connect with (leave empty for default)
# supported drivers:    mysqldb | pymysql
# see sqlalchemy docs for more info: <https://docs.sqlalchemy.org/en/latest/core/engines.html>
KAM_DB_DRIVER = ''
KAM_DB_TYPE = 'mysql'
KAM_DB_PORT = '3306'
KAM_DB_NAME = 'kamailio'
KAM_DB_USER = 'kamailio'
KAM_DB_PASS = 'kamailiorw'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'
RTP_CFG_PATH = '/etc/kamailio/kamailio.cfg'

# SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = True

FLT_CARRIER = 8
FLT_PBX = 9
FLT_OUTBOUND = 8000
FLT_INBOUND = 9000

# The domain used to create user accounts for PBX and Endpoint registrations

DOMAIN = 'sip.dsiprouter.org'

# Teleblock Settings
TELEBLOCK_GW_ENABLED = 0
TELEBLOCK_GW_IP = '62.34.24.22'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''

# Flowroute API Settings
FLOWROUTE_ACCESS_KEY=''
FLOWROUTE_SECRET_KEY=''
FLOWROUTE_API_ROOT_URL = "https://api.flowroute.com/v2"

# updated dynamically! ONLY set here if you need static values
INTERNAL_IP_ADDR = '68.183.140.81'
INTERNAL_IP_NET = '68.183.140.*'
EXTERNAL_IP_ADDR = '68.183.140.81'

# upload folder for files
UPLOAD_FOLDER = '/tmp'

# Cloud Platform
# The cloud platform the dSIPRouter is installed on
# The installer will update this
# '' = other or native install 
# AWS = Amazon Web Services, GCP = Google Cloud Platform, AZURE = Microsoft Azure, DO = Digital Ocean
CLOUD_PLATFORM = ''

