import re, requests

import settings


class UpdateUtils():
    @staticmethod
    def get_repo_version_list():
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }

        r = requests.get(settings.GIT_RELEASE_URL, params=params, headers=headers, data=payload)
        return r.json()

    @staticmethod
    def get_latest_version():
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }

        r = requests.get(settings.GIT_RELEASE_URL, params=params, headers=headers, data=payload)
        latest = {
            'tag_name': '',
            'ver_num': 0
        }
        for rel in r.json():
            tag_name = rel['tag_name']
            ver_num = float(re.sub(r'^v([0-9]+\.[0-9]+).*?$', r'\1', tag_name, flags=re.MULTILINE))
            if ver_num > latest['ver_num']:
                latest = {
                    'tag_name': tag_name,
                    'ver_num': ver_num
                }
        return latest
