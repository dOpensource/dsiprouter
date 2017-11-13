## dSIPRouter by dOpenSource | a Flyball Company [ Built in Detroit ]

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to to use SIP Service Provider, which enables two basic use cases:

- **SIP Trunking services:** Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc
- **Hosted PBX services:** Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX. We have an integration with FusionPBX that make this really easy and scalable!

### Supported Platforms:

#### OS Support

- CentOS 7 (tested on 7.3.1611)
- Debian Jessie (tested on 8.9)

#### Kamailio Versions
- Kamailio 4.x (tested on Kamailio 4.4.5, 4.4.6)
* Kamailio 5.x support is coming very soon

#### Database Support

- MySQL 5.x

### Prerequisites:

- Must run this as the root user (you can use sudo)
- Kamailio needs to be installed with the default kamailio configuration directory
- You will need your kamailio database
  

### Installing and Running It:

#### Install (No Proxy audio (RTP) traffic)

```
./dsiprouter.sh install
```

#### Install (Proxy audio (RTP) traffic)

If you need to proxy RTP traffic then add the -rtpengine parameter.  So, the command to install dSIPRouter and the RTPEngine would be

```
./dsiprouter.sh install -rtpengine
```

Once the install is complete, dSIPRouter will automatically start the Web GUI and the RTPEngine.  

### Login 

Open a broswer and go to http://[ip address of your server]:5000

The default username/password is admin/password.  

### Stopping dSIPRouter:
```
./dsiprouter.sh stop
```

### Starting dSIPRouter:
```
./dsiprouter.sh start
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

### Changing Admin Password

vi ./gui/settings
change the PASSWORD field to reflect the password you want

### Screenshots

#### Carrier Management Screen
![dSIPRouter Carrier Screen](/docs/images/dsiprouter-carriers.jpg)

#### PBX(s) and Endpoint Management Screen
![dSIPRouter PBX Screen](/docs/images/dsiprouter-pbxs.jpg)

#### PBX(s) and Endpoint Management Screen
![dSIPRouter FusionPBX Domain Support Screen](/docs/images/dsiprouter-fusionpbx_domain_support.jpg)

#### Inbound Mapping Screen
![dSIPRouter Inbound Mapping Screen](/docs/images/dsiprouter-inboundmapping.jpg)

#### Outbound Routing Screen
![dSIPRouter Outbound Routing Screen](/docs/images/dsiprouter-outboundrouting.jpg)
