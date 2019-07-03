API
===

+----------+----------------+-----------------------------------------------+
| METHODS  | FUNCTIONS      | ENDPOINTS THEY SUPPORT                        |
+==========+================+===============================================+
| PUT      | Update existing| /api/v1/endpoint/lease/<int:leaseid>/revoke   |
|          | information at |                                               |
|          | endpoint       |                                               |
+----------+----------------+-----------------------------------------------+
| GET      | Get Information| /api/v1/kamailio/stats/                       |
|          | from Endpoint  | /api/v1/endpoint/lease/                       |
|          |                | /api/v1/kamailio/reload/                      |
+----------+----------------+-----------------------------------------------+
| POST     | Create new     | /api/v1/endpoint/<int:id>                     |
|          | information at |                                               |
|          | endpoint       |                                               |
+----------+----------------+-----------------------------------------------+

The steps to obtain the API Token key and using the different curl commands are listen below.

Note: Make sure to to ssh into your serve to run these commands.

Getting Your Token
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  DSIP_TOKEN=$(cat /opt/dsiprouter/gui/settings.py | grep API_TOKEN | cut -d "'" -f 2)


Executing Kamailio stats API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash
  
  curl -H "Authorization: Bearer $DSIP_TOKEN"
  -X GET http://demo.dsiprouter.org:5000/api/v1/kamailio/stats


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
 -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/1/revoke"


One Line Version:

.. code-block:: bash

 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/1/revoke"

