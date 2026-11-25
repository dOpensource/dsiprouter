import ast
import os
import re
import requests

import settings
from util.pyasync import BackgroundResult

# upgrades are run as root from these settings, the file can only be changed by root
UPGRADE_SETTINGS_FILE = '/etc/dsiprouter/upgrade_settings.py'
# the settings shipped with the project, used when dSIPRouter is not installed
UPGRADE_SETTINGS_TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'upgrade_settings.py')


def loadUpgradeSettings():
    """
    Load the upgrade settings\n
    The file is read as data, each setting is a line in the format NAME = value

    :return:    upgrade settings by name
    :rtype:     dict
    """

    settings_file = UPGRADE_SETTINGS_FILE if os.path.isfile(UPGRADE_SETTINGS_FILE) else UPGRADE_SETTINGS_TEMPLATE
    upgrade_settings = {}

    with open(settings_file, 'r') as fp:
        nodes = ast.parse(fp.read()).body
    for node in nodes:
        if not isinstance(node, ast.Assign) or len(node.targets) != 1 or not isinstance(node.targets[0], ast.Name):
            continue
        try:
            upgrade_settings[node.targets[0].id] = ast.literal_eval(node.value)
        except ValueError:
            continue
    return upgrade_settings


class ReleaseLookupPending(Exception):
    """
    The releases are being looked up, the result is not available yet
    """


class ReleaseLookupError(Exception):
    """
    The releases could not be looked up
    """


class UpdateUtils():
    # seconds the releases API is given to connect and to send the next part of its response
    LOOKUP_TIMEOUT = (5, 15)
    # seconds a lookup is given as a whole, the upgrade page stops waiting for it after that
    LOOKUP_DEADLINE = 60

    @staticmethod
    def get_repo_version_list(release_url):
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }
        r = requests.get(release_url, params=params, headers=headers, timeout=UpdateUtils.LOOKUP_TIMEOUT)
        r.raise_for_status()
        return r.json()

    @staticmethod
    def lookup_latest_version(release_url):
        latest = {
            'tag_name': '',
            'ver_num': 0
        }
        for rel in UpdateUtils.get_repo_version_list(release_url):
            tag_name = rel['tag_name']
            ver_num = float(re.sub(r'^v([0-9]+\.[0-9]+).*?$', r'\1', tag_name, flags=re.MULTILINE))
            if ver_num > latest['ver_num']:
                latest = {
                    'tag_name': tag_name,
                    'ver_num': ver_num
                }
        return latest

    # the GUI handles one request at a time, the lookup over the network is not run while a request is handled
    latest_version = BackgroundResult(lookup_latest_version.__func__, ttl=300, error_ttl=30, timeout=LOOKUP_DEADLINE)

    @staticmethod
    def get_latest_version():
        """
        Get the latest release of the repo in the upgrade settings\n
        The last result of the lookup is returned, the lookup is run again in the background when that result is too old

        :return:    tag and version number of the latest release (None if no lookup succeeded), why the last lookup failed (None if it did not)
        :rtype:     tuple[dict|None, ReleaseLookupError|None]
        :raises ReleaseLookupPending:   if the first lookup with the current upgrade settings has not finished
        """

        latest, error, _ = UpdateUtils.latest_version.get(loadUpgradeSettings()['GIT_RELEASE_URL'])
        if error is not None:
            # the release found by an earlier lookup is returned with the error
            return latest, ReleaseLookupError('{}: {}'.format(type(error).__name__, error))
        if latest is None:
            raise ReleaseLookupPending()
        return latest, None
