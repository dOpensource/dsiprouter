.. _cdrs:

Call Detail Records
^^^^^^^^^^^^^^^^^^^

The Call Detail Records (CDR) page lists the calls of an endpoint group.

1) Select the endpoint group. Its calls are listed with the start time, duration and direction of each call, the gateway groups, usernames and addresses the call came from and went to, and the Call ID.

2) The Filter Calls switch selects between all calls and the billable calls only.

3) The refresh button loads the calls again. The download button saves the calls that are listed as a CSV file.

The list can be searched, sorted by any column and paged.

Viewing a Call in Homer
-----------------------

When dSIPRouter is integrated with Homer (it was installed with the ``-homer`` option, which sets ``HOMER_HEP_HOST``), the Call ID of each call is a link.
The link opens the call in Homer in a new tab, searching for the Call ID in a time window around the call.

CDRs via the API
----------------

The CDRs of an endpoint group can be retrieved for a date and time range with the API, see :doc:`api`.
