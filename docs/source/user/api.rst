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

Executing Domains API
---------------------

Every domain has a ``type``:

- ``passthru``: registrations are passed through to a single PBX, ``pbxs`` holds exactly one endpoint id
- ``msteams``: Microsoft Teams Direct Routing, requires a DSIP_MSTEAMS license, ``pbxs`` is ignored
- ``local``: users authenticate against the local subscriber table, calls are sent to the ``pbxs`` endpoints
- ``realtime``: users authenticate against an Asterisk Realtime DB, calls are sent to the ``pbxs`` endpoints

``pbxs`` are endpoint ids (the IDs shown on the endpoint group page). Changes require a Kamailio reload.
Domains created by an endpoint group (FusionPBX sync) are listed with ``"editable": false`` and can not be
changed through this API.

List all domains, or only one type:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET https://$DSIP_HOSTNAME:5000/api/v1/domains
    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET "https://$DSIP_HOSTNAME:5000/api/v1/domains?type=local"

Create a pass-thru domain:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"domain":"pbx.example.com","type":"passthru","pbxs":[12],"notes":"Main PBX"}' \
         https://$DSIP_HOSTNAME:5000/api/v1/domains

Create several domains at once (all or none are created):

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X POST -d '{"domain":["a.example.com","b.example.com"],"type":"local","pbxs":[12,13]}' \
         https://$DSIP_HOSTNAME:5000/api/v1/domains

Update a domain (any subset of ``domain``, ``type``, ``pbxs``, ``notes``, ``dispatcher_alg``), the id is kept:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"pbxs":[13],"notes":"moved"}' https://$DSIP_HOSTNAME:5000/api/v1/domains/<id>

Delete a domain (its dispatcher set and, for MSTeams, its endpoint group are removed too):

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X DELETE https://$DSIP_HOSTNAME:5000/api/v1/domains/<id>

Further Reading
+++++++++++++++

All available routes are documented in the :doc:`routes documentation <../routes/index>`.
