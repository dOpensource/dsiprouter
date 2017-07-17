## dSIPRouter by dOpenSource

Allows you to quickly turn kamailio into a easy to to use SIP trunking service that allow you to manage your carriers and PBX's from a web gui

### Supported Platforms:

- CentOS 7 (tested on 7.3.1611)
- Kamailio 4.x (tested on Kamailio 4.4.5)

### Prerequisites:

- Must run this as the root user (you can use sudo)
- Kamailio needs to be installed with the default kamailio configurtion directory, which is /etc/kamailio on CentOS 7
- The Kamailio database must be mysql and the root user must be able to access the tables without a password

### Installing and Running It:

./run_dsiprouter.sh 


Open a broswer and go to http://localhost:5000

The username/password is admin/password

The first time it's executed it will attempt to install everything and create a hidden file called ./.installed.  You can remove that file if you want to force a reinstall

### Stopping It:

./stop_dsiprouter.sh


### Run At Startup:

Put this line in /etc/rc.local

<your directory>/run_dsiprouter.sh

* We will provide a systemctl startup/stop script in the near future


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
