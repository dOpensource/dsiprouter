#!/usr/bin/env bash

(( ${DEBUG:-0} == 1 )) && set -x

# where the new project files were downloaded
NEW_PROJECT_DIR=${NEW_PROJECT_DIR:-/tmp/dsiprouter}
# project dir where previous repo was located
OLD_PROJECT_DIR=${DSIP_PROJECT_DIR:-/opt/dsiprouter}
# the backup directory set by dsiprouter.sh
CURR_BACKUP_DIR=${CURR_BACKUP_DIR:-"/var/backups/dsiprouter/$(date '+%s')"}
# system config files for dsiprouter
DSIP_SYSTEM_CONFIG_DIR='/etc/dsiprouter'
DSIP_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py"
# system library files for dsiprouter
DSIP_LIB_DIR='/var/lib/dsiprouter'
SYSTEM_KAMAILIO_CONFIG_DIR='/etc/kamailio'
SYSTEM_RTPENGINE_CONFIG_DIR='/etc/rtpengine'
# source dirs the installer builds from, removed before a reinstall so it rebuilds them (same path as dsiprouter.sh)
SRC_DIR='/usr/local/src'
# schema and data files shipped with this upgrade
UPGRADE_DIR="${NEW_PROJECT_DIR}/resources/upgrade/v0.793"
# named apart from the db.sql/user.sql files written by installKamailio()
KAMDB_DUMP_FILE="${CURR_BACKUP_DIR}/kam_db.sql"
KAMDB_USER_DUMP_FILE="${CURR_BACKUP_DIR}/kam_user.sql"
# data only rows of the kamailio DB, replayed after schema.sql so the restored rows land in the new tables
KAMDB_DATA_FILE="${CURR_BACKUP_DIR}/kam_data.sql"
# rows of the tables the triggers on the base tables write, restored after the base rows so the trigger output is replaced
KAMDB_DERIVED_FILE="${CURR_BACKUP_DIR}/kam_derived.sql"
KAMDB_DERIVED_TABLES=(dsip_gw2gwgroup dsip_gwgroup2lb)
# tables, views, triggers and routines of the kamailio DB, object N is saved as ${KAMDB_OBJECTS_DIR}/N.sql and listed on line N of the manifest
KAMDB_OBJECTS_DIR="${CURR_BACKUP_DIR}/kam_objects"
KAMDB_OBJECTS_MANIFEST="${KAMDB_OBJECTS_DIR}/manifest.tsv"
# column definitions of every kamailio base table, used to ADD COLUMN extra user columns after the reinstall
KAMDB_COLUMNS_FILE="${CURR_BACKUP_DIR}/kam_columns.tsv"
# systemd units and drop-in dirs the reinstall can change, each is backed up and restored as one entry
SYSTEMD_UNITS=(dsiprouter.service kamailio.service rtpengine.service dsip-init.service mariadb.service nginx-watcher.service nginx-watcher.path)
SYSTEMD_DROPINS=(dsiprouter.service.d kamailio.service.d rtpengine.service.d dsip-init.service.d mariadb.service.d nginx.service.d)
SYSTEM_NGINX_CONFIG_DIR='/etc/nginx'
# installer-managed files restored as individual entries so unrelated files in the same directory survive
MANAGED_FILES=(
    /usr/bin/dsiprouter
    /etc/sudoers.d/99-dsiprouter
    /etc/bash_completion.d/dsiprouter
    /etc/bash.bashrc
    /usr/share/man/man1/dsiprouter.1
    /usr/share/man/man1/dsiprouter.1.gz
    /usr/sbin/nginx-stop
    /etc/logrotate.d/kamailio
    /etc/logrotate.d/rtpengine
    /etc/rsyslog.d/kamailio.conf
    /etc/rsyslog.d/rtpengine.conf
)

# state read by resetConfigsHandler to decide what can be restored safely
MIGRATION_COMPLETE=0
BACKUP_COMPLETE=0
CHANGES_STARTED=0
KAM_DB_BACKED_UP=0
KAM_DB_TOUCHED=0
MASKED_UNITS=()
STOPPED_UNITS=()

if [[ ! -f "${OLD_PROJECT_DIR}/dsiprouter/dsip_lib.sh" ]]; then
    echo "could not find the installed dSIPRouter project files" >&2
    echo "expected dsip_lib.sh to be here: ${OLD_PROJECT_DIR}/dsiprouter/dsip_lib.sh" >&2
    exit 1
fi
# import dsip_lib utility / shared functions
. ${OLD_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# preflight: nothing below this point is changed until the checks pass
[[ ! -e "$NEW_PROJECT_DIR" ]] && {
    printerr 'could not find repo to upgrade from'
    echo "expected updated repo to be here: $NEW_PROJECT_DIR"
    exit 1
}
[[ ! -f "${UPGRADE_DIR}/schema.sql" || ! -f "${UPGRADE_DIR}/settings.json" ]] && {
    printerr 'new project files for this upgrade are missing'
    echo "expected files to be here: ${UPGRADE_DIR}"
    exit 1
}

printdbg 'validating system configuration'
if ! dsiprouter licensemanager -check tag=DSIP_CORE; then
    printerr 'A DSIP_CORE license is required to use the auto upgrade feature'
    echo 'Consider supporting the hard working engineers maintaining this software if you would like to use this feature'
    exit 1
fi

# OS support map mirrors validateOSInfo() in dsiprouter.sh, values must stay in sync
unset NEW_KAM_VERSION NEW_RTPENGINE_VER
DISTRO=$(getDistroName)
DISTRO_VER=$(getDistroVer)
DISTRO_MAJOR_VER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
case "$DISTRO" in
debian)
    case "$DISTRO_VER" in
    13)
        NEW_KAM_VERSION="6.0.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    12|11|10)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    9)
        NEW_KAM_VERSION="5.7.6"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    esac
    ;;
centos)
    case "$DISTRO_VER" in
    9)
        NEW_KAM_VERSION="6.0.2"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    8)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    7)
        NEW_KAM_VERSION="5.7.6"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    esac
    ;;
amzn)
    case "$DISTRO_VER" in
    2)
        NEW_KAM_VERSION="5.7.6"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    esac
    ;;
ubuntu)
    case "$DISTRO_VER" in
    24.04)
        NEW_KAM_VERSION="5.8.4"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    22.04)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    20.04)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr9.5.5.1"
        ;;
    esac
    ;;
rhel)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    8)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr9.5.5.1"
        ;;
    esac
    ;;
almalinux)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    8)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    esac
    ;;
rocky)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    8)
        NEW_KAM_VERSION="5.8.3"
        NEW_RTPENGINE_VER="mr11.5.1.11"
        ;;
    esac
    ;;
esac
if [[ -z "$NEW_KAM_VERSION" || -z "$NEW_RTPENGINE_VER" ]]; then
    printerr 'Your Operating System Version is not supported by this upgrade'
    exit 1
fi
export NEW_KAM_VERSION NEW_RTPENGINE_VER

printdbg 'retrieving current system settings'
# NOTE: the SET_* exports are read by the reinstall (dsiprouter.sh) so existing secrets are kept
# reads an encrypted setting into a variable
# an encrypted empty secret is stored as nonce-only hex (length 2*AES_CTR_NONCE_SIZE) and is valid
# note: sets the variable directly (no subshell) so that exit is honored
# usage: loadSecret <attribute name> <variable name>
function loadSecret() {
    local NAME="$1"
    local VAR="$2"
    local RAW VALUE PK_FILE
    local NONCE_HEX_LEN=$(( ${AES_CTR_NONCE_SIZE:-0} * 2 ))
    local ENCRYPTED=0

    RAW=$(getConfigAttrib "$NAME" "$DSIP_CONFIG_FILE")
    if grep -qE "^${NAME}[ \t]*=[ \t]*b['\"]" "$DSIP_CONFIG_FILE"; then
        ENCRYPTED=1
    fi

    if (( ENCRYPTED == 1 )); then
        PK_FILE=$(getConfigAttrib 'DSIP_PRIV_KEY' "$DSIP_CONFIG_FILE")
        if [[ ! -r "$PK_FILE" ]]; then
            printerr "could not decrypt ${NAME}: DSIP_PRIV_KEY is missing or unreadable, no changes were made"
            exit 1
        fi
        if (( NONCE_HEX_LEN == 0 )); then
            printerr "could not decrypt ${NAME}: AES_CTR_NONCE_SIZE is unset, no changes were made"
            exit 1
        fi
    fi

    VALUE=$(decryptConfigAttrib "$NAME" "$DSIP_CONFIG_FILE")
    if (( ENCRYPTED == 1 )) && (( ${#RAW} > NONCE_HEX_LEN )) && [[ -z "$VALUE" ]]; then
        printerr "could not decrypt ${NAME} from ${DSIP_CONFIG_FILE}, no changes were made"
        exit 1
    fi
    printf -v "$VAR" '%s' "$VALUE"
}

# NOTE: the privkey file is not exported here, the reinstall keeps the existing key file
export PYTHON_CMD=${OLD_PROJECT_DIR}/venv/bin/python
SET_ROOT_DB_USER=$(getConfigAttrib 'ROOT_DB_USER' "$DSIP_CONFIG_FILE")
export SET_ROOT_DB_USER ROOT_DB_USER="$SET_ROOT_DB_USER"
loadSecret 'ROOT_DB_PASS' SET_ROOT_DB_PASS
export SET_ROOT_DB_PASS ROOT_DB_PASS="$SET_ROOT_DB_PASS"
ROOT_DB_HOST=$(getConfigAttrib 'ROOT_DB_HOST' "$DSIP_CONFIG_FILE")
ROOT_DB_PORT=$(getConfigAttrib 'ROOT_DB_PORT' "$DSIP_CONFIG_FILE")
ROOT_DB_NAME=$(getConfigAttrib 'ROOT_DB_NAME' "$DSIP_CONFIG_FILE")
KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' "$DSIP_CONFIG_FILE")
SET_KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' "$DSIP_CONFIG_FILE")
export SET_KAM_DB_HOST KAM_DB_HOST="$SET_KAM_DB_HOST"
SET_KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' "$DSIP_CONFIG_FILE")
export SET_KAM_DB_USER KAM_DB_USER="$SET_KAM_DB_USER"
loadSecret 'KAM_DB_PASS' SET_KAM_DB_PASS
export SET_KAM_DB_PASS KAM_DB_PASS="$SET_KAM_DB_PASS"
loadSecret 'DSIP_API_TOKEN' SET_DSIP_API_TOKEN
export SET_DSIP_API_TOKEN DSIP_API_TOKEN="$SET_DSIP_API_TOKEN"
loadSecret 'MAIL_PASSWORD' SET_DSIP_MAIL_PASS
export SET_DSIP_MAIL_PASS MAIL_PASSWORD="$SET_DSIP_MAIL_PASS"
loadSecret 'DSIP_IPC_PASS' SET_DSIP_IPC_TOKEN
export SET_DSIP_IPC_TOKEN DSIP_IPC_PASS="$SET_DSIP_IPC_TOKEN"
DSIP_LICENSE_STORE=$(getConfigAttrib 'DSIP_LICENSE_STORE' "$DSIP_CONFIG_FILE")
export ROOT_DB_HOST ROOT_DB_PORT ROOT_DB_NAME KAM_DB_NAME DSIP_LICENSE_STORE

printdbg 'preparing for migration'
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    REINSTALL_KAMAILIO=1
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    REINSTALL_DSIPROUTER=1
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
    OLD_RTPENGINE_VER=$(rtpengine -v 2>&1 | awk '{print $2}' | cut -d '~' -f 2)
    if [[ "$OLD_RTPENGINE_VER" != "$NEW_RTPENGINE_VER" ]]; then
        REINSTALL_RTPENGINE=1
    fi
fi

DB_CONNECTED=0
if withRootDBConn mysql -sN -e 'SELECT 1;' </dev/null >/dev/null 2>&1; then
    DB_CONNECTED=1
fi
# the kamailio DB is only in scope when kamailio is installed, otherwise it is never dumped, restored or written
KAM_DB_EXISTS=0
if (( REINSTALL_KAMAILIO == 1 && DB_CONNECTED == 1 )) && checkDB "$KAM_DB_NAME"; then
    KAM_DB_EXISTS=1
fi
if (( REINSTALL_KAMAILIO == 1 )); then
    if (( DB_CONNECTED == 0 )); then
        printerr 'kamailio is installed but the root DB connection failed, no changes were made'
        exit 1
    fi
    if (( KAM_DB_EXISTS == 0 )); then
        printerr "kamailio is installed but the DB ${KAM_DB_NAME} was not found, no changes were made"
        exit 1
    fi
fi

# the kamailio DB user must be a real account that is not the root DB user, restore drops and recreates it
if (( KAM_DB_EXISTS == 1 )) && [[ -z "$KAM_DB_USER" || "$KAM_DB_USER" == "$ROOT_DB_USER" ]]; then
    printerr 'the kamailio DB user must be set and must differ from the root DB user, no changes were made'
    exit 1
fi

# these names are interpolated into SQL, so only plain identifiers are accepted
if (( KAM_DB_EXISTS == 1 )) && [[ ! "$KAM_DB_NAME" =~ ^[A-Za-z0-9_]+$ || ! "$KAM_DB_USER" =~ ^[A-Za-z0-9_]+$ ]]; then
    printerr 'the kamailio DB name and DB user may only contain letters, digits and underscores, no changes were made'
    exit 1
fi

# never reuse a backup dir that already has content, it could be stale or partial
if [[ -e "$CURR_BACKUP_DIR" ]] && [[ -n "$(ls -A "$CURR_BACKUP_DIR" 2>/dev/null)" ]]; then
    printerr "backup directory already has content, refusing to reuse it: ${CURR_BACKUP_DIR}"
    exit 1
fi

# copies a directory tree from the system into the backup, mirrored under the same absolute path
# usage: backupTree <system dir>
# notes: a tree that does not exist is recorded with a marker, so restore removes whatever the upgrade creates
function backupTree() {
    local SRC="$1"
    local DST="${CURR_BACKUP_DIR}${SRC}"

    if [[ ! -e "$SRC" && ! -L "$SRC" ]]; then
        mkdir -p "$(dirname "$DST")" && touch "${DST}.absent"
        return
    fi
    mkdir -p "$DST" && cp -afP "${SRC}/." "${DST}/"
}

# replaces a directory tree in the system with the backed up copy
# usage: restoreTree <system dir>
function restoreTree() {
    local DST="$1"
    local SRC="${CURR_BACKUP_DIR}${DST}"

    # refuse to wipe anything other than an absolute directory path
    [[ "$DST" == /* && "$DST" != "/" ]] || {
        printerr "refusing to restore into an unexpected path: ${DST}"
        return 1
    }
    if [[ -e "${SRC}.absent" ]]; then
        rm -rf "$DST"
        return
    fi
    [[ -d "$SRC" ]] || {
        printerr "backup directory is missing, cannot restore: ${SRC}"
        return 1
    }
    rm -rf "$DST" && mkdir -p "$DST" && cp -afP "${SRC}/." "${DST}/"
}

# copies a single file, symlink or directory from the system into the backup, mirrored under the same path
# usage: backupEntry <system path>
# notes: absent entries are skipped, restoreEntry treats an entry missing from the backup as absent
function backupEntry() {
    local SRC="$1"
    local DST_DIR

    [[ -e "$SRC" || -L "$SRC" ]] || return 0
    DST_DIR="${CURR_BACKUP_DIR}$(dirname "$SRC")"
    mkdir -p "$DST_DIR" && cp -afP "$SRC" "${DST_DIR}/"
}

# puts a single file, symlink or directory back, whatever the upgrade left in its place is removed
# usage: restoreEntry <system path>
function restoreEntry() {
    local DST="$1"
    local SRC="${CURR_BACKUP_DIR}${DST}"

    [[ "$DST" == /* && "$DST" != "/" && -n "${DST##*/}" ]] || {
        printerr "refusing to restore into an unexpected path: ${DST}"
        return 1
    }
    rm -rf "$DST" || return 1
    if [[ -e "$SRC" || -L "$SRC" ]]; then
        mkdir -p "$(dirname "$DST")" || return 1
        cp -afP "$SRC" "$(dirname "$DST")/" || return 1
    fi
}

# snapshots the root crontab, or records that none existed
function backupCrontab() {
    local DST="${CURR_BACKUP_DIR}/crontab.root"
    local STDERR="${CURR_BACKUP_DIR}/crontab.root.stderr"
    local CRONTAB_ERROR

    mkdir -p "$CURR_BACKUP_DIR" || return 1
    command -v crontab >/dev/null 2>&1 || {
        printerr 'crontab is not available, cannot back up root crontab'
        return 1
    }
    if crontab -u root -l >"$DST" 2>"$STDERR"; then
        rm -f "$STDERR" || return 1
        return 0
    fi
    CRONTAB_ERROR=$(<"$STDERR")
    rm -f "$DST" "$STDERR" || return 1
    if [[ "$CRONTAB_ERROR" == *'no crontab for'* ]]; then
        touch "${DST}.absent"
        return
    fi
    printerr "could not read root crontab: ${CRONTAB_ERROR:-unknown error}"
    return 1
}

# restores the root crontab from the snapshot, or removes one the upgrade created
function restoreCrontab() {
    local SRC="${CURR_BACKUP_DIR}/crontab.root"

    if [[ -e "${SRC}.absent" ]]; then
        if command -v crontab >/dev/null 2>&1; then
            crontab -u root -r >/dev/null 2>&1 || true
        fi
        return 0
    fi
    [[ -f "$SRC" ]] || {
        printerr "crontab backup is missing, cannot restore"
        return 1
    }
    command -v crontab >/dev/null 2>&1 || {
        printerr "crontab is not available, cannot restore"
        return 1
    }
    crontab -u root "$SRC"
}

# dumps the kamailio DB user accounts so they can be restored
# output: CREATE USER (when the server supports SHOW CREATE USER) then GRANT statements
# notes: SHOW CREATE USER carries the password hash on MySQL 8, where SHOW GRANTS does not
# returns: 0 on success, non zero otherwise
function dumpKamDBGrants() {
    local ACCOUNTS CREATE_USER GRANTS ACCOUNT
    local ACCOUNT_LIST=()
    local ALL_SQL=''

    ACCOUNTS=$(withRootDBConn mysql -sN -A \
        -e "SELECT CONCAT(QUOTE(user), '@', QUOTE(host)) FROM mysql.user WHERE user='${KAM_DB_USER}';" \
        </dev/null 2>/dev/null) || return 1
    mapfile -t ACCOUNT_LIST <<<"$ACCOUNTS"
    for ACCOUNT in "${ACCOUNT_LIST[@]}"; do
        [[ -n "$ACCOUNT" ]] || continue
        CREATE_USER=$(withRootDBConn mysql -sN -A -e "SHOW CREATE USER ${ACCOUNT};" </dev/null 2>/dev/null) || CREATE_USER=''
        GRANTS=$(withRootDBConn mysql -sN -A -e "SHOW GRANTS FOR ${ACCOUNT};" </dev/null 2>/dev/null) || return 1
        [[ -n "$CREATE_USER" ]] && ALL_SQL+="${CREATE_USER}"$'\n'
        ALL_SQL+="${GRANTS}"$'\n'
    done
    [[ -n "$ALL_SQL" ]] && awk 'NF && !x[$0]++ { if ($0 ~ /;$/) print $0; else print $0 ";" }' <<<"$ALL_SQL"
    printf '%s\n' 'FLUSH PRIVILEGES;'
}

# dumps the kamailio DB for rollback, DEFINER clauses are kept so restored objects are not root-owned
# usage: dumpKamDBFull <db>
# output: dumped database as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpKamDBFull() {
    withRootDBConn mysqldump --single-transaction --opt --routines --triggers --hex-blob --databases "$1" \
        2>/dev/null |
        sed -r -e 's|ENGINE=MyISAM|ENGINE=InnoDB|g' 2>/dev/null
    return ${PIPESTATUS[0]}
}

# dumps one view as a replayable CREATE VIEW statement, the original DEFINER is kept so the view does not become root-owned
# usage: dumpKamDBView <db> <view>
# output: the statement and a completion line (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpKamDBView() {
    local DB="$1" NAME="$2"
    local RAW VIEW_SQL

    RAW=$(withRootDBConn mysql -e "SHOW CREATE VIEW \`${DB}\`.\`${NAME}\`\G" </dev/null 2>/dev/null) || return 1
    # vertical output right-aligns the labels, so they are matched with leading spaces allowed
    # the view body keeps its DB qualifier, views are only replayed into the DB they were dumped from (KAM_DB_NAME)
    VIEW_SQL=$(sed -n '/^ *Create View: /,/^ *character_set_client: /{/^ *character_set_client: /d;s/^ *Create View: //;p}' <<<"$RAW") || return 1
    [[ -n "$VIEW_SQL" ]] || return 1
    printf '%s;\n' "$VIEW_SQL"
    echo '-- Dump completed'
}

# dumps only the rows of the kamailio DB, with column names so a re-ordered table still loads correctly
# output: INSERT statements with the -- Dump completed marker on success (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpKamDBData() {
    # version is not dumped, the reinstall sets the schema versions the reinstalled kamailio needs
    withRootDBConn mysqldump --single-transaction --no-create-info --no-create-db --complete-insert \
        --replace --skip-triggers --hex-blob --ignore-table="${1}.version" "$1" 2>/dev/null
}

# lists the base tables of a DB that are restored from the data dump, version is left out
# usage: kamDBBaseTables <db>
# output: one table name per line
# returns: 0 on success, non zero otherwise
function kamDBBaseTables() {
    [[ "$1" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    withRootDBConn mysql -sN -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='${1}' AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME <> 'version';" </dev/null 2>/dev/null
}

# lists the named tables of a DB that exist as base tables
# usage: kamDBTablesIn <db> <table>...
# output: one table name per line, nothing when none exist
# returns: 0 on success, non zero otherwise
function kamDBTablesIn() {
    local DB="$1"
    local NAME LIST=''

    shift
    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    for NAME in "$@"; do
        [[ "$NAME" =~ ^[A-Za-z0-9_]+$ ]] || return 1
        LIST+="'${NAME}',"
    done
    [[ -n "$LIST" ]] || return 0
    withRootDBConn mysql -sN -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME IN (${LIST%,});" </dev/null 2>/dev/null
}

# empties the named tables of a DB, foreign key checks are off so the table order does not matter
# triggers do not fire on TRUNCATE, so the rows written by triggers are not re-created by emptying
# usage: truncateKamDBTables <db> <table>...
# returns: 0 on success, non zero otherwise
function truncateKamDBTables() {
    local DB="$1"
    local NAME SQL='SET FOREIGN_KEY_CHECKS=0;'
    local COUNT=0

    shift
    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    for NAME in "$@"; do
        [[ -n "$NAME" ]] || continue
        [[ "$NAME" =~ ^[A-Za-z0-9_]+$ ]] || {
            printerr "unexpected table name in ${DB}: ${NAME}"
            return 1
        }
        SQL+="TRUNCATE TABLE \`${NAME}\`;"
        COUNT=$((COUNT + 1))
    done
    (( COUNT == 0 )) && return 0
    SQL+='SET FOREIGN_KEY_CHECKS=1;'
    withRootDBConn --db="$DB" mysql -e "$SQL" </dev/null
}

# dumps the rows of the derived tables, they are restored from this dump and not from the trigger output
# output: INSERT statements with the -- Dump completed marker, or only the marker when none of the tables exist
# returns: 0 on success, non zero otherwise
function dumpKamDBDerived() {
    local DB="$1"
    local TABLES
    local TABLE_LIST=()

    TABLES=$(kamDBTablesIn "$DB" "${KAMDB_DERIVED_TABLES[@]}") || return 1
    mapfile -t TABLE_LIST < <(sed '/^$/d' <<<"$TABLES")
    if (( ${#TABLE_LIST[@]} == 0 )); then
        echo '-- Dump completed'
        return 0
    fi
    withRootDBConn mysqldump --single-transaction --no-create-info --no-create-db --complete-insert \
        --replace --skip-triggers --hex-blob "$DB" "${TABLE_LIST[@]}" 2>/dev/null
}

# lists the tables, views, triggers and routines of a DB, version is left out of the tables
# usage: kamDBObjectList <db>
# output: one <kind><TAB><name> line per object, kind is TABLE, VIEW, TRIGGER, PROCEDURE or FUNCTION
# returns: 0 on success, non zero otherwise
function kamDBObjectList() {
    [[ "$1" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    withRootDBConn mysql -sN -e "SELECT 'TABLE', TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='${1}' AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME <> 'version' UNION ALL SELECT 'VIEW', TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${1}' UNION ALL SELECT 'TRIGGER', TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${1}' UNION ALL SELECT ROUTINE_TYPE, ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='${1}';" </dev/null 2>/dev/null
}

# lists the distinct DEFINER accounts of views, triggers and routines in a DB
# usage: kamDBDefiners <db>
# output: one user@host line per account
# returns: 0 on success, non zero otherwise
function kamDBDefiners() {
    local DB="$1"
    local OUT='' PART

    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    PART=$(withRootDBConn mysql -sN -e "SELECT DEFINER FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND DEFINER IS NOT NULL AND DEFINER <> '';" </dev/null 2>/dev/null) || return 1
    OUT+="${PART}"$'\n'
    PART=$(withRootDBConn mysql -sN -e "SELECT DEFINER FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${DB}' AND DEFINER IS NOT NULL AND DEFINER <> '';" </dev/null 2>/dev/null) || return 1
    OUT+="${PART}"$'\n'
    PART=$(withRootDBConn mysql -sN -e "SELECT DEFINER FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='${DB}' AND DEFINER IS NOT NULL AND DEFINER <> '';" </dev/null 2>/dev/null) || return 1
    OUT+="${PART}"$'\n'
    sed '/^$/d' <<<"$OUT" | sort -u
}

# dumps one trigger, procedure or function as a replayable statement, the original DEFINER is kept so the object does not become root-owned
# usage: dumpKamDBRoutine <db> <TRIGGER|PROCEDURE|FUNCTION> <name>
# output: the statement with its SQL mode and a completion line (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpKamDBRoutine() {
    local DB="$1" KIND="$2" NAME="$3"
    local LABEL RAW MODE SQL

    case "$KIND" in
    TRIGGER) LABEL='SQL Original Statement' ;;
    PROCEDURE) LABEL='Create Procedure' ;;
    FUNCTION) LABEL='Create Function' ;;
    *) return 1 ;;
    esac
    RAW=$(withRootDBConn mysql -e "SHOW CREATE ${KIND} \`${DB}\`.\`${NAME}\`\G" </dev/null 2>/dev/null) || return 1
    # the SQL mode is replayed so the body parses the same way it did before the upgrade
    MODE=$(sed -n 's/^ *sql_mode: //p' <<<"$RAW")
    MODE=${MODE//\'/\'\'}
    SQL=$(sed -n "/^ *${LABEL}: /,/^ *character_set_client: /{/^ *character_set_client: /d;s/^ *${LABEL}: //;p}" <<<"$RAW") || return 1
    [[ -n "$SQL" ]] || return 1
    printf "SET SESSION sql_mode='%s';\n" "$MODE"
    printf 'DELIMITER //\n%s//\nDELIMITER ;\n' "$SQL"
    echo '-- Dump completed'
}

# dumps the tables, views, triggers and routines of a DB, so the ones the reinstall does not create can be restored
# usage: dumpKamDBObjects <db> <dir>
# output: <dir>/manifest.tsv with one <kind><TAB><name> line per object, object N is saved as <dir>/N.sql
# returns: 0 on success, non zero otherwise
function dumpKamDBObjects() {
    local DB="$1" DIR="$2"
    local LIST KIND NAME OUT
    local N=0

    LIST=$(kamDBObjectList "$DB") || return 1
    mkdir -p "$DIR" || return 1
    : >"${DIR}/manifest.tsv" || return 1
    while IFS=$'\t' read -r KIND NAME; do
        [[ -n "$KIND" ]] || continue
        N=$((N + 1))
        OUT="${DIR}/${N}.sql"
        case "$KIND" in
        TABLE)
            # structure only, the rows come from the data dump
            withRootDBConn mysqldump --no-data --skip-triggers --skip-add-drop-table --no-create-db "$DB" "$NAME" </dev/null 2>/dev/null >"$OUT" || return 1
            ;;
        VIEW)
            dumpKamDBView "$DB" "$NAME" >"$OUT" || return 1
            ;;
        TRIGGER|PROCEDURE|FUNCTION)
            dumpKamDBRoutine "$DB" "$KIND" "$NAME" >"$OUT" || return 1
            ;;
        *)
            return 1
            ;;
        esac
        grep -q '^-- Dump completed' "$OUT" || return 1
        printf '%s\t%s\n' "$KIND" "$NAME" >>"${DIR}/manifest.tsv" || return 1
    done <<<"$LIST"
}

# dumps the column definitions of every base table, used to ADD COLUMN extra user columns after the reinstall
# usage: dumpKamDBColumns <db>
# output: one <table><TAB><column><TAB><column ddl> line per column (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpKamDBColumns() {
    local DB="$1"
    local BASE RAW TABLE COL DDL COL_SQL

    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    BASE=$(kamDBBaseTables "$DB") || return 1
    # COLUMN_DEFAULT is already a SQL literal on MariaDB 10.2+ (quoted strings, current_timestamp(), numbers)
    COL_SQL="SELECT TABLE_NAME, COLUMN_NAME, CONCAT('\`', COLUMN_NAME, '\` ', COLUMN_TYPE, IF(CHARACTER_SET_NAME IS NOT NULL AND COLLATION_NAME IS NOT NULL AND DATA_TYPE IN ('char','varchar','tinytext','text','mediumtext','longtext','enum','set'), CONCAT(' CHARACTER SET ', CHARACTER_SET_NAME, ' COLLATE ', COLLATION_NAME), ''), IF(IFNULL(GENERATION_EXPRESSION,'') <> '', CONCAT(IF(IS_NULLABLE='NO', ' NOT NULL', ' NULL'), ' GENERATED ALWAYS AS (', GENERATION_EXPRESSION, ') ', IF(EXTRA LIKE '%STORED%' OR EXTRA LIKE '%PERSISTENT%', 'STORED', 'VIRTUAL')), CONCAT(IF(IS_NULLABLE='NO', ' NOT NULL', ' NULL'), CASE WHEN COLUMN_DEFAULT IS NULL THEN IF(IS_NULLABLE='NO', '', ' DEFAULT NULL') ELSE CONCAT(' DEFAULT ', COLUMN_DEFAULT) END, IF(EXTRA IS NULL OR EXTRA='' OR EXTRA LIKE '%GENERATED%', '', CONCAT(' ', EXTRA))))) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME <> 'version' ORDER BY TABLE_NAME, ORDINAL_POSITION;"
    RAW=$(withRootDBConn mysql -sN -r -e "$COL_SQL" </dev/null 2>/dev/null) || return 1
    while IFS=$'\t' read -r TABLE COL DDL; do
        [[ -n "$TABLE" ]] || continue
        grep -Fxq -- "$TABLE" <<<"$BASE" || continue
        [[ "$TABLE" =~ ^[A-Za-z0-9_]+$ && "$COL" =~ ^[A-Za-z0-9_]+$ && -n "$DDL" ]] || return 1
        printf '%s\t%s\t%s\n' "$TABLE" "$COL" "$DDL"
    done <<<"$RAW"
}

# lists the names of one kind of object in a DB, for the kinds the restore replays
# usage: kamDBExistingNames <db> <TABLE|VIEW|TRIGGER|PROCEDURE|FUNCTION>
# output: one name per line
# returns: 0 on success, non zero otherwise
function kamDBExistingNames() {
    local DB="$1" KIND="$2"

    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    case "$KIND" in
    TABLE) kamDBBaseTables "$DB" ;;
    VIEW) withRootDBConn mysql -sN -e "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}';" </dev/null 2>/dev/null ;;
    TRIGGER) withRootDBConn mysql -sN -e "SELECT TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${DB}';" </dev/null 2>/dev/null ;;
    PROCEDURE|FUNCTION) withRootDBConn mysql -sN -e "SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='${DB}' AND ROUTINE_TYPE='${KIND}';" </dev/null 2>/dev/null ;;
    *) return 1 ;;
    esac
}

# replays the saved tables, views, triggers or routines that the reinstalled DB does not have
# usage: restoreKamDBObjects <db> <TABLE|VIEW|TRIGGER|PROCEDURE|FUNCTION>
# notes: an object the reinstall created is kept as the installer defined it, the saved copy is not replayed over it
# returns: 0 on success, non zero otherwise
function restoreKamDBObjects() {
    local DB="$1" WANT="$2"
    local KIND NAME EXISTING FILE
    local N=0
    local FILES=()

    [[ -f "$KAMDB_OBJECTS_MANIFEST" ]] || {
        printerr "object dump is missing, cannot restore ${DB}: ${KAMDB_OBJECTS_MANIFEST}"
        return 1
    }
    EXISTING=$(kamDBExistingNames "$DB" "$WANT") || return 1
    while IFS=$'\t' read -r KIND NAME; do
        N=$((N + 1))
        [[ "$KIND" == "$WANT" ]] || continue
        grep -Fxq -- "$NAME" <<<"$EXISTING" && continue
        FILES+=("${KAMDB_OBJECTS_DIR}/${N}.sql")
    done <"$KAMDB_OBJECTS_MANIFEST"

    if (( ${#FILES[@]} == 0 )); then
        return 0
    fi
    if [[ "$WANT" == TABLE ]]; then
        # foreign keys are off so the tables can be created in any order
        {
            echo 'SET FOREIGN_KEY_CHECKS=0;'
            cat "${FILES[@]}"
            echo 'SET FOREIGN_KEY_CHECKS=1;'
        } | withRootDBConn --db="$DB" mysql || return 1
        return 0
    fi
    if [[ "$WANT" == VIEW ]]; then
        # views are replayed in passes so a view that selects from another custom view or function can be created after its dependency
        local PENDING=("${FILES[@]}")
        local NEXT=()
        local PROGRESS
        while (( ${#PENDING[@]} > 0 )); do
            NEXT=()
            PROGRESS=0
            for FILE in "${PENDING[@]}"; do
                if withRootDBConn --db="$DB" mysql <"$FILE" >/dev/null 2>&1; then
                    PROGRESS=1
                else
                    NEXT+=("$FILE")
                fi
            done
            if (( PROGRESS == 0 )); then
                printerr "could not recreate view(s) in ${DB}"
                for FILE in "${NEXT[@]}"; do
                    withRootDBConn --db="$DB" mysql <"$FILE" || return 1
                done
                return 1
            fi
            PENDING=("${NEXT[@]}")
        done
        return 0
    fi
    for FILE in "${FILES[@]}"; do
        withRootDBConn --db="$DB" mysql <"$FILE" || return 1
    done
}

# adds saved columns that the reinstalled tables do not have, installer column definitions are never changed
# usage: addMissingKamDBColumns <db>
# notes: called after the base tables are emptied so NOT NULL columns without a default can be added
# returns: 0 on success, non zero otherwise
function addMissingKamDBColumns() {
    local DB="$1"
    local TABLE COL DDL EXISTING_TABLES EXISTING_COLS

    [[ "$DB" =~ ^[A-Za-z0-9_]+$ ]] || return 1
    [[ -f "$KAMDB_COLUMNS_FILE" ]] || {
        printerr "column dump is missing, cannot restore ${DB}: ${KAMDB_COLUMNS_FILE}"
        return 1
    }
    EXISTING_TABLES=$(kamDBBaseTables "$DB") || return 1
    EXISTING_COLS=$(withRootDBConn mysql -sN -e "SELECT CONCAT(TABLE_NAME, '.', COLUMN_NAME) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}';" </dev/null 2>/dev/null) || return 1
    while IFS=$'\t' read -r TABLE COL DDL; do
        [[ -n "$TABLE" && -n "$COL" && -n "$DDL" ]] || continue
        [[ "$TABLE" =~ ^[A-Za-z0-9_]+$ && "$COL" =~ ^[A-Za-z0-9_]+$ ]] || {
            printerr "unexpected column name in ${DB}: ${TABLE}.${COL}"
            return 1
        }
        grep -Fxq -- "$TABLE" <<<"$EXISTING_TABLES" || continue
        grep -Fxq -- "${TABLE}.${COL}" <<<"$EXISTING_COLS" && continue
        withRootDBConn --db="$DB" mysql -e "ALTER TABLE \`${TABLE}\` ADD COLUMN ${DDL};" </dev/null || {
            printerr "could not add column ${TABLE}.${COL} in ${DB}"
            return 1
        }
    done <"$KAMDB_COLUMNS_FILE"
}

# sets VERSION in the saved dsip_settings row of this install, the GUI loads that row over settings.py when LOAD_SETTINGS_FROM is db
# usage: setKamDBSettingsVersion
# notes: the row is matched on DSIP_ID from settings.py, a DB without the table is skipped
# returns: 0 on success, non zero otherwise
function setKamDBSettingsVersion() {
    local TABLE_FOUND DSIP_ID_VALUE DB_VERSION

    TABLE_FOUND=$(kamDBTablesIn "$KAM_DB_NAME" dsip_settings) || return 1
    [[ -n "$TABLE_FOUND" ]] || return 0
    DSIP_ID_VALUE=$(getConfigAttrib 'DSIP_ID' "$DSIP_CONFIG_FILE")
    # DSIP_ID is hex encoded by the installer, anything else is refused rather than escaped into SQL
    [[ "$DSIP_ID_VALUE" =~ ^[A-Za-z0-9_.+/=-]+$ ]] || {
        printerr "DSIP_ID is not set to a valid value in ${DSIP_CONFIG_FILE}, cannot update VERSION in dsip_settings"
        return 1
    }
    withRootDBConn --db="$KAM_DB_NAME" mysql -e "UPDATE dsip_settings SET VERSION='0.793' WHERE DSIP_ID='${DSIP_ID_VALUE}';" </dev/null || return 1
    DB_VERSION=$(withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "SELECT VERSION FROM dsip_settings WHERE DSIP_ID='${DSIP_ID_VALUE}';" </dev/null) || return 1
    [[ "$DB_VERSION" == '0.793' ]] || {
        printerr "could not set VERSION to 0.793 for DSIP_ID in ${KAM_DB_NAME}.dsip_settings"
        return 1
    }
}

# usage: backupFailed <message>
# notes: only called before any system change, so nothing needs restoring
function backupFailed() {
    printerr "backup failed: $*"
    printerr "no system changes were made, incomplete backup will not be used: ${CURR_BACKUP_DIR}"
    exit 1
}

# usage: stopAndMaskService <unit>
# notes: absent units are skipped, changed units are recorded for resetConfigsHandler
function stopAndMaskService() {
    local UNIT="$1"

    if ! systemctl cat "$UNIT" >/dev/null 2>&1; then
        printdbg "${UNIT} is not installed, skipping"
        return 0
    fi
    if systemctl is-active --quiet "$UNIT"; then
        STOPPED_UNITS+=("$UNIT")
        systemctl stop "$UNIT" || return 1
    fi
    # recorded before masking so a partial mask is still unmasked on restore
    MASKED_UNITS+=("$UNIT")
    systemctl mask "$UNIT" || return 1
}

# restores the kamailio DB and its user accounts from the dumps taken before the upgrade
# notes: the DB is dropped and re-imported so views and routines match the dump, accounts created by the upgrade are removed
function restoreKamDB() {
    local ACCOUNTS ACCOUNT
    local ACCOUNT_LIST=()
    local RESTORE_FAILED=0

    [[ -s "$KAMDB_DUMP_FILE" && -s "$KAMDB_USER_DUMP_FILE" ]] || {
        printerr "DB or grants dump is missing, cannot restore ${KAM_DB_NAME}: ${CURR_BACKUP_DIR}"
        return 1
    }
    # the dump is only imported into a DB that was dropped, never into a DB that still has the upgraded tables
    if withRootDBConn mysql -e "DROP DATABASE IF EXISTS \`${KAM_DB_NAME}\`;"; then
        withRootDBConn mysql <"$KAMDB_DUMP_FILE" || RESTORE_FAILED=1
    else
        RESTORE_FAILED=1
    fi

    # accounts are reset even if the DB import failed, so no account created by the upgrade survives
    ACCOUNTS=$(withRootDBConn mysql -sN -A \
        -e "SELECT CONCAT(QUOTE(user), '@', QUOTE(host)) FROM mysql.user WHERE user='${KAM_DB_USER}';" \
        </dev/null 2>/dev/null) || RESTORE_FAILED=1
    mapfile -t ACCOUNT_LIST <<<"$ACCOUNTS"
    for ACCOUNT in "${ACCOUNT_LIST[@]}"; do
        [[ -n "$ACCOUNT" ]] || continue
        withRootDBConn mysql -e "DROP USER ${ACCOUNT};" || RESTORE_FAILED=1
    done
    withRootDBConn mysql <"$KAMDB_USER_DUMP_FILE" || RESTORE_FAILED=1

    (( RESTORE_FAILED == 0 ))
}

# restores the system to the state captured in the backup
# notes: only runs after a change started and the backup was verified complete
resetConfigsHandler() {
    local EXIT_CODE="$1"
    local RESTORE_FAILED=0
    local UNIT

    # ignore repeated signals while restoring, a partial restore is worse than a slow one
    trap '' SIGHUP SIGINT SIGQUIT SIGTERM
    trap - EXIT

    if (( MIGRATION_COMPLETE == 1 )); then
        trap - SIGHUP SIGINT SIGQUIT SIGTERM
        exit 0
    fi
    printerr "upgrade did not complete (exit code: ${EXIT_CODE})"

    if (( CHANGES_STARTED == 0 )); then
        printwarn 'no system changes were made, nothing to restore'
        exit 1
    fi
    if (( BACKUP_COMPLETE == 0 )); then
        printerr "system was changed but the backup is incomplete, restore manually from ${CURR_BACKUP_DIR}"
        exit 1
    fi

    printwarn 'upgrade failed, resetting system to previous state'
    # every masked unit is stopped before the restore, the installer may have started it with the upgraded config and code
    # a start on a running unit does nothing, so only the units that were running before the upgrade are started after the restore
    for UNIT in "${MASKED_UNITS[@]}"; do
        systemctl unmask "$UNIT" || RESTORE_FAILED=1
        systemctl stop "$UNIT" || RESTORE_FAILED=1
    done

    for TREE in "$OLD_PROJECT_DIR" "$DSIP_LIB_DIR" "$DSIP_SYSTEM_CONFIG_DIR" "$SYSTEM_KAMAILIO_CONFIG_DIR" "$SYSTEM_RTPENGINE_CONFIG_DIR" "$SYSTEM_NGINX_CONFIG_DIR"; do
        restoreTree "$TREE" || RESTORE_FAILED=1
    done
    for SYS_DIR in /etc/systemd/system /lib/systemd/system; do
        for NAME in "${SYSTEMD_UNITS[@]}" "${SYSTEMD_DROPINS[@]}"; do
            restoreEntry "${SYS_DIR}/${NAME}" || RESTORE_FAILED=1
        done
    done
    # defaults files: remove the ones the upgrade created, then put back every backed up one (including deleted ones)
    shopt -s nullglob
    for FILE in /etc/default/kamailio* /etc/default/rtpengine* "${CURR_BACKUP_DIR}"/etc/default/kamailio* "${CURR_BACKUP_DIR}"/etc/default/rtpengine*; do
        restoreEntry "/etc/default/${FILE##*/}" || RESTORE_FAILED=1
    done
    for FILE in /etc/profile.d/dsip_*.sh "${CURR_BACKUP_DIR}"/etc/profile.d/dsip_*.sh; do
        restoreEntry "/etc/profile.d/${FILE##*/}" || RESTORE_FAILED=1
    done
    shopt -u nullglob
    for FILE in "${MANAGED_FILES[@]}"; do
        restoreEntry "$FILE" || RESTORE_FAILED=1
    done
    restoreCrontab || RESTORE_FAILED=1
    systemctl daemon-reload || RESTORE_FAILED=1

    # only restore the DB if a stage may have changed it, the dump is the only copy of the old state
    if (( KAM_DB_BACKED_UP == 1 && KAM_DB_TOUCHED == 1 )); then
        restoreKamDB || RESTORE_FAILED=1
    fi

    if (( RESTORE_FAILED == 0 )); then
        for UNIT in "${STOPPED_UNITS[@]}"; do
            systemctl start "$UNIT" || RESTORE_FAILED=1
        done
    fi

    if (( RESTORE_FAILED == 1 )); then
        printerr "restore was incomplete, manual recovery required from: ${CURR_BACKUP_DIR}"
    else
        printwarn "system restored to previous state, backup is here: ${CURR_BACKUP_DIR}"
    fi
    trap - SIGHUP SIGINT SIGQUIT SIGTERM
    exit 1
}

# applies schema.sql, then restores the saved accounts and rows into the reinstalled kamailio DB
# notes: tables the reinstall does not create are recreated first, every base table is then emptied before extra columns and the data replay
#        routines are created before views so a view that calls a custom function can be created, views retry unresolved dependencies
#        triggers are created last so the data replay does not fire them
#        the VERSION of the saved dsip_settings row is set to this release, the view dsip_prefix_mapping is checked, the upgrade fails if it is missing
# replay a data file and fail on a mysql error or a data-alteration warning (the dump header relaxes sql_mode so changes can otherwise be silent)
function importKamDBDataFile() {
    local FILE="$1" OUT RC

    OUT=$(withRootDBConn --db="$KAM_DB_NAME" mysql --show-warnings <"$FILE" 2>&1)
    RC=$?
    [[ -n "$OUT" ]] && printf '%s\n' "$OUT" >&2
    if (( RC != 0 )); then
        printerr "importing ${FILE} failed with exit code ${RC}"
        return 1
    fi
    if grep -qE '^Warning \(Code (1048|1263|1264|1265|1292|1366|1406)\)' <<<"$OUT"; then
        printerr "importing ${FILE} would lose or alter data: $(grep -E '^Warning \(Code (1048|1263|1264|1265|1292|1366|1406)\)' <<<"$OUT" | head -n 3 | tr '\n' ' ')"
        printerr 'the import warning indicates saved data may not be preserved, the upgrade is rolled back'
        return 1
    fi
    return 0
}

function restoreKamDBAfterReinstall() {
    local ACCOUNTS ACCOUNT TABLES DERIVED
    local ACCOUNT_LIST=() TABLE_LIST=() DERIVED_LIST=()

    withRootDBConn --db="$KAM_DB_NAME" mysql <"${UPGRADE_DIR}/schema.sql" || return 1

    # custom tables the saved DB had are recreated empty, the installer tables that exist are kept as the installer defined them
    restoreKamDBObjects "$KAM_DB_NAME" TABLE || return 1

    # the reinstall recreates the kamailio user, it is dropped so the saved account and its grants replace it
    ACCOUNTS=$(withRootDBConn mysql -sN -A \
        -e "SELECT CONCAT(QUOTE(user), '@', QUOTE(host)) FROM mysql.user WHERE user='${KAM_DB_USER}';" \
        </dev/null 2>/dev/null) || return 1
    mapfile -t ACCOUNT_LIST <<<"$ACCOUNTS"
    for ACCOUNT in "${ACCOUNT_LIST[@]}"; do
        [[ -n "$ACCOUNT" ]] || continue
        withRootDBConn mysql -e "DROP USER ${ACCOUNT};" || return 1
    done
    withRootDBConn mysql <"$KAMDB_USER_DUMP_FILE" || return 1

    # the installer seeds rows (dispatcher, gateways, rules, ...), so every base table is emptied before extra columns and the saved rows are loaded
    TABLES=$(kamDBBaseTables "$KAM_DB_NAME") || return 1
    mapfile -t TABLE_LIST < <(sed '/^$/d' <<<"$TABLES")
    truncateKamDBTables "$KAM_DB_NAME" "${TABLE_LIST[@]}" || return 1
    # extra user columns on installer tables, added on empty tables so NOT NULL columns without a default succeed
    addMissingKamDBColumns "$KAM_DB_NAME" || return 1
    importKamDBDataFile "$KAMDB_DATA_FILE" || return 1

    # the triggers on dr_gw_lists and dr_rules wrote derived rows during the data load, so the derived tables are emptied and replaced from their dump
    DERIVED=$(kamDBTablesIn "$KAM_DB_NAME" "${KAMDB_DERIVED_TABLES[@]}") || return 1
    mapfile -t DERIVED_LIST < <(sed '/^$/d' <<<"$DERIVED")
    truncateKamDBTables "$KAM_DB_NAME" "${DERIVED_LIST[@]}" || return 1
    importKamDBDataFile "$KAMDB_DERIVED_FILE" || return 1

    # routines before views: a view that calls a custom function cannot be created until the function exists
    restoreKamDBObjects "$KAM_DB_NAME" PROCEDURE || return 1
    restoreKamDBObjects "$KAM_DB_NAME" FUNCTION || return 1
    restoreKamDBObjects "$KAM_DB_NAME" VIEW || return 1
    # triggers last, the saved triggers would otherwise fire during the data replay
    restoreKamDBObjects "$KAM_DB_NAME" TRIGGER || return 1

    setKamDBSettingsVersion || return 1
    withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "SELECT 1 FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${KAM_DB_NAME}' AND TABLE_NAME='dsip_prefix_mapping';" </dev/null | grep -q 1
}

# lists the settings the new template defines that the installed settings file does not
# usage: missingSettings <new template> <installed settings file>
# output: the source of each missing setting, one block per setting
# notes: only literal values are copied, a non-literal missing setting fails so it is never guessed
# returns: 0 on success, non zero otherwise
function missingSettings() {
    "$PYTHON_CMD" - "$1" "$2" <<'EOF'
import ast
import sys

with open(sys.argv[1]) as f:
    template_src = f.read()
with open(sys.argv[2]) as f:
    installed = {t.id for node in ast.parse(f.read()).body if isinstance(node, ast.Assign) for t in node.targets if isinstance(t, ast.Name)}

for node in ast.parse(template_src).body:
    if not isinstance(node, ast.Assign) or len(node.targets) != 1 or not isinstance(node.targets[0], ast.Name):
        continue
    name = node.targets[0].id
    # VERSION is owned by this upgrade, the template value must never be copied in
    if name in installed or name == 'VERSION':
        continue
    try:
        ast.literal_eval(node.value)
    except ValueError:
        sys.exit(f'non-literal setting cannot be migrated automatically: {name}')
    print(ast.get_source_segment(template_src, node))
EOF
}

# appends the settings the installed settings file lacks, existing lines are never changed
# usage: addMissingSettings <new template> <installed settings file>
# returns: 0 on success, non zero otherwise
function addMissingSettings() {
    local MISSING

    MISSING=$(missingSettings "$1" "$2") || {
        printerr "could not compare the settings in ${2} with the new template"
        return 1
    }
    if [[ -n "$MISSING" ]]; then
        printf '\n# added by the v0.793 upgrade, existing values were kept\n%s\n' "$MISSING" >>"$2" || return 1
    fi
    # nothing may be missing after the append, a failed comparison must not pass as an empty result
    MISSING=$(missingSettings "$1" "$2") || return 1
    [[ -z "$MISSING" ]] || {
        printerr "settings still missing from ${2} after the upgrade"
        return 1
    }
}

# reinstalls the services that were masked and stopped, then restores the kamailio DB, sets VERSION
# notes: exits through the caller on failure, resetConfigsHandler restores the backup
function applyUpgrade() {
    local INSTALL_OPTS=()
    local INSTALL_ENV=()
    local VAR UNIT

    printdbg 'migrating dSIPRouter project files'
    cp -rf "${NEW_PROJECT_DIR}/." "${OLD_PROJECT_DIR}/" || return 1
    export DSIP_PROJECT_DIR="$OLD_PROJECT_DIR"
    # the stages below use the new definitions, the same as v0.77 re-sources after the sync
    [[ -f "${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh" ]] || return 1
    export PYTHON_CMD="${DSIP_PROJECT_DIR}/venv/bin/python"
    . "${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh"

    printdbg 'adding new settings to the dSIPRouter config'
    addMissingSettings "${NEW_PROJECT_DIR}/gui/settings.py" "${DSIP_CONFIG_FILE}" || return 1

    # set before the installer runs, the regenerated kamailio config takes DSIP_VERSION from VERSION
    printdbg 'setting installed version'
    setConfigAttrib 'VERSION' '0.793' "${DSIP_CONFIG_FILE}" -q || return 1
    # sed only rewrites an existing VERSION line, so the value is read back to confirm it was written
    [[ "$(getConfigAttrib 'VERSION' "${DSIP_CONFIG_FILE}")" == '0.793' ]] || {
        printerr "could not set VERSION to 0.793 in ${DSIP_CONFIG_FILE}"
        return 1
    }

    # the conditional markers and source dirs are removed so the installer runs the reinstall
    if (( REINSTALL_KAMAILIO == 1 )); then
        INSTALL_OPTS+=(-kam)
        rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" || return 1
        rm -rf "${SRC_DIR}/kamailio" || return 1
        rm -f "${DSIP_SYSTEM_CONFIG_DIR}/kamailio/kamailio.cfg" || return 1
    fi
    if (( REINSTALL_DSIPROUTER == 1 )); then
        INSTALL_OPTS+=(-dsip)
        rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" || return 1
        rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled" || return 1
    fi
    if (( REINSTALL_RTPENGINE == 1 )); then
        INSTALL_OPTS+=(-rtp)
        rm -rf "${SRC_DIR}/rtpengine" || return 1
        rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" || return 1
    fi

    # the installer restarts the units it reinstalls and fails on a masked unit, so they are unmasked before it runs
    printdbg 'unmasking services'
    for UNIT in "${MASKED_UNITS[@]}"; do
        systemctl unmask "$UNIT" || return 1
    done
    systemctl daemon-reload || return 1

    # an empty flag list must not reach the installer, 'install' with no flags installs everything
    if (( ${#INSTALL_OPTS[@]} > 0 )); then
        printdbg 'upgrading services'
        # the installer runs with a cleared environment, so the values it needs are passed explicitly
        # no SET_* credentials are forwarded: with RUNNING_UPGRADE=1 the installer keeps the stored secrets from settings.py
        # forwarding an empty SET_ROOT_DB_PASS makes setCredentials rewrite the root DB account, which opens it to passwordless login
        INSTALL_ENV=(CURR_BACKUP_DIR="$CURR_BACKUP_DIR" RUNNING_UPGRADE=1 DSIP_PROJECT_DIR="$DSIP_PROJECT_DIR"
            HOME="$HOME" LANG="$LANG" LANGUAGE="$LANGUAGE" LC_ALL="$LC_ALL" PATH="$PATH" PWD="$PWD" USER="root")
        env -i "${INSTALL_ENV[@]}" "${DSIP_PROJECT_DIR}/dsiprouter.sh" install "${INSTALL_OPTS[@]}" || {
            printerr 'failed upgrading services'
            return 1
        }
    fi

    if (( REINSTALL_KAMAILIO == 1 )); then
        printdbg 'migrating kamailio database'
        restoreKamDBAfterReinstall || {
            printerr "failed migrating kamailio database, restore from: ${CURR_BACKUP_DIR}"
            return 1
        }
    fi

    # the installer may rewrite the settings file, so VERSION is checked again after it ran
    [[ "$(getConfigAttrib 'VERSION' "${DSIP_CONFIG_FILE}")" == '0.793' ]] || {
        printerr "VERSION is not 0.793 after the reinstall in ${DSIP_CONFIG_FILE}"
        return 1
    }

    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
        printwarn 'kamailio service requires restarting'
    fi
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
        printwarn 'dsiprouter service requires restarting'
    fi
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
        printwarn 'rtpengine service requires restarting'
    fi
    return 0
}

# the names of the kamailio DB objects are interpolated into SQL and file paths, so anything outside plain identifiers stops the upgrade before any change
if (( KAM_DB_EXISTS == 1 )); then
    KAM_OBJECTS_PREFLIGHT=$(kamDBObjectList "$KAM_DB_NAME") || {
        printerr "could not list the objects of ${KAM_DB_NAME}, no changes were made"
        exit 1
    }
    while IFS=$'\t' read -r KIND NAME; do
        [[ -n "$KIND" ]] || continue
        [[ "$NAME" =~ ^[A-Za-z0-9_]+$ ]] || {
            printerr "unsupported ${KIND} name in ${KAM_DB_NAME}: ${NAME}, rename it before upgrading, no changes were made"
            exit 1
        }
    done <<<"$KAM_OBJECTS_PREFLIGHT"

    KAM_COLUMNS_PREFLIGHT=$(withRootDBConn mysql -sN -e "SELECT DISTINCT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${KAM_DB_NAME}' AND TABLE_NAME IN (SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='${KAM_DB_NAME}' AND TABLE_TYPE='BASE TABLE');" </dev/null 2>/dev/null) || {
        printerr "could not list the columns of ${KAM_DB_NAME}, no changes were made"
        exit 1
    }
    while IFS= read -r NAME; do
        [[ -n "$NAME" ]] || continue
        [[ "$NAME" =~ ^[A-Za-z0-9_]+$ ]] || {
            printerr "unsupported column name in ${KAM_DB_NAME}: ${NAME}, rename it before upgrading, no changes were made"
            exit 1
        }
    done <<<"$KAM_COLUMNS_PREFLIGHT"

    KAM_EVENTS_PREFLIGHT=$(withRootDBConn mysql -sN -e "SELECT EVENT_NAME FROM information_schema.EVENTS WHERE EVENT_SCHEMA='${KAM_DB_NAME}';" </dev/null 2>/dev/null) || {
        printerr "could not list the events of ${KAM_DB_NAME}, no changes were made"
        exit 1
    }
    if [[ -n "$KAM_EVENTS_PREFLIGHT" ]]; then
        printerr "scheduled EVENT objects in ${KAM_DB_NAME} are not supported by this upgrade: ${KAM_EVENTS_PREFLIGHT//$'\n'/, }"
        printerr 'drop them before upgrading, no changes were made'
        exit 1
    fi

    KAM_DEFINERS_PREFLIGHT=$(kamDBDefiners "$KAM_DB_NAME") || {
        printerr "could not list the DEFINER accounts of ${KAM_DB_NAME}, no changes were made"
        exit 1
    }
    while IFS= read -r DEFINER; do
        [[ -n "$DEFINER" ]] || continue
        [[ "$DEFINER" =~ ^[A-Za-z0-9_.$-]+@[A-Za-z0-9_.:%-]+$ ]] || {
            printerr "unsupported DEFINER in ${KAM_DB_NAME}: ${DEFINER}, no changes were made"
            exit 1
        }
        checkDBUserExists "$DEFINER"
        case $? in
        0) ;;
        2)
            printerr "DEFINER account ${DEFINER} does not exist, create it before upgrading, no changes were made"
            exit 1
            ;;
        *)
            printerr "could not verify DEFINER account ${DEFINER}, no changes were made"
            exit 1
            ;;
        esac
    done <<<"$KAM_DEFINERS_PREFLIGHT"
fi

# armed before the backup so a signal during the backup is handled, nothing is restored until CHANGES_STARTED
# each signal reports its own exit status so the restore message shows what interrupted the upgrade
trap 'resetConfigsHandler 129' SIGHUP
trap 'resetConfigsHandler 130' SIGINT
trap 'resetConfigsHandler 131' SIGQUIT
trap 'resetConfigsHandler 143' SIGTERM
trap 'resetConfigsHandler $?' EXIT

printdbg 'backing up configs and databases before making any change'
mkdir -p "$CURR_BACKUP_DIR" || backupFailed "could not create ${CURR_BACKUP_DIR}"
backupTree "$OLD_PROJECT_DIR" || backupFailed "${OLD_PROJECT_DIR}"
backupTree "$DSIP_LIB_DIR" || backupFailed "${DSIP_LIB_DIR}"
backupTree "$DSIP_SYSTEM_CONFIG_DIR" || backupFailed "${DSIP_SYSTEM_CONFIG_DIR}"
backupTree "$SYSTEM_KAMAILIO_CONFIG_DIR" || backupFailed "${SYSTEM_KAMAILIO_CONFIG_DIR}"
backupTree "$SYSTEM_RTPENGINE_CONFIG_DIR" || backupFailed "${SYSTEM_RTPENGINE_CONFIG_DIR}"
backupTree "$SYSTEM_NGINX_CONFIG_DIR" || backupFailed "${SYSTEM_NGINX_CONFIG_DIR}"
for SYS_DIR in /etc/systemd/system /lib/systemd/system; do
    for NAME in "${SYSTEMD_UNITS[@]}" "${SYSTEMD_DROPINS[@]}"; do
        backupEntry "${SYS_DIR}/${NAME}" || backupFailed "${SYS_DIR}/${NAME}"
    done
done
shopt -s nullglob
for FILE in /etc/default/kamailio* /etc/default/rtpengine*; do
    backupEntry "$FILE" || backupFailed "${FILE}"
done
for FILE in /etc/profile.d/dsip_*.sh; do
    backupEntry "$FILE" || backupFailed "${FILE}"
done
shopt -u nullglob
for FILE in "${MANAGED_FILES[@]}"; do
    backupEntry "$FILE" || backupFailed "${FILE}"
done
backupCrontab || backupFailed "root crontab"

if (( KAM_DB_EXISTS == 1 )); then
    dumpKamDBFull "$KAM_DB_NAME" >"$KAMDB_DUMP_FILE" || backupFailed "${KAM_DB_NAME} DB dump"
    grep -q '^-- Dump completed' "$KAMDB_DUMP_FILE" || backupFailed "${KAM_DB_NAME} DB dump is incomplete"
    dumpKamDBGrants >"$KAMDB_USER_DUMP_FILE" || backupFailed "${KAM_DB_USER} grants dump"
    dumpKamDBData "$KAM_DB_NAME" >"$KAMDB_DATA_FILE" || backupFailed "${KAM_DB_NAME} data dump"
    grep -q '^-- Dump completed' "$KAMDB_DATA_FILE" || backupFailed "${KAM_DB_NAME} data dump is incomplete"
    dumpKamDBDerived "$KAM_DB_NAME" >"$KAMDB_DERIVED_FILE" || backupFailed "${KAM_DB_NAME} derived tables dump"
    grep -q '^-- Dump completed' "$KAMDB_DERIVED_FILE" || backupFailed "${KAM_DB_NAME} derived tables dump is incomplete"
    dumpKamDBObjects "$KAM_DB_NAME" "$KAMDB_OBJECTS_DIR" || backupFailed "${KAM_DB_NAME} tables, views, triggers and routines dump"
    [[ -f "$KAMDB_OBJECTS_MANIFEST" ]] || backupFailed "${KAM_DB_NAME} object manifest is missing"
    dumpKamDBColumns "$KAM_DB_NAME" >"$KAMDB_COLUMNS_FILE" || backupFailed "${KAM_DB_NAME} column dump"
    [[ -f "$KAMDB_COLUMNS_FILE" ]] || backupFailed "${KAM_DB_NAME} column dump is missing"
    KAM_DB_BACKED_UP=1
fi

# only a verified backup is marked complete, and only then can the handler restore from it
date '+%s' >"${CURR_BACKUP_DIR}/.complete" || backupFailed "could not write backup marker"
BACKUP_COMPLETE=1
printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

printdbg 'stopping and masking services before reinstall'
CHANGES_STARTED=1
if (( REINSTALL_DSIPROUTER == 1 )); then
    stopAndMaskService dsiprouter.service || { printerr 'failed stopping or masking dsiprouter.service'; exit 1; }
fi
if (( REINSTALL_KAMAILIO == 1 )); then
    stopAndMaskService kamailio.service || { printerr 'failed stopping or masking kamailio.service'; exit 1; }
fi
if (( REINSTALL_RTPENGINE == 1 )); then
    stopAndMaskService rtpengine.service || { printerr 'failed stopping or masking rtpengine.service'; exit 1; }
fi

# set before any reinstall or DB write so resetConfigsHandler knows the DB may have changed
if (( KAM_DB_EXISTS == 1 )); then
    KAM_DB_TOUCHED=1
fi
applyUpgrade || { printerr 'upgrade stage failed'; exit 1; }

MIGRATION_COMPLETE=1
printdbg 'upgrade completed successfully'
exit 0
