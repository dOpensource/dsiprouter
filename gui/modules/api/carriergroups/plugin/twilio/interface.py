import os
from twilio.rest import Client

# Metadata about plugin
plugin_version = 1.0
plugin_name = "twilio"
default_twilio_domain_name = "pstn.twilio.com"


# Get plugin meta data
def getPluginMetaData():
    return "{'authfields': ['account_sid':'string','account_token':'string']}, \
             'prefix': '+', \
            }"

# Initializes the plugin
def init(account_sid,auth_token):
    
    
    try:

        # Find your Account SID and Auth Token at twilio.com/console
        # and set the environment variables. See http://twil.io/secure
        account_sid = os.environ['TWILIO_ACCOUNT_SID'] if account_sid == None else account_sid
        auth_token = os.environ['TWILIO_AUTH_TOKEN'] if auth_token == None else auth_token
    
        client = Client(account_sid, auth_token)
        return client
    
    except KeyError as ke:
        print("The {} key is not set".format(ke))

    except Exception as ex:
        raise Exception( type(ex).__name__ + "-" + str(ex))
        print(ex)
        return False


def createTrunk(client,trunk_name,dsip_ip_address,twilio_domain_name=default_twilio_domain_name):

    try:
        # Convert trunk name to a lower case
        trunk_name = trunk_name.lower()
        fqdn_domain_name = "{}.{}".format(trunk_name,twilio_domain_name)
        trunk = client.trunking.trunks.create(friendly_name=trunk_name,domain_name=fqdn_domain_name)
       
        if trunk:
            trunk.ip_access_control_lists.create(createIPAccessControlList(client,trunk_name,dsip_ip_address))
   
    except Exception as ex:
        raise Exception( type(ex).__name__ + "-" + str(ex))

    return trunk.sid

def createIPAccessControlList(client,trunk_name,dsip_ip_address):

    ip_access_control_list = client.sip \
                                .ip_access_control_lists \
                                .create(friendly_name=trunk_name)


    ip_address = client.sip \
            .ip_access_control_lists(ip_access_control_list.sid) \
            .ip_addresses \
            .create(friendly_name=trunk_name, ip_address=dsip_ip_address)


    return ip_access_control_list.sid

# Used for unit testing

def main():

    trunk_name="dSIPRouter"
    dsip_ip_address="138.197.157.191/32"
    try:
        if init():
            createTrunk(trunk_name, dsip_ip_address)
    except Exception as ex:
        print(ex)

if __name__ == "__main__":
    main()
