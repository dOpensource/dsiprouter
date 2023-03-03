Command Line Options
==========================

Execute "./dsiprouter.sh" followed by one of the listed commands.
**NOTE** Once installed the command will be available globally as *dsiprouter* with tab-completion.

===================================     ======================================================================
Command                                 What does it do?
===================================     ======================================================================
install                                 Installs dSIPRouter and related services
uninstall                               Uninstall dSIPRouter and related services
clusterinstall                          Install dSIPRouter (via SSH) on a cluster of nodes
upgrade                                 Upgrade dSIPRouter platform (requires license)
start                                   Starts dSIPRouter
stop                                    Stops dSIPRouter
restart                                 Restarts dSIPRouter
configurekam                            Reconfigures the Kamailio configuration file based on dSIPRouter settings
configuresslcert                        Reconfigures SSL certificate used by Kamailio and dSIPRouter
renewsslcert                            Renew configured letsencrypt SSL certificate
installmodules                          Install / uninstall dDSIProuter modules
resetpassword                           Generate new random dSIPRouter admin account password
setcredentials                          Set various credentials manually
chown                                   Update file permissions for dSIPRouter and related services
version                                 Show dSIPRouter version
help                                    List all of the options
===================================     ======================================================================

Refer to :ref:`installing_dsiprouter` to get the complete one line version of the command.


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

