# make sure the generated source files are imported instead of the template ones
import sys
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import fcntl, ipaddress, re
import settings
from util.networking import hostToIP, isValidHostname

# Server name matching options
KAM_TLS_SNI_DOMAIN = 0
KAM_TLS_SNI_ALL = 1
KAM_TLS_SNI_SUBDOMAINS = 2
KAM_TLS_SNI_MODES = (KAM_TLS_SNI_DOMAIN, KAM_TLS_SNI_ALL, KAM_TLS_SNI_SUBDOMAINS)

# header formats per domain profile
DOMAIN_START_HEADER = '#========== {domain}_start ==========#'
DOMAIN_END_HEADER = '#========== {domain}_end ==========#'

# larger TLS configs are not parsed
KAM_TLSCFG_MAX_SIZE = 4 * 1024 * 1024
# the default profiles have no ip and port, they are never matched
IP_ADDRESS_REGEX = re.compile(r'[0-9A-Fa-f:.]{2,45}')
SECTION_HEADER_REGEX = re.compile(r'\[(server|client):(\[[^\[\]\s]+\]|[^\[\]:\s]+):([0-9]{1,5})\]')


def createCustomTLSConfig(domain, ip, port, server_name_mode):
    """
    Create a Domain TLS Profile string for the Kamailio TLS Config\n
    Reference: https://kamailio.org/docs/modules/5.5.x/modules/tls.html

    :param domain:              domain profile to create
    :type domain:               str
    :param ip:                  ip kamailio will match for profile
    :type ip:                   str
    :param port:                port kamailio will match for profile
    :type port:                 int|str
    :param server_name_mode:    server name matching mode
    :type server_name_mode:     int|str
    :return:                    tls config for a custom domain
    :rtype:                     str
    """

    port = str(port)
    server_name_mode = str(server_name_mode)

    return (
        DOMAIN_START_HEADER + '\n' + (
            '[server:{ip}:{port}]\n'
            'method = TLSv1.2+\n'
            'verify_certificate = yes\n'
            'require_certificate = yes\n'
            'private_key = {certs_dir}/{domain}/dsiprouter-key.pem\n'
            'certificate = {certs_dir}/{domain}/dsiprouter-cert.pem\n'
            'ca_list = {certs_dir}/ca-list.pem\n'
            'server_name = {domain}\n'
            'server_name_mode = {name_mode}\n'
            '\n'
            '[client:{ip}:{port}]\n'
            'method = TLSv1.2+\n'
            'verify_certificate = yes\n'
            'require_certificate = yes\n'
            'private_key = {certs_dir}/{domain}/dsiprouter-key.pem\n'
            'certificate = {certs_dir}/{domain}/dsiprouter-cert.pem\n'
            'ca_list = {certs_dir}/ca-list.pem\n'
            'server_name = {domain}\n'
            'server_name_mode = {name_mode}\n'
            'server_id = {domain}\n'
        ) + DOMAIN_END_HEADER + '\n\n'
    ).format(ip=ip, port=port, certs_dir=settings.DSIP_CERTS_DIR, domain=domain, name_mode=server_name_mode)


def readTLSConfigLines(kamtlscfg_file):
    """
    Read the lines of an open Kamailio TLS Config

    :param kamtlscfg_file:  TLS config opened in binary mode
    :type kamtlscfg_file:   typing.BinaryIO
    :return:                lines of the config, line endings included
    :rtype:                 list[str]
    :raises ValueError:     if the config is larger than KAM_TLSCFG_MAX_SIZE or not valid UTF-8
    """

    kamtlscfg_bytes = kamtlscfg_file.read(KAM_TLSCFG_MAX_SIZE + 1)
    if len(kamtlscfg_bytes) > KAM_TLSCFG_MAX_SIZE:
        raise ValueError('kamailio TLS config is larger than {} bytes'.format(KAM_TLSCFG_MAX_SIZE))
    return kamtlscfg_bytes.decode('utf-8').splitlines(keepends=True)


def writeTLSConfigLines(kamtlscfg_file, lines):
    """
    Replace the contents of an open Kamailio TLS Config

    :param kamtlscfg_file:  TLS config opened in binary mode for reading and writing
    :type kamtlscfg_file:   typing.BinaryIO
    :param lines:           lines of the config, line endings included
    :type lines:            list[str]
    """

    kamtlscfg_file.seek(0)
    kamtlscfg_file.write(''.join(lines).encode('utf-8'))
    kamtlscfg_file.truncate()


def parseDomainHeader(line):
    """
    Parse a domain profile header line

    :param line:    line of the TLS config
    :type line:     str
    :return:        domain and kind of header ('start' or 'end'), None if the line is not a header
    :rtype:         tuple[str, str]|None
    """

    prefix, start_suffix = DOMAIN_START_HEADER.split('{domain}')
    end_suffix = DOMAIN_END_HEADER.split('{domain}')[1]

    line = line.rstrip('\r\n')
    if not line.startswith(prefix):
        return None
    for kind, suffix in (('start', start_suffix), ('end', end_suffix)):
        if line.endswith(suffix) and len(line) > len(prefix) + len(suffix):
            return line[len(prefix):-len(suffix)], kind
    return None


def findDomainBlocks(lines):
    """
    Find the domain profiles in the lines of a TLS config\n
    A start header without an end header for the same domain is not a profile

    :param lines:   lines of the TLS config
    :type lines:    list[str]
    :return:        domain, index of the start header, index of the end header
    :rtype:         list[tuple[str, int, int]]
    """

    blocks = []
    open_domain = None
    open_index = 0

    for index, line in enumerate(lines):
        header = parseDomainHeader(line)
        if header is None:
            continue
        domain, kind = header
        if kind == 'start':
            open_domain = domain
            open_index = index
        elif domain == open_domain:
            blocks.append((domain, open_index, index))
            open_domain = None
    return blocks


def parseDomainBlock(lines):
    """
    Parse the server and client sections of a domain profile

    :param lines:   lines between the start and end header of the profile
    :type lines:    list[str]
    :return:        sections by type, each with ip, port and params
    :rtype:         dict[str, dict]
    """

    sections = {}
    section = None

    for line in lines:
        line = line.strip()
        if len(line) == 0 or line[0] == '#':
            continue
        if line[0] == '[':
            match = SECTION_HEADER_REGEX.fullmatch(line)
            if match is None:
                section = None
                continue
            section = {'ip': match.group(2), 'port': int(match.group(3)), 'params': {}}
            sections[match.group(1)] = section
            continue
        key, separator, value = line.partition('=')
        if section is not None and len(separator) != 0:
            section['params'][key.strip()] = value.strip()
    return sections


def removeDomainBlocks(lines, domain):
    """
    Remove the profiles of a domain from the lines of a TLS config\n
    The empty lines following a removed profile are removed with it

    :param lines:   lines of the TLS config
    :type lines:    list[str]
    :param domain:  domain profile to remove
    :type domain:   str
    :return:        lines of the TLS config without the profiles of the domain
    :rtype:         list[str]
    """

    kept = []
    next_index = 0

    for block_domain, start, end in findDomainBlocks(lines):
        if block_domain != domain:
            continue
        kept.extend(lines[next_index:start])
        next_index = end + 1
        while next_index < len(lines) and len(lines[next_index].strip()) == 0:
            next_index += 1
    kept.extend(lines[next_index:])
    return kept


def normalizeDomainProfile(domain, ip, port, server_name_mode):
    """
    Validate the values a domain profile is created from

    :param domain:              domain profile to create
    :type domain:               str
    :param ip:                  ip kamailio will match for profile, resolved from the domain if empty
    :type ip:                   str
    :param port:                port kamailio will match for profile
    :type port:                 int|str
    :param server_name_mode:    server name matching mode
    :type server_name_mode:     int|str
    :return:                    ip formatted for the TLS config, port, server name matching mode
    :rtype:                     tuple[str, int, int]
    :raises ValueError:         if a value can not be used in the TLS config
    """

    if not isValidHostname(domain):
        raise ValueError('domain is not a valid hostname')

    # TLS config does not accept hostnames, resolve IP if needed
    if ip is None or len(ip) == 0:
        ip = hostToIP(domain)
    ip = ip.strip('[]')
    # an IPv6 zone id can hold any character
    if IP_ADDRESS_REGEX.fullmatch(ip) is None:
        raise ValueError('ip is not a valid address')
    address = ipaddress.ip_address(ip)
    # IPv6 addresses require square brackets
    ip = '[{}]'.format(address) if address.version == 6 else str(address)

    port = int(port)
    if not 0 < port <= 65535:
        raise ValueError('port is out of range')

    server_name_mode = int(server_name_mode)
    if server_name_mode not in KAM_TLS_SNI_MODES:
        raise ValueError('server name matching mode is not supported')

    return ip, port, server_name_mode


def getCustomTLSConfigs(domain_filter=None):
    """
    Get kamailio TLS configs for additional domains\n
    Server and client domain/ip/port are assumed to be the same\n
    The optional domain filter returns domains & subdomains that match

    Returned Data Format:

    .. code-block:: python

        {
            '<domain>': {
                'ip': '<str>',
                'port': '<int>'
                'server': {<server params>},
                'client': {<client params>}
            },
            ...
        }

    :param domain_filter:   filter on this domain / subdomains
    :type domain_filter:    str
    :return:                TLS configs for custom domain profiles
    :rtype:                 dict|None
    """

    custom_configs = {}

    try:
        with open(settings.KAM_TLSCFG_PATH, 'rb') as kamtlscfg_file:
            fcntl.flock(kamtlscfg_file, fcntl.LOCK_SH)
            lines = readTLSConfigLines(kamtlscfg_file)

        for domain, start, end in findDomainBlocks(lines):
            if domain_filter is not None and domain != domain_filter and not domain.endswith('.' + domain_filter):
                continue
            sections = parseDomainBlock(lines[start + 1:end])
            if 'server' not in sections or 'client' not in sections:
                continue
            custom_configs[domain] = {
                'ip': sections['server']['ip'],
                'port': sections['server']['port'],
                'server': sections['server']['params'],
                'client': sections['client']['params']
            }

        return custom_configs
    except (OSError, ValueError):
        return None


def addCustomTLSConfig(domain, ip='', port=5061, server_name_mode=KAM_TLS_SNI_DOMAIN):
    """
    Add an additional domain to kamailio TLS configs\n
    An existing profile for the domain is replaced

    :param domain:              domain profile to create
    :type domain:               str
    :param ip:                  ip kamailio will match for profile
    :type ip:                   str
    :param port:                port kamailio will match for profile
    :type port:                 int|str
    :param server_name_mode:    server name matching mode
    :type server_name_mode:     int|str
    :return:                    whether addition succeeded
    :rtype:                     bool
    """

    try:
        ip, port, server_name_mode = normalizeDomainProfile(domain, ip, port, server_name_mode)
        domain_config = createCustomTLSConfig(domain, ip, port, server_name_mode)

        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            fcntl.flock(kamtlscfg_file, fcntl.LOCK_EX)
            lines = removeDomainBlocks(readTLSConfigLines(kamtlscfg_file), domain)
            if len(lines) != 0 and not lines[-1].endswith('\n'):
                lines.append('\n')
            lines.append(domain_config)
            writeTLSConfigLines(kamtlscfg_file, lines)

        return True
    except Exception:
        return False


def updateCustomTLSConfig(domain, ip=None, port=None, server_name_mode=None):
    """
    Update an additional domain in kamailio TLS configs

    :param domain:              domain profile to update
    :type domain:               str
    :param ip:                  ip kamailio will match for profile
    :type ip:                   str
    :param port:                port kamailio will match for profile
    :type port:                 int|str
    :param server_name_mode:    server name matching mode
    :type server_name_mode:     int|str
    :return:                    whether update succeeded
    :rtype:                     bool
    """

    try:
        domain_configs = getCustomTLSConfigs(domain)
        if domain_configs is None or domain not in domain_configs:
            return False
        domain_data = domain_configs[domain]

        ip = ip if ip is not None else domain_data['ip']
        port = port if port is not None else domain_data['port']
        server_name_mode = server_name_mode if server_name_mode is not None \
            else domain_data['server']['server_name_mode']

        return addCustomTLSConfig(domain, ip, port, server_name_mode)
    except Exception:
        return False


def deleteCustomTLSConfig(domain):
    """
    Delete an additional domain in kamailio TLS configs

    :param domain:          domain profile to delete
    :type domain:           str
    :return:                whether delete succeeded
    :rtype:                 bool
    """

    try:
        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            fcntl.flock(kamtlscfg_file, fcntl.LOCK_EX)
            lines = readTLSConfigLines(kamtlscfg_file)
            writeTLSConfigLines(kamtlscfg_file, removeDomainBlocks(lines, domain))

        return True
    except (OSError, ValueError):
        return False
