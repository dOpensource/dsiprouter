#########
Use Cases
#########
This section contains a list of the common use cases that are implemented using dSIPRouter

====================================
SIP Trunking Using IP Authentication
====================================
dSIPRouter enables an organization to start supporting SIP Trunking within minutes.  Here are the steps to set it up using IP Authenication:

1. Login to dSIPRouter
2. Valiate that your carrier is defined and specified in the Global Outbound Routes.  If not, please follow the steps in :ref:`carrier_groups` and/or   :ref:`global_outbound_routes`s documentation.  
3. Click on PBX's and Endpoints
4. Click "Add" 
5. Select IP Authentication and fill in the fields specified below: 
- Friendly Name
- IP Address of the PBX or Endpoint Device

.. image:: images/sip_trunking_ip_auth.png
        :align: center

Username/Password Authentication
===============================
Use the following if you want to use username/password authenication:

- Friendly Name
- Click the "Username/Password Auth" radio button
- Enter a username  
- Enter a domain. Note, you can make up the domain name.  If you don't specify one then the default domain will be used, which is sip.dsiprouter.org by default.
- Enter a password

.. image:: images/sip_trunking_credentials_auth.png
        :align: center

6. Click "Add"
7. Click "Reload" to make the change active.

=====================================
Using SIP Trunking  - FreePBX Example
=====================================

The following screenshot(s) shows how to configure a PJSIP trunk within FreePBX for Username/Password Authentication.  

The first screenshot shows the General tab of the  "pjsip settings" page:

.. image:: images/sip_trunking_freepbx_pjsip_1.png
        :align: center
        
The following fields needs to be entered

==================   ============
Field                Value
==================   ============
Username             Username from dSIPRouter PBX Setup
SIP Server           Domain name defined in the dSIPRouter PBX Setup
SIP Server           SIP port, which is 5060 in dSIPRouter
==================   ============

.. image:: images/sip_trunking_freepbx_pjsip_2.png
        :align: center


The following fields needs to be entered

==================   ============
Field                Value
==================   ============
Outbound Proxy       IP address of dSIPRouter - must include the "\;lr" at the end
From Domain          The name of the domain defined in the dSIPRouter PBX Setup
==================   ============


======================================
Using SIP Trunking - FusionPBX Example
======================================
Coming soon!

===========
PBX Hosting
===========
 FusionPBX 
 ^^^^^^^^^
 Asterisk or FreePBX
 ^^^^^^^^^^^^^^^^^^^
 
