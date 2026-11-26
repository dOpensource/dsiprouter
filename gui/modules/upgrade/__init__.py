import ast
import os

import settings
from modules.upgrade.releases import ReleasesError, getSupportedReleases
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
    :raises modules.upgrade.releases.ReleasesError: if the settings could not be read
    """

    settings_file = UPGRADE_SETTINGS_FILE if os.path.isfile(UPGRADE_SETTINGS_FILE) else UPGRADE_SETTINGS_TEMPLATE
    upgrade_settings = {}

    try:
        with open(settings_file, 'r') as fp:
            nodes = ast.parse(fp.read()).body
    except (OSError, SyntaxError, ValueError) as ex:
        raise ReleasesError('could not read the upgrade settings: {}'.format(settings_file)) from ex

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
    # seconds a lookup is given as a whole, the upgrade page stops waiting for it after that
    # the lookup lists the tags of the repo, asks the releases API and fetches the settings of up to 50 releases
    LOOKUP_DEADLINE = 300

    # the GUI handles one request at a time, the lookup over the network is not run while a request is handled
    supported_releases = BackgroundResult(getSupportedReleases, ttl=300, error_ttl=30, timeout=LOOKUP_DEADLINE)

    @classmethod
    def get_supported_releases(cls):
        """
        Get the releases the installed version can be upgraded to, oldest first\n
        The releases are tracked from the repo in the upgrade settings, each release lists the versions it can be upgraded from\n
        The last result of the lookup is returned, the lookup is run again in the background when that result is too old

        :return:    supported releases (None if no lookup succeeded), why the last lookup failed (None if it did not)
        :rtype:     tuple[list[modules.upgrade.releases.Release]|None, ReleaseLookupError|None]
        :raises ReleaseLookupPending:   if the first lookup with the current upgrade settings has not finished
        """

        try:
            upgrade_settings = loadUpgradeSettings()
        except ReleasesError as ex:
            return None, ReleaseLookupError(str(ex))
        repo_url = upgrade_settings.get('GIT_REPO_URL', '')
        track_beta = upgrade_settings.get('GIT_TRACK_BETA_RELEASES', False) is True
        release_api_url = upgrade_settings.get('GIT_RELEASE_URL', '') or None

        releases, error, _ = cls.supported_releases.get(repo_url, str(settings.VERSION), track_beta, release_api_url)
        if error is not None:
            # the releases found by an earlier lookup are returned with the error
            reason = str(error) if isinstance(error, ReleasesError) else '{}: {}'.format(type(error).__name__, error)
            return (list(releases) if releases is not None else None), ReleaseLookupError(reason)
        if releases is None:
            raise ReleaseLookupPending()
        return list(releases), None
