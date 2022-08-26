from functools import wraps
from threading import Thread, Lock
from multiprocessing import Process
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor


class ThreadingIter():
    """
    Takes an iterator/generator and makes it thread-safe\n
    Implements locking for given iterator / generator
    """

    def __init__(self, iter):
        self.iter = iter
        self.lock = Lock()

    def __iter__(self):
        return self

    def next(self):
        with self.lock:
            return self.iter.next()

def thread(func):
    """
    Wrap function to execute within a single thread
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        thr = Thread(target=func, args=args, kwargs=kwargs, daemon=True)
        thr.start()

    return wrapper

def proc(func):
    """
    Wrap function to execute within a single thread
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        proc = Process(target=func, args=args, kwargs=kwargs, daemon=True)
        proc.start()

    return wrapper

def mpexec(func, args=None, kwargs=None, workers=None, callback=None):
    """
    Execute task within pool of processes

    :param func:        callable function to execute
    :param args:        list of arg lists for each function execution
    :param kwargs:      list of kwarg dicts for each function execution
    :param workers:     number of workers processes to use
    :param callback:    callable function to execute after each completion
    :return:            list of running tasks
    """

    with ProcessPoolExecutor(max_workers=workers) as executor:
        # no args or kwargs, number of tasks = num workers
        if args is None and kwargs is None:
            workers = workers if workers is not None else 1
            if callback:
                tasks = [executor.submit(func).add_done_callback(callback) for _ in range(workers)]
            else:
                tasks = [executor.submit(func) for _ in range(workers)]
        # args without kwargs
        elif kwargs is None:
            if callback:
                tasks = [executor.submit(func, *func_args).add_done_callback(callback) for func_args in args]
            else:
                tasks = [executor.submit(func, *func_args) for func_args in args]
        # args and kwargs
        else:
            if callback:
                tasks = [executor.submit(func, *func_args, **func_kwargs).add_done_callback(callback) for func_args, func_kwargs in zip(args, kwargs)]
            else:
                tasks = [executor.submit(func, *func_args, **func_kwargs) for func_args, func_kwargs in zip(args, kwargs)]

    return tasks

def mtexec(func, args=None, kwargs=None, workers=None, callback=None):
    """
    Execute task within pool of threads

    :param func:        callable function to execute
    :param args:        list of arg lists for each function execution
    :param kwargs:      list of kwarg dicts for each function execution
    :param workers:     number of workers threads to use
    :param callback:    callable function to execute after each completion
    :return:            list of running tasks
    """

    with ThreadPoolExecutor(max_workers=workers) as executor:
        # no args or kwargs, number of tasks = num workers
        if args is None and kwargs is None:
            workers = workers if workers is not None else 1
            if callback:
                tasks = [executor.submit(func).add_done_callback(callback) for _ in range(workers)]
            else:
                tasks = [executor.submit(func) for _ in range(workers)]
        # args without kwargs
        elif kwargs is None:
            if callback:
                tasks = [executor.submit(func, *func_args).add_done_callback(callback) for func_args in args]
            else:
                tasks = [executor.submit(func, *func_args) for func_args in args]
        # args and kwargs
        else:
            if callback:
                tasks = [executor.submit(func, *func_args, **func_kwargs).add_done_callback(callback) for func_args, func_kwargs in zip(args, kwargs)]
            else:
                tasks = [executor.submit(func, *func_args, **func_kwargs) for func_args, func_kwargs in zip(args, kwargs)]

    return tasks

