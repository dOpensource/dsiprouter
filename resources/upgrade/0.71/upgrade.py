import sys
import os
import json
import datetime
import subprocess
import mysql.connector
import daemon
import lockfile
import signal
import logging

# sys.path.append("/etc/dsiprouter/gui/settings.py")
sys.path.insert(0, '/etc/dsiprouter/gui')
import settings

upgrade_settings = {}


# compare the version code from the settings file with the current version code
def start_upgrade():
    logging.info("Starting upgrade process")
    global upgrade_settings
    current_version = settings.VERSION
    upgrade_settings = read_settings()
    logging.info("Current Version: " + current_version)
    logging.info("Upgrade Version: " + upgrade_settings['version'])
    if upgrade_settings['depends'] == current_version:
        logging.info("Version Check Passed. Proceeding with upgrade to version " + upgrade_settings['version'])
        backup_system()
        upgrade_database()
        upgrade_dsiprouter()
        logging.info("Upgrade complete.")

        #TODO: Add git status diff checking


        sys.exit(0)
    else:
        logging.error("Version Check Failed. Please verify the version of the upgrade script and the version of the current installation")
        sys.exit(1)


def backup_system():
    # backup the system as is currently
    logging.info("Starting backup process")
    backup_destination = settings.BACKUP_FOLDER
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

    logging.info("Backup destination: " + backup_destination)

    # MySQL database credentials
    mysql_user = upgrade_settings['database_credentials']['user']
    mysql_password = upgrade_settings['database_credentials']['password']
    mysql_host = upgrade_settings['database_credentials']['host']
    mysql_db = upgrade_settings['database_credentials']['name']

    # create a backup of the mysql database
    logging.info("Backing up MySQL database")
    try:
        mysql_dump_cmd = f"mysqldump    -u {mysql_user} -p{mysql_password} {mysql_db} > {backup_destination}/{mysql_db}_{timestamp}.sql"
        output = subprocess.check_output(mysql_dump_cmd, shell=True)
        logging.info(output.decode("utf-8"))
        logging.info("MySQL database backup complete")
    except subprocess.CalledProcessError as e:
        logging.error("Error backing up MySQL database")
        logging.error(e.output.decode("utf-8"))


    # directory to archive
    dsip_project_dir = settings.DSIP_PROJECT_DIR
    dsip_config_dir = '/etc/dsiprouter'
    kamailio_config_dir = '/etc/kamailio'

    # create a tar archive of the specified directories
    logging.info("Backing up dSIP project directory : " + dsip_project_dir)
    try:
        tar_cmd = f"tar -zcvf {backup_destination}/dsip_project_{timestamp}.tar.gz {dsip_project_dir}"
        output = subprocess.check_output(tar_cmd, shell=True)
        # logging.info(output.decode("utf-8"))
    except subprocess.CalledProcessError as e:
        logging.error("Error backing up dSIP project directory")
        # logging.error(e.output.decode("utf-8"))

    try:
        logging.info("Backing up config directory")
        tar_cmd = f"tar -zcvf {backup_destination}/dsip_config_{timestamp}.tar.gz {dsip_config_dir}"
        output = subprocess.check_output(tar_cmd, shell=True)
        # logging.info(output.decode("utf-8"))
    except subprocess.CalledProcessError as e:
        logging.error("Error backing up dSIP project directory")
        # logging.error(e.output.decode("utf-8"))

    # backup the kamailio config
    try:
        logging.info("Backing up kamailio config")
        tar_cmd = f"tar -zcvf {backup_destination}/kamailio_config_{timestamp}.tar.gz {kamailio_config_dir}"
        output = subprocess.check_output(tar_cmd, shell=True)
        # logging.info(output.decode("utf-8"))
    except subprocess.CalledProcessError as e:
        logging.error("Error backing up dSIP project directory")
        # logging.error(e.output.decode("utf-8"))

    logging.info("Backup complete")


# reads settings from a json file info a dictionary
def read_settings():
    logging.info("Reading upgrade settings")
    try:
        with open('settings.json') as f:
            global upgrade_settings
            upgrade_settings = json.load(f)
            logging.info("Upgrade Settings loaded successfully.")
            return upgrade_settings
    except FileNotFoundError:
        logging.error("Upgrade Settings file (settings.json) not found")
        sys.exit(1)


# write a function that loops through an array of sql statements and executes them
def upgrade_database():
    logging.info("Starting DB Upgrade process")
    global upgrade_settings
    # MySQL database credentials
    mysql_user = upgrade_settings['database_credentials']['user']
    mysql_password = upgrade_settings['database_credentials']['password']
    mysql_host = upgrade_settings['database_credentials']['host']
    mysql_db = upgrade_settings['database_credentials']['name']

    queries = upgrade_settings['database_migrations']

    try:
        # connect to the MySQL database
        logging.info("Connecting to MySQL database")
        cnx = mysql.connector.connect(user=mysql_user, password=mysql_password, host=mysql_host, database=mysql_db)
        logging.info("Connected Successfully")
        cursor = cnx.cursor()

        # execute the SQL queries one by one
        for query in queries:
            logging.info("Executing Migration: " + query)
            cursor.execute(query)
            if query.strip().upper().startswith("SELECT"):
                print(cursor.fetchall())
            logging.info("Migration completed successfully")

        logging.info("Closing DB Connection")
        # close the cursor and connection
        cursor.close()
        cnx.close()

    except mysql.connector.Error as err:
        logging.error("An error occurred: {}".format(err))
        sys.exit(1)
    except Exception as e:
        logging.error("An unexpected error occurred {}".format(e))
        sys.exit(1)



def upgrade_dsiprouter():
    logging.info("Starting dSIPRouter Upgrade process")
    global upgrade_settings

    for command in upgrade_settings['dsiprouter']:
        os.system(command)


context = daemon.DaemonContext(
    working_directory='/opt/dsiprouter/resources/upgrade/0.71',
    # umask=0o002,
    pidfile=lockfile.FileLock('/var/run/dsip_upgrade.pid'),
)

context.signal_map = {
    signal.SIGTERM: 'terminate',
    signal.SIGHUP: 'terminate',
}

# with context:

os.chdir("/opt/dsiprouter/resources/upgrade/0.71")

# clear the contents of the log file
log_file_name = '/var/log/dsiprouter_upgrade.log'
open(log_file_name, 'w').close()

logging.basicConfig(filename=log_file_name,
                    level=logging.DEBUG,
                    encoding='utf-8',
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    datefmt='%m/%d/%Y %I:%M:%S %p'
                    )
start_upgrade()
