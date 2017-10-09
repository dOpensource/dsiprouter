## dSIPRouter by dOpenSource | a Flyball Company
##### [ Built in Detroit ]


Allows you to quickly turn [Kamailio](https://www.kamailio.org/) into a easy to to use SIP trunking service that allow you to manage your carriers and PBX's from a web gui

### Supported Platforms:

- CentOS 7 (tested on 7.3.1611)
- Debian Jessie (tested on 8.9)
- Kamailio 4.x (tested on Kamailio 4.4.5, 4.4.6)

### Prerequisites:

- Must run this as the root user (you can use sudo)
- Kamailio needs to be installed with the default kamailio configurtion directory, which is /etc/kamailio on CentOS 7
- The Kamailio database must be mysql and the root user must be able to access the tables without a password.  You can add a password to the root database user after the installation.   

### Installing and Running It:

The install command will install dSIPRouter. 

./dsiprouter.sh install


If you need to proxy RTP traffic then add the -rtpengine parameter.  So, the command to install dSIPRouter and the RTPEngine would be

./dsiprouter.sh install -rtpengine

Once the install is complete, dSIPRouter will automatically start the Web GUI and the RTPEngine.  

Open a broswer and go to http://[ip address of your server]:5000

The default username/password is admin/password.  

The first time it's executed it will attempt to install everything and create a hidden file called ./.installed.  You can remove that file if you want to force a reinstall

### Stopping dSIPRouter:

./dsiprouter.sh stop

### Run At Startup:

Put this line in /etc/rc.local

<your directory>/dsiprouter.sh start

* We will provide a systemctl startup/stop script in the near future

### Changing Admin Password

navigate to `dsiprouter` directory and  
`vi ./gui/settings.py`
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

### License

* Apache License 2.0, [read more here](./LICENSE)
