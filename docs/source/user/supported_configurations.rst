.. _supported_configurations

Supported Configurations
========================


Pass Thru to PBX Authentication Supported Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

================   =================   =====================   =================   =================   =================   ==========
PBX Distribution    PBX Version        Driver Type / Version     Phone Tested      Registration Test    Ext to Ext Test       Notes 
================   =================   =====================   =================   =================   =================   ==========
FreePBX            Asterisk 13.22.0    chan_sip                                          Pass                 Pass             see :ref:`enabling-the-path-header-for-asterisk-chan_sip`
FreePBX            Asterisk 16.9.0     chan_pjsip 2.9, 2.10    Yealink T54W, T46S        Pass                 Pass       
FusionPBX          FreeSWITCH 1.6      Sofia                   Polycom VVX 410           Pass                 Pass  
================   =================   =====================   =================   =================   =================   ==========


.. _enabling-the-path-header-for-asterisk-chan_sip:

Enabling the Path Header for Asterisk chan_sip  
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. Login into the FreePBX Admin GUI

2. Click Settings -> Asterisk SIP Settings

3. Click Chan SIP Settings

4. Find the "Other SIP Settings" field 
   
5. Add the following field and click "Add Field"

   supportpath = yes

6. Click Submit

7. Click the red "Apply" settings button at the very top of the page
