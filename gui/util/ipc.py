# make sure the generated source files are imported instead of the template ones
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

import os, signal
from multiprocessing.managers import SyncManager
from util.security import AES_CTR
import settings

# create server to share data over sockets
def createSettingsManager(shared_settings, address=settings.DSIP_IPC_SOCK, authkey=None):
    if authkey is None:
        authkey = AES_CTR.decrypt(settings.DSIP_IPC_PASS)

    class SettingsManager(SyncManager):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)

    SettingsManager.register("getSettings", lambda: shared_settings,
                             exposed=['__contains__', '__delitem__', '__getitem__', '__len__', '__setitem__', 'clear', 'copy',
                                      'get', 'has_key', 'items', 'keys', 'pop', 'popitem', 'setdefault', 'update', 'values'])

    manager = SettingsManager(address=address, authkey=authkey)
    return manager

class DummySettingsManager():
    """
    Sole purpose is to allow the settings manager to be defined globally and lazy loaded on startup
    """

    @staticmethod
    def noop(*args, **kwargs):
        return None
    def getSettings(self, *args, **kwargs):
        DummySettingsManager.noop(*args, **kwargs)
    def start(self, *args, **kwargs):
        DummySettingsManager.noop(*args, **kwargs)
    def shutdown(self, *args, **kwargs):
        DummySettingsManager.noop(*args, **kwargs)

# TODO: add error handling / good return codes for the following funcs
def setSharedSettings(fields_dict={}, address=settings.DSIP_IPC_SOCK, authkey=None):
    if authkey is None:
        authkey = AES_CTR.decrypt(settings.DSIP_IPC_PASS)

    class SettingsManager(SyncManager):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)

    SettingsManager.register("getSettings")

    manager = SettingsManager(address=address, authkey=authkey)
    manager.connect()
    settings_proxy = manager.getSettings()
    settings_proxy.update(list(fields_dict.items()))

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
