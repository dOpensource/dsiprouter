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
DSIP_PASSWORD = b'45a540d2c0d538cb14890120647cac96bfdb9f5fbb031da94cf0d0dbccfb3b2c9699845f683870a8de88b8be9b0e422066688749dd301420e68ef6584560ffaae651d2c3d7b1c8f75121e3c3a5cde8b3dd3790cd1f79ac10329d757ff0ec8935e55ac67506ada1078d8861df7020429a2841d5c169bf7a177fec8684fd95bc85'
DSIP_API_TOKEN = b'05d3d0b4cc45b4e6d0fbfef3144b3a6d67b5acad5feb1327084c2ae427523953fc41b0e1efc9d7d8c23d766be0995f28dea1cf6fb8f7b2e032cafa9433455ba70789fc3a548757294530b76021da5b65'
DSIP_API_PROTO = 'https'
DSIP_API_HOST = '127.0.0.1'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'
DSIP_PID_FILE = '/var/run/dsiprouter/dsiprouter.pid'
DSIP_IPC_SOCK = '/var/run/dsiprouter/dsiprouter.sock'
DSIP_IPC_PASS = b'8df5f402aa3af6e166b4d4424731a2a38a55fc541339fb998caad3ca5d5b54056ade199e5bac522e7916cdb6064122b11b31000256651b5a7bcf2b1338c01f0295cff7f20396731b120e31d48b169c69'

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
DSIP_SSL_EMAIL = 'admin@sbc.dsiprouter.net'
DSIP_CERTS_DIR = '/etc/dsiprouter/certs'

# dSIPRouter internal settings

VERSION = '0.62'
DEBUG = True
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
KAM_DB_PASS = b'276007174cfb560526643e84d527b553c089964fcdde265bf0178a2d0b34967fb44cf9152713652c92b3b71160ca03ef906f362e3c1b8bc30a24e89526a0eca7603874887af9790eaa570ac4dcb3cb6c'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'
KAM_TLSCFG_PATH = '/etc/kamailio/tls.cfg'
RTP_CFG_PATH = '/etc/kamailio/kamailio.cfg'

# SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_SQL_DEBUG = True

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
INTERNAL_IP_ADDR = '68.183.205.221'
INTERNAL_IP_NET = '68.183.205.*'
EXTERNAL_IP_ADDR = '68.183.205.221'
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
