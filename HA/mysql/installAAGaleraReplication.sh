#!/usr/bin/env bash
#
# Summary:      mysql active active galera replication
#
# Supported OS: debian, centos, amzn
#
# Notes:        uses mariadb
#               you must be able to ssh to every node in the cluster from where script is run
#               supported ssh authentication methods: password, pubkey
#               if quorum is lost between 2-node cluster you must reset the quorum, bootstrap the non-primary:
#               mysql -e "SET GLOBAL wsrep_provider_options='pc.bootstrap=YES';"
#               ref: <http://galeracluster.com/documentation-webpages/quorumreset.html>
##
# TODO:         support active/passive galera replication
#               https://medium.com/mr-dops/mariadb-with-galera-cluster-8ded2e83721b
#

# set project root, if in a git repo resolve top level dir
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
SSH_KEY_FILE=""
# galera library only available on mariadb ver >= 10.1
# at the time of writing default repo ver == 5.5
# they also do have patches for 5.5 and 10.0 if needed
MYSQL_REQ_VER="10.1"
DEBUG=0


printUsage() {
    pprint "Usage: $0 [-h|--help|-debug|-remotedb] [-i <ssh key file>] <[sshuser1[:sshpass1]@]node1[:sshport1]> <[sshuser2[:sshpass2]@]node2[:sshport2]> ..."
}

# loop through args and evaluate any options
NODES=()
while (( $# > 0 )); do
    ARG="$1"
    case $ARG in
        -h|--help)
            printUsage
            exit 0
            ;;
        -debug)
            DEBUG=1
            shift
            ;;
        -remotedb)
            WITH_REMOTE_DB=1
            shift
            ;;
        -i)
            shift
            SSH_KEY_FILE="$1"
            shift
            ;;
        *)  # add to list of args
            NODES+=( "$ARG" )
            shift
            ;;
    esac
done

if (( $DEBUG == 1 )); then
    set -x
fi

if (( ${#NODES[@]} < 2 )); then
    printerr "At least 2 nodes are required to setup replication"
    printUsage
    exit 1
fi

# install local requirements for script
# TODO: validate sudo exists, if not and user=root then install, otherwise fail
if ! cmdExists 'ssh' || ! cmdExists 'sshpass' || ! cmdExists 'nmap' || ! cmdExists 'sed' || ! cmdExists 'awk'; then
    printdbg 'Installing local requirements for cluster install'

    if cmdExists 'apt-get'; then
        sudo apt-get install -y openssh-client sshpass gawk
    elif cmdExists 'dnf'; then
        sudo dnf install -y openssh-clients sshpass gawk
    elif cmdExists 'yum'; then
        sudo yum install --enablerepo=epel -y openssh-clients sshpass gawk
    else
        printerr "Your local OS is not currently not supported"
        exit 1
    fi
fi

# sanity check
if (( $? != 0 )); then
    printerr 'Could not install requirements for cluster install'
    exit 1
fi

# prints number of nodes in cluster
getClusterSize() {
    local OPT=""
    local MYSQL_USER='' MYSQL_PASS='' MYSQL_HOST='' MYSQL_PORT=''

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
        -e "select VARIABLE_VALUE from information_schema.GLOBAL_STATUS where VARIABLE_NAME='wsrep_cluster_size'" \
        || echo '0'
}

setFirewallRules() {
    firewall-cmd --zone=public --add-port=${MYSQL_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${GALERA_REPL_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${GALERA_REPL_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${GALERA_INCR_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${GALERA_SNAP_PORT}/tcp --permanent

    firewall-cmd --reload
}

# loop through args and gather variables
NODE_NAMES=()
HOST_LIST=()
INT_IP_LIST=()
declare -A CLOUD_DICT
CLOUD_PLATFORM=""
CLUSTER_RESOURCES=(cluster_vip cluster_srcaddr)
SSH_CMD_LIST=()
i=0
for NODE in ${NODES[@]}; do
    SSH_OPTS=(-o StrictHostKeyChecking=no -o CheckHostIp=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -x)
    RSYNC_OPTS=()

    NODE_NAME="${CLUSTER_NAME}-node$((i+1))"
    NODE_NAMES+=( "$NODE_NAME" )

    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

    HOST_LIST+=( "$HOST" )

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]"
        exit 1
    fi

    if [[ -z "$HOST" ]]; then
        printerr "Node [${NODE}] does not contain a host"
        printUsage
        exit 1
    fi
    USERHOST_LIST+=( "${USER}@${HOST}" )

    if [[ -n "$PASS" ]]; then
        export SSHPASS="${PASS}"
        SSH_CMD="sshpass -e ssh"
        RSYNC_CMD="sshpass -e rsync"
        SSH_OPTS+=(-o PreferredAuthentications=password)
    else
        SSH_CMD="ssh"
        RSYNC_CMD="rsync"
        if [[ -n "$SSH_KEY_FILE" ]]; then
            SSH_OPTS+=(-o PreferredAuthentications=publickey -i $SSH_KEY_FILE)
        else
            SSH_OPTS+=(-o PreferredAuthentications=publickey)
        fi
    fi

    RSYNC_OPTS+=(--port=${PORT} -z --exclude=".*")
    SSH_OPTS+=(-p ${PORT})

    printdbg 'validating unattended ssh connection'
    if ! checkSSH ${SSH_CMD} ${SSH_OPTS[@]} ${USERHOST_LIST[$i]}; then
        printerr "Could not establish unattended ssh connection to [${USERHOST_LIST[$i]}] on port [${PORT}]"
        exit 1
    fi

    # wrap up some args / options
    SSH_CMD_LIST+=( "${SSH_CMD} ${SSH_OPTS[*]}" )
    RSYNC_CMD_LIST+=( "${RSYNC_CMD} ${RSYNC_OPTS[*]}" )

    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        MYSQL_PORT="$MYSQL_PORT"
        GALERA_REPL_PORT="$GALERA_REPL_PORT"
        GALERA_INCR_PORT="$GALERA_INCR_PORT"
        GALERA_SNAP_PORT="$GALERA_SNAP_PORT"
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f cmdExists)

        # awk is required for getInternalIP()
        printdbg 'installing requirements on remote node ${HOST_LIST[$i]}'
        if ! cmdExists 'awk'; then
            if cmdExists 'apt-get'; then
                export DEBIAN_FRONTEND=noninteractive
                apt-get install -y gawk
            elif cmdExists 'dnf'; then
                dnf install -y gawk
            elif cmdExists 'yum'; then
                yum install -y gawk
            else
                printerr "OS on remote node [${HOST_LIST[$i]}] is currently not supported"
                exit 1
            fi

            if (( \$? != 0 )); then
                printerr "Failed to install requirements on remote node ${HOST_LIST[$i]}"
                exit 1
            fi
        fi
EOSSH

    printdbg 'checking if node is deployed on a supported cloud platform'
    CLOUD_PLATFORM=$(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "$(typeset -f getCloudPlatform); getCloudPlatform;")
    CLOUD_DICT[$CLOUD_PLATFORM]=1

    # warn the user if we don't have an integration setup for this provider yet
    case "${CLOUD_LIST[$i]}" in
        AWS|GCE|AZURE|VULTR|OCE)
            printwarn 'support for this cloud platform has not been tested'
            printwarn 'attempting install anyways'
            ;;
    esac

    # find the internal IP that the cluster will communicate over
    if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
        INT_IP_LIST+=($(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address;"))
    else
        INT_IP_LIST+=($(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "$(typeset -f getInternalIP); getInternalIP;"))
    fi

    i=$((i+1))
done

# make sure user does not try to install on 2 different cloud platforms
if (( ${#CLOUD_DICT[@]} > 1 )); then
    printerr 'nodes are deployed on different cloud platforms'
    printerr 'installation on differing cloud platforms is not supported'
    exit 1
fi

# loop through args and pre-configure mysql server
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        MYSQL_USER="$MYSQL_USER"
        MYSQL_PASS="$MYSQL_PASS"
        MYSQL_PORT="$MYSQL_PORT"
        GALERA_REPL_PORT="$GALERA_REPL_PORT"
        GALERA_INCR_PORT="$GALERA_INCR_PORT"
        GALERA_SNAP_PORT="$GALERA_SNAP_PORT"
        NODE_NAMES=( ${NODE_NAMES[@]} )
        INT_IP_LIST=( ${INT_IP_LIST[@]} )
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f cmdExists)
        $(typeset -f getPkgVer)
        $(typeset -f mysqlSecureInstall)
        $(typeset -f setFirewallRules)

        # state is tracked here, if it exists we have completed this section already
        STATE_FILE="${MYSQL_BACKUP_DIR}/state/${HOST_LIST[$i]}"
        if [[ -f "\$STATE_FILE" ]]; then
            printwarn 'initial configuration already complete, skipping..'
            exit 0
        fi
        # trap exit signals to remove state file in case we exit early
        cleanupHandler() {
            rm -f "\$STATE_FILE"
            trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
        }
        trap 'cleanupHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

        printdbg 'setting up cluster hostname resolution'

        # for each node remove the loopback hostname if present
        # this will cause issues when adding nodes to the cluster
        # ref: https://serverfault.com/questions/363095/why-does-my-hostname-appear-with-the-address-127-0-1-1-rather-than-127-0-0-1-in
        grep -v -E '^127\.0\.1\.1' /etc/hosts >/tmp/hosts &&
            mv -f /tmp/hosts /etc/hosts

        # hostnames are required even if not DNS resolvable (on each node)
        j=0
        while (( \$j < \${#INT_IP_LIST[@]} )); do
            if ! grep -q -F "\${NODE_NAMES[\$j]}" /etc/hosts 2>/dev/null; then
                echo "\${INT_IP_LIST[\$j]} \${NODE_NAMES[\$j]}" >>/etc/hosts
            fi
            j=\$((j+1))
        done

        # backup dirs we will be using
        mkdir -p ${MYSQL_BACKUP_DIR}/{etc,var/lib,\${HOME},dumps,state}

        # will determine how we merge databases later on
        # 0 == no merge (fresh install no changes)
        # 1 == overwrite (existing databases cloned)
        # 2 == merge (merge primary databases with existing)
        echo 'MYSQL_MERGE_ACTION=0' >>\${STATE_FILE}

        printdbg 'installing requirements on remote node ${HOST_LIST[$i]}'
        if cmdExists 'apt-get'; then
            # debian specific settings
            echo 'MYSQL_SECTION="mysqld"' >>\${STATE_FILE}
            echo 'MYSQL_CLUSTER_CONFIG="/etc/mysql/mariadb.conf.d/cluster.cnf"' >>\${STATE_FILE}
            export DEBIAN_FRONTEND=noninteractive

            apt-get install -y curl perl sed gawk rsync dirmngr bc expect firewalld

            if (( \$? != 0 )); then
                printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                exit 1
            fi

            # install or upgrade mysql if needed
            # debian has multiple packages for mariadb-server, easier to find version with dpkg
            MYSQL_VER=\$(getPkgVer 'mariadb-server(-[0-9.]+)?$')
            if cmdExists 'mysql'; then
                # check repo version and update if needed
                if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                    echo 'MYSQL_MERGE_ACTION=1' >>\${STATE_FILE}

                    # backup data in case upgrade fails
                    systemctl stop mariadb
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

                    if (( \$? != 0 )); then
                        printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                        exit 1
                    fi

                    systemctl enable mariadb
                    systemctl start mariadb

                    # automate mysql_secure_install cmds
                    mysqlSecureInstall "temp" "${MYSQL_PASS}"

                    # allow auto login for root
                    printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

                else
                    echo 'MYSQL_MERGE_ACTION=2' >>\${STATE_FILE}

                    # make sure root can login remotely
                    mysql --user='root' --password='${MYSQL_PASS}' mysql \\
                        -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                        -e 'SET PASSWORD FOR "root"@"%" = PASSWORD("${MYSQL_PASS}");' \\
                        -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                        -e 'FLUSH PRIVILEGES;'
                fi
            else
                # check repo version and update if needed
                LATEST_VER=\$(getPkgVer -l 'mariadb-server')
                if (( \$(echo "\${LATEST_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                    MYSQL_MAJOR_VER=\$(getPkgVer -l 'mariadb-server' | cut -c -4)
                fi

                debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password password temp"
                debconf-set-selections <<< "mariadb-server-\${MYSQL_MAJOR_VER} mysql-server/root_password_again password temp"
                apt-get install -y mariadb-client mariadb-server

                if (( \$? != 0 )); then
                    printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                    exit 1
                fi

                systemctl enable mariadb
                systemctl start mariadb

                # automate mysql_secure_install cmds
                mysqlSecureInstall "temp" "${MYSQL_PASS}"

                # allow auto login for root user
                printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

            fi

            # make sure mysql is listening for external connections prior to dumping databases
            if ! grep -qoP '^(?!#)bind-address[ \t]*=[ \t]*0\.0\.0\.0' /etc/mysql/mariadb.conf.d/50-server.cnf; then
                perl -i -pe 's%^(?!#)(bind-address[ \t]*=[ \t]*).*\$%\${1}0.0.0.0%m' /etc/mysql/mariadb.conf.d/50-server.cnf
                systemctl restart mariadb
            fi

        elif cmdExists 'yum' || cmdExists 'dnf'; then
            # centos specific settings
            echo 'MYSQL_SECTION="galera"' >>\${STATE_FILE}
            echo 'MYSQL_CLUSTER_CONFIG="/etc/my.cnf.d/cluster.cnf"' >>\${STATE_FILE}

            if cmdExists 'dnf'; then
                dnf install -y curl perl sed gawk rsync bc expect firewalld
            else
                yum install -y curl perl sed gawk rsync bc expect firewalld
            fi

            if (( \$? != 0 )); then
                printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                exit 1
            fi

            # SELINUX integration
            if sestatus | head -1 | grep -qi 'enabled'; then
                yum install -y policycoreutils-python setools-console selinux-policy-devel

                if (( \$? != 0 )); then
                    printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                    exit 1
                fi

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
                    echo 'MYSQL_MERGE_ACTION=1' >>\${STATE_FILE}

                    # backup data in case upgrade fails
                    systemctl stop mariadb
                    mv -f /var/lib/mysql ${MYSQL_BACKUP_DIR}/var/lib/
                    cp -f /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                    cp -rf /etc/my.cnf* ${MYSQL_BACKUP_DIR}/etc/
                    cp -rf /etc/mysql* ${MYSQL_BACKUP_DIR}/etc/
                    cp -f \${HOME}/.my.cnf* ${MYSQL_BACKUP_DIR}/\${HOME}/

                    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                    if cmdExists 'dnf'; then
                        dnf install -y MariaDB-client MariaDB-server
                    else
                        yum install -y MariaDB-client MariaDB-server
                    fi

                    if (( \$? != 0 )); then
                        printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                        exit 1
                    fi

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

                    systemctl enable mariadb
                    systemctl start mariadb

                    mysqladmin --user='root' password 'temp'

                    # automate mysql_secure_install cmds
                    mysqlSecureInstall "temp" "${MYSQL_PASS}"

                    # allow auto login for root
                    printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf

                else
                    echo 'MYSQL_MERGE_ACTION=2' >>\${STATE_FILE}

                    # make sure root can login remotely
                    mysql --user='root' --password='${MYSQL_PASS}' mysql \\
                        -e 'CREATE USER IF NOT EXISTS "root"@"%";' \\
                        -e 'SET PASSWORD FOR "root"@"%" = PASSWORD("${MYSQL_PASS}");' \\
                        -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' \\
                        -e 'FLUSH PRIVILEGES;'
                fi
            else
                # check repo version and update if needed
                if (( \$(echo "\${MYSQL_VER:-0} < ${MYSQL_REQ_VER}" | bc -l) )); then
                    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
                fi
                if cmdExists 'dnf'; then
                    dnf install -y MariaDB-client MariaDB-server
                else
                    yum install -y MariaDB-client MariaDB-server
                fi

                if (( \$? != 0 )); then
                    printerr "failed installing requirements on remote node ${HOST_LIST[$i]}"
                    exit 1
                fi

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

                systemctl enable mariadb
                systemctl start mariadb

                mysqladmin --user='root' password 'temp'

                # automate mysql_secure_install cmds
                mysqlSecureInstall "temp" "${MYSQL_PASS}"

                # allow auto login for root user
                printf '%s\n%s\n%s\n' '[client]' 'user = root' 'password = ${MYSQL_PASS}' > ~/.my.cnf
            fi

            # make sure mysql is listening for external connections prior to dumping databases
            if ! grep -qoP '^(?!#)bind-address[ \t]*=[ \t]*0\.0\.0\.0' /etc/my.cnf.d/50-server.cnf; then
                perl -i -pe 's%^(?!#)(bind-address[ \t]*=[ \t]*).*\$%\${1}0.0.0.0%m' /etc/my.cnf.d/50-server.cnf
                systemctl restart mariadb
            fi

        else
            printerr "Your OS Distro is currently not supported"
            exit 1
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

        printdbg 'updating firewall rules'
        setFirewallRules

        # store the new root user password for next iteration to use
        echo "MYSQL_PASS='\$MYSQL_PASS'" >>\${STATE_FILE}

        # remove signal handler since we were successful
        trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM

        exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "preparing node for cluster install failed on ${HOST_LIST[$i]}"
        exit 1
    fi

    i=$((i+1))
done

# loop through args and configure galera cluster
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        MYSQL_USER="$MYSQL_USER"
        MYSQL_PASS=""
        MYSQL_PORT="$MYSQL_PORT"
        GALERA_REPL_PORT="$GALERA_REPL_PORT"
        GALERA_INCR_PORT="$GALERA_INCR_PORT"
        GALERA_SNAP_PORT="$GALERA_SNAP_PORT"
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f cmdExists)
        $(typeset -f getClusterSize)
        $(typeset -f dumpMysqlDatabases)

        # get the stored state for this node
        STATE_FILE="${MYSQL_BACKUP_DIR}/state/${HOST_LIST[$i]}"
        . \${STATE_FILE}

        # export and merge databases from the primary node
        SQLCREDS=()
        case \$MYSQL_MERGE_ACTION in
            0)
                printdbg 'no database export needed on ${HOST_LIST[$i]} using address ${INT_IP_LIST[$i]}'
                ;;
            1)
                printdbg 'exporting database overwrite on ${HOST_LIST[$i]} using address ${INT_IP_LIST[$i]}'
                dumpMysqlDatabases --full ${MYSQL_USER}:${MYSQL_PASS}@localhost:${MYSQL_PORT} >${MYSQL_BACKUP_DIR}/dumps/primary.sql &&
                dumpMysqlDatabases --grants ${MYSQL_USER}:${MYSQL_PASS}@localhost:${MYSQL_PORT} >>${MYSQL_BACKUP_DIR}/dumps/primary.sql || {
                    printerr 'failed exporting databases'
                    exit 1
                }
                ;;
            2)
                printdbg 'exporting merged databases on ${HOST_LIST[$i]} using address ${INT_IP_LIST[$i]}'

                for IP in ${INT_IP_LIST[@]}; do
                    SQLCREDS+=(${MYSQL_USER}:${MYSQL_PASS}@\${IP}:${MYSQL_PORT})
                done

                dumpMysqlDatabases --merge \${SQLCREDS[@]} >${MYSQL_BACKUP_DIR}/dumps/primary.sql &&
                dumpMysqlDatabases --grants ${MYSQL_USER}:${MYSQL_PASS}@localhost:${MYSQL_PORT} >>${MYSQL_BACKUP_DIR}/dumps/primary.sql || {
                    printerr 'failed exporting databases'
                    exit 1
                }
                ;;
        esac

        # merge databases if needed
        if (( $i == 0 )) && (( \$MYSQL_MERGE_ACTION != 0 )); then
            printdbg 'importing merged databases on primary node'

            mysql < ${MYSQL_BACKUP_DIR}/dumps/primary.sql
        else
            printdbg 'importing databases on ${HOST_LIST[$i]}'

            case \$MYSQL_MERGE_ACTION in
                0)
                    dumpMysqlDatabases --grants ${MYSQL_USER}:${MYSQL_PASS}@${INT_IP_LIST[0]}:${MYSQL_PORT} >${MYSQL_BACKUP_DIR}/dumps/import.sql &&
                    mysql <${MYSQL_BACKUP_DIR}/dumps/import.sql || {
                        printerr 'failed importing databases'
                        exit 1
                    }
                    ;;
                1)
                    dumpMysqlDatabases --full ${MYSQL_USER}:${MYSQL_PASS}@${INT_IP_LIST[0]}:${MYSQL_PORT} >${MYSQL_BACKUP_DIR}/dumps/import.sql &&
                    dumpMysqlDatabases --grants ${MYSQL_USER}:${MYSQL_PASS}@${INT_IP_LIST[0]}:${MYSQL_PORT} >>${MYSQL_BACKUP_DIR}/dumps/import.sql &&
                    mysql <${MYSQL_BACKUP_DIR}/dumps/import.sql || {
                        printerr 'failed importing databases'
                        exit 1
                    }
                    ;;
                2)
                    dumpMysqlDatabases --full ${MYSQL_USER}:${MYSQL_PASS}@${INT_IP_LIST[0]}:${MYSQL_PORT} >${MYSQL_BACKUP_DIR}/dumps/import.sql &&
                    dumpMysqlDatabases --grants ${MYSQL_USER}:${MYSQL_PASS}@localhost:${MYSQL_PORT} >>${MYSQL_BACKUP_DIR}/dumps/import.sql &&
                    mysql <${MYSQL_BACKUP_DIR}/dumps/import.sql || {
                        printerr 'failed importing databases'
                        exit 1
                    }
                    ;;
            esac
        fi

        systemctl stop mariadb

        printdbg 'configuring galera cluster settings'
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
wsrep_cluster_address="gcomm://$(join ',' ${NODE_NAMES[@]})"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="${NODE_NAMES[$i]}"
wsrep_node_name="${NODE_NAMES[$i]}"
EOF
        ) > \${MYSQL_CLUSTER_CONFIG}

        # fix debian.cnf to be the same on all nodes (used by debian-maintenance)
        if [[ -e "/etc/mysql/debian.cnf" ]]; then
            sed -i -r \\
                -e "s|(host[\t ]*\=[\t ]*).*|host = localhost|g" \\
                -e "s|(user[\t ]*\=[\t ]*).*|user = ${MYSQL_USER}|g" \\
                -e "s|(password[\t ]*\=[\t ]*).*|password = ${MYSQL_PASS}|g" \\
                /etc/mysql/debian.cnf
        fi

        # startup mysql server
        if (( $i == 0 )); then
            # bootstrap first db node
            perl -i -pe 's%(safe_to_bootstrap:)[ \t]*[0-9]%\1 1%' /var/lib/mysql/grastate.dat
            galera_new_cluster
            if (( \$? == 0 )) && (( \$(getClusterSize) == 1 )); then
                printdbg "Bootstrapping cluster success"
            else
                printerr "Bootstrapping cluster failed [${NODE_NAMES[$i]}]"
                exit 1
            fi
        else
            # restart service to connect other db nodes
            systemctl restart mariadb
            if (( \$? == 0 )) && (( \$(getClusterSize) >= 2 )); then
                printdbg "Adding Node to cluster success"
            else
                printerr "Adding Node to cluster failed [${NODE_NAMES[$i]}]"
                exit 1
            fi
        fi

        # remove the state file after successful configuration
        rm -f \${STATE_FILE}

        exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "galera configuration failed on ${HOST_LIST[$i]}"
        exit 1
    fi

    i=$((i+1))
done

exit 0