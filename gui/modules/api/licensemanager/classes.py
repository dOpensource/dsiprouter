import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import requests, secrets, datetime, functools
from util.security import Credentials, AES_CTR


def wcApiPropagateHttpError(method):
    @functools.wraps(method)
    def wrapper(self, *args, **kwargs):
        try:
            return method(self, *args, **kwargs)
        except requests.HTTPError as ex:
            ex.response._content = ex.response.content.replace(self._license_key.encode('utf-8'), b'<redacted>')
            raise WoocommerceError(response=ex.response)

    return wrapper

class WoocommerceError(requests.HTTPError):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    def __str__(self):
        r_json = self.response.json()
        return '\n'.join(' '.join(r_json['data']['errors'][k]) for k in r_json['data']['errors'])

class WoocommerceLicense(object):
    # this API key is locked down to only allow functionality below
    SERVER = {
        "baseurl": "https://dopensource.com/wp-json/lmfwc/v2/licenses/",
        "key": "ck_068f510a518ff5ecf1cbdcbc7db7f9bac2331613",
        "secret": "cs_5ae2f3decfa59f427a59b41f2e41459d18023dd7",
    }
    # constant salt used for equality checks
    # should not be used for generating a hash that is stored
    CMP_SALT = 'A' * Credentials.SALT_LEN
    # the woocommerce license length may change due to application specific requirements
    # therefore we parse it out based on the length of the machine id, which will not change
    MACHINE_ID_LEN = 32

    def __init__(self, license_key=None, key_combo=None, decrypt=False):
        # set attributes based on clientside data
        if license_key is not None:
            if key_combo is not None:
                raise ValueError('license_key and key_combo are mutually exclusive')

            if isinstance(license_key, str):
                if len(license_key) == 0:
                    raise ValueError('license_key must not be empty')
                if decrypt:
                    license_key = AES_CTR.decrypt(license_key)
            elif isinstance(license_key, bytes):
                if len(license_key) == 0:
                    raise ValueError('license_key must not be empty')
                if decrypt:
                    license_key = AES_CTR.decrypt(license_key)
                else:
                    license_key = license_key.decode('utf-8')
            else:
                raise ValueError('license_key must be a string or byte string')
            self._license_key = license_key

            with open('/etc/machine-id', 'r') as f:
                server_machine_id = f.read(WoocommerceLicense.MACHINE_ID_LEN)
                if len(server_machine_id) != WoocommerceLicense.MACHINE_ID_LEN:
                    raise Exception("the server machine-id is invalid")
                self.__machine_id = server_machine_id
                self.__machine_match = True
        elif key_combo is not None:
            if isinstance(key_combo, str):
                if len(key_combo) == 0:
                    raise ValueError('key_combo must not be empty')
                if decrypt:
                    key_combo = AES_CTR.decrypt(key_combo.encode('utf-8'))
            elif isinstance(key_combo, bytes):
                if len(key_combo) == 0:
                    raise ValueError('key_combo must not be empty')
                if decrypt:
                    key_combo = AES_CTR.decrypt(key_combo)
                else:
                    key_combo = key_combo.decode('utf-8')
            else:
                raise ValueError('key_combo must be a string or byte string')

            try:
                self._license_key = key_combo[:-WoocommerceLicense.MACHINE_ID_LEN]
                self.__machine_id = key_combo[-WoocommerceLicense.MACHINE_ID_LEN:]
            except IndexError:
                raise ValueError('key_combo is invalid')

            with open('/etc/machine-id', 'r') as f:
                server_machine_id = f.read(WoocommerceLicense.MACHINE_ID_LEN)
                if len(server_machine_id) != WoocommerceLicense.MACHINE_ID_LEN:
                    raise Exception("the server machine-id is invalid")
                self.__machine_match = self.__machine_id == server_machine_id
        else:
            raise ValueError('one of license_key or key_combo is required')

        # set attributes based on serverside data
        # noinspection PyArgumentList
        self.sync()

    def __eq__(self, obj):
        return isinstance(obj, WoocommerceLicense) and \
               secrets.compare_digest(self.hash(WoocommerceLicense.CMP_SALT), obj.hash(WoocommerceLicense.CMP_SALT))

    def __ne__(self, obj):
        return not self.__eq__(obj)

    # allow passing to dict() and iterable()
    def __iter__(self):
        for k, v in self.asDict().items():
            yield k, v

    # only return select attributes in the iterable/dict representation
    def asDict(self):
        return {
            'id': self.id,
            'tags': self.tags,
            'expires': self.expires,
            'active': self.active,
            'valid': self.valid,
            'license_key': self.license_key,
        }

    @property
    def machine_match(self):
        return self.__machine_match

    @property
    def tags(self):
        return self._tags

    @property
    def expires(self):
        if self._expires_at is not None:
            return datetime.datetime.strptime(self._expires_at, '%Y-%m-%d %H:%M:%S')
        if self._valid_for is not None:
            return datetime.datetime.strptime(self._created_at, '%Y-%m-%d %H:%M:%S') + datetime.timedelta(days=self._valid_for)
        # no expires set, it is valid forever
        return datetime.datetime.max

    @property
    def active(self):
        return (self._status == 3 or self._status == 2) and self._times_activated > 0 and self.expires > datetime.datetime.now()

    @property
    def license_key(self):
        return self._license_key

    @property
    def valid(self):
        return self.active and self.machine_match

    @property
    def id(self):
        return self._id

    @wcApiPropagateHttpError
    def sync(self):
        res = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        res.raise_for_status()
        r_json = res.json()

        if 'errors' in r_json['data']:
            raise requests.HTTPError(response=res)

        self._id = r_json['data']["id"]
        # self._order_id = r_json['data']["orderId"]
        # self._user_id = r_json['data']["userId"]
        self._expires_at = r_json['data']["expiresAt"]
        self._valid_for = r_json['data']["validFor"] if r_json['data']["validFor"] != 0 else None
        # self._source = r_json['data']["source"]
        self._status = r_json['data']["status"]
        self._times_activated = r_json['data']["timesActivated"]
        self._times_activated_max = r_json['data']["timesActivatedMax"]
        self._created_at = r_json['data']["createdAt"]
        # self._created_by = r_json['data']["createdBy"]
        self._updated_at = r_json['data']["updatedAt"]
        # self._updated_by = r_json['data']["updatedBy"]
        self._tags = r_json['data']['tags']

    @wcApiPropagateHttpError
    def activate(self):
        res = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + 'activate/' + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        res.raise_for_status()
        r_json = res.json()

        if 'errors' in r_json['data']:
            raise requests.HTTPError(response=res)

        self._times_activated = r_json['data']['timesActivated']
        self._times_activated_max = r_json['data']['timesActivatedMax']
        self._updated_at = r_json['data']['updatedAt']

        return r_json.get('success', False)

    @wcApiPropagateHttpError
    def deactivate(self):
        res = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + 'deactivate/' + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        res.raise_for_status()
        r_json = res.json()

        if 'errors' in r_json['data']:
            raise requests.HTTPError(response=res)

        self._times_activated = r_json['data']['timesActivated']
        self._times_activated_max = r_json['data']['timesActivatedMax']
        self._updated_at = r_json['data']['updatedAt']

        return r_json.get('success', False)

    def hash(self, salt=None):
        return Credentials.hashCreds('{}{}'.format(self._license_key, self.__machine_id), salt)

    # need original key for queries to woocommerce
    # format: <license_key><machine_id>
    def encrypt(self):
        return AES_CTR.encrypt('{}{}'.format(self._license_key, self.__machine_id))