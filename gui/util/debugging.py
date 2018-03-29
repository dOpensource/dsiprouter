import sys, logging, traceback
from util.printing import printerror
from util.logging import logcrit, logdebug, logerror, loginfo, lognolvl, logwarn


def debug_exception(ex, log_ex=True, print_ex=False, showstack=True):
    """
    Debugging of an exception: print and/or log frame and/or stacktrace\n
    :param ex:          The exception object
    :param log_ex:      True | False
    :param print_ex:    True | False
    :param showstack:   True | False
    """

    # get basic info and the stack
    exc_type, exc_value, exc_tb = sys.exc_info()
    # get root logger
    logger = logging.getLogger()

    if log_ex:
        logcrit('((( EXCEPTION )))\n[CLASS]: {}\n[VALUE]: {}'.format(exc_type, exc_value))
        # get detailed exception info
        if vars(ex):
            ex_info = []
            for k, v in vars(ex).items():
                ex_info.append('[{}]: {}'.format(k.upper(), v))
            logcrit('\n'.join(ex_info))
        logerror('((( BACKTRACE )))'.format(exc_type, exc_value))

    if print_ex:
        printerror('((( EXCEPTION )))\n[CLASS]: {}\n[VALUE]: {}'.format(exc_type, exc_value))
        # get detailed exception info
        if vars(ex):
            ex_info = []
            for k, v in vars(ex).items():
                ex_info.append('[{}]: {}'.format(k.upper(), v))
            printerror('\n'.join(ex_info))
        printerror('((( BACKTRACE ))))')

    if showstack:
        for tb_info in traceback.extract_tb(exc_tb):
            filename, linenum, funcname, source = tb_info
            if funcname != '<module>':
                funcname = funcname + '()'
            if log_ex:
                logerror(
                    '[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}'.format(
                        filename, linenum, funcname, source))
            if print_ex:
                printerror(
                    '[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}'.format(
                        filename, linenum, funcname, source))
    else:
        filename, linenum, funcname, source = traceback.extract_tb(exc_tb)[0]
        if funcname != '<module>':
            funcname = funcname + '()'

        if log_ex:
            logerror(
                '[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}'.format(
                    filename, linenum, funcname, source))
        if print_ex:
            printerror(
                '[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}'.format(
                    filename, linenum, funcname, source))

def debug_endpoint(log_dbg=False, print_dbg=True, args=None):
    """
    Debugging of an endpoint: print and/or log endpoint request and debug info\n
    Must be run within an executing endpoint, where a valid request context exists\n
    :param log_dbg:     True | False
    :param print_dbg:   True | False
    :param args:        A list of args
    """

    log_lvl = logging.DEBUG

    endpoint = ""
    if request.endpoint:
        endpoint = request.endpoint

    if log_dbg:
        logc('[Debugging Endpoint {}]'.format(endpoint), MAGENTA, level=log_lvl)

        if args:
            logc('test args provided:', BLUE, level=log_lvl)
            for arg in args:
                logc('arg: {}'.format(arg), CYAN, level=log_lvl)
        if request.url:
            logc('request url:', BLUE, level=log_lvl)
            logc(request.url, GREEN, level=log_lvl)
        if request.method:
            logc('request method:', BLUE, level=log_lvl)
            logc(request.method, GREEN, level=log_lvl)
        if request.headers:
            logc('request headers:', BLUE, level=log_lvl)
            for header in request.headers:
                logc(header, GREEN, level=log_lvl)
        if request.args:
            logc('request args:', BLUE, level=log_lvl)
            for arg in request.args:
                logc(arg, GREEN, level=log_lvl)
        if request.form:
            logc('request form data:', BLUE, level=log_lvl)
            for data in request.form:
                logc(data, GREEN, level=log_lvl)
        if request.json:
            logc('request json data:', BLUE, level=log_lvl)
            for data in request.json:
                logc(data, GREEN, level=log_lvl)
        if request.files:
            logc('request files:', BLUE, level=log_lvl)
            for file in request.files:
                logc(file.filename, GREEN, level=log_lvl)
        if request.cookies:
            logc('request cookies:', BLUE, level=log_lvl)
            for cookie in request.cookies:
                logc(cookie, GREEN, level=log_lvl)
        if request.data:
            logc('request raw data:', BLUE, level=log_lvl)
            logc(request.data, GREEN, level=log_lvl)

    if print_dbg:
        print("\n", flush=True)
        printc('[Debugging Endpoint {}]'.format(endpoint), MAGENTA)
        
        if args:
            printc('test args provided:', BLUE)
            for arg in args:
                printc('arg: {}'.format(arg), CYAN)
        if request.url:
            printc('request url:', BLUE)
            printc(request.url, GREEN)
        if request.method:
            printc('request method:', BLUE)
            printc(request.method, GREEN)
        if request.headers:
            printc('request headers:', BLUE)
            for header in request.headers:
                printc(header, GREEN)
        if request.args:
            printc('request args:', BLUE)
            for arg in request.args:
                printc(arg, GREEN)
        if request.form:
            printc('request form data:', BLUE)
            for data in request.form:
                printc(data, GREEN)
        if request.json:
            printc('request json data:', BLUE)
            for data in request.json:
                printc(data, GREEN)
        if request.files:
            printc('request files:', BLUE)
            for file in request.files:
                printc(file.filename, GREEN)
        if request.cookies:
            printc('request cookies:', BLUE)
            for cookie in request.cookies:
                printc(cookie, GREEN)
        if request.data:
            printc('request raw data:', BLUE)
            printc(request.data, GREEN)
            
        print("\n", flush=True)

