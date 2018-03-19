## dSIPRouter by dOpenSource | a Flyball Company [ Built in Detroit ]

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to use SIP Service Provider platform, which enables two basic use cases:

- **SIP Trunking services:** Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc.  We have support for IP and credential based authentication.

- **Hosted PBX services:** Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX. We have an integration with FusionPBX that make this really easy and scalable!

**Follow us at #dopensource on Twitter to get the latest updates on dSIPRouter**

### Supported Platforms:

#### OS Support

You will get the best experience on Debian Stretch!  

- CentOS 7 (tested on 7.3.1611)
- Debian Jessie (tested on 8.9)
- Debian Stretch (tested on 9.3)

#### Kamailio Versions
- Kamailio 4.x (tested on Kamailio 4.4.5, 4.4.6)
- Kamailio 5.1 (only for Debian Stretch)

#### Database Support

- MySQL 5.x 
- MariaDB 10.x

### Prerequisites:

- Must run this as the root user (you can use sudo)
- git and curl needs to be installed
- python version 3.4 or older

**On Debian Stretch 9.x:**

- Kamailio will be automatically installed along with dSIPRouter.  Must be installed on a fresh install of Debian Stretch.  You will not be prompted for any information.  It will take anywhere from 3-5 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.

**On Debian Jessie 8.9:**

- Kamailio will be automatically installed along with dSIPRouter.  Just click "enter" and "y" to not have a ROOT password on mysql and to accept all of the default settings. 

**On CentOS 7.x:**

- Kamailio needs to be installed with the default kamailio configuration directory
- You will need your kamailio database credentials.


### Installing and Running It:

#### Install (No Proxy audio (RTP) traffic)

```
apt-get update
apt-get install -y git curl
git clone https://github.com/dOpensource/dsiprouter.git
cd dsiprouter
./dsiprouter.sh install
```

#### Install (Proxy audio (RTP) traffic)

If you need to proxy RTP traffic then add the -rtpengine parameter.  So, the command to install dSIPRouter and the RTPEngine would be

```
apt-get update
apt-get install -y git curl
git clone https://github.com/dOpensource/dsiprouter.git
cd dsiprouter
./dsiprouter.sh install -rtpengine
```

Once the install is complete, dSIPRouter will automatically start the HTTP server and the RTPEngine if it was installed.    

### Login 

Open a broswer and go to `http://[ip address of your server]:5000`

The username and the dynamically generated password is displayed after the install

### Stopping dSIPRouter:
```
./dsiprouter.sh stop
```

### Starting dSIPRouter:
```
./dsiprouter.sh start
```

### Restarting dSIPRouter:
```
./dsiprouter.sh restart
```

### Run At Startup:

Put this line in /etc/rc.local

```
<your directory>/dsiprouter.sh start
```
* We will provide a systemctl startup/stop script in the near future

### Uninstall
```
./dsiprouter.sh uninstall
```

### Gryphon Teleblock Support

The Gryphon Teleblock services allows a call center to stay in compliance with "DO NOT CALL" lists.  When enabled,
calls are routed to their service.  The service will return a SIP return code.  If the call is on the "DO NOT CALL" list a SIP return code of 403  will be returned and dSIPRouter will send a SIP error message back to the user or the call can be routed to a media server, which will play a message to the user. A SIP return code of 499 means that the call is NOT on the "DO NOT CALL" list and dSIPRouter will route the call to the carrier you have defined.

The settings for this can be found in "Global Outbound Routes".  Note, you can enable this service from GUI and test that it's working as expected.  If you want the service enabled when Kamailio restarts you need to specify the settings in your /etc/kamailio/kamailio.cfg.  The default settings are:

```
teleblock.gw_enabled = 0 desc "Enable Teleblock support"
teleblock.gw_ip = "66.203.90.197" desc "Teleblock IP"
teleblock.gw_port = "5066" desc "Teleblock Port"
teleblock.media_ip = "" desc "Teleblock media ip"
teleblock.media_port = "" desc "Teleblock media port"
```

Change the teleblock.gw_enabled value to a 1, update the gateway ip and port based on what Gryphon provides you and optionally you can specify a media server ip and port that can play a pre-recorded message to a user.  
 

### Change Configuration Parameters

To change the configuration settings edit `gui/settings.py` file, e.g. `vi ./gui/settings.py`

* USERNAME - web gui username
* PASSWORD - web gui password
* DSIP_PORT - port on which web gui is running, 5000 by default
* DOMAIN - the domain used to create usernames for PBX and Endpoint registration.  

#### Gryphon Teleblock Support

* TELEBLOCK_GW_ENABLED  - will enabled teleblock support in the gui
* TELEBLOCK_GW_IP - gateway ip of the teleblock service
* TELEBLOCK_GW_PORT - gateway port of the teleblock services
* TELEBLOCK_MEDIA_IP - ip of a media server that will play messages when a number is on the "DO NOT CALL" list
* TELEBLOCK_MEDIA_PORT - port of the media server

You will need to restart dSIPRouter for the changes to take effect.

### Screenshots

#### Carrier Management Screen
![dSIPRouter Carrier Screen](/docs/images/dsiprouter-carriers.jpg)

#### PBX(s) and Endpoint Management Screen
![dSIPRouter PBX Screen](/docs/images/dsiprouter-pbxs.jpg)

#### PBX and/or Endpoint IP or Credential Based Authentication Input Screen
![dSIPRouter PBX Screen with Auth](/docs/images/dsiprouter-pbx-auth.jpg)

#### FusionPBX Domain Support
![dSIPRouter FusionPBX Domain Support Screen](/docs/images/dsiprouter-fusionpbx_domain_support.jpg)

#### Inbound Mapping Screen
![dSIPRouter Inbound Mapping Screen](/docs/images/dsiprouter-inboundmapping.jpg)

#### Outbound Routing Screen
![dSIPRouter Outbound Routing Screen](/docs/images/dsiprouter-outboundrouting.jpg)

#### Gryphon Teleblock Support
![dSIPRouter Gryphon Teleblock Support](/docs/images/dsiprouter-teleblock.jpg)

### License

* Apache License 2.0, [read more here](./LICENSE)
