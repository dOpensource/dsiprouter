API
===

+----------+----------------+---------------------------------------------------+
| KAMAILIO API                                                                  |
+==========+================+===================================================+
| PUT      | Update existing| N/A                                               |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| GET      | Get Information| - /api/v1/kamailio/stats/                         |
|          | from Endpoint  | - /api/v1/kamailio/reload/                        |
+----------+----------------+---------------------------------------------------+
| POST     | Create new     | N/A                                               |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| DELETE   | Delete         | N/A                                               |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+

+----------+----------------+---------------------------------------------------+
| ENDPOINT API                                                                  |
+==========+================+===================================================+
| PUT      | Update existing| - /api/v1/endpoint/lease/<int:leaseid>/revoke     |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| GET      | Get Information| - /api/v1/endpoint/lease/                         |
|          | from Endpoint  |                                                   |
+----------+----------------+---------------------------------------------------+
| POST     | Create new     | - /api/v1/endpoint/<int:id>                       |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| DELETE   | Delete         | N/A                                               |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+

+----------+----------------+---------------------------------------------------+
| INBOUND MAPPING API                                                           |
+==========+================+===================================================+
| PUT      | Update existing| - /api/v1/inboundmapping                          |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| GET      | Get Information| - /api/v1/inboundmapping                          |
|          | from Endpoint  |                                                   |
+----------+----------------+---------------------------------------------------+
| POST     | Create new     | - /api/v1/inboundmapping                          |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+
| DELETE   | Delete         | - /api/v1/inboundmapping                          |
|          | information at |                                                   |
|          | endpoint       |                                                   |
+----------+----------------+---------------------------------------------------+

The steps to obtain the API Token key and using the different curl commands are listen below.

Note: Make sure to to login to your instance via ssh.

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


Inbound Mapping Valid commands
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

--------------------------
GET /api/v1/inboundmapping
--------------------------

.. code-block:: bash

    curl -X GET -H "Authorization: Bearer ${token}" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping"
    curl -X GET -H "Authorization: Bearer ${token}" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?ruleid=3"
    curl -X GET -H "Authorization: Bearer ${token}" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?did=1313"

---------------------------
POST /api/v1/inboundmapping
---------------------------

.. code-block:: bash

    curl -X POST -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping" -d '{"did": "1313", "servers": ["66","67"], "notes": "1313 DID Mapping"}'
    curl -X POST -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping" -d '{"did": "1313","servers": ["66","67"]}'
    curl -X POST -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping" -d '{"did": "", "servers": ["66"], "notes": "Default DID Mapping"}'

---------------------------
PUT /api/v1/inboundmapping
---------------------------

.. code-block:: bash

    curl -X PUT -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?ruleid=3" -d '{"did": "01234", "notes": "01234 DID Mapping"}'
    curl -X PUT -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?did=1313" -d '{"servers": ["67"]}'
    curl -X PUT -H "Authorization: Bearer ${token}" --connect-timeout 3 -H "Content-Type: application/json" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?did=1313" -d '{"did": "01234", "notes": "01234 DID Mapping"}'

-------------------------------
DELETE /api/v1/inboundmapping
-------------------------------

.. code-block:: bash

    curl -X DELETE -H "Authorization: Bearer ${token}" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?ruleid=3"
    curl -X DELETE -H "Authorization: Bearer ${token}" "http://demo.dsiprouter.org:5000/api/v1/inboundmapping?did=1313"


