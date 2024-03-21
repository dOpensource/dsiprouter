class KamailioError(Exception):
    """
    There was an error communicating with Kamailio
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)


class NoDispatcherSets(KamailioError):
    """
    No dispatcher sets exist but the module is loaded
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)