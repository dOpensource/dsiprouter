import settings, re
from configobj import ConfigObj

# Used to update a configuration file with a set of fields and values in the fielddict object

def updateConfigFile(configfile, fielddict):
    try:
        config = ConfigObj(configfile,unrepr=True)
        for x in fielddict:
            config[x]=fielddict[x]
        config.write()
    except:
        print('Problem updating the {0} configuration file').format(configfile)

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

def main():
    print('in main')
    configfile = 'settings.py'
    fields = {}
    fields['TELEBLOCK_GW_ENABLED']=0
    fields['TELEBLOCK_GW_IP']='62.34.24.22'
    updateConfigFile(configfile,fields)

if __name__== "__main__":
      main()
