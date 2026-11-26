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

Executing Outbound Routes API
-----------------------------

List all outbound routes (both simple and LCR):

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET https://$DSIP_HOSTNAME:5000/api/v1/outboundroutes

Create a simple outbound route (matches a To-Prefix to a carrier group):

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"name":"My Route","prefix":"1","gwgroupid":"2"}' \
         https://$DSIP_HOSTNAME:5000/api/v1/outboundroutes

Create an LCR (From-Prefix) outbound route. The presence of ``from_prefix`` promotes the rule to LCR routing and auto-allocates a dynamic groupid in ``[FLT_LCR_MIN, FLT_FWD_MIN)``:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"name":"313 to ATT","from_prefix":"313","prefix":"1","gwgroupid":"2"}' \
         https://$DSIP_HOSTNAME:5000/api/v1/outboundroutes

Update a route (any subset of fields). Sending ``"from_prefix": ""`` demotes an LCR route back to simple:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"priority":5}' https://$DSIP_HOSTNAME:5000/api/v1/outboundroutes/<ruleid>

Delete a route (paired ``dsip_lcr`` row, if any, is removed automatically):

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X DELETE https://$DSIP_HOSTNAME:5000/api/v1/outboundroutes/<ruleid>

Executing Inbound Mapping API
-----------------------------

Map a DID to an endpoint group. ``servers`` takes one or two endpoint group IDs, each prefixed with ``#``:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"did":"13132222223","servers":["#22"],"name":"Main Number"}' \
         https://$DSIP_HOSTNAME:5000/api/v1/inboundmapping

Map a DID with a hard forward. Calls to the DID are forwarded to the ``did`` given in ``hard-forward``.
``carrier_group`` is the name of the carrier group (or endpoint group) the forwarded call is sent to, without it the call is routed by the outbound routes:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"did":"13132222223","servers":["#22"],"name":"Main Number","hard-forward":{"did":"13135555555","carrier_group":"My Carrier"}}' \
         https://$DSIP_HOSTNAME:5000/api/v1/inboundmapping

Add, change or remove the hard forward of an existing mapping. The mapping is selected with ``ruleid`` or ``did``, sending ``"hard-forward": null`` removes the hard forward:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"hard-forward":{"did":"13135555555"}}' \
         "https://$DSIP_HOSTNAME:5000/api/v1/inboundmapping?did=13132222223"

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"hard-forward":null}' \
         "https://$DSIP_HOSTNAME:5000/api/v1/inboundmapping?did=13132222223"

List the mappings. Each mapping is returned with its ``hard-forward``, which is ``null`` when none is set:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET https://$DSIP_HOSTNAME:5000/api/v1/inboundmapping

A request naming a ``carrier_group`` that does not exist is answered with ``400 Bad Request``.

Executing CDR API
-----------------

Get the CDRs of an endpoint group. ``dt_from`` and ``dt_to`` limit the CDRs to calls that started in that range, both are inclusive and optional.
The accepted formats are ``YYYY-MM-DD``, ``YYYY-MM-DD HH:MM:SS`` and ``YYYY-MM-DDTHH:MM:SS``:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET \
         "https://$DSIP_HOSTNAME:5000/api/v1/cdrs/endpointgroups/<gwgroupid>?dt_from=2026-11-01T00:00:00&dt_to=2026-11-30T23:59:59"

``dtfilter`` is still accepted in place of ``dt_from``, it is ignored when ``dt_from`` is given.
The CDRs are returned as JSON, with ``type=csv`` they are returned as a CSV file.

Managing Users via the API
--------------------------

The ``/api/v1/auth/user`` endpoints require the API token, like the rest of the API.
From a session of the UI they can only be used by users with the ``dsip_admin`` role.

Further Reading
+++++++++++++++

All available routes are documented in the :doc:`routes documentation <../routes/index>`.
