Command Line Options
====================

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
chown                                   Update file permissions for dSIPRouter and related services
configurekam                            Reconfigures the Kamailio configuration file based on dSIPRouter settings
configuredsip                           Reconfigures the dSIPRouter configuration file, updating dynamic settings
renewsslcert                            Renew configured letsencrypt SSL certificate
configuresslcert                        Reconfigures SSL certificate used by Kamailio and dSIPRouter
installmodules                          Install / uninstall dDSIProuter modules
resetpassword                           Generate new random dSIPRouter admin account password
setcredentials                          Set various credentials manually
version                                 Show dSIPRouter version
help                                    List all of the options
===================================     ======================================================================

Refer to :ref:`installing_dsiprouter` to get the complete one line version of the command.


To start dSIPRouter:

.. code-block:: bash

    dsiprouter start

To stop dSIPRouter:

.. code-block:: bash

    dsiprouter stop

To restart dSIPRouter:

.. code-block:: bash

    dsiprouter restart

To uninstall dSIPRouter:

.. code-block:: bash

    dsiprouter uninstall -all
