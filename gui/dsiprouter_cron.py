#!/usr/bin/env python3
#
# summary:
#   dsiprouter cronjob interface script
# usage:
#   /opt/dsiprouter/gui/dsiprouter_cron.py <module> <command> [<args...>]
# supported modules:
#   api
#   cdr
#   fusionpbx
# supported commands:
#   api         -   cleanleases
#   cdr         -   sendreport <gwgroupid>
#   fusionpbx   -   sync
#

import sys


if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) < 2:
        sys.exit(1)
    mod = args.pop(0)
    cmd = args.pop(0)

    if mod == 'api':
        if cmd == 'cleanleases':
            from modules.api.cron_functions import cleanupLeases
            cleanupLeases()
            sys.exit(0)

    elif mod == 'cdr':
        if cmd == 'sendreport' and len(args) > 0:
            from modules.cdr.cron_functions import sendCdrReport
            gwgroupid = args[0]
            sendCdrReport(gwgroupid)
            sys.exit(0)

    elif mod == 'fusionpbx':
        if cmd == 'sync':
            from modules.fusionpbx.fusionpbx_sync_functions import run_sync
            import settings
            run_sync(settings)
            sys.exit(0)

    sys.exit(1)
