#########
Use Cases
#########
This section contains a list of the common use cases that are implemented using dSIPRouter

============
SIP Trunking
============
dSIPRouter enables an organization to start supporting SIP Trunking within minutes.  Here are the steps to set it up

1. Login to dSIPRouter
2. Valiate that your carrier is defined and specified in the Global Outbound Routes.  If not, please follow the steps in the Carrier Groups(carrier_groups.html) and Global Outbound Routes documentation.  
3. Click on PBX's and Endpoints
4. Click "Add" 
5. Enter the following fields

  a) IP Authentication

- Friendly Name
- IP Address

.. image:: images/sip_trunking_ip_auth.png
        :align: center

  b) Username/Password Authentcation

- Friendly Name
- Click the "Username/Password Auth" radio button
- Enter a username in the format of username@domainname.com.  Note, if you don't provide a domain then the domain will 
default to the ip address of the dSIPRouter server.
- Enter a password

.. image:: images/sip_trunking_credentials_auth.png
        :align: center

6. Click "Add"
7. Click "Reload" to make the change active.


===========
PBX Hosting
===========
 FusionPBX 
 ^^^^^^^^^
 Asterisk or FreePBX
 ^^^^^^^^^^^^^^^^^^^
 
 
