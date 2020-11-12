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
DSIP_PASSWORD = b'6c88b2492c881a045598fbe4b4299596796a6c7421796ae8e3f143251b82edd396d55c1432b17694c18ab551c8c8f51f70e313ea0f49974e67a900f0611d3e7074f3d0de648cb3f771618bde6ca44497ab15a92093ea44b8f1016f89eadfab0aa395c75f19abc5e5dcaa5fa8cf7c8e1899ddaab24d0116f3ea30fd369062d464'
DSIP_API_TOKEN = b'0d2f96a31d82d47c38e3179234b9b89f53d9c792deccd695f6bb50826512138ecbfbd583bc29adc380801ce964f7cfbdcfa538360bbe495037b191b95bd50603330e448c6dfec99357008f220492be83'
DSIP_API_PROTO = 'https'
DSIP_API_HOST = '127.0.0.1'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'
DSIP_PID_FILE = '/var/run/dsiprouter/dsiprouter.pid'
DSIP_IPC_SOCK = '/var/run/dsiprouter/dsiprouter.sock'
DSIP_IPC_PASS = b'83b089a547732a40c7891603d4aa230aacfe7c24752148e6fe9cf2db3756d5e3120934a8709c6fc0b79918aac9e5a1344684075108dc44b064aeb79a9504f0d5f511dda3ecc9cea28e0528c997845368'
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
DSIP_SSL_EMAIL = 'admin@134.122.33.190'
DSIP_CERTS_DIR = '/etc/dsiprouter/certs'

# dSIPRouter internal settings

VERSION = '0.63'
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
KAM_DB_PASS = b'faaf8735f7c39a74a9027545c4f2d6ec163b9d4c77839bf48055c339751094b6328825ebc1468dd0d86910c4da0791c73dab9f7d9d1a7b39e79c1c082b9a7df839fe365b9c86000b7e6cc9d69e293752'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'
KAM_TLSCFG_PATH = '/etc/kamailio/tls.cfg'
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
INTERNAL_IP_ADDR = '178.128.233.182'
INTERNAL_IP_NET = '178.128.233.*'
EXTERNAL_IP_ADDR = '178.128.233.182'
EXTERNAL_FQDN = 'sip.dsiprouter.org'

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
MAIL_DEFAULT_SENDER = 'dSIPRouter {}-{} <{}>'.format(str(DSIP_CLUSTER_ID), str(DSIP_ID), MAIL_USERNAME)
MAIL_DEFAULT_SUBJECT = 'dSIPRouter System Notification'

# backup settings
BACKUP_FOLDER = '/var/backups/dsiprouter'
################# End DB-Backed Settings #################

################# Local-Only Settings ####################
# settings in this section are not stored on the DB

# where the project was installed
DSIP_PROJECT_DIR = '/opt/dsiprouter'

# dr_routing prefix matching supported characters
# refer to: <https://kamailio.org/docs/modules/5.1.x/modules/drouting.html#idp26708356>
DID_PREFIX_ALLOWED_CHARS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '#', '*'}

# micosoft teams settings
MSTEAMS_DNS_ENDPOINTS = ["sip.pstnhub.microsoft.com:5061;transport=tls","sip2.pstnhub.microsoft.com:5061;transport=tls","sip3.pstnhub.microsoft.com:5061;transport=tls"]
MSTEAMS_IP_ENDPOINTS = ["52.114.148.0","52.114.132.46","52.114.75.24","52.114.76.76","52.114.7.24","52.114.14.70"]

# Where to sync settings from
# file  - load from setting.py file
# db    - load from dsip_settings table
LOAD_SETTINGS_FROM = 'file'
############### End Local-Only Settings ##################
