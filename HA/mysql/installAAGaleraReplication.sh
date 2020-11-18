#!/usr/bin/env bash
#
# Summary:      mysql active active galera replication
# Supported OS: debian, centos
# Notes:        uses mariadb
#               you must be able to ssh to every node in the cluster from where script is run
#               supported ssh authentication methods: password, pubkey
#               if quorum is lost between 2-node cluster you must reset the quorum, bootstrap the non-primary:
#               mysql -e "SET GLOBAL wsrep_provider_options='pc.bootstrap=YES';"
#               ref: <http://galeracluster.com/documentation-webpages/quorumreset.html>
# Usage:        ./installAAGaleraReplication.sh [-h|--help|-remotedb] <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ...
#

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
. ${PROJECT_ROOT}/HA/shared_lib.sh


# node configuration settings
CLUSTER_NAME="mysqlcluster"
MYSQL_USER="root"
MYSQL_PASS="$(createPass)"
MYSQL_PORT="3306"
BACKUPS_DIR="/var/backups"
WITH_REMOTE_DB=0
MYSQL_BACKUP_DIR="${BACKUPS_DIR}/mysql"
GALERA_REPL_PORT="4567"
GALERA_INCR_PORT="4568"
GALERA_SNAP_PORT="4444"
SSH_DEFAULT_OPTS="-o StrictHostKeyChecking=no -o CheckHostIp=no -o ServerAliveInterval=5 -o ServerAliveCountMax=2"
# galera library only available on mariadb ver >= 10.1
# at the time of writing default repo ver == 5.5
# they also do have patches for 5.5 and 10.0 if needed
MYSQL_REQ_VER="10.1"


printUsage() {
    pprint "Usage: $0 [-h|--help|-remotedb] <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ..."
}

if ! isRoot; then
    printerr "Must be run with root privileges" && exit 1
fi

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printUsage && exit 1
fi

# loop through args and evaluate any options
ARGS=()
while (( $# > 0 )); do
    ARG="$1"
    case $ARG in
        -remotedb)
            WITH_REMOTE_DB=1
            shift
            ;;
        *)  # add to list of args
            ARGS+=( "$ARG" )
            shift
            ;;
    esac
done

if (( ${#ARGS[@]} < 2 )); then
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

# prints number of nodes in cluster
getClusterSize() {
    local OPT=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        OPT="$1"
        case $OPT in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # no valid args skip
                shift
                ;;
        esac
    done

    mysql -sN --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
        -e "select VARIABLE_VALUE from information_schema.GLOBAL_STATUS where VARIABLE_NAME='wsrep_cluster_size'"
}

# $1 == ipv4 persistent rules file
# $2 == ipv6 persistent rules file
setFirewallRules() {
    local IP4RESTORE_FILE="$1"
    local IP6RESTORE_FILE="$2"

    # use firewalld if installed
    if cmdExists "firewall-cmd"; then
        firewall-cmd --zone=public --add-port=${MYSQL_PORT}/tcp --permanent
        firewall-cmd --zone=public --add-port=${GALERA_REPL_PORT}/tcp --permanent
        firewall-cmd --zone=public --add-port=${GALERA_REPL_PORT}/udp --permanent
        firewall-cmd --zone=public --add-port=${GALERA_INCR_PORT}/tcp --permanent
        firewall-cmd --zone=public --add-port=${GALERA_SNAP_PORT}/tcp --permanent

        firewall-cmd --reload
    else
        # set ipv4 firewall rules for each node
        iptables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
        iptables -I INPUT 1 -p tcp --dport ${GALERA_REPL_PORT} -j ACCEPT
        iptables -I INPUT 1 -p udp --dport ${GALERA_REPL_PORT} -j ACCEPT
        iptables -I INPUT 1 -p tcp --dport ${GALERA_INCR_PORT} -j ACCEPT
        iptables -I INPUT 1 -p tcp --dport ${GALERA_SNAP_PORT} -j ACCEPT

        # set ipv6 firewall rules for each node
        ip6tables -I INPUT 1 -p tcp --dport ${MYSQL_PORT} -j ACCEPT
        ip6tables -I INPUT 1 -p tcp --dport ${GALERA_REPL_PORT} -j ACCEPT
        ip6tables -I INPUT 1 -p udp --dport ${GALERA_REPL_PORT} -j ACCEPT
        ip6tables -I INPUT 1 -p tcp --dport ${GALERA_INCR_PORT} -j ACCEPT
        ip6tables -I INPUT 1 -p tcp --dport ${GALERA_SNAP_PORT} -j ACCEPT
    fi

    # Remove duplicates and save
    mkdir -p $(dirname ${IP4RESTORE_FILE})
    iptables-save | awk '!x[$0]++' > ${IP4RESTORE_FILE}
    mkdir -p $(dirname ${IP6RESTORE_FILE})
    ip6tables-save | awk '!x[$0]++' > ${IP6RESTORE_FILE}
}

# loop through args and grab hosts
HOST_LIST=()
for NODE in ${ARGS[@]}; do
    HOST_LIST+=( $(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1) )
done

# loop through args and run setup commands
i=0
for NODE in ${ARGS[@]}; do
    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]" && exit 1
    fi

    SSH_CMD="ssh"
    if [ -z "$HOST" ]; then
        printerr "Node [${NODE}] does not contain a host" && printUsage && exit 1
    else
        SSH_REMOTE_HOST="${HOST}"
    fi
    SSH_REMOTE_HOST="${USER}@${SSH_REMOTE_HOST}"
    if [ -n "$PASS" ]; then
        #SSH_CMD="sshpass -f <(printf '${PASS}\n') ssh"
        #SSH_CMD="sshpass -p '${PASS}' ssh"
        export SSHPASS="${PASS}"
        SSH_CMD="sshpass -e ssh"
    fi
    SSH_OPTS="${SSH_DEFAULT_OPTS} -p ${PORT}"
    SSH_CMD="${SSH_CMD} ${SSH_REMOTE_HOST} ${SSH_OPTS}"

    # validate unattended ssh connection
    if ! checkSSH ${SSH_CMD}; then
        printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]" && exit 1
    fi

    NODE_NAME="${CLUSTER_NAME}-node$((i+1))"
    # remote server will be using bash as interpreter
    SSH_CMD="${SSH_CMD} bash"
    # DEBUG:
    printdbg "SSH_CMD: ${SSH_CMD}"

    # run commands through ssh
#    (cat <<- EOSSH
    (${SSH_CMD} <<- EOSSH
    set -x

    # re-declare functions and vars we pass to remote server
    # note that variables in function definitions (from calling environement)
    # lose scope unless local to function, they must be passed to remote
    $(typeset -f printdbg)
    $(typeset -f printerr)
    $(typeset -f cmdExists)
    $(typeset -f setOSInfo)
    $(typeset -f getPkgVer)
    $(typeset -f getClusterSize)
    $(typeset -f dumpMysqlDatabases)
    $(typeset -f setFirewallRules)
    MYSQL_USER="$MYSQL_USER"
    MYSQL_PASS="$MYSQL_PASS"
    MYSQL_PORT="$MYSQL_PORT"
    GALERA_REPL_PORT="$GALERA_REPL_PORT"
    GALERA_INCR_PORT="$GALERA_INCR_PORT"
    GALERA_SNAP_PORT="$GALERA_SNAP_PORT"
    ESC_SEQ="\033["
    ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
    ANSI_RED="\${ESC_SEQ}1;31m"
    ANSI_GREEN="\${ESC_SEQ}1;32m"

    # backup dirs we will be using
    mkdir -p ${MYSQL_BACKUP_DIR}/{etc,var/lib,\${HOME},dumps}

    # function to implement mysqldump merging
    dumpPrimaryNode() {
        case \$MYSQL_MERGE_ACTION in
            0)
                printdbg 'no database merging needed on ${HOST}'
                ;;
            1)
                printdbg 'overwriting databases on ${HOST}'
                dumpMysqlDatabases --full --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' >> ${MYSQL_BACKUP_DIR}/dumps/primary.sql
                dumpMysqlDatabases --grants --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' >> ${MYSQL_BACKUP_DIR}/dumps/primary.sql
                ;;
            2)
                printdbg 'merging databases on ${HOST}'
                dumpMysqlDatabases --merge --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' >> ${MYSQL_BACKUP_DIR}/dumps/primary.sql
                dumpMysqlDatabases --grants --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' >> ${MYSQL_BACKUP_DIR}/dumps/primary.sql
                ;;
        esac
    }


    # will determine how we merge databases
    # 0 == no merge (fresh install no changes)
    # 1 == overwrite (existing databases cloned)
    # 2 == merge (merge primary databases with existing)
    MYSQL_MERGE_ACTION=0

    setOSInfo
    printdbg 'installing requirements'
    if [[ "\$DISTRO" == "debian" ]]; then
        # debian specific settings
        MYSQL_SERVICE="mysql"
        MYSQL_SECTION="mysqld"
        MYSQL_CLUSTER_CONFIG="/etc/mysql/mariadb.conf.d/cluster.cnf"
        IP4RESTORE_FILE="/etc/iptables/rules.v4"
        IP6RESTORE_FILE="/etc/iptables/rules.v6"
        export DEBIAN_FRONTEND=noninteractive

        apt-get install -y curl perl sed gawk rsync dirmngr bc iptables-persistent netfilter-persistent

        # install or upgrade mysql if needed
        # debian has multiple packages for mariadb-server, easier to find version with dpkg
        MYSQL_VER=\$(dpkg -l |  grep -P 'mariadb-server(-[0-9]+)?(?!-\w)' | awk '{print \$3}' \\
            | grep -oP '([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' | sed 's/\./%/; s/\.//g; s/%/\./')
        if cmdExists 'mysql'; then
            # check repo version and update if needed
            if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                MYSQL_MERGE_ACTION=1

                # dump primary node databases
                if (( $i == 0 )); then
                    dumpPrimaryNode
                fi

                # backup data in case upgrade fails
                systemctl stop \${MYSQL_SERVICE}
                mv -f /var/lib/mysql ${MYSQL_BACKUP_DIR}/var/lib/
                cp -f /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                cp -rf /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                cp -rf /etc/mysql* ${MYSQL_BACKUP_DIR}/etc/
                cp -f \${HOME}/.my.cnf* ${MYSQL_BACKUP_DIR}/\${HOME}/

                curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                MYSQL_MAJOR_VER=\$(getPkgVer -l 'mariadb-server' | cut -c -4)

                debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password password temp"
                debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password_again password temp"
                apt-get install -y mariadb-client mariadb-server

                systemctl enable \${MYSQL_SERVICE}
                systemctl start \${MYSQL_SERVICE}

                # automate mysql_secure_install cmds
                mysql --user='root' --password='temp' mysql \\
                    -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                    -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                    -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                    -e 'DELETE FROM db WHERE Db="test" or Db="test\_%";' \\
                    -e 'DELETE FROM user WHERE User="";' \\
                    -e 'FLUSH PRIVILEGES;'

                # allow auto login for root
                printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

            else
                MYSQL_MERGE_ACTION=2

                # make sure root can login remotely
                mysql --user='root' --password='${MYSQL_PASS}' mysql \\
                    -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                    -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                    -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                    -e 'FLUSH PRIVILEGES;'

                # dump primary node databases
                if (( $i == 0 )); then
                    dumpPrimaryNode
                fi
            fi
        else
            # check repo version and update if needed
            if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                MYSQL_MAJOR_VER=\$(getPkgVer -l 'mariadb-server' | cut -c -4)
            fi

            debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password password temp"
            debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password_again password temp"
            apt-get install -y mariadb-client mariadb-server

            systemctl enable \${MYSQL_SERVICE}
            systemctl start \${MYSQL_SERVICE}

            # automate mysql_secure_install cmds
            mysql --user='root' --password='temp' mysql \\
                -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                -e 'DELETE FROM db WHERE Db="test" or Db="test\_%";' \\
                -e 'DELETE FROM user WHERE User="";' \\
                -e 'FLUSH PRIVILEGES;'

            # allow auto login for root user
            printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

        fi

    elif [[ "\$DISTRO" == "centos" ]]; then
        # centos specific settings
        MYSQL_SERVICE="mariadb"
        MYSQL_SECTION="galera"
        MYSQL_CLUSTER_CONFIG="/etc/my.cnf.d/cluster.cnf"
        IP4RESTORE_FILE="/etc/sysconfig/iptables"
        IP6RESTORE_FILE="/etc/sysconfig/ip6tables"

        yum install -y curl perl sed gawk rsync bc

        # centos SELINUX
        if sestatus | head -1 | grep -qi 'enabled'; then
            yum install -y policycoreutils-python setools-console selinux-policy-devel

            semanage permissive -a mysqld_t

            semanage port -a -t mysqld_port_t -p tcp 3306
            semanage port -a -t mysqld_port_t -p tcp 4567
            semanage port -a -t mysqld_port_t -p tcp 4568
            semanage port -a -t mysqld_port_t -p tcp 4444
            semanage port -a -t mysqld_port_t -p udp 4567

            setsebool -P daemons_enable_cluster_mode 1

            mkdir -p /tmp/selinux

            (cat <<'EOF'
module galera 1.0;

require {
    type mysqld_t;
    type rsync_exec_t;
    type anon_inodefs_t;
    type proc_net_t;
    type kerberos_port_t;
    class file { read execute execute_no_trans getattr open };
    class tcp_socket { name_bind name_connect };
    class process { setpgid siginh rlimitinh noatsecure };
    type unconfined_t;
    type initrc_tmp_t;
    type init_t;
    class service enable;
}

#============= mysqld_t ==============
allow mysqld_t initrc_tmp_t:file open;
allow mysqld_t self:process setpgid;
allow mysqld_t rsync_exec_t:file { read execute execute_no_trans getattr open };
allow mysqld_t anon_inodefs_t:file getattr;
allow mysqld_t proc_net_t:file { read open };
allow mysqld_t kerberos_port_t:tcp_socket { name_bind name_connect };

#============= unconfined_t ==============
allow unconfined_t init_t:service enable;
EOF
            ) > /tmp/selinux/galera.te

            checkmodule -M -m /tmp/selinux/galera.te -o /tmp/selinux/galera.mod
            semodule_package -m /tmp/selinux/galera.mod -o /tmp/selinux/galera.pp
            semodule -i /tmp/selinux/galera.pp
        fi

        # install or upgrade mysql if needed
        MYSQL_VER=\$(getPkgVer 'mariadb-server')
        if cmdExists 'mysql'; then
            # check repo version and update if needed
            if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                MYSQL_MERGE_ACTION=1
                # dump primary node databases
                if (( $i == 0 )); then
                    dumpPrimaryNode
                fi

                # backup data in case upgrade fails
                systemctl stop \${MYSQL_SERVICE}
                mv -f /var/lib/mysql ${MYSQL_BACKUP_DIR}/var/lib/
                cp -f /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                cp -rf /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                cp -rf /etc/mysql* ${MYSQL_BACKUP_DIR}/etc/
                cp -f \${HOME}/.my.cnf* ${MYSQL_BACKUP_DIR}/\${HOME}/

                curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                yum install -y MariaDB-client MariaDB-server

                # on CentOS mariadb fresh install doesn't have socket connection
                # we need this to allow unix socket as fallback (parsed last in configs)
                if ! grep -q '\[mysqld\]' /etc/my.cnf 2>/dev/null; then
                    (cat <<'EOF'
[mysqld]
user                = mysql
pid-file            = /var/lib/mysql/mysql.pid
socket              = /var/lib/mysql/mysql.sock
port                = 3306
basedir             = /usr
datadir             = /var/lib/mysql
bind-address        = 127.0.0.1
tmpdir              = /tmp
log_error           = /var/log/mysql/error.log
expire_logs_days    = 10
max_binlog_size     = 100M
plugin-load-add     = auth_socket.so
skip-external-locking

[mysqld_safe]
log-error           = /var/log/mysql/error.log
pid-file            = /var/lib/mysql/mysql.pid

EOF
                    ) > /etc/my.cnf.d/server.cnf

                    # make other configs lower priority
                    mv -f /etc/my.cnf.d/server.cnf /etc/my.cnf.d/50-server.cnf
                    mv -f /etc/my.cnf.d/mysql-clients.cnf /etc/my.cnf.d/50-mysql-clients.cnf
                fi

                systemctl enable \${MYSQL_SERVICE}
                systemctl start \${MYSQL_SERVICE}

                mysqladmin --user='root' password 'temp'

                # automate mysql_secure_install cmds
                mysql --user='root' --password='temp' mysql \\
                    -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                    -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                    -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                    -e 'UPDATE user SET plugin="unix_socket" WHERE Host="localhost";' \\
                    -e 'UPDATE user SET plugin="" WHERE Host<>"localhost";' \\
                    -e 'DELETE FROM db WHERE Db="test" or Db="test\_%";' \\
                    -e 'DELETE FROM user WHERE User="";' \\
                    -e 'FLUSH PRIVILEGES;'


                # allow auto login for root
                printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

            else
                MYSQL_MERGE_ACTION=2

                # make sure root can login remotely
                mysql --user='root' --password='${MYSQL_PASS}' mysql \\
                    -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                    -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                    -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                    -e 'UPDATE user SET plugin="unix_socket" WHERE Host="localhost";' \\
                    -e 'UPDATE user SET plugin="" WHERE Host<>"localhost";' \\
                    -e 'FLUSH PRIVILEGES;'

                # dump primary node databases
                if (( $i == 0 )); then
                    dumpPrimaryNode
                fi
            fi
        else
            # check repo version and update if needed
            if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
            fi
            yum install -y MariaDB-client MariaDB-server

            # on CentOS mariadb fresh install doesn't have socket connection
            # we need this to allow unix socket as fallback (parsed last in configs)
            if ! grep -q '\[mysqld\]' /etc/my.cnf 2>/dev/null; then
                (cat <<'EOF'
[mysqld]
user                = mysql
pid-file            = /var/lib/mysql/mysql.pid
socket              = /var/lib/mysql/mysql.sock
port                = 3306
basedir             = /usr
datadir             = /var/lib/mysql
bind-address        = 127.0.0.1
tmpdir              = /tmp
log_error           = /var/log/mysql/error.log
expire_logs_days    = 10
max_binlog_size     = 100M
plugin-load-add     = auth_socket.so
skip-external-locking

[mysqld_safe]
log-error           = /var/log/mysql/error.log
pid-file            = /var/lib/mysql/mysql.pid

EOF
                ) > /etc/my.cnf.d/server.cnf

                # make other configs lower priority
                mv -f /etc/my.cnf.d/server.cnf /etc/my.cnf.d/50-server.cnf
                mv -f /etc/my.cnf.d/mysql-clients.cnf /etc/my.cnf.d/50-mysql-clients.cnf
            fi

            systemctl enable \${MYSQL_SERVICE}
            systemctl start \${MYSQL_SERVICE}

            mysqladmin --user='root' password 'temp'

            # automate mysql_secure_install cmds
            mysql --user='root' --password='temp' mysql \\
                -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                -e 'UPDATE user SET Password=PASSWORD("${MYSQL_PASS}") WHERE User="root";' \\
                -e 'UPDATE user SET plugin="unix_socket" WHERE Host="localhost";' \\
                -e 'UPDATE user SET plugin="" WHERE Host<>"localhost";' \\
                -e 'DELETE FROM db WHERE Db="test" or Db="test\_%";' \\
                -e 'DELETE FROM user WHERE User="";' \\
                -e 'FLUSH PRIVILEGES;'

            # allow auto login for root user
            printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf
        fi

    else
        printerr "Your OS Distro is currently not supported" && exit 1
    fi

    if ! cmdExists 'rsync' || ! cmdExists 'rsync'; then
        printerr 'Failed to install requirements' && exit 1
    fi

    # if mysql is not local to kamailio allow remote auth for kamailio user
    if (( ${WITH_REMOTE_DB} == 1 )); then
         mysql -sN -A -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>'' AND host='localhost' AND user LIKE 'kamailio%';" \\
            | mysql -sN -A \\
            | sed 's/$/;/g' \\
            | awk '!x[\$0]++' \\
            | sed 's/localhost/%/g' \\
            | mysql
    fi

    # merge databases if needed
    if (( $i == 0 )) && (( \$MYSQL_MERGE_ACTION != 0 )); then
        printdbg 'merging databases on primary node'
        mysql < ${MYSQL_BACKUP_DIR}/dumps/primary.sql
    else
        case \$MYSQL_MERGE_ACTION in
            0)
                printdbg 'merging database grants on ${HOST}'
                dumpMysqlDatabases --grants --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' --host='${HOST_LIST[0]}' | mysql
                ;;
            1)
                printdbg 'overwriting databases on ${HOST}'
                dumpMysqlDatabases --full --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' --host='${HOST_LIST[0]}' | mysql
                dumpMysqlDatabases --grants --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' --host='${HOST_LIST[0]}' | mysql
                ;;
            2)
                printdbg 'merging databases on ${HOST}'
                dumpMysqlDatabases --merge --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' --host='${HOST_LIST[0]}' | mysql
                dumpMysqlDatabases --grants --user='${MYSQL_USER}' --password='${MYSQL_PASS}' --port='${MYSQL_PORT}' --host='${HOST_LIST[0]}' | mysql
                ;;
        esac
    fi

    systemctl stop \${MYSQL_SERVICE}

    setFirewallRules "\$IP4RESTORE_FILE" "\$IP6RESTORE_FILE"

    # configure cluster settings
    ( cat << EOF
[\${MYSQL_SECTION}]
binlog_format=row
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
log_error=/var/log/mysql/error.log

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=\$(find /usr/lib{32,64,}{/x86_64*,/i386*,}/galera/ -name 'libgalera_smm*.so' -print -quit 2>/dev/null)

# Galera Cluster Configuration
wsrep_cluster_name="${CLUSTER_NAME}"
wsrep_cluster_address="gcomm://$(join ',' ${HOST_LIST[@]})"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="\$(hostname -I | awk '{print \$1}')"
wsrep_node_name="${NODE_NAME}"
EOF
    ) > \${MYSQL_CLUSTER_CONFIG}

    # fix debian.cnf to be the same on all nodes (used by debian-maintenance)
    if [[ "\$DISTRO" == "debian" ]]; then
        sed -i -r \\
            -e "s|(host[\t ]*\=[\t ]*).*|host = localhost|g" \\
            -e "s|(user[\t ]*\=[\t ]*).*|user = ${MYSQL_USER}|g" \\
            -e "s|(password[\t ]*\=[\t ]*).*|password = ${MYSQL_PASS}|g" \\
            /etc/mysql/debian.cnf
    fi

    # startup mysql server
    if (( $i == 0 )); then
        # TODO: should we dump primary db as well?

        # bootstrap first db node
        galera_new_cluster
        if (( \$? == 0 )) && (( \$(getClusterSize) == 1 )); then
            printdbg "Bootstrapping cluster success"
        else
            printerr "Bootstrapping cluster failed [${NODE_NAME}]" && exit 1
        fi
    else
        # restart service to connect other db nodes
        systemctl restart \${MYSQL_SERVICE}
        if (( \$? == 0 )) && (( \$(getClusterSize) >= 2 )); then
            printdbg "Adding Node to cluster success"
        else
            printerr "Adding Node to cluster failed [${NODE_NAME}]" && exit 1
        fi
    fi

    exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "galera configuration failed on ${HOST}" && exit 1
    fi

    i=$((i+1))
done

exit 0