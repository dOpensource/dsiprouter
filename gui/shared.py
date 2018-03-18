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


def main():
    print('in main')
    configfile = 'settings.py'
    fields = {}
    fields['TELEBLOCK_GW_ENABLED']=0
    fields['TELEBLOCK_GW_IP']='62.34.24.22'
    updateConfigFile(configfile,fields)

if __name__== "__main__":
      main()
