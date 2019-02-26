#!/usr/bin/env bash

# mysql active active group replication
# Supported OS: debian
# Notes:        uses mysql community db

# TODO: configure from remote server using ssh keys

# install requirements on all nodes
MYSQL_APT_CONFIG_VER="0.8.10-1"
MYSQL_APT_CONFIG_NAME="mysql-apt-config_${MYSQL_APT_CONFIG_VER}_all.deb"
MYSQL_APT_CONFIG_URL="https://dev.mysql.com/get/${MYSQL_APT_CONFIG_NAME}"
wget ${MYSQL_APT_CONFIG_URL}
dpkg --force-depends -i ${MYSQL_APT_CONFIG_NAME}
apt-get update -y
apt-get install -y libaio1
apt-get install -y libmecab2
apt-get install -y mysql-common mysql-client mysql-server
apt-get install -y uuid-runtime
apt-get -f install -y

# set for each node
ID=2
INTERNAL_IP=$(hostname -I | awk '{print $1}')
PORT="3306"
REPL_PORT="6606"

# set for each node
iptables -A INPUT -p tcp --dport ${PORT} -j ACCEPT
iptables -A INPUT -p tcp --dport ${REPL_PORT} -j ACCEPT
iptables-save

# shared between nodes
# get using: uuidgen
GROUP_ID="2ff15901-0fda-4ea8-9391-51fbb53ae28d"
IP_LIST="10.10.2.40,10.10.2.41"
SEED_LIST="10.10.2.40:${REPL_PORT},10.10.2.41:${REPL_PORT}"


# run on all nodes
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

########### run on one node ############
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

##### dump and copy to all other nodes #####
mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges > repl_dump.sql
#mysql --skip-column-names -A \
#    -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" | mysql --skip-column-names -A | sed 's/$/;/g' > repl_grants.sql
#    -e 'select * from information_schema.user_privileges'

##### import this dump to all other nodes #####
mysql --init-command="RESET MASTER" < repl_dump.sql

##### bootstrap a single db node #######
mysql <<- 'EOF'
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;
EOF
########################################

### run on the rest of the nodes ###
mysql -e 'START GROUP_REPLICATION'
####################################

# NOTE: if a node becomes out of sync and can not rejoin (irrecoverable GTID's out of sync)
# you must dump a good database, import to down server, and resync with the group
#mysql --init-command="RESET MASTER" < repl_dump.sql
#mysql -e 'START GROUP_REPLICATION'

# check the status of group
mysql -e 'SELECT * FROM performance_schema.replication_group_members'

exit 0