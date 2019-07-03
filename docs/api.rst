API
===

The steps to obtain the API Token key and using the different curl commands are listen below.

Note: Make sure to to ssh into your serve to run these commands.

Getting Your Token
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  cat /opt/dsiprouter/gui/settings.py | grep API_TOKEN


Executing Kamailio stats API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash
  
  curl -H "Authorization: Bearer $DSIP_TOKEN" 
  -X GET http://<addressOfYourInstance>:5000/api/v1/kamailio/stats

One Line Version:

.. code-block:: bash
  
  curl -H "Authorization: Bearer $DSIP_TOKEN" -X GET http://<addressOfYourInstance>:5000/api/v1/kamailio/stats


Executing Lease Point API
^^^^^^^^^^^^^^^^^^^^^^^^^
Getting the endlease

.. code-block:: bash
 
 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" 
 -X GET "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease?ttl=15&email=mack@dsiprouter.org"


One Line Version:

.. code-block:: bash

 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X GET "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease?ttl=15&email=mack@dsiprouter.org"

Revoking and replacing with your own lease ID

.. code-block:: bash
 
 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" 
 -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/<leaseid>/revoke"


One Line Version:

.. code-block:: bash

 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/<leaseid>/revoke"
