# make sure the generated source files are imported instead of the template ones
import sys
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import re, socket
import settings
from util.networking import ipv6Test, hostToIP

# Server name matching options
KAM_TLS_SNI_DOMAIN = 0
KAM_TLS_SNI_ALL = 1
KAM_TLS_SNI_SUBDOMAINS = 2

# header formats per domain profile
DOMAIN_START_HEADER = '#========== {domain}_start ==========#'
DOMAIN_END_HEADER = '#========== {domain}_end ==========#'


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
            kamtlscfg_bytes = kamtlscfg_file.read()

            if domain_filter is None:
                regex = DOMAIN_START_HEADER.format(domain=r'(?P<domain>.*?)').encode('utf-8') + \
                        rb'''\n(?:\[server\:(?!default)\[?(?P<server_ip>.*?)\]?\:(?P<server_port>[0-9]+)\])\n(?P<server_params>.*?)\n(?=\[|#)\n*''' + \
                        rb'''(?:\[client\:(?!default)\[?(?P<client_ip>.*?)\]?\:(?P<client_port>[0-9]+)\])\n(?P<client_params>.*?)(?=\[|#)''' + \
                        DOMAIN_END_HEADER.format(domain=r'(?P=domain)').encode('utf-8')
            else:
                regex = DOMAIN_START_HEADER.format(domain=r'(?P<domain>(?:.*?\.)*{})'.format(domain_filter)).encode('utf-8') + \
                        rb'''\n(?:\[server\:(?!default)\[?(?P<server_ip>.*?)\]?\:(?P<server_port>[0-9]+)\])\n(?P<server_params>.*?)\n(?=\[|#)\n*''' + \
                        rb'''(?:\[client\:(?!default)\[?(?P<client_ip>.*?)\]?\:(?P<client_port>[0-9]+)\])\n(?P<client_params>.*?)(?=\[|#)''' + \
                        DOMAIN_END_HEADER.format(domain=r'(?P=domain)').encode('utf-8')
            matches = [x.groupdict() for x in re.finditer(regex, kamtlscfg_bytes, flags=re.DOTALL | re.MULTILINE)]

            for match in matches:
                domain = match['domain'].decode('utf-8')
                ip = match['server_ip'].decode('utf-8')
                server_config_strs = match['server_params'].decode('utf-8').rstrip().split('\n')
                client_config_strs = match['client_params'].decode('utf-8').rstrip().split('\n')
                custom_configs[domain] = {
                    'ip': ip if not ipv6Test(ip) else '[' + ip + ']',
                    'port': int(match['server_port'].decode('utf-8')),
                    'server': {x.split(' = ')[0]: x.split(' = ')[1] for x in server_config_strs},
                    'client': {x.split(' = ')[0]: x.split(' = ')[1] for x in client_config_strs}
                }

        return custom_configs
    except:
        return None


def addCustomTLSConfig(domain, ip='', port=5061, server_name_mode=KAM_TLS_SNI_DOMAIN):
    """
    Add an additional domain to kamailio TLS configs

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
        # TLS config does not accept hostnames, resolve IP if needed
        if len(ip) == 0:
            ip = hostToIP(domain)
        # IPv6 addresses require square brackets
        elif ipv6Test(ip):
            ip = '[' + ip + ']'
        domain_config_bytes = createCustomTLSConfig(domain, ip, port, server_name_mode).encode('utf-8')

        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            kamtlscfg_file.seek(0, 2)
            kamtlscfg_file.write(domain_config_bytes)

        return True
    except:
        return False


def updateCustomTLSConfig(domain, ip=None, port=None, server_name_mode=None):
    """
    Add an additional domain to kamailio TLS configs

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
        if domain not in domain_configs:
            return False
        else:
            domain_data = domain_configs[domain]

        ip = ip if ip is not None else domain_data['ip']
        port = port if port is not None else domain_data['port']
        server_name_mode = server_name_mode if server_name_mode is not None \
            else domain_data['server']['server_name_mode']

        if not deleteCustomTLSConfig(domain):
            return False
        if not addCustomTLSConfig(domain, ip, port, server_name_mode):
            return False

        return True
    except:
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
            kamtlscfg_bytes = kamtlscfg_file.read()

            regex = DOMAIN_START_HEADER.format(domain=domain).encode() + rb'.*?' + \
                    DOMAIN_END_HEADER.format(domain=domain).encode() + rb'\n*'
            custom_tls_bytes = re.sub(regex, b'', kamtlscfg_bytes, flags=re.DOTALL | re.MULTILINE)
            kamtlscfg_file.truncate(0)
            kamtlscfg_file.seek(0, 0)
            kamtlscfg_file.write(custom_tls_bytes)

        return True
    except:
        return False
