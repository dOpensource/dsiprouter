#!/usr/bin/env bash

# mysql active active galera replication
# Supported OS: debian
# Notes:        uses mariadb

# TODO: configure from remote server using ssh keys

# function definitions
join() {
    local IFS="$1"; shift; echo "$*";
}

getClusterSize() {
    printf '%s' $(mysql -N -e "select VARIABLE_VALUE from information_schema.GLOBAL_STATUS where VARIABLE_NAME='wsrep_cluster_size'")
}

# configuration settings
CLUSTER_NAME="mysql_cluster"
INTERNAL_IP=$(hostname -I | awk '{print $1}')
MYSQL_PORT="3306"
SSH_PORT="22"
GALERA_REPL_PORT="4567"
GALERA_INCR_PORT="4568"
GALERA_SNAP_PORT="4444"

# debian locations
IP4RESTORE_FILE="/etc/iptables/rules.v4"
IP6RESTORE_FILE="/etc/iptables/rules.v6"

# service name changes between OS
# debian
MYSQL_SERVICE="mysql"
# centos
#MYSQL_SERVICE="mariadb"

# install requirements on all nodes
apt-get update -y
apt-get install -y rsync mariadb-server

# TODO: if mysql exists dump tables and copy to other DB's
##### dump and copy to all other nodes #####
#mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges > repl_dump.sql
##mysql --skip-column-names -A \
##    -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" | mysql --skip-column-names -A | sed 's/$/;/g' > repl_grants.sql
##    -e 'select * from information_schema.user_privileges'

##### import this dump to all other nodes #####
#mysql < repl_dump.sql

# set ipv4 firewall rules for each node
iptables -I INPUT 1 -p tcp --dport ${SSH_PORT} -j ACCEPT
iptables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
iptables -I INPUT 1 -p tcp --dport ${GALERA_REPL_PORT} -j ACCEPT
iptables -I INPUT 1 -p udp --dport ${GALERA_REPL_PORT} -j ACCEPT
iptables -I INPUT 1 -p tcp --dport ${GALERA_INCR_PORT} -j ACCEPT
iptables -I INPUT 1 -p tcp --dport ${GALERA_SNAP_PORT} -j ACCEPT
# Remove duplicates and save
mkdir -p $(dirname ${IP4RESTORE_FILE})
iptables-save | awk '!x[$0]++' > ${IP4RESTORE_FILE}

# set ipv6 firewall rules for each node
ip6tables -I INPUT 1 -p tcp --dport ${SSH_PORT} -j ACCEPT
ip6tables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
ip6tables -I INPUT 1 -p tcp --dport ${GALERA_REPL_PORT} -j ACCEPT
ip6tables -I INPUT 1 -p udp --dport ${GALERA_REPL_PORT} -j ACCEPT
ip6tables -I INPUT 1 -p tcp --dport ${GALERA_INCR_PORT} -j ACCEPT
ip6tables -I INPUT 1 -p tcp --dport ${GALERA_SNAP_PORT} -j ACCEPT
# Remove duplicates and save
mkdir -p $(dirname ${IP6RESTORE_FILE})
ip6tables-save | awk '!x[$0]++' > ${IP6RESTORE_FILE}

# shared between nodes
# TODO: get from cmdline args
IP_LIST=("10.10.10.150" "10.10.10.151")
i=0
for IP in ${IP_LIST[@]}; do
    if [[ "$IP" == "$INTERNAL_IP" ]]; then
        NODE_NAME="${CLUSTER_NAME}_NODE${i}"
    fi
    i=$((i+1))
done
NODE_NAME=${NODE_NAME:-$CLUSTER_NAME_$INTERNAL_IP}

# run on all nodes
cat << EOF > /etc/mysql/conf.d/cluster.cnf
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="${CLUSTER_NAME}"
wsrep_cluster_address="gcomm://$(join ',' ${IP_LIST[@]})"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="${INTERNAL_IP}"
wsrep_node_name="${NODE_NAME}"
EOF

# stop mysql service
systemctl stop ${MYSQL_SERVICE}

# copy the 1st node's debian.cnf to the rest of the nodes
# rsync /etc/mysql/debian.cnf root@10.10.10.151:/etc/mysql/debian.cnf

##### bootstrap a single db node #######
galera_new_cluster
if (( $? != 0 )) || (( $(getClusterSize) < 1 )); then
    echo "Bootstrapping cluster failed" && exit 1
fi
########################################

### run on the rest of the nodes ###
systemctl restart ${MYSQL_SERVICE}
if (( $? != 0 )) || (( $(getClusterSize) < 2 )); then
    echo "Node addition to cluster failed" && exit 1
fi
####################################

exit 0