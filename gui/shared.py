# make sure the generated source files are imported instead of the template ones
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

import sys, os, re, json, socket, requests, logging, traceback, inspect, string, random, ssl
from calendar import monthrange
from importlib import reload
from flask import request, render_template, make_response, jsonify
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import escape
from werkzeug.urls import iri_to_uri
import settings


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

def isValidIP(address, ip_proto=''):
    """
    Determine if ip address is valid
    :address:       str
    :tcp_proto:     str
    :ref:           <https://stackoverflow.com/questions/319279/how-to-validate-ip-address-in-python>
    """
    if ip_proto == '4':
        return ipv4Test(address)
    elif ip_proto == '6':
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

# TODO: this will return whatever is set on the system (i.e. internal FQDN)
#       we should allow specifying the ip so external FQDN on natted systems can be resolved
def getDNSNames():
    """ Returns ( hostname, domain, fqdn ) of system """

    host, domain, fqdn = '', '', ''

    try:
        fqdn = socket.getfqdn()
        host = fqdn.split('.', 1)[0]
        domain = fqdn.split('.', 1)[1]
    except:
        pass
    if host == '':
        try:
            fqdn = socket.gethostbyaddr(socket.gethostname())[0]
            host = fqdn.split('.', 1)[0]
            domain = fqdn.split('.', 1)[1]
        except:
            pass
    if host == '':
        try:
            fqdn = socket.getaddrinfo(socket.gethostname(), 0, flags=socket.AI_CANONNAME)[0][3]
            host = fqdn.split('.', 1)[0]
            domain = fqdn.split('.', 1)[1]
        except:
            pass

    return host, domain, fqdn

# TODO: make sure we aren't resolving to DNSMasq internal domains
#       (local.cluster,localhost,etc..)
def hostToIP(host):
    """
    Convert host to IP Address\n
    Supports conversion to IPv4 and IPv6\n
    IPv4 takes priority and is tried first

    :param host:        hostname/fqdn to convert to IP
    :type host:         str
    :return:            IP address of host
    :rtype:             str|None
    """

    try:
        return socket.getaddrinfo(host, 0, socket.AF_INET)[0][4][0]
    except:
        pass
    try:
        return socket.getaddrinfo(host, 0, socket.AF_INET6)[0][4][0]
    except:
        pass
    return None

def ipToHost(ip):
    """
    Converts IP Address to hostname\n
    Supports conversion from IPv4 and IPv6

    :param ip:      IP address to convert
    :type ip:       str
    :return:        hostname for IP
    :rtype:         str|None
    """

    try:
        return socket.gethostbyaddr(ip)[0]
    except:
        return None

def parseSipUri(uri):
    """
    Parse SIP URI into its components

    components dict format:

    .. code-block:: python

        res = {
            'proto': <str|None>,
            'user': <str|None>,
            'ipv6': <str|None>,
            'ipv4': <str|None>,
            'host': <str|None>,
            'port': <int|None>,
            'params': <dict|None>
        }

    :param uri:     SIP URI to parse
    :type uri:      str
    :return:        components of SIP URI
    :rtype:         dict|None
    """

    match = re.search(
        (r'^'
         r'(?:(?P<proto>[a-zA-Z]+):)?'
         r'(?:(?P<user>[a-zA-Z0-9\-_.]+)@)?'
         r'(?:'
         r'(?:\[?(?P<ipv6>(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\]?)|'
         r'(?P<ipv4>(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))|'
         r'(?P<host>(?:(?:[a-zA-Z0-9]|[a-zA-Z0-9_][a-zA-Z0-9\-_]*[a-zA-Z0-9])\.)*(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]))'
         r')'
         r'(?::(?P<port>[1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5]))?'
         r'(?:;(?P<params>[^\s]*))?'
         r'$'),
        uri)
    if match:
        res = match.groupdict()
        if res['port'] is not None:
            res['port'] = int(res['port'])
        if res['params'] is not None:
            res['params'] = {x[0]: (x[1] if len(x) == 2 else True) for x in [y.split('=', 1) for y in res['params'].split(';')]}
        return res
    return None

def parseGenericUri(uri):
    """
    Parse Generic URI into its components (as generic as possible)\n
    Port is the only part type casted (parse delimited fields accordingly)

    components dict format:

    .. code-block:: python

        res = {
            'proto': <str|None>,
            'userpw': <str|None>,
            'ipv6': <str|None>,
            'ipv4': <str|None>,
            'host': <str|None>,
            'port': <int|None>,
            'path': <str|None>,
            'params': <str|None>
        }

    :param uri:     URI to parse
    :type uri:      str
    :return:        components of URI
    :rtype:         dict|None
    """

    match = re.search(
        (r'^'
         r'(?:(?P<proto>[a-zA-Z]+):/?/?)?'
         r'(?:(?P<userpw>[a-zA-Z0-9\-_.]+(?::.+)?)(?:@))?'
         r'(?:'
         r'(?:\[?(?P<ipv6>(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\]?)|'
         r'(?P<ipv4>(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))|'
         r'(?P<host>(?:(?:[a-zA-Z0-9]|[a-zA-Z0-9_][a-zA-Z0-9\-_]*[a-zA-Z0-9])\.)*(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]))'
         r')'
         r'(?::(?P<port>[1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5]))?'
         r'(?P<path>/[^\s?;]*)?'
         r'(?:(?:[?;])(?P<params>.*))?'
         r'$'),
        uri)
    if match:
        res = match.groupdict()
        if res['port'] is not None:
            res['port'] = int(res['port'])
        return res
    return None


def safeUriToHost(uri, default_port=None):
    """
    Strips non-host parts and converges on the host\n
    Supports IPv4, IPv6, and FQDN addresses as the host\n
    Optionally formats with port if default port is set

    :param uri:             uri to extract host from
    :type uri:              str
    :param default_port:    default port if not found
    :type default_port:     int
    :return:                host or host:port if port set
    :rtype:                 str|None
    """

    ipv6_port_format = False
    parts = parseGenericUri(uri)
    if parts is None:
        return None

    if parts['ipv4'] is not None:
        res = parts['ipv4']
    elif parts['ipv6'] is not None:
        res = parts['ipv6']
        ipv6_port_format = True
    elif parts['host'] is not None:
        res = parts['host']
    else:
        res = None

    if res is not None and default_port is not None:
        if parts['port'] is not None:
            port = str(parts['port'])
        else:
            port = str(default_port)

        if parts['params'] is not None:
            params = str(parts['params'])
        else:
            params = None

        if ipv6_port_format:
            res = '[{}]'.format(res)
            return res

        if params is not None:
            res = '{}:{};{}'.format(res,port,params)
        else:
            res = '{}:{}'.format(res, port)

    return res

def safeStripPort(address):
    """
    Strip port from address\n
    Properly strips on IPv6, IPv4, and FQDN addresses

    :param address:     address to strip port from
    :type address:      str
    :return:            address with port stripped
    :rtype:             str
    """

    match = re.search(
        (r'^'
         r'(?P<host>.*?)'
         r'(?::(?P<port>[1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5]))?'
         r'$'),
        address)
    if match:
        res = match.groupdict()['host']
        if res[0] == '[' and res[-1] == ']':
            res = res[1:-1]
    else:
        res = address
    return res

def safeFormatSipUri(uri, default_proto='sip', default_user='', default_port=5060, default_params={}):
    """
    Given a SIP URI of questionable validity, parse out the good stuff, and fill in the rest

    :param uri:             URI to format / validate
    :type uri:              str
    :param default_proto:   default protocol if missing
    :type default_proto:    str
    :param default_user:    default user if missing
    :type default_user:     str
    :param default_port:    default port if missing
    :type default_port:     int
    :param default_params:  default SIP parameters
    :type default_params:   dict
    :return:                SIP URI safely formatted
    :rtype:                 str|None
    """

    parts = parseSipUri(uri)
    if parts is None:
        return None

    if parts['ipv4'] is not None:
        host = parts['ipv4']
    elif parts['ipv6'] is not None:
        host = '[{}]'.format(parts['ipv6'])
    elif parts['host'] is not None:
        host = parts['host']
    else:
        return None

    proto = parts['proto'] if parts['proto'] is not None else default_proto
    user = parts['user'] if parts['user'] is not None else default_user
    port = str(parts['port']) if parts['port'] is not None else str(default_port)

    tmp = parts['params'] if parts['params'] is not None else default_params
    params = ';'.join([('='.join([x[0],str(x[1])]) if not isinstance(x[1], bool) else x[0]) for x in tmp.items()])

    return proto + ':' + (user + '@' if len(user) > 0 else '') + \
           host + ':' + port + (';' + params if len(params) > 0 else '')

def isCertValid(hostname, externalip, port=5061):
    """ Returns true if the hostname has a valid cert"""

    result = {"tls_cert_valid": False, "tls_cert_details": "", "tls_error": ""}

    try:
        context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH, cafile=settings.DSIP_SSL_CA)
        context.load_cert_chain(certfile=settings.DSIP_SSL_CERT, keyfile=settings.DSIP_SSL_KEY)

        conn = context.wrap_socket(socket.socket(socket.AF_INET), server_hostname=hostname)
        conn.connect((externalip, port))
        # print("SSL established. Peer: {}".format(conn.getpeercert()))
        cert = conn.getpeercert()
        result['tls_cert_details'] = cert
        #ssl.match_hostname(cert, hostname)
        result['tls_cert_valid'] = True
        return result
    except Exception as ex:
        result['tls_error'] = str(ex)
        # Return valid even if the cert can't be validated.  We just want to validate
        # the ability to connect using the cert.
        return result

# TODO: kam jsonrpc url should be set in settings.py / install script
def healthCheck():
    """
    Checks the health of dsiprouter
    """

    cmdset = {"method": "dsiprouter.health_check", "jsonrpc": "2.0", "id": 1}
    r = requests.get('http://127.0.0.1:5060/api/kamailio', json=cmdset)
    if r is not None and r.status_code == 200:
        return True
    return False

def objToDict(obj):
    """
    converts an arbitrary object to dict
    """
    return dict((attr, getattr(obj, attr)) for attr in dir(obj) if
                not attr.startswith('__') and not inspect.ismethod(getattr(obj, attr)) and not inspect.isfunction(getattr(obj, attr)))

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
    elif hasattr(row, '__dict__'):
        d = row.__dict__
        d.pop('_sa_instance_state', None)
    else:
        d = objToDict(row)

    return d

def strFieldsToDict(fields_str):
    fields = {}
    for field in fields_str.split(','):
        if ':' in field:
            tmp = field.split(':', 1)
            fields[tmp[0]] = tmp[1]
    return fields

def dictToStrFields(fields_dict):
    return ','.join("{}:{}".format(k, v) for k, v in fields_dict.items())

def updateConfig(config_obj, field_dict, hot_reload=False):
    """
    Update a python config module
    :param config_obj:
    :param field_dict:
    :return:
    """
    config_file = "<no filepath available>"
    try:
        config_file = config_obj.__file__

        with open(config_file, 'r+') as config:
            config_str = config.read()
            for key, val in field_dict.items():
                regex = r"^(?!#)(?:" + re.escape(key) + \
                        r")[ \t]*=[ \t]*(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?\"\"\".*\"\"\"[ \t]*$|b?'''.*'''[ \v]*$|b?\".*\"[ \t]*$|b?'.*')"
                replace_str = "{} = {}".format(key, repr(val))
                config_str = re.sub(regex, replace_str, config_str, flags=re.MULTILINE)
            
            config.seek(0)
            config.write(config_str)
            config.truncate()

        if hot_reload:
            reload(config_obj)
    except:
        IO.logerr('Problem updating the {0} configuration file'.format(config_file))

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
    with open(settings.KAM_CFG_PATH, 'rb') as kamcfg_file:
        kamcfg_bytes = kamcfg_file.read()

        regex = rb'''CUSTOM_ROUTING_START.*CUSTOM_ROUTING_END'''
        custom_routes_bytes = re.search(regex, kamcfg_bytes, flags=re.MULTILINE | re.DOTALL).group(0)

        regex = rb'''^route\[(\w+)\]'''
        matches = re.finditer(regex, custom_routes_bytes, flags=re.MULTILINE)

        for matchnum, match in enumerate(matches):
            if len(match.groups()) > 0:
                custom_routes.append(match.group(1).decode('utf-8'))

    return custom_routes

def monthdelta(dt, delta):
    """ Return dt with a delta month change (neg or pos) """
    m, y = (dt.month + delta) % 12, dt.year + (dt.month + delta - 1) // 12
    if m == 0:
        m = 12
    d = min(dt.day, monthrange(y, m)[1])
    return dt.replace(day=d, month=m, year=y)

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

def debugException(ex=None, log_ex=True, print_ex=True, showstack=False):
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
            text += "[FILE]: {}\n[LINE NUM]: {}\n[FUNCTION]: {}\n[SOURCE]: {}\n".format(filename, linenum, funcname,
                source)
    if log_ex:
        IO.logerr(text)
    if print_ex:
        IO.printerr(text)

def debugEndpoint(log_out=True, print_out=True, **kwargs):
    """
    Debug an endpoint\n
    Must be run within request context

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
        for k, v in frame.f_globals.items():
            if not k.startswith('__') and frame.f_code.co_name in dir(v):
                calling_chain.append(k)
                break
    # parent func
    if frame.f_code.co_name != '<module>':
        calling_chain.append(frame.f_code.co_name)

    text = "((( [DEBUG ENDPOINT]: {} )))\n".format(' -> '.join(calling_chain))
    text += '\n'.join((
        '{}: {}'.format('accept_charsets', str(request.accept_charsets).strip()),
        '{}: {}'.format('accept_encodings', str(request.accept_encodings).strip()),
        '{}: {}'.format('accept_languages', str(request.accept_languages).strip()),
        '{}: {}'.format('accept_mimetypes', str(request.accept_mimetypes).strip()),
        '{}: {}'.format('access_control_request_headers', str(request.access_control_request_headers).strip()),
        '{}: {}'.format('access_control_request_method', str(request.access_control_request_method).strip()),
        '{}: {}'.format('access_route', str(request.access_route).strip()),
        '{}: {}'.format('args', str(request.args).strip()),
        '{}: {}'.format('authorization', str(request.authorization).strip()),
        '{}: {}'.format('base_url', str(request.base_url).strip()),
        '{}: {}'.format('blueprint', str(request.blueprint).strip()),
        '{}: {}'.format('cache_control', str(request.cache_control).strip()),
        '{}: {}'.format('charset', str(request.charset).strip()),
        '{}: {}'.format('content_encoding', str(request.content_encoding).strip()),
        '{}: {}'.format('content_length', str(request.content_length).strip()),
        '{}: {}'.format('content_md5', str(request.content_md5).strip()),
        '{}: {}'.format('content_type', str(request.content_type).strip()),
        '{}: {}'.format('cookies', str(request.cookies).strip()),
        '{}: {}'.format('files', str(request.files).strip()),
        '{}: {}'.format('form', str(request.form).strip()),
        '{}: {}'.format('headers', str(request.headers).strip()),
        '{}: {}'.format('json', str(request.get_json(force=True, silent=True)).strip()),
        '{}: {}'.format('method', str(request.method).strip()),
        '{}: {}'.format('query_string', str(request.query_string).strip()),
        '{}: {}'.format('referrer', str(request.referrer).strip()),
        '{}: {}'.format('remote_addr', str(request.remote_addr).strip()),
        '{}: {}'.format('remote_user', str(request.remote_user).strip()),
        '{}: {}'.format('url', str(request.url).strip()),
        '{}: {}'.format('user_agent', str(request.user_agent).strip()),
        '{}: {}'.format('values', str(request.values).strip()),
        '{}: {}'.format('view_args', str(request.view_args).strip()),
    ))

    if len(kwargs) > 0:
        for k, v in sorted(kwargs):
            text += "{}: {}\n".format(k, str(v).strip())

    if log_out:
        IO.logdbg(text)

    if print_out:
        IO.printdbg(text)

def allowed_file(filename, ALLOWED_EXTENSIONS={'csv', 'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def showError(type="", code=None, msg=None):
    code = int(code) if code is not None else StatusCodes.HTTP_INTERNAL_SERVER_ERROR
    return render_template('error.html', type=type, msg=msg), code

def showApiError(ex, payload={}):
    debugException(ex)

    if isinstance(ex, sql_exceptions.SQLAlchemyError):
        payload['error'] = "db"
        if len(str(ex)) > 0:
            payload['msg'] = str(ex)
        else:
            payload['msg'] = "Unknown DB Error Occurred"
        status_code = StatusCodes.HTTP_INTERNAL_SERVER_ERROR
    elif isinstance(ex, http_exceptions.HTTPException):
        payload['error'] = "http"
        if len(ex.description) > 0:
            payload['msg'] = ex.description
        else:
            payload['msg'] = "Unknown HTTP Error Occurred"
        status_code = ex.code or StatusCodes.HTTP_INTERNAL_SERVER_ERROR
    else:
        payload['error'] = "server"
        if len(str(ex)) > 0:
            payload['msg'] = str(ex)
        else:
            payload['msg'] = "Unknown Error Occurred"
        status_code = StatusCodes.HTTP_INTERNAL_SERVER_ERROR

    return jsonify(payload), status_code

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
    # if len(render_args) == 3:
    response.status = code

    # change response location
    response.headers['Location'] = location

    return response

def getRequestData():
    """
    Get data from request formatted as dict\n
    Must be run within request context

    -----

    The following data formats are supported:

    - multipart forms
    - url encoded forms
    - JSON body

    :return:        request data
    :rtype:         dict
    """

    content_type = str.lower(request.headers.get('Content-Type', ''))
    if 'multipart/form-data' in content_type:
        data = request.form.to_dict(flat=False)
    elif 'application/x-www-form-urlencoded' in content_type:
        data = request.form.to_dict(flat=False)
    else:
        data = request.get_json(force=True)

    # fix data if client is sloppy (http_async_client)
    if request.headers.get('User-Agent') == 'http_async_client':
        data = json.loads(list(data)[0])

    return data

class StatusCodes():
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
