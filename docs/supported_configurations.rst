Supported Configurations
========================


Pass Thru to PBX Authentication Supported Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

================   =================   ===========   =================   ================   ==========
PBX Distribution    PBX Version        Driver Type   Registration Test   Ext to Ext Test    Notes 
================   =================   ===========   =================   ================   ==========
FreePBX            Asterisk 13.22.0    chan_sip       Pass                  Pass             Support for the Path header needs to be enabled :ref:`enabling-the-path-header-for-asterisk-chan_sip`
FreePBX            Asterisk 13.22.0    chan_pjsip     Not Tested            Not Tested      
FusionPBX          FreeSWITCH 1.6      Sofia          Pass                  Pass  
================   =================   ===========   =================   ================   ==========




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
