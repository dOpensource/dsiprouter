import re, requests


class UpdateUtils():
    @staticmethod
    def get_repo_version_list():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }

        r = requests.get(url, params=params, headers=headers, data=payload)
        return r.json()

    @staticmethod
    def get_latest_version():
        url = "https://api.github.com/repos/dOpensource/dsiprouter/releases"
        payload = {}
        headers = {
            'Accept': 'application/vnd.github+json'
        }
        params = {
            "per_page": 100
        }

        r = requests.get(url, params=params, headers=headers, data=payload)
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
