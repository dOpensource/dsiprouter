.. _debian10-install:

Debian 10/11 Install
=================

Note that this only covers one configuration with RTP traffic proxied. Contributions of additional configurations are welcome if you have tested them!

Make sure to **set the hostmane to a fully qualified domain name (FQDN)** that has DNS records pointed at the server (like sbc.yourdomain.com) prior to installation. The average install time is between 9-12 minutes depending on the resources on your vm/server and the options your specify.

Set the Hostname 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code-block:: bash
  
  hostnamectl set-hostname <hostname>
  

Install (Don't Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  apt-get update -y
  apt-get install -y git
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install -kam -dsip


One Line Version:

.. code-block:: bash

  apt-get update -y && apt-get install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git && cd dsiprouter && ./dsiprouter.sh install -kam -dsip


Install (Proxy audio (RTP) traffic)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you need to proxy RTP traffic then use -all install option. The command to install dSIPRouter and the RTPEngine would be:


.. code-block:: bash

  apt-get update -y
  apt-get install -y git
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install -all


One Line Version:

.. code-block:: bash

  apt-get update -y && apt-get install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git && cd dsiprouter && ./dsiprouter.sh install -all


Install (Proxy audio (RTP) traffic with PBX and dSIPRouter behind NAT)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you have a requirement where the PBX's and dSIPRouter are behind NAT then use the steps below, which are the same as above, but you will add a -servernat parameter.

.. code-block:: bash

  apt-get update -y
  apt-get install -y git
  cd /opt
  git clone https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install -all -servernat


One Line Version:

.. code-block:: bash

  apt-get update -y && apt-get install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git && cd dsiprouter && ./dsiprouter.sh install -all -servernat
  
 
Once the install is complete, dSIPRouter will automatically start MySQL, Kamailio and the UI.
