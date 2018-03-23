'''
@Summary: Contains methods to be applied as python decorators
@Author: `devopsec <https://github.com/devopsec>`_
'''

from threading import Thread

def async(f):
    def wrapper(*args, **kwargs):
        thr = Thread(target=f, args=args, kwargs=kwargs)
        thr.start()
    return wrapper
