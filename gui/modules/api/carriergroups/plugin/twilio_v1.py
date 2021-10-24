import os
import 
from twilio.rest import Client


twilio_domain_name = "pstn.twilio.com"
name = "dSIPRouter-147182149157"
trunk_name = name
dsip_ip_address = "147.182.149.157"

# Find your Account SID and Auth Token at twilio.com/console
# and set the environment variables. See http://twil.io/secure
account_sid = os.environ['TWILIO_ACCOUNT_SID']
auth_token = os.environ['TWILIO_AUTH_TOKEN']

client = Client(account_sid, auth_token)

def createTrunk():


    try:
        
        fqdn_domain_name = "{}.{}".format(trunk_name,twilio_domain_name)
        trunk = client.trunking.trunks.create(friendly_name=trunk_name,domain_name=fqdn_domain_name)
        
        trunk.ip_access_control_lists.create(createIPAccessControlList())
    
    except Exception as ex:
        print(ex)

    print(trunk.sid)

def createIPAccessControlList():

    ip_access_control_list = client.sip \
                                .ip_access_control_lists \
                                .create(friendly_name=name)


    ip_address = client.sip \
            .ip_access_control_lists(ip_access_control_list.sid) \
            .ip_addresses \
            .create(friendly_name=name, ip_address=dsip_ip_address)


    return ip_access_control_list.sid

# Used for unit testing

def main():

    createTrunk()

if __name__ == "__main__":
    main()
