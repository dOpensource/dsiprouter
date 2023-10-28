#!/usr/bin/env bash
#
# Summary:      mysql active active group replication
# Supported OS: debian
# Author:       DevOpSec <tmoore@goflyball.com>
# Date:         Feb-2019
# Notes:        uses mysql community db
#

# TODO: configure from remote server using ssh keys
# TODO: add support for rhel-based distros

######################### warn user and exit #########################
{
    echo ""
    printerr "Mysql Group Replication install is under construction"
    echo ""
    printwarn "Use this script AT YOUR OWN RISK"
    echo ""
    echo "We suggest you use Mysql Galera Replication (install script included in repo) at this time"
    echo "If you must have Mysql Group Replication, READ THE ENTIRE script and FOLLOW THE COMMENTS"
    echo ""
    exit 1
}
######################################################################

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
. ${PROJECT_ROOT}/HA/shared_lib.sh


# node configuration settings
MYSQL_PORT="3306"
REPL_PORT="6606"


printUsage() {
    pprint "Usage: $0 [-remotedb|-h|--help] <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ..."
}

if ! isRoot; then
    printerr "Must be run with root privileges" && exit 1
fi

if (( $# < 2 )) || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printerr "At least 2 nodes are required to setup replication" && printUsage && exit 1
fi

setOSInfo
# install local requirements for script
case "$DISTRO" in
    debian|ubuntu|linuxmint)
        apt-get install -y sshpass gawk
        ;;
    centos|redhat|amazon)
        yum install -y epel-release
        yum install -y sshpass gawk
        ;;
    *)
        printerr "Your OS Distro is currently not supported"
        exit 1
        ;;
esac


##### shared between ALL NODES (set per your own configs)
# get using: uuidgen
GROUP_ID="2ff15901-0fda-4ea8-9391-51fbb53ae28d"
IP_LIST="10.10.2.40,10.10.2.41"
SEED_LIST="10.10.2.40:${REPL_PORT},10.10.2.41:${REPL_PORT}"
########################################

##### install requirements FOR EACH NODE
MYSQL_APT_CONFIG_VER="0.8.10-1"
MYSQL_APT_CONFIG_NAME="mysql-apt-config_${MYSQL_APT_CONFIG_VER}_all.deb"
MYSQL_APT_CONFIG_URL="https://dev.mysql.com/get/${MYSQL_APT_CONFIG_NAME}"
IP4RESTORE_FILE="/etc/iptables/rules.v4"
IP6RESTORE_FILE="/etc/iptables/rules.v6"
wget ${MYSQL_APT_CONFIG_URL}
dpkg --force-depends -i ${MYSQL_APT_CONFIG_NAME}
apt-get update -y
apt-get install -y libaio1
apt-get install -y libmecab2
apt-get install -y mysql-common mysql-client mysql-server
apt-get install -y uuid-runtime
apt-get install -y iptables-persistent netfilter-persistent
apt-get -f install -y
########################################

##### set firewall rules FOR EACH NODE
# use firewalld if installed
if cmdExists "firewall-cmd"; then
    firewall-cmd --zone=public --add-port=${MYSQL_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${REPL_PORT}/tcp --permanent
    firewall-cmd --reload
else
    # set ipv4 firewall rules for each node
    iptables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport ${REPL_PORT} -j ACCEPT
    # set ipv6 firewall rules for each node
    ip6tables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
    ip6tables -I INPUT 1 -p tcp --dport ${REPL_PORT} -j ACCEPT
fi

# Remove duplicates and save
mkdir -p $(dirname ${IP4RESTORE_FILE})
iptables-save | awk '!x[$0]++' > ${IP4RESTORE_FILE}
mkdir -p $(dirname ${IP6RESTORE_FILE})
ip6tables-save | awk '!x[$0]++' > ${IP6RESTORE_FILE}
########################################

##### set dynamic variables FOR EACH NODE (id increments per node)
ID=1
INTERNAL_IP=$(hostname -I | awk '{print $1}')
########################################

##### add cluster config FOR EACH NODE
cat << EOF > /etc/mysql/conf.d/cluster.cnf
[mysqld]
bind-address=0.0.0.0

# General replication settings
plugin-load = group_replication.so
gtid_mode = ON
enforce_gtid_consistency = ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
binlog_checksum = NONE
log_slave_updates = ON
log_bin = binlog
binlog_format = ROW
# prevent use of non-transactional storage engines
disabled_storage_engines="MyISAM,BLACKHOLE,FEDERATED,ARCHIVE"
transaction_write_set_extraction = XXHASH64
# InnoDB gap locks are problematic for multi-primary conflict detection,
# but none are used with READ-COMMITTED so isolate those
transaction-isolation = 'READ-COMMITTED'
group_replication = FORCE_PLUS_PERMANENT
group_replication_bootstrap_group = OFF
group_replication_start_on_boot = ON

# Shared replication group configuration
group_replication_group_name = "${GROUP_ID}"
group_replication_ip_whitelist = "${IP_LIST}"
group_replication_group_seeds = "${SEED_LIST}"

# Multi-primary mode, where any host can accept writes
group_replication_single_primary_mode = OFF
group_replication_enforce_update_everywhere_checks = ON

# Host specific replication configuration
server_id = ${ID}
group_replication_local_address = "${INTERNAL_IP}:${REPL_PORT}"
EOF

# restart mysql with new config loaded
MYSQL_SERVICES=$(systemctl list-unit-files | grep 'mysql' | awk '{print $1}')
for SERVICE in $MYSQL_SERVICES; do systemctl restart ${SERVICE}; done
########################################

##### set logging and privileges ON PRIMARY NODE
mysql <<- 'EOF'
SET SQL_LOG_BIN=0;
ALTER USER IF EXISTS kamailio@'%' IDENTIFIED WITH 'mysql_native_password' BY 'kamailiorw';
FLUSH PRIVILEGES;
CHANGE MASTER TO MASTER_USER='kamailio', MASTER_PASSWORD='kamailiorw' FOR CHANNEL 'group_replication_recovery';
# Parallel applier support -- Speedup distributed recovery time??
#SET @@GLOBAL.binlog_transaction_dependency_tracking=WRITESET;
#SET @@GLOBAL.binlog_transaction_dependency_tracking=WRITESET_SESSION;
SET @@GLOBAL.binlog_transaction_dependency_tracking=COMMIT_ORDER; #default
SET SQL_LOG_BIN=1;
EOF
########################################

##### dump db ON PRIMARY NODE
# TODO: change this to use functions from shared_lib
mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges > repl_dump.sql
mysql -sN -A -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" \
    | mysql -sN -A \
    | sed 's/$/;/g' \
    | awk '!x[$0]++' >> repl_dump.sql
########################################


##### import db dump to ALL NON-PRIMARY NODES
mysql --init-command="RESET MASTER" < repl_dump.sql
########################################

##### bootstrap the PRIMARY NODE
mysql <<- 'EOF'
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;
EOF
########################################

### run replication on ALL NON-PRIMARY NODES
mysql -e 'START GROUP_REPLICATION'
####################################

# NOTE: if a node becomes out of sync and can not rejoin (irrecoverable GTID's out of sync)
#       here is the process to resync an out of sync server:
# 1. dump one of the good databases
# 2. import to down server (shown below)
# 3. resync with the group (shown below)
#
#mysql --init-command="RESET MASTER" < repl_dump.sql
#mysql -e 'START GROUP_REPLICATION'

# check the status of group
mysql -e 'SELECT * FROM performance_schema.replication_group_members'

exit 0