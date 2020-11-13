Command Line Options
==========================

Execute "./dsiprouter.sh" followed by one of the listed commands.
**NOTE** Once installed the command will be available globally as *dsiprouter* with tab-completion.

===================================   ======================================================================
Command                               What does it do?
===================================   ======================================================================
install                               Installs dSIPRouter and related components as specified
uninstall                             Uninstall dSIPRouter
start                                 Starts dSIPRouter
stop                                  Stops dSIPRouter from running
restart                               Restarts dSIPRouter after a stop
configurekam                          Reconfigures the Kamailio configuration file based on dSIPRouter Settings
renewsslcert                          Renew configured letsencrypt SSL certificate
installmodules                        Install / uninstall dDSIProuter modules
enableservernat                       Enable Server NAT
disableservernet                      Disable Server NAT
resetpassword                         Generate new random dSIPRouter admin account password
setcredentials                        Set various credentials manually
setkamdbconfig                        Set Kamailio's database connection URI
generatekamconfig                     Generate fresh Kamailio config for dSIPRouter from the template
updatekamconfig                       Update Kamailio config with dynamic values
updatertpconfig                       Update RTPEngine config with dynamic values
updatednsconfig                       Update DNSmasq config with dynamic values
version|-v|--version                  Show dSIPRouter version
help|-h|--help                        List all of the options
===================================   ======================================================================

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

