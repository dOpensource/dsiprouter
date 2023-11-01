dSIPRouter API Intro
====================

The complete API is defined as a public Postman Workspace, which can be found `here <https://www.postman.com/dopensource/workspace/dsiprouter/collection/4319695-9c09dea3-0b4b-4a20-a615-fb8fc16811af?action=share&creator=4319695>`_ 

The steps to obtain the API Token key and examples of using the API via curl are below, but we highly recommend using Postman for testing the API.

Getting Your Token
------------------

Your token was provided to you after you installed dSIPRouter.  You can reset your token if you didn't write it down, by executing the following command

.. code-block:: bash

    DSIP_HOSTNAME=<your ip or hostname>
    DSIP_TOKEN=<your token>
    dsiprouter setcredentials -ac $DSIP_TOKEN

Executing Kamailio stats API
----------------------------

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET https://$DSIP_HOSTNAME:5000/api/v1/kamailio/stats

Executing Lease Point API
-------------------------

Create a new endpoint lease

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X GET "https://$DSIP_HOSTNAME:5000/api/v1/endpoint/lease?ttl=15&email=mack@dsiprouter.org"

Revoking and replacing with your own lease ID

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X PUT "https://$DSIP_HOSTNAME:5000/api/v1/endpoint/lease/1/revoke"

Further Reading
+++++++++++++++

All available routes are documented in the :doc:`routes documentation <../routes/index>`.
