.. _installing_dsiprouter:


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



Install Options
^^^^^^^^^^^^^^^^

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic) 
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

OS Support
^^^^^^^^^^

- **Debian Stretch (tested on 9.6)**
- **CentOS 7**


Kamailio will be automatically installed along with dSIPRouter.  Must be installed on a fresh install of Debian Stretch or CentOS 7.  You will not be prompted for any information.  It will take anywhere from 4-9 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.  Links to the installation documentation are below:

- :ref:`debian9-install`
- :ref:`centos7-install`

Amazon AMI's
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We now provide Amazon AMI's (pre-built images) which allows you to get up and going even faster.  You can find a list of the images `here <https://aws.amazon.com/marketplace/search/results?x=0&y=0&searchTerms=dsiprouter/>`_.  The images are a nominal fee, which goes toward supporting the project.
