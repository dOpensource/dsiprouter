import ast
import os
import re
import requests

import settings

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


class UpdateUtils():
    @staticmethod
    def get_repo_version_list():
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }
        r = requests.get(loadUpgradeSettings()['GIT_RELEASE_URL'], params=params, headers=headers)
        return r.json()

    @staticmethod
    def get_latest_version():
        latest = {
            'tag_name': '',
            'ver_num': 0
        }
        for rel in UpdateUtils.get_repo_version_list():
            tag_name = rel['tag_name']
            ver_num = float(re.sub(r'^v([0-9]+\.[0-9]+).*?$', r'\1', tag_name, flags=re.MULTILINE))
            if ver_num > latest['ver_num']:
                latest = {
                    'tag_name': tag_name,
                    'ver_num': ver_num
                }
        return latest
