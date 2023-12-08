################ Database-Backed Settings ################
# settings in this section are synced with the DB

# dSIPRouter settings
# dSIPRouter will need to be restarted for any changes to take effect - except settings that can be hot reloaded
# for more information on hot reloading and shared memory via IPC see shared.updateConfig() and dsiprouter.syncSettings()

DSIP_ID = None
DSIP_CLUSTER_ID = 1
DSIP_CLUSTER_SYNC = False
DSIP_PROTO = 'https'
DSIP_PORT = '5000'
DSIP_USERNAME = 'admin'
DSIP_PASSWORD = 'admin'
DSIP_API_TOKEN = 'admin'
DSIP_API_PROTO = 'https'
DSIP_API_PORT = 5000
DSIP_PRIV_KEY = '/etc/dsiprouter/privkey'
DSIP_PID_FILE = '/run/dsiprouter/dsiprouter.pid'
DSIP_UNIX_SOCK = '/run/dsiprouter/dsiprouter.sock'
DSIP_IPC_SOCK = '/run/dsiprouter/ipc.sock'
DSIP_IPC_PASS = 'admin'

# dsiprouter logging settings
# syslog level and facility values based on:
# <http://www.nightmare.com/squirl/python-ext/misc/syslog.py>

DSIP_LOG_LEVEL = 3
DSIP_LOG_FACILITY = 18

# dSIPRouter SSL settings
# ssl key / cert are absolute paths
# email for re-certification must match certs
DSIP_SSL_KEY = '/etc/dsiprouter/certs/dsiprouter-key.pem'
DSIP_SSL_CERT = '/etc/dsiprouter/certs/dsiprouter-cert.pem'
DSIP_SSL_CA = '/etc/dsiprouter/certs/ca-list.pem'
DSIP_SSL_EMAIL = 'admin@sbc4.customers.dsiprouter.net'
DSIP_CERTS_DIR = '/etc/dsiprouter/certs'

# dSIPRouter internal settings

VERSION = '0.74'
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
KAM_DB_PASS = 'kamailiorw'

KAM_KAMCMD_PATH = '/usr/sbin/kamcmd'
KAM_CFG_PATH = '/etc/kamailio/kamailio.cfg'
KAM_TLSCFG_PATH = '/etc/kamailio/tls.cfg'
RTP_CFG_PATH = '/etc/rtpengine/rtpengine.conf'

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
DEFAULT_AUTH_DOMAIN = 'sip.dsiprouter.org'

# Teleblock Settings
TELEBLOCK_GW_ENABLED = 0
TELEBLOCK_GW_IP = '62.34.24.22'
TELEBLOCK_GW_PORT = '5066'
TELEBLOCK_MEDIA_IP = ''
TELEBLOCK_MEDIA_PORT = ''

# Flowroute API Settings
# TODO: encrypt/decrypt these creds instead of storing in plaintext
FLOWROUTE_ACCESS_KEY = ''
FLOWROUTE_SECRET_KEY = ''
FLOWROUTE_API_ROOT_URL = 'https://api.flowroute.com/v2'

# Homer settings
HOMER_ID = None
HOMER_HEP_HOST = ''
HOMER_HEP_PORT = 9060

# Network Settings
# possible network modes:
# 0:    (full-auto)     dynamically update all network settings, updated on startup
# 1:    (manual)        user sets all network settings manually, interfaces are ignored
# 2:    (dmz)           internal/external IP/subnet resolved from public/private interfaces, all other settings as in mode 0
NETWORK_MODE = 0
IPV6_ENABLED = False
# example: 192.168.0.1
INTERNAL_IP_ADDR = ''
# example: 192.168.0.1/24
INTERNAL_IP_NET = ''
# example: 2604:a880:400:d0::2048:3001
INTERNAL_IP6_ADDR = ''
# example: 2604:a880:400:d0::2048:3001/64
INTERNAL_IP6_NET = ''
# example: sip.dsiprouter.org
INTERNAL_FQDN = ''
# example: 1.1.1.1
EXTERNAL_IP_ADDR = ''
# example: 2604:a880:400:d0::2048:3001
EXTERNAL_IP6_ADDR = ''
# example: sip.dsiprouter.org
EXTERNAL_FQDN = ''
# example: eth0
PUBLIC_IFACE = ''
# example: eth1
PRIVATE_IFACE = ''

# upload folder for files
UPLOAD_FOLDER = '/tmp'

# email server config
MAIL_SERVER = 'smtp.gmail.com'
MAIL_PORT = 587
MAIL_USE_TLS = True
MAIL_USERNAME = ''
MAIL_PASSWORD = ''
MAIL_ASCII_ATTACHMENTS = False
MAIL_DEFAULT_SENDER = 'dSIPRouter <donotreply@sip.dsiprouter.org>'
MAIL_DEFAULT_SUBJECT = 'dSIPRouter System Notification'

# dSIPRouter licensing
DSIP_CORE_LICENSE = ''
DSIP_STIRSHAKEN_LICENSE = ''
DSIP_TRANSNEXUS_LICENSE = ''
DSIP_MSTEAMS_LICENSE = ''

################# End DB-Backed Settings #################

################# Local-Only Settings ####################
# settings in this section are not stored on the DB

# the key used by the flask session manager
DSIP_SESSION_KEY = None

# the fqdn / ip address used by uac/nathelper modules when contacting other servers
UAC_REG_ADDR = ''

# Cloud Platform
# The cloud platform the dSIPRouter is installed on
# The installer will update this
# '' = other or bare metal install
# AWS = Amazon Web Services, GCP = Google Cloud Platform, AZURE = Microsoft Azure, DO = Digital Ocean, VULTR = Vultr Cloud
CLOUD_PLATFORM = ''

# backup settings
BACKUP_FOLDER = '/var/backups/dsiprouter'

# TransNexus Settings
# TODO: marked for review, these settings should be synced across cluster in the DB
TRANSNEXUS_AUTHSERVICE_ENABLED = 0
TRANSNEXUS_AUTHSERVICE_HOST = 'outbound.sip.clearip.com:5060'
TRANSNEXUS_VERIFYSERVICE_ENABLED = 0
TRANSNEXUS_VERIFYSERVICE_HOST = 'inbound.sip.clearip.com:5060'

# STIR/SHAKEN Settings
# TODO: marked for review, these settings should be synced across cluster in the DB
STIR_SHAKEN_ENABLED = 0
STIR_SHAKEN_PREFIX_A = ''
STIR_SHAKEN_PREFIX_B = ''
STIR_SHAKEN_PREFIX_C = ''
STIR_SHAKEN_PREFIX_INVALID = ''
STIR_SHAKEN_BLOCK_INVALID = 0
STIR_SHAKEN_CERT_URL = ''
STIR_SHAKEN_KEY_PATH = ''

# where the project was installed
DSIP_PROJECT_DIR = '/opt/dsiprouter'
# where the dsip docs are served from
DSIP_DOCS_DIR = '/opt/dsiprouter/docs/build/html'

# dr_routing prefix matching supported characters
# refer to: <https://kamailio.org/docs/modules/5.1.x/modules/drouting.html#idp26708356>
DID_PREFIX_ALLOWED_CHARS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '#', '*'}

# micosoft teams settings
# pick one of the
MSTEAMS_DNS_ENDPOINTS = ["sip.pstnhub.microsoft.com","sip2.pstnhub.microsoft.com","sip3.pstnhub.microsoft.com"]
#MSTEAMS_DNS_ENDPOINTS = ["sip.pstnhub.dod.teams.microsoft.us","sip.pstnhub.gov.teams.microsoft.us"]
MSTEAMS_IP_ENDPOINTS = ["52.114.148.0","52.114.132.46","52.114.75.24","52.114.76.76","52.114.7.24","52.114.14.70","52.114.32.169"]
#MSTEAMS_IP_ENDPOINTS = ["52.127.64.33","52.127.88.59","52.127.64.34","52.127.92.64"]

# root DB credentials
ROOT_DB_HOST = 'localhost'
ROOT_DB_PORT = ''
ROOT_DB_USER = 'root'
ROOT_DB_PASS = ''
ROOT_DB_NAME = 'mysql'

# Where to sync settings from
# file  - load from setting.py file
# db    - load from dsip_settings table
LOAD_SETTINGS_FROM = 'file'

# where upgrades will be pulled from
GIT_REPO_URL = 'https://github.com/dOpensource/dsiprouter.git'
GIT_RELEASE_URL = 'https://api.github.com/repos/dOpensource/dsiprouter/releases'
############### End Local-Only Settings ##################
