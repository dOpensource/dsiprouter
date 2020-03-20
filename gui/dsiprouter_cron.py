from modules.fusionpbx.fusionpbx_sync_functions import run_sync
from modules.api.api_cron_functions import api_cron
import settings

if __name__=='__main__':
    # FusionPBX Sync
    run_sync(settings)
    # Clean up expired leases / Send CDRs
    api_cron()
