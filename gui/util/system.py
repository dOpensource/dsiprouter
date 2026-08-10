# make sure the generated source files are imported instead of the template ones
import os
import sys


if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import psutil
import requests
import subprocess
from werkzeug import exceptions as http_exceptions
from util.security import AES_CTR
import settings

class dSIPComponent:
    product_name = ""
    type = ""
    version = ""
    status = ""
    location = ""

    def __init__(self, name, type, version, status, location="local"):
        self.name = name
        self.type = type
        self.version = version
        self.status = status
        self.location = location

class dSIPAlert:
    type = ""
    title = ""
    message = ""

    def __init__(self, type, title, message):
        self.type = type
        self.title = title
        self.message = message      


def system_info():

   
    data = {'components': [], 'alerts': []}

    
     # Check if Kamailio is running
    result = subprocess.run(["pgrep", "-f", "kamailio"], capture_output=True, text=True) 
    kamailio_status = "Running" if result.stdout is not None and result.stdout.strip() != "" else "Not Running"

    # Get Kamailio version
    result = subprocess.run(["kamailio", "-v"], capture_output=True, text=True) 
    
    # Only using waiting stat for now, but we can easily add more if needed
    kamailio_version = result.stdout.strip().split()[2] if result.stdout is not None else "Unknown"

    kamailio_component = dSIPComponent("Kamailio", "SIP Server", kamailio_version, kamailio_status)
    data['components'].append(kamailio_component.__dict__)
    

    # RTPEngine Version
    version = "Unknown"
    status = "Unknown"
    if os.path.exists("/etc/dsiprouter/.rtpengineinstalled"):
        try:
            result = subprocess.run(["rtpengine", "-v"], capture_output=True, text=True)
        except FileNotFoundError:
            # RTPEngine is not installed or not found in the system PATH
            dsip_alert = dSIPAlert("error", "RTPEngine Error", "RTPEngine is not installed or not found in the system PATH. Please install RTPEngine and make sure it's in the system PATH.")
            data['alerts'].append(dsip_alert.__dict__)
            rtpengine_component = dSIPComponent("RTPEngine", "Media Proxy", version, status)
            data['components'].append(rtpengine_component.__dict__)
            result = None
            pass

          
        if result is not None and result.returncode == 0:
            
            # Future proofing this. stderr is used, but they may switch to stdout which is why I'm checking both. Also, if they change the output format, this will still work as long as the version is the second word in the output.
            if result.stdout is not None and result.stdout.strip() != "":
                version = result.stdout.strip().split()[1]  # Assuming the version is the second word in the output
            else:
                version = result.stderr.strip().split()[1]  # Assuming the version is the second word in the output
        
            # Check if RTPEngine is running by checking for the rtpengine process. This isn't the most elegant way to do it, but RTPEngine doesn't have a built-in
            # way to check if it's running that I could find, and this is a simple way to do it without adding any additional dependencies.
            result = subprocess.run(["pgrep", "-x", "rtpengine"], capture_output=True, text=True) 
            status = "Running" if result.stdout is not None and result.stdout.strip() != "" else "Not Running"  

            rtpengine_component = dSIPComponent("RTPEngine", "Media Proxy", version, status)
            data['components'].append(rtpengine_component.__dict__)
       
            
        
    
    # dSIPRouter Version
    result = subprocess.run(["pgrep", "-f", "dsiprouter"], capture_output=True, text=True) 
    dsiprouter_component = dSIPComponent("dSIPRouter", "UI", settings.VERSION, "Running" if result.stdout is not None and result.stdout.strip() != "" else "Not Running")
    data['components'].append(dsiprouter_component.__dict__)

    # MySQL Version
    # Check if MySQL is running locally or remotely
    if settings.KAM_DB_HOST == 'localhost' or settings.KAM_DB_HOST == '127.0.0.1':
        db_location = "local"
    else:
        db_location = "remote"
    
    # Connect to database using Kam credentials and get version.  Can't connect as root because dSIPRouter runs as a non-root user  and doesn't have access to the root credentials.
    result = subprocess.run(["mysql", "-h", settings.KAM_DB_HOST, "-u", settings.KAM_DB_USER, "-p" + AES_CTR.decrypt(settings.KAM_DB_PASS), "-N","-e SELECT VERSION();"], capture_output=True, text=True)
    if result.returncode != 0:
        # MySQL is not installed or not found in the system PATH
        database_type = "Unknown"
        version = "Unknown"
        db_status = "Unknown"
        alert = {}
        alert['type'] = "error"
        alert['title'] = "Database Error"
        alert['message'] = result.stderr.strip()
        data['alerts'].append(alert)

    else:
        if result.stdout is not None and result.stdout.strip() != "":
            database_type = result.stdout.strip().split("-")[1]
            version = result.stdout.strip().split("-")[0]
            db_status = "Running"
        else:
            database_type = "Unknown"
            version = "Unknown"
            db_status = "Unknown"

        
    mysql_component = dSIPComponent("Database", database_type, version, db_status, db_location)
    data['components'].append(mysql_component.__dict__)
           


    

    return data
    #return {
    #    'cpu_percent': psutil.cpu_percent(),
    #    'memory_percent': psutil.virtual_memory().percent,
    #    'disk_percent': psutil.disk_usage('/').percent,
    #    'network_sent': psutil.net_io_counters().bytes_sent,
    #    'network_recv': psutil.net_io_counters().bytes_recv
    #}

# MySQL Version
# Then Status of each service (running, stopped, etc.)

if __name__ == "__main__":
    print(system_info())