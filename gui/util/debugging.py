import sys, logging, traceback
from util.printing import printerror
from util.logging import logcrit, logdebug, logerror, loginfo, lognolvl, logwarn


def debug_exception(ex, log_ex=True, print_ex=False, showstack=True):
    """
    Debugging of an exception: print and/or log frame and/or stacktrace
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