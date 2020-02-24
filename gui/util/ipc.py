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
    with open(pid_file, 'r') as f:
        pid = f.read()

    if len(pid) > 0:
        pid = int(pid)
        try:
            if not load_shared_settings:
                os.kill(pid, signal.SIGUSR1)
            else:
                os.kill(pid, signal.SIGUSR2)
        except ProcessLookupError:
            pass
