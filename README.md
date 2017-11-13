## dSIPRouter by dOpenSource | a Flyball Company [ Built in Detroit ]

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into a easy to to use SIP trunking service, which enables three different use cases:

- Providing SIP Trunking services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc
- Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX. We have an integration with FusionPBX that make this really easy and scalable!
- Both use cases above

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

The install command will install dSIPRouter (will not proxy audio (RTP) traffic). 

```
./dsiprouter.sh install
```
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
### Run At Startup:

Put this line in /etc/rc.local

<your directory>/dsiprouter.sh start

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

#### Inbound Mapping Screen
![dSIPRouter Inbound Mapping Screen](/docs/images/dsiprouter-inboundmapping.jpg)

#### Outbound Routing Screen
![dSIPRouter Outbound Routing Screen](/docs/images/dsiprouter-outboundrouting.jpg)
