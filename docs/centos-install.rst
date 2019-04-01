
.. _centos7-install:

CentOS 7 Install
================

The steps to install each configuration is below.  Note, there are one line versions of the install in each section below.  The average install time is between 4-9 minutes depending on the resources on your vm/server.

Note: You can add a "-b <version number>" to the end of the git command to install and specific version of dSIPRouter.

Install (Don't Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::
 
  
  yum install -y git curl 
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install -kam -dsip
|

One Line Version: 
::
   yum install -y git curl;cd /opt;git clone https://github.com/dOpensource/dsiprouter.git;cd    dsiprouter;./dsiprouter.sh install -kam -dsip


Once the install is complete, dSIPRouter will automatically start MariaDB, Kamailio and the UI.

Install (Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Not supported yet without paid support

Install (Proxy audio (RTP) traffic with PBX and dSIPRouter behind NAT)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Not supported yet without paid support
