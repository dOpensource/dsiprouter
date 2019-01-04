import settings, sys, os, re, socket, requests, logging, traceback, inspect, string, random
from flask import request, render_template


# Used to grab network info dynamically at startup
# TODO: we need to dynamically set this info for kamailio.cfg file
def getInternalIP():
    """ Returns current ip of system """

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]


def getExternalIP():
    """ Returns external ip of system """
    ip = None
    externalip_services = ["http://ipv4.myexternalip.com/raw", "http://ipv4.icanhazip.com", "https://api.ipify.org"]

    for url in externalip_services:
        try:
            ip = requests.get(url).text.strip()
        except:
            pass
        if ip != None and ip != "":
            break
    return ip


def getDNSNames():
    """ Returns ( hostname, domain ) of system """

    host, domain = None, None

    try:
        host, domain = socket.getfqdn().split('.', 1)
    except:
        pass
    if host == None or host == "":
        try:
            host, domain = socket.gethostbyaddr(socket.gethostname())[0].split('.', 1)
        except:
            pass
    if host == None or host == "":
        try:
            host, domain = socket.getaddrinfo(socket.gethostname(), 0, flags=socket.AI_CANONNAME)[0][3].split('.', 1)
        except:
            pass
    return host, domain

def hostToIP(host):
    """ Returns ip of host, or None on failure"""
    try:
         return socket.gethostbyname(host)
    except:
        return None


def ipToHost(ip):
    """ Returns hostname of ip, or None on failure"""
    try:
        return socket.gethostbyaddr(ip)[0]
    except:
        return None


def objToDict(obj):
    """
    converts an arbitrary object to dict
    """
    return dict((attr, getattr(obj, attr)) for attr in dir(obj) if
                not attr.startswith('__') and not inspect.ismethod(getattr(obj, attr)))


def rowToDict(row):
    """
    convertings sqlalchemy row object to python dict
    does not recurse through relationships
    tries table data, then _asdict() method, then objToDict()
    """
    d = {}

    if hasattr(row, '__table__'):
        for column in row.__table__.columns:
            d[column.name] = str(getattr(row, column.name))
    elif hasattr(row, '_asdict'):
        d = row._asdict()
    else:
        d = objToDict(row)

    return d


def strFieldsToDict(fields_str):
    return dict(field.split(':') for field in fields_str.split(','))


def dictToStrFields(fields_dict):
    return ','.join("{}:{}".format(k, v) for k, v in fields_dict.items())


def updateConfig(config_obj, field_dict):
    config_file = "<no filepath available>"
    try:
        config_file = config_obj.__file__

        with open(config_file, 'r+') as config:
            config_str = config.read()
            for key, val in field_dict.items():
                regex = r"^(?!#)(?:" + re.escape(key) + \
                        r")[ \t]*=[ \t]*(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|\"\"\".*\"\"\"[ \t]*$|'''.*'''[ \v]*$|\".*\"[ \t]*$|'.*')"
                replace_str = "{} = {}".format(key, repr(val))
                config_str = re.sub(regex, replace_str, config_str, flags=re.MULTILINE)
            config.seek(0)
            config.write(config_str)
            config.truncate()
    except:
        print('Problem updating the {0} configuration file').format(config_file)


def stripDictVals(d):
    for key, val in d.items():
        if isinstance(val, str):
            d[key] = val.strip()
        elif isinstance(val, int):
            d[key] = int(str(val).strip())
    return d


def getCustomRoutes():
    """ Return custom kamailio routes from config file """
    custom_routes = []
    with open(settings.KAM_CFG_PATH, 'r') as kamcfg_file:
        kamcfg_str = kamcfg_file.read()

        regex = r"CUSTOM_ROUTING_START.*CUSTOM_ROUTING_END"
        custom_routes_str = re.search(regex, kamcfg_str, flags=re.MULTILINE | re.DOTALL).group(0)

        regex = r"route\[(\w+)\]"
        matches = re.finditer(regex, custom_routes_str, flags=re.MULTILINE | re.DOTALL)

        for matchnum, match in enumerate(matches):
            if len(match.groups()) > 0:
                custom_routes.append(match.group(1))

        for route in custom_routes:
            print(route)
    return custom_routes

def generateID(size=10, chars=string.ascii_lowercase + string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))


# modified method from Python cookbook, #475186
def supportsColor(stream):
    """ Return True if terminal supports ASCII color codes  """
    if not hasattr(stream, "isatty") or not stream.isatty():
        # auto color only on TTYs
        return False
    try:
        import curses
        curses.setupterm()
        return curses.tigetnum("colors") > 2
    except:
        # guess false in case of error
        return False


class IO():
    """ Contains static methods for handling i/o operations """

    if supportsColor(sys.stdout):
        @staticmethod
        def printerr(message):
            print('\x1b[1;31m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def printinfo(message):
            print('\x1b[1;32m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def printwarn(message):
            print('\x1b[1;33m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def printdbg(message):
            print('\x1b[1;34m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def printbold(message):
            print('\x1b[1;37m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def logcrit(message):
            logging.getLogger().log(logging.CRITICAL, '\x1b[1;31m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def logerr(message):
            logging.getLogger().log(logging.ERROR, '\x1b[1;31m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def loginfo(message):
            logging.getLogger().log(logging.INFO, '\x1b[1;32m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def logwarn(message):
            logging.getLogger().log(logging.WARNING, '\x1b[1;33m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def logdbg(message):
            logging.getLogger().log(logging.DEBUG, '\x1b[1;34m' + str(message).strip() + '\x1b[0m')

        @staticmethod
        def lognolvl(message):
            logging.getLogger().log(logging.NOTSET, '\x1b[1;37m' + str(message).strip() + '\x1b[0m')

    else:
        @staticmethod
        def printerr(message):
            print(str(message).strip())

        @staticmethod
        def printinfo(message):
            print(str(message).strip())

        @staticmethod
        def printwarn(message):
            print(str(message).strip())

        @staticmethod
        def printdbg(message):
            print(str(message).strip())

        @staticmethod
        def printbold(message):
            print(str(message).strip())

        @staticmethod
        def logcrit(message):
            logging.getLogger().log(logging.CRITICAL, str(message).strip())

        @staticmethod
        def logerr(message):
            logging.getLogger().log(logging.ERROR, str(message).strip())

        @staticmethod
        def loginfo(message):
            logging.getLogger().log(logging.INFO, str(message).strip())

        @staticmethod
        def logwarn(message):
            logging.getLogger().log(logging.WARNING, str(message).strip())

        @staticmethod
        def logdbg(message):
            logging.getLogger().log(logging.DEBUG, str(message).strip())

        @staticmethod
        def lognolvl(message):
            logging.getLogger().log(logging.NOTSET, str(message).strip())


def debugException(ex, log_ex=True, print_ex=False, showstack=True):
    """
    Debugging of an exception: print and/or log frame and/or stacktrace
    :param ex:          The exception object
    :param log_ex:      True | False
    :param print_ex:    True | False
    :param showstack:   True | False
    """

    # get basic info and the stack
    exc_type, exc_value, exc_tb = sys.exc_info()

    text = "((( EXCEPTION )))\n[CLASS]: {}\n[VALUE]: {}\n".format(exc_type, exc_value)
    # get detailed exception info
    if vars(ex):
        for k, v in vars(ex).items():
            text += "[{}]: {}\n".format(k.upper(), str(v))

    # determine how far we trace it back
    tb_list = None
    if showstack:
        tb_list = traceback.extract_tb(exc_tb)
    else:
        tb_list = traceback.extract_tb(exc_tb, limit=1)

    # ensure a backtrace exists first
    if tb_list is not None and len(tb_list) > 0:
        text += "((( BACKTRACE )))\n"

        for tb_info in tb_list:
            filename, linenum, funcname, source = tb_info

            if funcname != '<module>':
                funcname = funcname + '()'
            text += "[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}".format(filename, linenum, funcname,
                                                                                      source)
    if log_ex:
        IO.logerr(text)
    if print_ex:
        IO.printerr(text)


def debugEndpoint(log_out=False, print_out=True, **kwargs):
    """
    Debug an endpoint, must be run within request context
    :param log_out:       True | False
    :param print_out:     True | False
    :param kwargs:        Any args to print / log (<key=value> key word pairs)
    """

    calling_chain = []

    frame = sys._getframe().f_back if sys._getframe().f_back is not None else sys._getframe()
    # parent module
    if hasattr(frame.f_code, 'co_filename'):
        calling_chain.append(os.path.abspath(frame.f_code.co_filename))
    # parent class
    if 'self' in frame.f_locals:
        calling_chain.append(frame.f_locals["self"].__class__)
    else:
        for k,v in frame.f_globals.items():
            if not k.startswith('__') and frame.f_code.co_name in dir(v):
                calling_chain.append(k)
                break
    # parent func
    if frame.f_code.co_name != '<module>':
        calling_chain.append(frame.f_code.co_name)

    text = "((( [DEBUG ENDPOINT]: {} )))\n".format(' -> '.join(calling_chain))
    items_dict = objToDict(request)
    for k, v in sorted(items_dict.items()):
        text += '{}: {}\n'.format(k, str(v).strip())
    if len(kwargs) > 0:
        for k, v in sorted(kwargs):
            text += "{}: {}\n".format(k, v)

    if log_out:
        IO.logdbg(text)

    if print_out:
        IO.printdbg(text)

def allowed_file(filename,ALLOWED_EXTENSIONS=set(['csv','txt','pdf','png','jpg','jpeg','gif'])):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def showError(type="", code=500, msg=None):
    return render_template('error.html', type=type), code

