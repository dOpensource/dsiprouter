import subprocess
import time
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


class BackgroundResult():
    """
    Keeps the last result of a function that takes too long to run while a request is handled\n
    The function runs in a thread, the last result is returned right away\n
    A result the function returned is kept when a later run raises an exception or does not finish in time
    """

    # runs that did not finish in time and have not ended, no other run is started when there are this many
    MAX_ABANDONED = 3

    def __init__(self, func, ttl, error_ttl, timeout):
        """
        :param func:        function to run
        :type func:         callable
        :param ttl:         seconds a result is used before the function is run again
        :type ttl:          int|float
        :param error_ttl:   seconds before the function is run again after it raised an exception or did not finish in time
        :type error_ttl:    int|float
        :param timeout:     seconds the function is given to finish before the run is given up on
        :type timeout:      int|float
        """

        self.func = func
        self.name = getattr(func, '__name__', 'function')
        self.ttl = ttl
        self.error_ttl = error_ttl
        self.timeout = timeout
        self.lock = Lock()
        # identifies the run that is waited for, None if there is none
        self.token = None
        self.started = 0.0
        self.run_args = None
        self.abandoned = 0
        self.args = None
        self.time = 0.0
        self.value = None
        self.error = None
        # start of the run that returned the newest result
        self.value_started = 0.0

    def store(self, args, value, error, started):
        # called with the lock held
        if error is not None and self.args == args:
            # a result the function returned for these arguments before is kept
            self.error = error
        else:
            self.args, self.value, self.error = args, value, error
        if error is None:
            self.value_started = started
        self.time = time.monotonic()

    def run(self, token, started, *args):
        # the result when the function is ended by something that is not an Exception
        value, error = None, RuntimeError('{} did not finish'.format(self.name))
        try:
            value, error = self.func(*args), None
        except Exception as ex:
            error = ex
        finally:
            with self.lock:
                if self.token is token:
                    self.token = None
                    self.store(args, value, error, started)
                else:
                    # the run was given up on, a result it still returned is used unless a later run returned one
                    self.abandoned -= 1
                    if error is None and started > self.value_started:
                        self.store(args, value, None, started)

    def get(self, *args):
        """
        Get the last result of the function for the arguments\n
        The function is started when there is no result for the arguments or the result is too old\n
        A thread can not be stopped: a run that does not finish in time is given up on and reported as failed,
        the function is run again after the error interval while only a few of such runs have not ended

        :param args:    arguments of the function
        :return:        last result the function returned (None if there is none), exception if the last run failed (None otherwise), whether a run is waited for
        :rtype:         tuple
        """

        with self.lock:
            now = time.monotonic()
            if self.token is not None and now - self.started >= self.timeout:
                self.store(self.run_args, None, TimeoutError('{} did not finish within {} seconds'.format(self.name, self.timeout)), self.started)
                self.token = None
                self.abandoned += 1

            value, error = None, None
            expired = True
            if self.args == args:
                value, error = self.value, self.error
                expired = now - self.time >= (self.error_ttl if error is not None else self.ttl)

            if expired and self.token is None:
                if self.abandoned < self.MAX_ABANDONED:
                    # the thread can not store its result before the lock is released
                    self.token = object()
                    self.started = now
                    self.run_args = args
                    Thread(target=self.run, args=(self.token, now) + args, daemon=True).start()
                elif error is None:
                    # without an error the caller would wait for a run that is not started
                    error = RuntimeError('{} runs of {} have not ended, it is not run again before one of them ends'.format(self.abandoned, self.name))
            return value, error, self.token is not None


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
    :param workers:     number of worker processes to use (or rounds to execute when args not provided)
    :param callback:    callable function to execute after each completion
    :return:            list of results returned by executing tasks
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

    return [task.result() for task in tasks]


def mtexec(func, args=None, kwargs=None, workers=None, callback=None):
    """
    Execute task within pool of threads

    :param func:        callable function to execute
    :param args:        list of arg lists for each function execution
    :param kwargs:      list of kwarg dicts for each function execution
    :param workers:     number of worker processes to use (or rounds to execute when args not provided)
    :param callback:    callable function to execute after each completion
    :return:            list of results returned by executing tasks
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

    return [task.result() for task in tasks]
