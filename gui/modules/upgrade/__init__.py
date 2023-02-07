import requests
import re

class UpdateUtils():

    @staticmethod
    def get_repo_version_list():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer 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',
            'X-GitHub-Api-Version': '2022-11-28',
        }

        response = requests.request("GET", url, headers=headers, data=payload)

        release_list = response.json()
        return release_list

    @staticmethod
    def get_latest_version():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer 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',
            'X-GitHub-Api-Version': '2022-11-28',
        }

        response = requests.request("GET", url, headers=headers, data=payload)

        release_list = response.json()

        # print(release_list[0])

        return  re.sub(r'[^0-9.]', '', release_list[0]['tag_name'])
