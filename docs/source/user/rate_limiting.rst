.. _rate_limiting:

Rate Limiting
^^^^^^^^^^^^^

Kamailio counts the SIP requests it receives from each IP address (pike module).
An address that sends more requests than allowed is banned for a period of time, its requests are dropped until the ban ends.
Requests from dSIPRouter itself are not counted.

Changing the Limits
-------------------

1) Click on Rate Limiting in the menu.

2) Change the settings on the Rate Limiting tab and click Save.

3) Reload Kamailio, the UI shows that a reload is required.

===================================     =========     ====================================================================
Setting                                 Default       Description
===================================     =========     ====================================================================
sampling_time_unit                      2             Time unit in seconds used to sample the number of requests from an
                                                      IP address
reqs_density_per_unit                   50            Number of requests per sampling time unit allowed from an IP address
                                                      before it is flagged as a flood
remove_latency                          30            Time in seconds an IP address is kept in memory after its request
                                                      rate dropped back to normal
ipban_period                            300           Time in seconds an IP address is banned once it exceeded the limit
===================================     =========     ====================================================================

The settings are stored in the dSIPRouter config as ``PIKE_SAMPLING_TIME_UNIT``, ``PIKE_REQS_DENSITY_PER_UNIT``, ``PIKE_REMOVE_LATENCY`` and ``PIKE_IPBAN_PERIOD`` and are written to the Kamailio config.

Viewing Banned Hosts
--------------------

The Banned Hosts tab lists the IP addresses that are banned at the moment and the time each ban ends.
