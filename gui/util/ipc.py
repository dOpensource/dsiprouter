# make sure the generated source files are imported instead of the template ones
import sys
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import inspect, os, signal
from UltraDict import UltraDict, Exceptions as shmem_exceptions
import settings


SETTINGS_SHMEM_NAME = 'shmem_settings'
STATE_SHMEM_NAME = 'shmem_state'


def createSharedMemoryDict(val, name):
    # globals from the top-level module
    caller_globals = dict(inspect.getmembers(inspect.stack()[-1][0]))["f_globals"]

    try:
        caller_globals[name] = UltraDict(val, name=name, create=True, auto_unlink=False, recurse=True)
    except shmem_exceptions.AlreadyExists:
        # we always want fresh memory, even if the memory was not deallocated properly
        UltraDict(name=name, create=False).unlink()
        caller_globals[name] = UltraDict(val, name=name, create=True, auto_unlink=False, recurse=True)

    return caller_globals[name]

def getSharedMemoryDict(name):
    # globals from the top-level module
    caller_globals = dict(inspect.getmembers(inspect.stack()[-1][0]))["f_globals"]

    if name in caller_globals:
        return caller_globals[name]

    caller_globals[name] = UltraDict(name=name, create=False)
    return caller_globals[name]


def sendSyncSettingsSignal(pid_file=settings.DSIP_PID_FILE, load_shared_settings=False):
    """
    Send signals to GUI process to synchronize settings from disk or shared memory

    :param pid_file:                path to PID file for process to send to
    :type pid_file:                 str
    :param load_shared_settings:    whether to load settings from shared memory or not
    :type load_shared_settings:     bool
    :return:                        None
    :rtype:                         None
    :except:                        OSError ProcessLookupError ValueError
    """
    with open(pid_file, 'r') as f:
        pid = int(f.read())
        if not load_shared_settings:
            os.kill(pid, signal.SIGUSR1)
        else:
            os.kill(pid, signal.SIGUSR2)
