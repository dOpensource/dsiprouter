"""
Backup and restore of the kamailio DB with the DB credentials of dSIPRouter\n
The DB clients run as the dsiprouter user and connect as the kamailio DB user, nothing is run as root
"""

import contextlib
import os
import re
import shutil
import subprocess
import tempfile

import settings
from util.security import AES_CTR

# same options and clean up as dumpDB() in dsip_lib.sh
DUMP_OPTS = ('--single-transaction', '--opt', '--routines', '--triggers', '--hex-blob')
DEFINER_REGEX = re.compile(rb'''DEFINER=[`"'][a-zA-Z0-9_%]*[`"']@[`"'][a-zA-Z0-9_%]*[`"']''')
# client commands that run a program or open a file: \\! \\. \\P \\T \\e and their long forms
BACKSLASHES_REGEX = re.compile(rb'\\+')
CLIENT_ESCAPE_CHARS = (b'!', b'.', b'P', b'T', b'e')
CLIENT_COMMAND_REGEX = re.compile(rb'\s*(?:system|source|pager|tee|edit)(?:\s|$)', flags=re.IGNORECASE)
CLIENT_TIMEOUT = 3600


class KamDBBackupError(Exception):
    """ The kamailio DB could not be backed up or restored """


def findClient(names):
    """
    Find a DB client program

    :param names:               names the client is installed as
    :type names:                tuple[str, ...]
    :return:                    path of the client
    :rtype:                     str
    :raises KamDBBackupError:   if the client is not installed
    """

    for name in names:
        path = shutil.which(name)
        if path is not None:
            return path
    raise KamDBBackupError('{} is not installed'.format(names[0]))


@contextlib.contextmanager
def clientConfig():
    """
    Create an option file with the connection settings of the kamailio DB user\n
    The password is passed in a file only the dsiprouter user can read, it never appears in the arguments of the client

    :return:    path of the option file, removed when the context exits
    :rtype:     typing.Iterator[str]
    """

    db_pass = settings.KAM_DB_PASS
    if isinstance(db_pass, bytes):
        db_pass = AES_CTR.decrypt(db_pass)
    db_host = settings.KAM_DB_HOST
    if isinstance(db_host, (list, tuple)):
        db_host = db_host[0]

    options = {'user': settings.KAM_DB_USER, 'password': db_pass, 'host': db_host}
    if len(str(settings.KAM_DB_PORT)) != 0:
        options['port'] = settings.KAM_DB_PORT

    lines = ['[client]']
    for name, value in options.items():
        value = str(value)
        if '\n' in value or '\r' in value:
            raise KamDBBackupError('the kamailio DB {} can not be used in an option file'.format(name))
        lines.append('{}="{}"'.format(name, value.replace('\\', '\\\\').replace('"', '\\"')))

    config_fd, config_path = tempfile.mkstemp(suffix='.cnf')
    try:
        with os.fdopen(config_fd, 'w') as config_file:
            config_file.write('\n'.join(lines) + '\n')
        yield config_path
    finally:
        os.unlink(config_path)


def hasClientCommands(dump_path):
    """
    Check a backup for client commands that run a program or open a file

    :param dump_path:   path of the backup
    :type dump_path:    str
    :return:            whether the backup contains such a command
    :rtype:             bool
    """

    with open(dump_path, 'rb') as dump_file:
        for line in dump_file:
            if CLIENT_COMMAND_REGEX.match(line) is not None:
                return True
            # every run of backslashes is looked at once, an even number of them is escaped backslashes, not a command
            for match in BACKSLASHES_REGEX.finditer(line):
                if len(match.group()) % 2 == 1 and line[match.end():match.end() + 1] in CLIENT_ESCAPE_CHARS:
                    return True
    return False


def dumpKamDB(dump_file):
    """
    Backup the kamailio DB

    :param dump_file:           file the backup is written to, opened in binary mode
    :type dump_file:            typing.BinaryIO
    :raises KamDBBackupError:   if the backup failed
    """

    dump_client = findClient(('mysqldump', 'mariadb-dump'))

    # the errors are spooled to a file so the client can never block on them while the backup is read
    with clientConfig() as config_path, tempfile.TemporaryFile() as errors_file:
        proc = subprocess.Popen(
            [dump_client, '--defaults-extra-file={}'.format(config_path), *DUMP_OPTS, '--databases', settings.KAM_DB_NAME],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=errors_file
        )
        try:
            for line in proc.stdout:
                dump_file.write(DEFINER_REGEX.sub(b'', line).replace(b'ENGINE=MyISAM', b'ENGINE=InnoDB'))
            returncode = proc.wait(timeout=CLIENT_TIMEOUT)
        except (OSError, subprocess.TimeoutExpired) as ex:
            proc.kill()
            proc.wait()
            raise KamDBBackupError('failed backing up the kamailio DB: {}'.format(ex)) from ex
        finally:
            proc.stdout.close()
        errors_file.seek(0)
        errors = errors_file.read()

    if returncode != 0:
        raise KamDBBackupError('failed backing up the kamailio DB: {}'.format(errors.decode('utf-8', 'replace').strip()[-2000:]))


def restoreKamDB(dump_path):
    """
    Restore the kamailio DB from a backup\n
    The statements in the backup run with the privileges of the kamailio DB user

    :param dump_path:           path of the backup
    :type dump_path:            str
    :raises KamDBBackupError:   if the backup was refused or the restore failed
    """

    client = findClient(('mysql', 'mariadb'))
    client_help = subprocess.run([client, '--help'], stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=60).stdout

    # the backup must not be able to run programs or access files through the client
    restore_opts = ['--local-infile=0']
    if '--sandbox' in client_help:
        restore_opts.append('--sandbox')
    else:
        # clients without a sandbox mode: a backup using a client command that runs a program or opens a file is refused
        if '--system-command' in client_help:
            restore_opts.append('--system-command=OFF')
        if hasClientCommands(dump_path):
            raise KamDBBackupError('refusing to restore the kamailio DB, the backup contains client commands')

    with clientConfig() as config_path, open(dump_path, 'rb') as dump_file:
        try:
            proc = subprocess.run(
                [client, '--defaults-extra-file={}'.format(config_path), *restore_opts],
                stdin=dump_file,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                timeout=CLIENT_TIMEOUT
            )
        except (OSError, subprocess.TimeoutExpired) as ex:
            raise KamDBBackupError('failed restoring the kamailio DB: {}'.format(ex)) from ex

    if proc.returncode != 0:
        raise KamDBBackupError('failed restoring the kamailio DB: {}'.format(proc.stderr.decode('utf-8', 'replace').strip()[-2000:]))
