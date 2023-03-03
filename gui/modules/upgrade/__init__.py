import requests
import re
import subprocess
import sys
import logging

sys.path.append('../../')
from util.pyasync import proc


class UpdateUtils():

    @staticmethod
    def get_repo_version_list():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }

        response = requests.request("GET", url, headers=headers, data=payload)

        release_list = response.json()
        return release_list

    @staticmethod
    def get_latest_version():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }

        response = requests.request("GET", url, headers=headers, data=payload)

        release_list = response.json()

        # print(release_list[0])

        return  re.sub(r'[^0-9.]', '', release_list[0]['tag_name'])

    @proc
    @staticmethod
    def start_upgrade():
        logging.info("Starting upgrade process")
        process = subprocess.Popen(["/usr/local/bin/python3", "/opt/dsiprouter/resources/upgrade/0.71/upgrade.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, error = process.communicate()
