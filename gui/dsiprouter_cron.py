from modules.fusionpbx.fusionpbx_sync_functions import *
from modules.api.api_cron_functions import *
import settings

if __name__=='__main__':
    #FusionPBX Sync 
    run_sync(settings)

    #Clean up expired leases
    api_cron(settings)
