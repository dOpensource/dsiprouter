import re, socket
import settings

#Server name matching options
KAM_TLS_SNI_ALL = 1
KAM_TLS_SNI_SUBDOMAINS = 2
KAM_TLS_SNI_DOMAIN = 3

def createCustomTLSConfig(domain, ip, port, server_name_mode):
    return [
        (
            '[server:{ip}:{port}]\n'
            'method = TLSv1.2+\n'
            'verify_certificate = yes\n'
            'require_certificate = yes\n'
            'private_key = {certs_dir}/{domain}/dsiprouter.key\n'
            'certificate = {certs_dir}/{domain}/dsiprouter.crt\n'
            'ca_list = {certs_dir}/{domain}/cacert.pem\n'
            'server_name = {domain}\n'
            'server_name_mode = {name_mode}\n'
        ).format(ip=ip, port=port, certs_dir=settings.DSIP_CERTS_DIR, domain=domain,
                 name_mode=server_name_mode).encode('utf-8'),
        (
            '[client:{ip}:{port}]\n'
            'method = TLSv1.2+\n'
            'verify_certificate = yes\n'
            'require_certificate = yes\n'
            'private_key = {certs_dir}/{domain}/dsiprouter.key\n'
            'certificate = {certs_dir}/{domain}/dsiprouter.crt\n'
            'ca_list = {certs_dir}/{domain}/cacert.pem\n'
            'server_name = {domain}\n'
            'server_name_mode = {name_mode}\n'
            'server_id = {domain}\n'
        ).format(ip=ip, port=port, certs_dir=settings.DSIP_CERTS_DIR, domain=domain,
                name_mode=server_name_mode).encode('utf-8')
    ]

# TODO: error handling, return None, return true or false
# TODO: allow option for get/filter for single domain config
def getCustomTLSConfigs():
    """
    Return kamailio TLS configs for additional domains
    return syntax: { 'domain_ip:domain_port': { 'server': {<server config>}, 'client': {<client config>} } }
    """
    custom_configs = {}

    try:
        with open(settings.KAM_TLSCFG_PATH, 'rb') as kamtlscfg_file:
            kamtlscfg_bytes = kamtlscfg_file.read()

            regex = rb'''(####### CUSTOM_DOMAINS_START #########\n.*?####### CUSTOM_DOMAINS_END #########\n?)'''
            custom_tls_bytes = re.search(regex, kamtlscfg_bytes, flags=re.DOTALL).group(1)

            regex = rb'''(?:\[server\:(.*?)\])\n(.*?)(?=\[|#)'''
            matches = re.findall(regex, custom_tls_bytes, flags=re.DOTALL)
            for server in matches:
                server_name = server[0].decode('utf-8')
                server_config_strs = server[1].decode('utf-8').rstrip().split('\n')
                custom_configs[server_name] = {
                    'server': {x.split(' = ')[0]:x.split(' = ')[1] for x in server_config_strs}
                }

            regex = rb'''(?:\[client\:(.*?)\])\n(.*?)(?=\[|#)'''
            matches = re.findall(regex, custom_tls_bytes, flags=re.DOTALL)
            for client in matches:
                client_name = client[0].decode('utf-8')
                client_config_strs = client[1].decode('utf-8').rstrip().split('\n')
                custom_configs[client_name]['client'] = {
                    x.split(' = ')[0]:x.split(' = ')[1] for x in client_config_strs
                }

        return custom_configs
    except:
        return None

def addCustomTLSConfig(domain, ip='', port='5061', server_name_mode='0'):
    """
    Add an additional domain to kamailio TLS configs
    """

    try:
        if len(ip) == 0:
            ip = socket.getaddrinfo(domain, 0, family=socket.AF_INET, flags=socket.AI_CANONNAME)[0][4][0]
        server_config_bytes, client_config_bytes = createCustomTLSConfig(domain, ip, port, server_name_mode)

        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            kamtlscfg_bytes = kamtlscfg_file.read()

            regex = rb'''(.*####### CUSTOM_DOMAINS_START #########\n)(.*?)(####### CUSTOM_DOMAINS_END #########\n?.*)'''
            kamtlscfg_bytes = re.sub(regex, rb''.join([rb'\1\2\n', server_config_bytes, client_config_bytes, rb'\3']), kamtlscfg_bytes, flags=re.DOTALL)
            kamtlscfg_file.seek(0,0)
            kamtlscfg_file.write(kamtlscfg_bytes)

        return True
    except:
        return False

def updateCustomTLSConfig(domain, ip='', port='5061', server_name_mode='0'):
    """
    Update an additional domain in kamailio TLS configs
    """

    try:
        if len(ip) == 0:
            ip = socket.getaddrinfo(domain, 0, family=socket.AF_INET, flags=socket.AI_CANONNAME)[0][4][0]
        server_config_bytes, client_config_bytes = createCustomTLSConfig(domain, ip, port, server_name_mode)

        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            kamtlscfg_bytes = kamtlscfg_file.read()

            regex = rb'''(####### CUSTOM_DOMAINS_START #########\n.*?####### CUSTOM_DOMAINS_END #########\n?)'''
            custom_tls_bytes = re.search(regex, kamtlscfg_bytes, flags=re.DOTALL).group(1)

            regex = rb'''(?:\n?\[(?:server|client)\:''' + ip.encode('utf-8') + rb'\:' + port.encode('utf-8') + \
                     rb'''\])\n(.*?server_name \= ''' + domain.encode('utf-8') + rb'''.*?)(?=\[|#)'''
            custom_tls_bytes = re.sub(regex, rb''.join([rb'\n', server_config_bytes, client_config_bytes]), custom_tls_bytes, flags=re.DOTALL)

            regex = rb'''(.*)####### CUSTOM_DOMAINS_START #########\n(.*?)####### CUSTOM_DOMAINS_END #########\n?(.*)'''
            kamtlscfg_bytes = re.sub(regex, rb''.join([rb'\1', custom_tls_bytes, rb'\3']), kamtlscfg_bytes, flags=re.DOTALL)
            kamtlscfg_file.seek(0,0)
            kamtlscfg_file.write(kamtlscfg_bytes)

        return True
    except:
        return False

def deleteCustomTLSConfig(domain, ip='', port='5061'):
    """
    Delete an additional domain in kamailio TLS configs
    """

    try:
        if len(ip) == 0:
            ip = socket.getaddrinfo(domain, 0, family=socket.AF_INET, flags=socket.AI_CANONNAME)[0][4][0]
        with open(settings.KAM_TLSCFG_PATH, 'r+b') as kamtlscfg_file:
            kamtlscfg_bytes = kamtlscfg_file.read()

            regex = rb'''(####### CUSTOM_DOMAINS_START #########\n.*?####### CUSTOM_DOMAINS_END #########\n?)'''
            custom_tls_bytes = re.search(regex, kamtlscfg_bytes, flags=re.DOTALL).group(1)

            regex = rb'''(?:\n?\[(?:server|client)\:''' + ip.encode('utf-8') + rb'\:' + port.encode('utf-8') + \
                     rb'''\])\n(.*?server_name \= ''' + domain.encode('utf-8') + rb'''.*?)(?=\[|#)'''
            custom_tls_bytes = re.sub(regex, b'', custom_tls_bytes, flags=re.DOTALL)

            regex = rb'''(####### CUSTOM_DOMAINS_START #########\n)(.*?)(####### CUSTOM_DOMAINS_END #########\n?)'''
            kamtlscfg_bytes = re.sub(regex, rb''.join([rb'\1', custom_tls_bytes, rb'\3']), kamtlscfg_bytes, flags=re.DOTALL)
            kamtlscfg_file.seek(0,0)
            kamtlscfg_file.write(kamtlscfg_bytes)

        return True
    except:
        return False
