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

### Prerequisites:

- Must run this as the root user (you can use sudo)
- git needs to be installed
- python version 3.0 or older

**On Debian 8.9:**

- Kamailio will be automatically installed along with dSIPRouter.  Just click "enter" and "y" to not have a ROOT password on mysql and to accept all of the default settings.  In the future we will enter all of these settings on your behalf.

**On CentOS 7.x:**

- Kamailio needs to be installed with the default kamailio configuration directory
- You will need your kamailio database credentials.


### Installing and Running It:

#### Install (No Proxy audio (RTP) traffic)

```
git clone https://github.com/dOpensource/dsiprouter.git
cd dsiprouter
./dsiprouter.sh install
```

#### Install (Proxy audio (RTP) traffic)

If you need to proxy RTP traffic then add the -rtpengine parameter.  So, the command to install dSIPRouter and the RTPEngine would be

```
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

### Change Configuration Parameters

To change the configuration settings edit `gui/settings.py` file, e.g. `vi ./gui/settings.py`

* USERNAME - web gui username
* PASSWORD - web gui password
* DSIP_PORT - port on which web gui is running, 5000 by default
* DOMAIN - the domain used to create usernames for PBX and Endpoint registration.  

You will need to restart dSIPRouter for the changes to take effect.

### Screenshots

#### Carrier Management Screen
![dSIPRouter Carrier Screen](/docs/images/dsiprouter-carriers.jpg)

#### PBX(s) and Endpoint Management Screen
![dSIPRouter PBX Screen](/docs/images/dsiprouter-pbxs.jpg)

#### PBX(s) and Endpoint IP or Credential Based Authentication
![dSIPRouter PBX Screen](/docs/images/dsiprouter-pbx-auth.jpg)

#### FusionPBX Domain Support
![dSIPRouter FusionPBX Domain Support Screen](/docs/images/dsiprouter-fusionpbx_domain_support.jpg)


#### Inbound Mapping Screen
![dSIPRouter Inbound Mapping Screen](/docs/images/dsiprouter-inboundmapping.jpg)

#### Outbound Routing Screen
![dSIPRouter Outbound Routing Screen](/docs/images/dsiprouter-outboundrouting.jpg)

### License

* Apache License 2.0, [read more here](./LICENSE)
