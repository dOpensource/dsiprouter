import os, subprocess
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


def process(func):
    """
    Wrap function to execute within a single process
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        proc = Process(target=func, args=args, kwargs=kwargs, daemon=True)
        proc.start()

    return wrapper


@process
def daemonize(cmd, timeout=300):
    """
    Run command in detached daemon process

    :param cmd:     commands to run
    :type cmd:      list
    :param timeout: timeout before daemonized process quits
    :type timeout:  int
    :return:        no return value
    :rtype:         None
    """

    # decouple from parent environment
    #os.chdir('/')
    #os.setsid()
    #os.umask(0)

    # run command with new sid
    # TODO: systemd tracks processes by cgroup and will kill these daemons when parent dies
    #       os.unshare should accomplish this but is too new and only supported in python 3.12
    #       back-porting would require compiling CPython modules or supporting multiple python versions?
    #       alternatively we could ship a small ansi-C program that handles this
    #       for now we workaround this in dsiprouter.sh but we should be more platform independent
    subprocess.run(
        cmd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=timeout,
        #start_new_session=True,
        restore_signals=False,
        #preexec_fn=lambda: os.unshare(os.CLONE_NEWCGROUP)
    )


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
