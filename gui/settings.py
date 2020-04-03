# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except for Teleblock settings

DSIP_ID = 1
DSIP_CLUSTER_ID = 1
DSIP_CLUSTER_SYNC = True
DSIP_PROTO = 'http'
DSIP_HOST = '0.0.0.0'
DSIP_PORT = 5000
DSIP_USERNAME = 'admin'
DSIP_PASSWORD = b'578ea75db709b1f9d1004b4e907237fbc55475afae339c9c04914d1329b0e71f4f7aef4ac9a670bebdfc03e4c6835a38870d4303b010dcd27e5623b7825e33be'
DSIP_SALT = b'77ea97c42a28b22875448dc713214629f99c08848da5273d6a46c82b01f79f729e08dffb8edfac936861cb41412d7297e3e50854b66961746217b7776a9e359a'
DSIP_API_TOKEN = b'0772ddeb9da77db4d4c516c58d09a7774d889eb4852707a8a014857a51fe43338a51d0283f9406d5885c369bc2a8315b93eeafe1173c998c17d75fa12d8126d2ec6abc5a956bfef960cc1c3b49c1f2c7'
DSIP_API_PROTO = 'http'
DSIP_API_HOST = '127.0.0.1'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'
DSIP_PID_FILE = '/var/run/dsiprouter/dsiprouter.pid'
DSIP_IPC_SOCK = '/var/run/dsiprouter/dsiprouter.sock'
DSIP_IPC_PASS = b'3dedc1844427fd6281d9a01aec71702a5a0003dbc08cd0ddfe549a76e2f95b95ae40e44a5d43216f5d04e7bf5b15bcece9af36f58a9f866f6004f4f98f8c4335c1a7b5a9875f0140d2bf21fcad10d6c8'

# dsiprouter logging settings
# syslog level and facility values based on:
# <http://www.nightmare.com/squirl/python-ext/misc/syslog.py>

DSIP_LOG_LEVEL = 3
DSIP_LOG_FACILITY = 18

# dSIPRouter SSL settings
# ssl key / cert are absolute paths
# email for re-certification must match certs
DSIP_SSL_KEY = ''
DSIP_SSL_CERT = ''
DSIP_SSL_EMAIL = ''

# dSIPRouter internal settings

VERSION = '0.60+ent'
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
KAM_DB_PASS = b'3094cff5c41bfc5371cd953428ea3f4132e2580e0d0abdcddeb3'

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

# updated dynamically! ONLY set here if you need static values
INTERNAL_IP_ADDR = '64.227.20.96'
INTERNAL_IP_NET = '64.227.20.*'
EXTERNAL_IP_ADDR = '64.227.20.96'
EXTERNAL_HOSTNAME = 'sbc3.dsiprouter.net'

# upload folder for files
UPLOAD_FOLDER = '/tmp'

# Cloud Platform
# The cloud platform the dSIPRouter is installed on
# The installer will update this
# '' = other or native install 
# AWS = Amazon Web Services, GCP = Google Cloud Platform, AZURE = Microsoft Azure, DO = Digital Ocean
CLOUD_PLATFORM = 'DO'

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
BACKUP_FOLDER= '/tmp'

# Where to sync settings from
# file  - load from setting.py file
# db    - load from dsip_settings table
LOAD_SETTINGS_FROM = 'file'

# micosoft teams settings
MSTEAMS_DNS_ENDPOINTS = ["sip.pstnhub.microsoft.com:5061;transport=tls","sip2.pstnhub.microsoft.com:5061;transport=tls","sip3.pstnhub.microsoft.com:5061;transport=tls"]
MSTEAMS_IP_ENDPOINTS = ["52.114.148.0","52.114.132.46","52.114.75.24","52.114.76.76","52.114.7.24","52.114.14.70"]
