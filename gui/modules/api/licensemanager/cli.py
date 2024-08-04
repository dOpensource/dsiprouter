# TODO: this is an ugly implementation but better than inline python in the shell script
#       marked for refactoring in v0.80

import csv, os, sys
DSIP_PROJECT_DIR = os.environ.get('DSIP_PROJECT_DIR', '/opt/dsiprouter')
DSIP_SYSTEM_CONFIG_DIR = os.environ.get('DSIP_SYSTEM_CONFIG_DIR', '/etc/dsiprouter')
sys.path = [
    f'{DSIP_SYSTEM_CONFIG_DIR}/gui',
    f'{DSIP_PROJECT_DIR}/gui',
    f'{DSIP_PROJECT_DIR}/gui/modules/api/licensemanager'
] + sys.path[1:]
if __name__ == '__main__':
    __package__ = 'modules.api.licensemanager'
import settings
from shared import IO
from .classes import WoocommerceLicense
from .functions import getLicenseStatus, licenseDictToStateDict, searchLicenses, addToLicenseStore, removeFromLicenseStore

def main():
    args = sys.argv[1:]

    if len(args) == 0:
        sys.exit(unknownCmd())

    sub_cmd = args.pop(0)

    if sub_cmd == '-retrieve':
        sys.exit(cmdRetrieve(args))
    if sub_cmd == '-list':
        sys.exit(cmdList(args))
    if sub_cmd == '-activate':
        sys.exit(cmdActivate(args))
    if sub_cmd == '-import':
        sys.exit(cmdImport(args))
    if sub_cmd == '-deactivate':
        sys.exit(cmdDeactivate(args))
    if sub_cmd == '-clear':
        sys.exit(cmdClear(args))
    if sub_cmd == '-check':
        sys.exit(cmdCheck(args))
    sys.exit(unknownCmd())

def cmdRetrieve(args):
    if len(args) != 1:
        sys.exit(unknownCmd())
    if args[0][:4] == 'tag=':
        key = None
        tag = args[0][4:]
    else:
        key = args[0]
        tag = None

    if isDsiprouterRunning():
        result = searchLicenses(license_key=key, license_tag=tag)
    else:
        result = searchLicenses(
            license_key=key,
            license_tag=tag,
            state_dict=licenseDictToStateDict(settings.DSIP_LICENSE_STORE)
        )

    if len(result) == 0:
        IO.printwarn('license(s) does not exist on this system')
        return 1

    output_data = []
    for license in result:
        data = dict(license)
        data['tags'] = ','.join(data['tags'])
        output_data.append(data)
    fields = ['id', 'tags', 'expires', 'active', 'valid', 'license_key']
    tsv = csv.DictWriter(sys.stdout, delimiter='\t', quoting=csv.QUOTE_NONE, fieldnames=fields)
    tsv.writeheader()
    for row in output_data:
        tsv.writerow(row)

    return 0

def cmdList(args):
    if len(args) != 0:
        sys.exit(unknownCmd())

    if isDsiprouterRunning():
        result = searchLicenses()
    else:
        result = searchLicenses(state_dict=licenseDictToStateDict(settings.DSIP_LICENSE_STORE))

    output_data = []
    for license in result:
        data = dict(license)
        data['tags'] = ','.join(data['tags'])
        output_data.append(data)
    fields = ['id', 'tags', 'expires', 'active', 'valid', 'license_key']
    tsv = csv.DictWriter(sys.stdout, delimiter='\t', quoting=csv.QUOTE_NONE, fieldnames=fields)
    tsv.writeheader()
    for row in output_data:
        tsv.writerow(row)

    return 0

def cmdActivate(args):
    if len(args) != 1:
        sys.exit(unknownCmd())
    key = args[0]

    if isDsiprouterRunning():
        state_dict = None
        matches = searchLicenses(license_key=key)
    else:
        state_dict = licenseDictToStateDict(settings.DSIP_LICENSE_STORE)
        matches = searchLicenses(license_key=key, state_dict=state_dict)
    if len(matches) == 0:
        license = WoocommerceLicense(license_key=key)
    else:
        license = matches[0]

    license.activate()
    try:
        addToLicenseStore(license, state_dict=state_dict)
    except:
        license.deactivate()
        raise

    IO.printinfo('license successfully activated')
    return 0

def cmdImport(args):
    if len(args) != 1:
        sys.exit(unknownCmd())

    dsip_runnning = isDsiprouterRunning()
    if dsip_runnning:
        state_dict = None
    else:
        state_dict = licenseDictToStateDict(settings.DSIP_LICENSE_STORE)

    with open(args[0], 'r') as fp:
        license_keys = [line.strip() for line in fp]

    for license_key in license_keys:
        if dsip_runnning:
            matches = searchLicenses(license_key=license_key)
        else:
            matches = searchLicenses(license_key=license_key, state_dict=state_dict)
        if len(matches) == 0:
            license = WoocommerceLicense(license_key=license_key)
        else:
            license = matches[0]

        license.activate()
        try:
            addToLicenseStore(license, state_dict)
        except:
            license.deactivate()
            raise

    IO.printinfo('license(s) successfully activated')
    return 0

def cmdDeactivate(args):
    if len(args) != 1:
        sys.exit(unknownCmd())
    if args[0][:4] == 'tag=':
        key = None
        tag = args[0][4:]
    else:
        key = args[0]
        tag = None

    dsip_runnning = isDsiprouterRunning()
    if dsip_runnning:
        state_dict = None
    else:
        state_dict = licenseDictToStateDict(settings.DSIP_LICENSE_STORE)

    if dsip_runnning:
        result = searchLicenses(license_key=key, license_tag=tag)
    else:
        result = searchLicenses(license_key=key, license_tag=tag, state_dict=state_dict)

    if len(result) == 0:
        IO.printwarn('license(s) does not exist on this system')
        return 1

    for license in result:
        license.deactivate()
        try:
            removeFromLicenseStore(license, state_dict=state_dict)
        except:
            license.activate()
            raise

    IO.printinfo('license(s) successfully deactivated')
    return 0

def cmdClear(args):
    if len(args) != 0:
        sys.exit(unknownCmd())

    dsip_runnning = isDsiprouterRunning()
    if dsip_runnning:
        state_dict = None
    else:
        state_dict = licenseDictToStateDict(settings.DSIP_LICENSE_STORE)

    if dsip_runnning:
        result = searchLicenses()
    else:
        result = searchLicenses(state_dict=state_dict)

    if len(result) == 0:
        IO.printwarn('no licenses exist on this system')
        return 0

    for license in result:
        license.deactivate()
        try:
            removeFromLicenseStore(license, state_dict=state_dict)
        except:
            license.activate()
            raise

    IO.printinfo('all system licenses successfully deactivated')
    return 0

def cmdCheck(args):
    if len(args) != 1:
        sys.exit(unknownCmd())
    if args[0][:4] == 'tag=':
        key = None
        tag = args[0][4:]
    else:
        key = args[0]
        tag = None

    if isDsiprouterRunning():
        status = getLicenseStatus(license_key=key, license_tag=tag)
    else:
        state_dict = licenseDictToStateDict(settings.DSIP_LICENSE_STORE)
        status = getLicenseStatus(license_key=key, license_tag=tag, state_dict=state_dict)

    if status == 0:
        IO.printwarn('license does not exist on this system')
        return 1
    if status == 1:
        IO.printwarn('license is present but not active')
        return 1
    if status == 2:
        IO.printwarn('license is present but associated with another machine')
        return 1
    if status == 3:
        IO.printinfo('license is present and active')
        return 0
    IO.printerr('unable to determine status of license')
    return 1

def unknownCmd():
    IO.printerr(f'{sys.argv[0]}: Invalid arguments provided')
    return 1

def isDsiprouterRunning():
    return os.waitstatus_to_exitcode(os.system('systemctl is-active -q dsiprouter')) == 0

def handleFatalException(ex_type, ex_value, ex_tb):
    IO.printerr('A fatal error occurred')
    IO.printerr(str(ex_value))
    sys.exit(1)

if __name__ == '__main__':
    if getattr(sys, 'gettrace', lambda: None)() is None:
        sys.excepthook = handleFatalException
    main()
