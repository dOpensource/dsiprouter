import socket, binascii, requests, re
import requests.packages.urllib3.util.connection as urllib3_conn
from util.pyasync import mtexec


# constants
RTF_UP = 0x0001                         # route usable
RTF_GATEWAY = 0x0002                    # destination is a gateway
RTF_HOST = 0x0004                       # host entry (net otherwise)
DSIP_DNS_ALIASES = ['local.cluster']    # special purpose dsip hostnames

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

def isValidIP(address, ip_ver=''):
    """ Determine if ip address is valid """
    if ip_ver == '4':
        return ipv4Test(address)
    elif ip_ver == '6':
        return ipv6Test(address)
    else:
        if not ipv4Test(address) and not ipv6Test(address):
            return False
        return True

def getInternalIP(ip_ver=''):
    """
    Get the internally routable ip address of the system

    :param ip_ver:  IP version to fetch '4'=>ipv4,'6'=>ipv6,''=>try both
    :type ip_ver:   str
    :return:        Internal IP address
    :rtype:         str|None
    """

    if ip_ver == '4':
        sock_types = (socket.AF_INET,)
    elif ip_ver == '6':
        sock_types = (socket.AF_INET6,)
    else:
        sock_types = (socket.AF_INET, socket.AF_INET6)

    for sock_type in sock_types:
        try:
            with socket.socket(sock_type, socket.SOCK_DGRAM) as s:
                s.connect(('www.google.com', 0))
                ip = s.getsockname()[0]
                if isValidIP(ip):
                    return ip
        except:
            pass

    return None

def getExternalIP(ip_ver=''):
    """
    Get the externally routable ip address of the system

    :param ip_ver:  IP version to fetch '4'=>ipv4,'6'=>ipv6,''=>try both
    :type ip_ver:   str
    :return:        External IP address
    :rtype:         str|None
    """

    tasks = []
    _allowed_gai_family = urllib3_conn.allowed_gai_family

    # redundancy in case a service provider goes down
    ipv4_resolvers = (
        ('https://icanhazip.com',),
        ('https://ipecho.net/plain',),
        ('https://myexternalip.com/raw',),
        ('https://api.ipify.org',),
        ('https://bot.whatismyipaddress.com',)
    )
    ipv6_resolvers = (
        ('https://icanhazip.com',),
        ('https://bot.whatismyipaddress.com',),
        ('https://ifconfig.co',),
        ('https://ident.me',),
        ('https://api6.ipify.org',)
    )

    # task performed by each thread
    def getip(url):
        try:
            ip = requests.get(url, timeout=2.0).text.strip()
            if isValidIP(ip):
                return ip
        except:
            pass
        return None

    # DNS exceptions can take a while to resolve, so instead we run all requests
    # in parallel and filter out the first good external IP (ipv4 given priority)
    if ip_ver == '4' or len(ip_ver) == 0:
        urllib3_conn.allowed_gai_family = lambda: socket.AF_INET
        tasks.extend(mtexec(getip, ipv4_resolvers))
    if ip_ver == '6' or len(ip_ver) == 0:
        urllib3_conn.allowed_gai_family = lambda: socket.AF_INET6
        tasks.extend(mtexec(getip, ipv6_resolvers))
    results = [task.result() for task in tasks]

    # undo urllib monkey patch
    urllib3_conn.allowed_gai_family = _allowed_gai_family

    return next((x for x in results if x is not None), None)


def hostToIP(host, ip_ver=''):
    """
    Convert host to IP Address\n
    Supports conversion to IPv4 and IPv6\n
    IPv4 takes priority and is tried first

    :param host:        hostname/fqdn to convert to IP
    :type host:         str
    :param ip_ver:      IP version to use
    :type ip_ver:       str
    :return:            IP address of host
    :rtype:             str|None
    """

    if ip_ver == '4' or len(ip_ver) == 0:
        try:
            return socket.getaddrinfo(host, 0, socket.AF_INET)[0][4][0]
        except:
            raise Exception("Endpoint hostname/address is malformed or not working:{0}".format(host))
    if ip_ver == '6' or len(ip_ver) == 0:
        try:
            return socket.getaddrinfo(host, 0, socket.AF_INET6)[0][4][0]
        except:
            raise Exception("Endpoint hostname/address is malformed or not working:{0}".format(host))
    return None

def ipToHost(ip, exclude_dsip_aliases=True):
    """
    Converts IP Address to hostname\n
    Supports conversion from IPv4 and IPv6

    :param ip:      IP address to convert
    :type ip:       str
    :return:        hostname for IP
    :rtype:         str|None
    """

    try:
        host = socket.gethostbyaddr(ip)[0]
        if exclude_dsip_aliases and host in DSIP_DNS_ALIASES:
            return None
        return host
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

        if ipv6_port_format:
            res = '[{}]'.format(res)
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

def getRoutingTableIPv4():
    """
    Get IPv4 routing table entries

    :return:    routing table entries
    :rtype:     list
    """

    rt_entries = []

    try:
        with open('/proc/net/route', 'r') as fp:
            _ = next(fp)
            for line in fp:
                fields = line.strip().split()
                rt_entries.append({
                    'iface': fields[0],             # interface name
                    'dst_addr': int(fields[1], 16), # destination network/host address
                    'gw_addr': int(fields[2], 16),  # gateway address
                    'flags': int(fields[3], 16),    # routing flags
                    'use': int(fields[5]),          # number of lookups for this route
                    'metric': int(fields[6]),       # hops to target address
                    'mask': int(fields[7], 16),     # network mask for destination
                    'mtu': int(fields[8])           # max packet size for this route
                })
    except:
        pass
    return rt_entries

def getRoutingTableIPv6():
    """
    Get IPv6 routing table entries

    :return:    routing table entries
    :rtype:     list
    """

    rt_entries = []

    try:
        with open('/proc/net/ipv6_route', 'r') as fp:
            _ = next(fp)
            for line in fp:
                fields = line.strip().split()
                rt_entries.append({
                    'iface': fields[9],                 # interface name
                    'dst_addr': int(fields[0], 16),     # destination network/host address
                    'dst_plen': int(fields[1], 16),     # destination address prefix length
                    'src_addr': int(fields[2], 16),     # source network/host address
                    'src_plen': int(fields[3], 16),     # source address prefix length
                    'next_hop': int(fields[4], 16),     # gateway / next hop address
                    'metric': int(fields[5], 16),       # hops to target address
                    'use': int(fields[7], 16),          # number of lookups for this route
                    'flags': int(fields[8], 16),        # routing flags
                })
    except:
        pass
    return rt_entries

# Inspired By: `Python CookBook <https://www.safaribooksonline.com/library/view/python-cookbook/0596001673/ch10s06.html>`_
def ipToInt(ip_str):
    """
    Convert IP string to integer

    :param ip_str:          ipv4 or ipv6 address
    :type ip_str:           str
    :return:                integer value for ip
    :rtype:                 int
    :raises ValueError:     on invalid IP conversion
    """

    for sock_type in (socket.AF_INET, socket.AF_INET6):
        try:
            return int(binascii.hexlify(socket.inet_pton(sock_type, ip_str)), 16)
        except:
            pass
    raise ValueError("invalid IP address")

def ipToStr(ip_int):
    """
    Convert integer IP to string

    :param ip_int:          integer value for ip
    :type ip_int:           int
    :return:                ipv4 or ipv6 address
    :rtype:                 str
    :raises ValueError:     on invalid IP conversion
    """

    for sock_type in (socket.AF_INET, socket.AF_INET6):
        try:
            return socket.inet_ntop(sock_type, binascii.unhexlify("{0:x}".format(ip_int)))
        except:
            pass
    raise ValueError("invalid IP address")

def netMaskToPrefixLen(mask):
    """
    Convert a network address mask to a CIDR prefix length\n
    For example: 255.255.255.0 -> 24\n
    Supports IPv4 and IPv6 (ipv6 generally doesn't use net masks though)\n
    Supplying network addresses other than a mask will give unintended results

    :param mask:    network address mask
    :type mask:     str|int
    :return:        CIDR prefix length
    :rtype:         str
    """

    if isinstance(mask, str):
        mask = ipToInt(mask)
    return str(len(bin(mask)[2:]))

def prefixLenToNetMask(prefixlen):
    """
    Convert a CIDR prefix length to a network address mask\n
    For example: 32 -> 255.255.255.255\n
    Supports IPv4 and IPv6 (prefix length range is from 0-128)

    :param prefixlen:       CIDR prefix length
    :type prefixlen:        str|int
    :return:                network address mask
    :rtype:                 str
    :raises ValueError:     on invalid IP conversion
    """

    if isinstance(prefixlen, str):
        prefixlen = int(prefixlen)
    mask = int('1' * 128, 2) & int('1' * prefixlen, 2)
    return ipToStr(mask)

def getInternalCIDR(ip_ver=''):
    """
    Get internal IP and network prefix length as CIDR address

    :param ip_ver:      IP version to use
    :type ip_ver:       str
    :return:            CIDR address
    :rtype:             str|None
    """

    if ip_ver == '4' or len(ip_ver) == 0:
        try:
            # find default ipv4 route and mask, then create CIDR address
            rt_entries = getRoutingTableIPv4()
            if len(rt_entries) == 0:
                raise Exception()
            def_iface = next(x for x in rt_entries \
                             if x['dst_addr'] == 0 and x['flags'] & (RTF_UP | RTF_GATEWAY))['iface']
            net_mask = next(x for x in rt_entries if x['gw_addr'] == 0 and x['iface'] == def_iface)['mask']
            prefix_len = netMaskToPrefixLen(net_mask)
            ip = getInternalIP(ip_ver='4')
            return '{}/{}'.format(ip, prefix_len)
        except:
            pass
    if ip_ver == '6' or len(ip_ver) == 0:
        try:
            # find default ipv6 route and mask, then create CIDR address
            rt_entries = getRoutingTableIPv6()
            if len(rt_entries) == 0:
                raise Exception()
            def_iface = next(x for x in rt_entries \
                             if x['dst_addr'] == 0 and x['flags'] & (RTF_UP | RTF_GATEWAY))['iface']
            prefix_len = str(next(x for x in rt_entries \
                               if x['dst_addr'] != 0 and x['next_hop'] != 0 \
                               and x['iface'] == def_iface)['dst_plen'])
            ip = getInternalIP(ip_ver='6')
            return '{}/{}'.format(ip, prefix_len)
        except:
            pass
    return None

