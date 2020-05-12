################ Database-Backed Settings ################
# settings in this section are synced with the DB

# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings
# unless hot reloading settings is enabled when updating settings, see shared.updateConfig()

DSIP_ID = 1
DSIP_CLUSTER_ID = 1
DSIP_CLUSTER_SYNC = False
DSIP_PROTO = 'https'
DSIP_HOST = '0.0.0.0'
DSIP_PORT = 5000
DSIP_USERNAME = 'admin'
DSIP_PASSWORD = b'3fc41957d0b180210792f66ab56aeb7c866dbdb03d7c566182b78d03f2d9f538064647f070df7ed99eccae618424b52e8151b0ba20d6811b818420a526081d63'
DSIP_SALT = b'5ee2657081d5e16eb0de0cd7e5084eedbff3282a4b2cd739943bb3250768a7f0b5fb79a6024f83521c0da0f75a04c6df8fad2d030a1ba5a97144d6f6a5bb6b2a'
DSIP_API_TOKEN = b'b39798b75858470f2c129d1a0b30ac12fdd3739816c1e3a55089c6e8223de792e62059a15238dba888f41c53243813db6517fb165fb01c0e63d9d53e42b8f5b86b03aa597c2174a0e664c8f65e9fde18'
DSIP_API_PROTO = 'https'
DSIP_API_HOST = '127.0.0.1'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'
DSIP_PID_FILE = '/var/run/dsiprouter/dsiprouter.pid'
DSIP_IPC_SOCK = '/var/run/dsiprouter/dsiprouter.sock'
DSIP_IPC_PASS = b'aa939c98781ba8a9c5208765e1f19ca57d73527565c99887a619aa3ff6e34c65a2b94b5d8f430502797aac8e9360ecc12c3227ea9776e6b4428673d8b811a28d4367e05b31dacecda20f6b9999bd4d74'

# dsiprouter logging settings
# syslog level and facility values based on:
# <http://www.nightmare.com/squirl/python-ext/misc/syslog.py>

DSIP_LOG_LEVEL = 3
DSIP_LOG_FACILITY = 18

# dSIPRouter SSL settings
# ssl key / cert are absolute paths
# email for re-certification must match certs
DSIP_SSL_KEY = '/etc/dsiprouter/certs/dsiprouter.key'
DSIP_SSL_CERT = '/etc/dsiprouter/certs/dsiprouter.crt'
DSIP_SSL_EMAIL = 'admin@INTERNAL_FQDN'

# dSIPRouter internal settings

VERSION = '0.61'
DEBUG = False
# '' (default)  = handle inbound with domain mapping from endpoints, inbound from carriers and outbound to carriers
# 'outbound'    = act as an outbound proxy only (no domain routing)
# 'inout'       = inbound from carriers and outbound to carriers only (no domain routing)
ROLE = ''
GUI_INACTIVE_TIMEOUT = 20

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
KAM_DB_PASS = b'9299197560a451c578264341c4ce0cdbd0c6543411a16e3b27ac'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'
RTP_CFG_PATH = '/etc/kamailio/kamailio.cfg'

# SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = False

# These constants shouldn't be modified
# FLT_CARRIER/FLT_PBX:          type in dr_gateway table
# FLT_OUTBOUND/FLT_INBOUND:     groupid in dr_rules table
# FLT_LCR_MIN/FLT_FWD_MIN:      range of groupid in dr_rules table
FLT_CARRIER = 8
FLT_PBX = 9
FLT_MSTEAMS = 17
FLT_OUTBOUND = 8000
FLT_INBOUND = 9000
FLT_LCR_MIN = 10000
FLT_FWD_MIN = 20000

# The domain used to create user accounts for PBX and Endpoint registrations
DOMAIN = 'sip.dsiprouter.org'

# Teleblock Settings
TELEBLOCK_GW_ENABLED = 0
TELEBLOCK_GW_IP = '62.34.24.22'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''

# Flowroute API Settings
FLOWROUTE_ACCESS_KEY = ''
FLOWROUTE_SECRET_KEY = ''
FLOWROUTE_API_ROOT_URL = 'https://api.flowroute.com/v2'

# updated dynamically! These values will be overwritten
INTERNAL_IP_ADDR = '10.0.1.6'
INTERNAL_IP_NET = '10.0.1.*'
EXTERNAL_IP_ADDR = '104.211.6.6'
EXTERNAL_FQDN = 'sip.dsiprouter.org'

# upload folder for files
UPLOAD_FOLDER = '/tmp'

# Cloud Platform
# The cloud platform the dSIPRouter is installed on
# The installer will update this
# '' = other or native install
# AWS = Amazon Web Services, GCP = Google Cloud Platform, AZURE = Microsoft Azure, DO = Digital Ocean
CLOUD_PLATFORM = 'AZURE'

# email server config
MAIL_SERVER = 'smtp.gmail.com'
MAIL_PORT = 587
MAIL_USE_TLS = True
MAIL_USERNAME = ''
MAIL_PASSWORD = ''
MAIL_ASCII_ATTACHMENTS = False
MAIL_DEFAULT_SENDER = '@smtp.gmail.com'.format(MAIL_USERNAME, MAIL_SERVER)
MAIL_DEFAULT_SUBJECT = 'dSIPRouter System Notification'

# backup settings
BACKUP_FOLDER = '/var/backups/dsiprouter'
################# End DB-Backed Settings #################

################# Local-Only Settings ####################
# settings in this section are not stored on the DB

# where the project was installed
DSIP_PROJECT_DIR = '/opt/dsiprouter'

# micosoft teams settings
MSTEAMS_DNS_ENDPOINTS = ["sip.pstnhub.microsoft.com:5061;transport=tls","sip2.pstnhub.microsoft.com:5061;transport=tls","sip3.pstnhub.microsoft.com:5061;transport=tls"]
MSTEAMS_IP_ENDPOINTS = ["52.114.148.0","52.114.132.46","52.114.75.24","52.114.76.76","52.114.7.24","52.114.14.70"]

# Where to sync settings from
# file  - load from setting.py file
# db    - load from dsip_settings table
LOAD_SETTINGS_FROM = 'file'
############### End Local-Only Settings ##################
