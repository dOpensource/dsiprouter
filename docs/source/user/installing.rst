.. _installing_dsiprouter:


Installing dSIPRouter
=====================

Install dSIPRouter takes approximately 9-12 minutes to install.  The following video shows you the install process:

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
- git needs to be installed
- Hostname needs to be set to a FQDN (for certbot to get LetsEncrypt certificate)
- The installer will handle all other dependencies



Install Options
^^^^^^^^^^^^^^^^

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic)
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

OS Support
^^^^^^^^^^

===================================     ================
OS / Distro                             Current Support
===================================     ================
Debian 11 (bullseye)                    STABLE
Debian 10 (buster)                      STABLE
Debian 9 (stretch)                      STABLE
RedHat Linux 8                          ALPHA
Alma Linux 8                            ALPHA
Rocky Linux 8                           ALPHA
Amazon Linux 2                          STABLE
Ubuntu 22.04 (jammy)                    ALPHA
Ubuntu 20.04 (focal)                    ALPHA
===================================     ================


Kamailio will be automatically installed along with dSIPRouter.
Must be installed on a fresh install of Debian Stretch, Debian Buster or CentOS.
You will not be prompted for any information.  It will take anywhere from  9-12 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.

We maintain installation documentation for the following operating systems.  Please open a pull request if you want to add and maintain addtional documentation:

- :ref:`debian_install`
- :ref:`rhel_install`

Amazon AMI's
^^^^^^^^^^^^

We now provide Amazon AMI's (pre-built images) which allows you to get up and going even faster.
You can find a list of the images `here <https://aws.amazon.com/marketplace/search/results?x=0&y=0&searchTerms=dsiprouter/>`_.
The images are a nominal fee, which goes toward supporting the project.
