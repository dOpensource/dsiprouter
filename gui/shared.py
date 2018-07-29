import settings, re, socket, requests

# Used to grab network info dynamically at startup
# TODO: we need to dynamically set this info for kamailio.cfg file
def getInternalIP():
    ''' Returns current ip of system '''

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]

def getExternalIP():
    ''' Returns external ip of system '''

    ip = requests.get("http://ipv4.myexternalip.com/raw").text.strip()
    if ip == None or ip == "":
        ip = requests.get("http://ipv4.icanhazip.com").text.strip()
    return ip

def getDNSNames():
    ''' Returns ( hostname, domain ) of system '''

    host,domain = socket.getfqdn().split('.', 1)
    if host == None or host == "":
        host,domain = socket.gethostbyaddr(socket.gethostname())[0].split('.', 1)
    if host == None or host == "":
        host,domain = socket.getaddrinfo(socket.gethostname(), 0, flags=socket.AI_CANONNAME)[0][3].split('.', 1)
    return host,domain

def objToDict(obj):
    return dict((key, getattr(obj, key)) for key in dir(obj) if not obj.startswith('__'))

def updateConfig(config_obj, field_dict):
    config_file = "<no filepath available>"
    try:
        config_file = config_obj.__file__

        with open(config_file, 'r+') as config:
            config_str = config.read()
            for key,val in field_dict.items():
                regex = r"^(?!#)(?:" + re.escape(key) + \
                        r")[ \t]*=[ \t]*(?:\w+\(.*\)[ \t\v]*$|\w+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|\"\"\".*\"\"\"[ \t]*$|'''.*'''[ \v]*$|\".*\"[ \t]*$|'.*')"
                replace_str = "{} = {}".format(key, repr(val))
                config_str = re.sub(regex, replace_str, config_str, flags=re.MULTILINE)
            config.seek(0)
            config.write(config_str)
            config.truncate()
    except:
        print('Problem updating the {0} configuration file').format(config_file)

def getCustomRoutes():
    custom_routes = []
    with open(settings.KAM_CFG_PATH, 'r') as kamcfg_file:
        kamcfg_str = kamcfg_file.read()

        regex = r"CUSTOM_ROUTING_START.*CUSTOM_ROUTING_END"
        custom_routes_str = re.search(regex, kamcfg_str, flags=re.MULTILINE|re.DOTALL).group(0)

        regex = r"route\[(\w+)\]"
        matches = re.finditer(regex, custom_routes_str, flags=re.MULTILINE|re.DOTALL)

        for matchnum, match in enumerate(matches):
            if len(match.groups()) > 0:
                custom_routes.append(match.group(1))

        for route in custom_routes:
            print(route)
    return custom_routes
