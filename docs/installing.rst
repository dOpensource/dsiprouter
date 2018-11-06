Prerequisites:


- Must run this as the root user (you can use sudo)
- git and curl needs to be installed
- python version 3.4 or older


OS Support

**Debian Stretch (tested on 9.4)**

Kamailio will be automatically installed along with dSIPRouter.  Must be installed on a fresh install of Debian Stretch.  You will not be prompted for any information.  It will take anywhere from 4-9 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.




**On CentOS 7.x:**

- Kamailio needs to be installed with the default kamailio configuration directory
- You will need your kamailio database credentials.



Database Support

- MariaDB 10.x



Kamailio Versions
- Kamailio 5.1 



Supported Platforms:

We have to limit our offiical support to Debian Stretch with Kamailio 5.1 because we just implemented a new framework for supporting multiple operating systems and different versions of Kamailio and RTPProxy.  But, we only had time to really test Debian Stretch.  Please contribute to the install process by committing code to the project or [purchasing support](https://dopensource.com/shop) so that we can provide more officially supported platform variations and to add additional features to make Kamailio and RTPProxy much easier to learn and use.



Non-Supported Platforms (but might work)

**Debian Jessie 8.x:**

- Kamailio will be automatically installed along with dSIPRouter.  Just click "enter" and "y" to not have a ROOT password on mysql and to accept all of the default settings. 



                              Installing and Running It:

There are three ways to install dSIPRouter:

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic) 
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

The steps to install each configuration is below.  Note, there are one line versions of the install in each section below.  The average install time is between 4-9 minutes depending on the resources on your vm/server.

  Install (Don't Proxy audio (RTP) traffic)

  .. code-block: console
    apt-get update 
    apt-get install -y git curl
    cd /opt
    git clone https://github.com/dOpensource/dsiprouter.git
    cd dsiprouter
    ./dsiprouter.sh install


  One Line Version: 
  .. code-block: console
    apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd    dsiprouter;./dsiprouter.sh install


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.

--> Install (Proxy audio (RTP) traffic)

If you need to proxy RTP traffic then add the -rtpengine parameter. The command to install dSIPRouter and the RTPEngine would be:


apt-get update

apt-get install -y git curl

cd /opt

git clone https://github.com/dOpensource/dsiprouter.git

cd dsiprouter

./dsiprouter.sh install -rtpengine



Or the One Line Version: apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd dsiprouter;./dsiprouter.sh install -rtpengine


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.  But, you will need to reboot the physical server or virtual machine for the RTP Engine to start.  This is a known [issue](https://github.com/dOpensource/dsiprouter/issues/42)   

 -->Install (Proxy audio (RTP) traffic with PBX and dSIPRouter behind NAT)

If you have a requirement where the PBX's and dSIPRouter are behind NAT then use the steps below, which are the same as above, but you will add a -servernat parameter.   


apt-get update

apt-get install -y git curl

cd /opt

git clone https://github.com/dOpensource/dsiprouter.git

cd dsiprouter

./dsiprouter.sh install -rtpengine -servernat

Or the One Line Version: apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd dsiprouter;./dsiprouter.sh install -rtpengine -servernat


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.  But, you will need to reboot the physical server or virtual machine for the RTP Engine to start.  This is a known [issue](https://github.com/dOpensource/dsiprouter/issues/42)
