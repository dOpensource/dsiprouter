import sys
import os
import re
import json
import datetime
import subprocess
import logging
import ast
import shutil

sys.path.insert(0, '/etc/dsiprouter/gui')
import settings

sys.path.insert(0, '/opt/dsiprouter/gui')
from util.security import AES_CTR

upgrade_settings = {}
upgrade_resources_dir = os.path.join(settings.DSIP_PROJECT_DIR, 'resources/upgrade')
upgrade_version = sys.argv[1]
current_resources_dir = os.path.join(upgrade_resources_dir, upgrade_version)
current_scripts_dir = os.path.join(current_resources_dir, upgrade_version)


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
        merge_settings()
        logging.info("Upgrade complete.")

        # TODO: Add git status diff checking

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
    mysql_user = settings.ROOT_DB_USER
    mysql_password = AES_CTR.decrypt(settings.ROOT_DB_PASS).decode('utf-8')
    mysql_host = settings.KAM_DB_HOST
    mysql_db = settings.KAM_DB_NAME

    # create a backup of the mysql database
    logging.info("Backing up MySQL database")
    try:
        mysql_dump_cmd = f"mysqldump --single-transaction --opt --events --routines --triggers --add-drop-database --flush-privileges   -u {mysql_user} -p{mysql_password} -h {mysql_host} {mysql_db} > {backup_destination}/{mysql_db}_{timestamp}.sql"
        # logging.info("Command is " + mysql_dump_cmd)
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

    try:
        logging.info("Backing up the config file")
        new_file_name = '/etc/dsiprouter/gui/settings.py.bak'
        old_file_name = '/etc/dsiprouter/gui/settings.py'
        shutil.copyfile(old_file_name, new_file_name)

    except Exception as e:
        logging.error("An unexpected error occurred when backing up the config file. {}".format(e))
        sys.exit(1)

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
    mysql_user = settings.ROOT_DB_USER
    mysql_password = AES_CTR.decrypt(settings.ROOT_DB_PASS).decode('utf-8')
    mysql_host = settings.KAM_DB_HOST
    mysql_db = settings.KAM_DB_NAME

    migration_scripts = upgrade_settings['database_migrations']

    try:
        current_dir = os.path.dirname(os.path.realpath(__file__))
        scripts_directory = os.path.join(current_dir, 'scripts')

        logging.info("Running scripts from " + scripts_directory)

        # execute the SQL queries one by one
        for db_script in migration_scripts:
            logging.info("Executing Migration: " + db_script)
            migration_command = f"mysql  -h {mysql_host} -u {mysql_user} -p{mysql_password} {mysql_db} < {scripts_directory}/{db_script}"
            output = subprocess.check_output(migration_command, shell=True)
            logging.info(output.decode("utf-8"))
            logging.info("Migration " + db_script + "completed successfully")

        logging.info("All DB Migrations completed successfully")

    except Exception as e:
        logging.error("An unexpected error occurred {}".format(e))
        sys.exit(1)


def upgrade_dsiprouter():
    logging.info("Starting dSIPRouter Upgrade process")
    global upgrade_settings

    try:
        current_dir = os.path.dirname(os.path.realpath(__file__))
        scripts_directory = os.path.join(current_dir, 'scripts')

        logging.info("Running scripts from " + scripts_directory)

        # execute the SQL queries one by one
        for script in upgrade_settings['dsiprouter']:
            script_command = f"/bin/bash {scripts_directory}/{script}"
            logging.info("Executing Script: " + script_command)
            output = subprocess.check_output(script_command, shell=True)
            logging.info(output.decode("utf-8"))
            logging.info("Script " + script + "completed successfully")

        logging.info("All Scripts completed successfully")

    except Exception as e:
        logging.error("An unexpected error occurred {}".format(e))
        sys.exit(1)


def merge_settings():
    logging.info("Upgrading the settings file")

    old_file_name = '/etc/dsiprouter/gui/settings.py.old'
    new_file_name = '/etc/dsiprouter/gui/settings.py'

    # Read new file
    with open(old_file_name, 'r') as f:
        file_contents = f.read()
        old_file_dict = ast.literal_eval(file_contents)
    with open(new_file_name, 'r') as f:
        file_contents = f.read()
        new_file_dict = ast.literal_eval(file_contents)

    # Merge keys from new file into old file
    for key, value in old_file_dict.items():
        if key in new_file_dict:
            new_file_dict[key] = value

    # Output the merged dictionary
    print(old_file_dict)

    try:
        config_file = new_file_name

        with open(config_file, 'r+') as config:
            config_str = config.read()
            for key, val in old_file_dict.items():
                regex = r"^(?!#)(?:" + re.escape(key) + \
                        r")[ \t]*=[ \t]*(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?\"\"\".*\"\"\"[ \t]*$|b?'''.*'''[ \v]*$|b?\".*\"[ \t]*$|b?'.*')"
                replace_str = "{} = {}".format(key, repr(val))
                config_str = re.sub(regex, replace_str, config_str, flags=re.MULTILINE)

            config.seek(0)
            config.write(config_str)
            config.truncate()
            logging.info('Successfully updated the configuration file')
    except:
        logging.info('Problem updating the {0} configuration file'.format(config_file))


os.chdir(os.path.join(upgrade_resources_dir, upgrade_version))

# clear the contents of the log file
log_file_name = '/var/log/dsiprouter_upgrade.log'
open(log_file_name, 'w').close()

logging.basicConfig(
    filename=log_file_name,
    level=logging.DEBUG,
    encoding='utf-8',
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%m/%d/%Y %I:%M:%S %p'
)
logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))

start_upgrade()
