Installing dSIPRouter
=====================

Install dSIPRouter takes approximately 4-9 minutes to install.  The following video shows you the install process:

.. raw:: html

        <object width="560" height="315"><param name="movie"
        value="https://www.youtube.com/embed/Iu4BQkL1wGc"></param><param
        name="allowFullScreen" value="true"></param><param
        name="allowscriptaccess" value="always"></param><embed
        src="https://www.youtube.com/embed/Iu4BQkL1wGc"
        type="application/x-shockwave-flash" allowscriptaccess="always"
        allowfullscreen="true" width=""
        height="385"></embed></object>



Prerequisites:
^^^^^^^^^^^^^^

- Must run this as the root user (you can use sudo)
- git and curl needs to be installed
- python version 3.4 or older


OS Support
^^^^^^^^^^

- **Debian Stretch (tested on 9.6)**
- **CentOS 7**

Kamailio will be automatically installed along with dSIPRouter.  Must be installed on a fresh install of Debian Stretch or CentOS 7.  You will not be prompted for any information.  It will take anywhere from 4-9 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.


Install Options
^^^^^^^^^^^^^^^^

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic) 
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

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
