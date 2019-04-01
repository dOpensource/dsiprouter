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

Refer to :ref:`installing_dsiprouter` to get the complete one line version of the command.


To start dSIPRouter:

::

./dsiprouter.sh start

|

To stop dSIPRouter:

::

./dsiprouter.sh stop

|

To restart dSIPRouter:

::

./dsiprouter.sh restart

|

To uninstall dSIPRouter:

::

./dsiprouter.sh unistall

|





