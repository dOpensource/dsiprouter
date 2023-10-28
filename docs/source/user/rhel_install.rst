.. _rhel_install:

Installing on a RHEL-based Distro
=================================

For a specific version of dSIPRouter add "-b <version number>" to the end of the `git clone` command.

Make sure to **set the hostmane to a fully qualified domain name (FQDN)** that has DNS records pointed at the server (like sbc.yourdomain.com) prior to installation.
The average install time is between 9-12 minutes depending on the resources on your vm/server and the options your specify.

Install (Don't Proxy audio (RTP) traffic)
-----------------------------------------

.. code-block:: bash

  yum install -y git
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install


One Line Version:

.. code-block:: bash

   yum install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git && cd dsiprouter && ./dsiprouter.sh install -kam -dsip


Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.

Install (Proxy audio (RTP) traffic)
-----------------------------------

If you need to proxy RTP traffic then use -all install option. The command to install dSIPRouter and the RTPEngine would be:


.. code-block:: bash

  yum install -y git
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install -all


One Line Version:

.. code-block:: bash

  yum install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git && cd dsiprouter && ./dsiprouter.sh install -all

The install script will automatically determine if the server is behind NAT.
Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.
