'''
@Summary: Contains methods to be applied as python decorators
@Author: devopsec
'''

from threading import Thread

def pyasync(f):
    def wrapper(*args, **kwargs):
        thr = Thread(target=f, args=args, kwargs=kwargs)
        thr.start()
    return wrapper
