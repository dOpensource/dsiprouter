Supported Configurations
========================


Pass Thru to PBX Authentication Supported Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

| PBX Distribution | PBX Version | Driver Type | Registration Test | Extention to Extension Test | Notes |
| FreePBX | Asterisk 13.22.0 | chan_sip | Yes | Yes | Support for the Path header has to be enable.  Instructions can be found here |
| FreePBX | Asterisk 13.22.0 | chan_pjsip |  |  | |
| FusionPBX 4.4.0 | FreeSWITCH 1.6.2 | Sofia | Yes | Yes | 



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
