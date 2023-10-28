.. _installing_dsiprouter:

Installing dSIPRouter
=====================

The following video shows you the install process:

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/Iu4BQkL1wGc" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 560px; height: 315px;"></iframe>
    </div>

We maintain installation documentation for the following operating systems.  Please open a pull request if you want to add and maintain addtional documentation:

- :ref:`debian_install`
- :ref:`rhel_install`

Install times vary by depending on OS and system hardware.
On debian/centos, expect a short install time, typically around 12 minutes.
On amazon linux, expect long compilation times, typically around 45 minutes.

dSIPRouter should be installed on a clean install of the OS.
To upgrade your dSIPRouter platform, see instead :ref:`upgrading`

Prerequisites:
--------------

- Must run this as the root user (you can use sudo)
- git needs to be installed
- Hostname needs to be set to a FQDN (for certbot to get LetsEncrypt certificate)
- The installer will handle all other dependencies

Install Options
----------------

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic)
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

OS Support
----------

===================================     ================
OS / Distro                             Current Support
===================================     ================
Debian 12 (bookworm)                    STABLE
Debian 11 (bullseye)                    STABLE
Debian 10 (buster)                      STABLE
Debian 9 (stretch)                      DEPRECATED
CentOS 9 (stream)                       STABLE
CentOS 8 (stream)                       STABLE
CentOS 7                                DEPRECATED
RedHat Linux 8                          ALPHA
Alma Linux 8                            ALPHA
Rocky Linux 8                           ALPHA
Amazon Linux 2                          STABLE
Ubuntu 22.04 (jammy)                    ALPHA
Ubuntu 20.04 (focal)                    DEPRECATED
===================================     ================

Amazon AMI's
------------

We now provide Amazon AMI's (pre-built images) which allows you to get up and going even faster.
You can find a list of the images `here <https://aws.amazon.com/marketplace/search/results?x=0&y=0&searchTerms=dsiprouter/>`_.
The images are a nominal fee, which goes toward supporting the project.
