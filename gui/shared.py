import settings, sys, os, re, socket, requests, logging, traceback, inspect, string, random
from flask import request, render_template, make_response
from werkzeug.utils import escape
from werkzeug.urls import iri_to_uri


def ipv4Test(address):
    try:
        socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            socket.inet_aton(address)
        except socket.error:
            return False
        return address.count('.') == 3
    except socket.error:  # not a valid address
        return False
    return True


def ipv6Test(address):
    try:
        socket.inet_pton(socket.AF_INET6, address)
    except socket.error:  # not a valid address
        return False
    return True

def isValidIP(address, tcp_proto=''):
    """
    Determine if ip address is valid
    :address:       str
    :tcp_proto:     str
    :ref:           <https://stackoverflow.com/questions/319279/how-to-validate-ip-address-in-python>
    """
    if tcp_proto == '4':
        return ipv4Test(address)
    elif tcp_proto == '6':
        return ipv6Test(address)
    else:
        if not ipv4Test(address) and not ipv6Test(address):
            return False
        return True

def getInternalIP():
    """ Returns current ip of system """
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]


def getExternalIP():
    """ Returns external ip of system """
    ip = None
    # redundancy in case a service provider goes down
    externalip_services = [
        "https://ipv4.icanhazip.com",
        "https://api.ipify.org",
        "https://myexternalip.com/raw",
        "https://ipecho.net/plain",
        "https://bot.whatismyipaddress.com"
    ]
    for url in externalip_services:
        try:
            ip = requests.get(url).text.strip()
        except:
            pass
        if ip is not None and isValidIP(ip) == True:
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
    converts sqlalchemy row object to python dict
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

        regex = r"^route\[(\w+)\]"
        matches = re.finditer(regex, custom_routes_str, flags=re.MULTILINE)

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


def debugException(ex=None, log_ex=True, print_ex=False, showstack=True):
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
    if ex is None:
        ex = exc_value
    for k,v in vars(ex).items():
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

def redirectCustom(location, *render_args, code=302, response_cb=None, force_redirect=False):
    """
    =======
    Summary
    =======

    Combines functionality of :func:`werkzeug.utils.redirect` with :func:`flask.templating.render_template`
    to allow for virtual redirection to an endpoint with any HTTP status code.\n

    =========
    Use Cases
    =========

    1. render template at a custom url (doesn't have to be an endpoint)

        def index():
            return redirectCustom('http://localhost:5000/notfound', render_template('not_found.html'), code=404)

        def index():
            html = '<h1>Are you lost {{ username }}?</h1>'
            return redirectCustom(url_for('notfound'), render_template_string(html), username='john', code=404)

    2. customizing the response before sending to the client

        def index():
            def addAuthHeaders(response):
                response.headers['Access-Control-Allow-Origin' = '*'
                response.headers['Access-Control-Allow-Headers'] = 'origin, x-requested-with, content-type'
                response.headers['Access-Control-Allow-Methods'] = 'PUT, GET, POST, DELETE, OPTIONS'
            return redirectCustom(url_for('login'), render_template('login_custom.html'), code=403, response_cb=addAuthHeaders)

    3. redirecting with a custom HTTP status code (normally restricted to 300's)

        def index():
            return redirectCustom(url_for('http://localhost:5000/error'), showError())

    4. forcing redirection when client normally would ignore location header

        def index():
            return redirectCustom(url_for(showError), showError(), code=500, force_redirect=True)


    :note: the endpoint logic is only executed when a the view function is passed in render_args
    :param location: the location the response should virtually redirect to
    :param render_args: the return value from a view / template rendering function
    :param code: the return HTTP status code, defaults to 302 like a normal redirect
    :param response_cb: callback function taking :class:`werkzeug.wrappers.Response` object as arg and returning edited response
    :param force_redirect: whether to force redirection on client, only needed when client ignores location header
    :return: client viewable :class:`werkzeug.wrappers.Response` object
    """

    display_location = escape(location)
    if isinstance(location, str):
        # Safe conversion as stated in :func:`werkzeug.utils.redirect`
        location = iri_to_uri(location, safe_conversion=True)

    # create a response object, from rendered data (accepts None)
    response = make_response(*render_args)

    # if no render_args given fill response with default redirect html
    if len(render_args) <= 0:
        response.response = '<!DOCTYPE HTML">\n' \
            '<html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; URL={location}">' \
            '<title>Redirecting</title></head>\n' \
            '<body><script type="text/javascript">window.location.href={location};</script></body></html>' if force_redirect else \
                '<body><h1>Redirecting...</h1>\n' \
                '<p>You should be redirected automatically to target URL: ' \
                '<a href="{location}">{display_location}</a>.  If not click the link.</p></body></html>' \
                    .format(location=escape(location), display_location=display_location)

        response.mimetype = 'text/html'

    # customize response if needed
    if response_cb is not None:
        response = response_cb(response)

    # override return code if set from render args
    if len(render_args) == 3:
        response.status = code

    # change response location
    response.headers['Location'] = location

    return response

class status():
    """
    Namespace for descriptive status codes, for code readability

    -- HTTP Status Codes --
    Original Idea From: `flask_api <https://www.flaskapi.org/>`_
    :ref RFC2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    :ref RFC6585: http://tools.ietf.org/html/rfc6585

    ... examples of possible future sections ...
    -- MYSQL Error Codes --
    -- SERVER Status Codes --
    -- KAMAILIO Error Codes --
    -- RTPENGINE Error Codes --
    """

    HTTP_CONTINUE = 100
    HTTP_SWITCHING_PROTOCOLS = 101
    HTTP_OK = 200
    HTTP_CREATED = 201
    HTTP_ACCEPTED = 202
    HTTP_NON_AUTHORITATIVE_INFORMATION = 203
    HTTP_NO_CONTENT = 204
    HTTP_RESET_CONTENT = 205
    HTTP_PARTIAL_CONTENT = 206
    HTTP_MULTI_STATUS = 207
    HTTP_MULTIPLE_CHOICES = 300
    HTTP_MOVED_PERMANENTLY = 301
    HTTP_FOUND = 302
    HTTP_SEE_OTHER = 303
    HTTP_NOT_MODIFIED = 304
    HTTP_USE_PROXY = 305
    HTTP_RESERVED = 306
    HTTP_TEMPORARY_REDIRECT = 307
    HTTP_PERMANENT_REDIRECT = 308
    HTTP_BAD_REQUEST = 400
    HTTP_UNAUTHORIZED = 401
    HTTP_PAYMENT_REQUIRED = 402
    HTTP_FORBIDDEN = 403
    HTTP_NOT_FOUND = 404
    HTTP_METHOD_NOT_ALLOWED = 405
    HTTP_NOT_ACCEPTABLE = 406
    HTTP_PROXY_AUTHENTICATION_REQUIRED = 407
    HTTP_REQUEST_TIMEOUT = 408
    HTTP_CONFLICT = 409
    HTTP_GONE = 410
    HTTP_LENGTH_REQUIRED = 411
    HTTP_PRECONDITION_FAILED = 412
    HTTP_REQUEST_ENTITY_TOO_LARGE = 413
    HTTP_REQUEST_URI_TOO_LONG = 414
    HTTP_UNSUPPORTED_MEDIA_TYPE = 415
    HTTP_REQUESTED_RANGE_NOT_SATISFIABLE = 416
    HTTP_EXPECTATION_FAILED = 417
    HTTP_PRECONDITION_REQUIRED = 428
    HTTP_TOO_MANY_REQUESTS = 429
    HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE = 431
    HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE = 444
    HTTP_INTERNAL_SERVER_ERROR = 500
    HTTP_NOT_IMPLEMENTED = 501
    HTTP_BAD_GATEWAY = 502
    HTTP_SERVICE_UNAVAILABLE = 503
    HTTP_GATEWAY_TIMEOUT = 504
    HTTP_HTTP_VERSION_NOT_SUPPORTED = 505
    HTTP_LOOP_DETECTED = 508
    HTTP_NOT_EXTENDED = 510
    HTTP_NETWORK_AUTHENTICATION_REQUIRED = 511
