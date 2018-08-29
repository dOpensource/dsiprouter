import requests
import settings

# TODO: automate route setup and ip auth config in flowroute

class Numbers():
    """
    Contains methods for accessing the flowroute Numbers api
    """

    def __init__(self):
        self.auth = (settings.FLOWROUTE_ACCESS_KEY, settings.FLOWROUTE_SECRET_KEY)
        self.api_url = settings.FLOWROUTE_API_ROOT_URL + "/numbers"

    def __del__(self):
        self.auth = None
        self.api_url = None

    def getNumbers(self, starts_with=None, contains=None, ends_with=None, limit=1000000, offset=None):
        """
        Get flowroute DID's associated with accnt

        .. seealso:: `flowroute list numbers <https://developer.flowroute.com/api/numbers/v2.0/list-account-phone-numbers/>`_
        :param starts_with: match numbers starting with..
        :param contains:    match numbers containing..
        :param ends_with:   match numbers ending with..
        :param limit:       limit of matched numbers
        :param offset:      offsets list of numbers returned
        :return:            list(*str)
        """
        payload = {
            'starts_with': starts_with,
            'contains': contains,
            'ends_with': ends_with,
            'limit': limit,
            'offset': offset
        }
        resp = requests.get(self.api_url, auth=self.auth, params=payload)
        resp.raise_for_status()
        return [num['attributes']['value'] for num in resp.json()['data']]
