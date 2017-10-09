# dSIPRouter settings

DSIP_PORT=5000
USERNAME='admin'
PASSWORD='password'

# dSIPRouter internal settings

VERSION=0.2
DEBUG=0

# MySQL settings for kamailio

KAM_DB_TYPE='mysql'
KAM_DB_HOST='localhost'
KAM_DB_PORT='3306'
KAM_DB_NAME='kamailio'
KAM_DB_USER='kamailio'
KAM_DB_PASS='kamailiorw'

# SQLAlchemy Settings

# Will disable modification tracking
SQLALCHEMY_TRACK_MODIFICATIONS=False
SQLALCHEMY_SQL_DEBUG=False

FLT_CARRIER=8
FLT_PBX=9
