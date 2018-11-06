Installing
==========

There are three ways to install dSIPRouter:

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic) 
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

The steps to install each configuration is below.  Note, there are one line versions of the install in each section below.  The average install time is between 4-9 minutes depending on the resources on your vm/server.

 -->Install (Don't Proxy audio (RTP) traffic)


apt-get update 

apt-get install -y git curl

cd /opt

git clone https://github.com/dOpensource/dsiprouter.git

cd dsiprouter

./dsiprouter.sh install


Or the One Line Version: apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd dsiprouter;./dsiprouter.sh install


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
   
Starting dSIPRouter
=====================
  
  .. toctree::
   :maxdepth: 2
   
   starting.rst
  
  
  
-->Login 

Open a broswer and go to `http://[ip address of your server]:5000`

The username and the dynamically generated password is displayed after the install



-->Starting dSIPRouter:

./dsiprouter.sh start



-->Stopping dSIPRouter:

./dsiprouter.sh stop



-->Restarting dSIPRouter:

./dsiprouter.sh restart



-->Run At Startup:

Put this line in /etc/rc.local


<your directory>/dsiprouter.sh start

* We will provide a systemctl startup/stop script in the near future

-->Uninstall

./dsiprouter.sh uninstall

