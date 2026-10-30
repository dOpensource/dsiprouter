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

Executing CDR Retention API
---------------------------

CDRs (the ``cdrs``, ``acc`` and ``missed_calls`` tables) older than ``CDR_RETENTION_DAYS`` are deleted by a cron job
every night at 02:30. ``0`` (the default) keeps CDRs forever. Whole days are kept: with 7 days, everything from
7 days ago at midnight (DB time) onward stays. The settings are stored in the database, so every node sharing it
uses the same values, and only one node runs the job at a time. They can also be changed on the
Settings page, in the "CDR Retention & Webhook" tab.

With ``CDR_ARCHIVE_ENABLED`` each expired day is first uploaded to an S3 bucket (AWS or any S3 compatible service,
such as DigitalOcean Spaces, through ``CDR_S3_ENDPOINT``) as gzipped CSV files named
``<prefix>YYYY/MM/<table>-YYYY-MM-DD.csv.gz``. Rows are only deleted after their upload succeeded; when an upload
fails the remaining CDRs are kept for the next run. A second file for the same day gets a ``.2``, ``.3``, ... suffix
so earlier archives are never overwritten. The secret key is stored encrypted and is never returned by the API.

Show the settings:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X GET https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr

Keep 90 days of CDRs and archive older ones to S3:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"CDR_RETENTION_DAYS":90,"CDR_ARCHIVE_ENABLED":true,"CDR_S3_BUCKET":"my-cdr-archive","CDR_S3_REGION":"us-east-1","CDR_S3_ACCESS_KEY":"<key>","CDR_S3_SECRET_KEY":"<secret>"}' \
         https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr

Check the bucket (writes and deletes a small object), then run the job right away instead of waiting for cron:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X POST https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr/test-s3
    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X POST https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr/run

The job can also be run from the shell: ``sudo -u dsiprouter /opt/dsiprouter/venv/bin/python /opt/dsiprouter/gui/dsiprouter_cron.py cdr purge``

Executing CDR Webhook API
-------------------------

With ``CDR_WEBHOOK_ENABLED`` a cron job sends the CDRs written since the last delivery to ``CDR_WEBHOOK_URL`` every
minute. Each request (``CDR_WEBHOOK_METHOD`` ``POST`` or ``PUT``) carries up to 100 CDRs as a JSON array of ``cdrs``
rows, oldest first, with the header ``X-DSIP-Event: cdr``. ``CDR_WEBHOOK_AUTH`` is ``basic`` (with
``CDR_WEBHOOK_USERNAME`` and ``CDR_WEBHOOK_PASSWORD``, the password is stored encrypted and never returned) or empty
for no authentication.

CDRs only count as sent after the webhook answered with a 2xx, otherwise the same CDRs are sent again on the next run,
so the receiver should treat ``cdr_id`` as unique. Enabling the webhook starts at the newest CDR, older CDRs are not
sent. While the webhook is enabled the retention job never deletes CDRs it has not sent yet.

``CDR_STORE_CDR`` (default ``true``) set to ``false`` deletes each CDR (and its ``acc`` rows) once the webhook accepted
it. It can only be turned off while the webhook is enabled.

Send CDRs to a webhook with basic auth, without keeping them in dSIPRouter:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" \
         -X PUT -d '{"CDR_WEBHOOK_ENABLED":true,"CDR_WEBHOOK_URL":"https://example.com/cdrs","CDR_WEBHOOK_METHOD":"POST","CDR_WEBHOOK_AUTH":"basic","CDR_WEBHOOK_USERNAME":"<user>","CDR_WEBHOOK_PASSWORD":"<password>","CDR_STORE_CDR":false}' \
         https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr

Send an empty array (``X-DSIP-Event: test``) to check the webhook, then send the pending CDRs right away:

.. code-block:: bash

    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X POST https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr/test-webhook
    curl -k -H "Authorization: Bearer $DSIP_TOKEN" -X POST https://$DSIP_HOSTNAME:5000/api/v1/settings/cdr/run-webhook

A CDR in the request body looks like:

.. code-block:: json

    [
        {
            "cdr_id": 1234, "src_username": "1001", "src_domain": "pbx.example.com", "dst_username": "18005551212",
            "dst_domain": "", "dst_ousername": "", "call_start_time": "2026-10-30 14:02:11", "duration": 63,
            "sip_call_id": "a84b4c76e66710", "sip_from_tag": "1928301774", "sip_to_tag": "314159",
            "src_ip": "203.0.113.10", "cost": 0, "rated": 0, "created": "2026-10-30 14:05:00",
            "calltype": "outbound", "fraud": 0, "src_gwgroupid": "12", "dst_gwgroupid": "7"
        }
    ]

Further Reading
+++++++++++++++

All available routes are documented in the :doc:`routes documentation <../routes/index>`.
