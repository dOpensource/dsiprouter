# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings

DSIP_ID = 1
DSIP_PROTO = 'http'
DSIP_HOST = '0.0.0.0'
DSIP_PORT = 5000
DSIP_USERNAME = 'admin'
DSIP_PASSWORD = 'admin'
DSIP_SALT = b'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
DSIP_API_TOKEN = 'admin'
DSIP_API_PROTO = 'http'
DSIP_API_HOST = '127.0.0.1'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'

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

VERSION = "0.60+ent"
DEBUG = False
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
SQLALCHEMY_SQL_DEBUG = False

FLT_CARRIER = 8     # type of 8 in dr_gateway table
FLT_PBX = 9         # type of 9 in dr_gateway table
FLT_OUTBOUND = 8000 # groupid of 8000 in dr_rules table
FLT_INBOUND = 9000  # groupid of 9000 in dr_rules table
FLT_LCR_MIN = 10000 # groupid of >= 10000 in dr_rules table
FLT_FWD_MIN = 20000 # groupid of >= 20000 in dr_rules table

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
INTERNAL_IP_ADDR = '172.21.0.2'
INTERNAL_IP_NET = '172.21.0.*'
EXTERNAL_IP_ADDR = '98.209.240.245'

# upload folder for files
UPLOAD_FOLDER = '/tmp'

# Cloud Platform
# The cloud platform the dSIPRouter is installed on
# The installer will update this
# '' = other or native install 
# AWS = Amazon Web Services, GCP = Google Cloud Platform, AZURE = Microsoft Azure, DO = Digital Ocean
CLOUD_PLATFORM = ''

# email server config
MAIL_SERVER = 'smtp.gmail.com'
MAIL_PORT = 587
MAIL_USE_TLS = True
MAIL_USERNAME = ''
MAIL_PASSWORD = ''
MAIL_ASCII_ATTACHMENTS = False
MAIL_DEFAULT_SENDER = 'DoNotReply@{}'.format(MAIL_SERVER)
MAIL_DEFAULT_SUBJECT = "dSIPRouter System Notification"

# Where to sync settings from
# file  - load from setting.py file
# db    - load from dsip_settings table
LOAD_SETTINGS_FROM = 'file'
