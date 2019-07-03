Command Line Options 
==========================

Execute "./dsiprouter.sh" followed by one of the listed options for the dsiprouter command lines. 
**NOTE** You must be in the directory where dSIPRouter was installed, which is /opt/dsiprouter to execute these commands.

===================================   ======================================================================
Option                                What does it do?                                 
===================================   ======================================================================
install                               Installs dSIPRouter and the RTPEngine if you need to proxy RTP traffic.
uninstall                             Uninstall dSIPRouter 
start                                 Starts dSIPRouter 
stop                                  Stops dSIPRouter from running                  
restart                               Restarts dSIPRouter after a stop
configurekam                          Reconfigures the Kamailio configuration file based on dSIPRouter Settings 
sslenable                             Enables SSL Support
enableservernat                       Enable Server NAT
disableservernet                      Disable Server NAT
resetpassword                         Resets dSIPRouter admin account and displays the password
help|-h|--help                        List all of the options
===================================   ======================================================================

Refer to `debian install <debian_install.rst>`_ or `centos install <debian_install.rst>`_ to get the complete one line version of the command.


To start dSIPRouter:

.. code-block:: bash

  ./dsiprouter.sh start


To stop dSIPRouter:

.. code-block:: bash

  ./dsiprouter.sh stop


To restart dSIPRouter:

.. code-block:: bash

  ./dsiprouter.sh restart


To uninstall dSIPRouter:

.. code-block:: bash

  ./dsiprouter.sh unistall

