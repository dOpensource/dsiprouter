.. _debian9-install:

Debian 9 Install
================

The steps to install each configuration is below.  Note, there are one line versions of the install in each section below.  The average install time is between 4-9 minutes depending on the resources on your vm/server.

Note: You can add a "-b <version number>" to the end of the git command to install and specific version of dSIPRouter.

Install (Don't Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::
 
  apt-get update 
  apt-get install -y git curl
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install
|

One Line Version: 
::
    apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd    dsiprouter;./dsiprouter.sh install


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.

Install (Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you need to proxy RTP traffic then add the -rtpengine parameter. The command to install dSIPRouter and the RTPEngine would be:


::

 apt-get update
 apt-get install -y git curl
 cd /opt
 git clone https://github.com/dOpensource/dsiprouter.git
 cd dsiprouter
 ./dsiprouter.sh install -rtpengine

|


One Line Version: 
::

 apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd dsiprouter;./dsiprouter.sh install -rtpengine


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.  But, you will need to reboot the physical server or virtual machine for the RTP Engine to start.  This is a known `issue <https://github.com/dOpensource/dsiprouter/issues/42>`_ .   

Install (Proxy audio (RTP) traffic with PBX and dSIPRouter behind NAT)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you have a requirement where the PBX's and dSIPRouter are behind NAT then use the steps below, which are the same as above, but you will add a -servernat parameter.   

::

 apt-get update
 apt-get install -y git curl
 cd /opt
 git clone https://github.com/dOpensource/dsiprouter.git
 cd dsiprouter
 ./dsiprouter.sh install -rtpengine -servernat
 
|


One Line Version: 

::

 apt-get update;apt-get install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd dsiprouter;./dsiprouter.sh install -rtpengine -servernat


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.  But, you will need to reboot the physical server or virtual machine for the RTP Engine to start.  This is a known `issue <https://github.com/dOpensource/dsiprouter/issues/42>`_ .  
