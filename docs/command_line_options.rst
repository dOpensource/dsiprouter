Command Line Options 
==========================

Implement "./dsiprouter sh" followed by one of the listed options for the dsiprouter command lines.

===================================  ======================================================================================================
Option                               What does it do?                                 
install [-rtpengine]                 installs dSIPRouter and the RTPEngine if you need to proxy RTP traffic.
install  [-rtpengine] [-servernat]   installs dSIPRouter and the RTPEngine if you need to proxy RTP traffic thats behind a NAT
start                                Starts dSIPRouter 
stop                                 Stops dSIPRouter from running                  
restart                              Restarts DSIPRouter after a stop
uninstall                            Uninstalls dSIPRouter 
===================================  ======================================================================================================

Refer to ::ref:`Installing dSIPRouter<installing.rst/install_option.rst>` to get the complete one line version of the command.

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





