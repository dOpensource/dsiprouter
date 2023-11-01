Troubleshooting
===============

Here you can troubleshoot logs for dSIPRouter, Kamailio and rtpengine:

All of our services are using syslog. For more information on `syslog <https://www.rsyslog.com/doc/master/index.html>`_ click here.

Default log facilities:

============  ==========
Log Facility  Service
============  ==========
local0        kamailio
local1        rtpengine
local2        dsiprouter
============  ==========

Kamailio Logging
----------------

1. How to turn logging on

Edit /etc/rsyslog.d/kamailio.conf and ensure the line beginning with local0 is not commented out:

.. code-block:: bash

    vi /etc/rsyslog.d/kamailio.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

2. How to turn logging off

Edit /etc/rsyslog.d/kamailio.conf and ensure the line beginning with local0 is commented out:

.. code-block:: bash

    vi /etc/rsyslog.d/kamailio.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

3. Location of the log files

The default location is found here: /var/log/kamailio.log

4. How to configure it

Edit /etc/kamailio/kamailio.conf and change the variable ‘debug’ to the syslog logging verbosity of your choice.

.. code-block:: bash

    vi /etc/kamailio/kamailio.conf

5. For more information see the documentation below:

https://www.kamailio.org/wiki/tutorials/3.2.x/syslog

RTPEngine Logging
-----------------

1. How to turn logging on

Edit /etc/rsyslog.d/rtpengine.conf and ensure the line beginning with local1 is not commented out:

.. code-block:: bash

    vi /etc/rsyslog.d/rtpengine.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

2. How to turn logging off

Edit /etc/rsyslog.d/rtpengine.conf and ensure the line beginning with local1 is commented out:

.. code-block:: bash

    vi/etc/rsyslog.d/rtpengine.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

3. Location of the log files

The default location is found here: /var/log/rtpengine.log

4. How to configure it

Edit /etc/rtpengine/rtpengine.conf and change the variable ‘debug’ to the syslog logging verbosity of your choice.

.. code-block:: bash

    vi /etc/rtpengine/rtpengine.conf

**5. For more information see the documentation below:**

https://github.com/sipwise/rtpengine

dSIPRouter Logging
------------------

1. How to turn logging on

Edit /etc/rsyslog.d/dsiprouter.conf and ensure the line beginning with local2 is not commented out:

.. code-block:: bash

    vi /etc/rsyslog.d/dsiprouter.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

2. How to turn logging off

Edit /etc/rsyslog.d/dsiprouter.conf and ensure the line beginning with local2 is commented out:

.. code-block:: bash

    vi /etc/rsyslog.d/dsiprouter.conf

Then restart syslog:

.. code-block:: bash

    systemctl restart rsyslog

3. Location of the log files

The default location is found here: /var/log/dsiprouter.log

4. How to configure it

Edit /etc/dsiprouter/gui/settings.py and change the variable ‘DSIP_LOG_LEVEL’ to the syslog logging verbosity of your choice.

.. code-block:: bash

    vi /etc/dsiprouter/gui/settings.py

**5. For more infornation see the documentation below:**

https://success.trendmicro.com/solution/TP000086250-What-are-Syslog-Facilities-and-Levels
