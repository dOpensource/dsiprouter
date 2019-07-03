API
===

+----------+----------------+---------------------------+
| METHODS  | FUNCTIONS      | ENDPOINTS THEY SUPPORT    |
+==========+================+===========================+
| PUT      | Update existing| - /api/v1/endpoint/lease/ |
|          | information at |   <int:leaseid>/revoke    |
|          | endpoint       | - /api/v1/inboundmapping  |
+----------+----------------+---------------------------+
| GET      | Get Information| - /api/v1/kamailio/stats/ |
|          | from Endpoint  | - /api/v1/endpoint/lease/ |
|          |                | - /api/v1/kamailio/reload/|
|          |                | - /api/v1/inboundmapping  |
+----------+----------------+---------------------------+
| POST     | Create new     | - api/v1/endpoint/<int:id>|
|          | information at | - /api/v1/inboundmapping  |
|          | endpoint       |                           |
+----------+----------------+---------------------------+
| DELETE   | Delete         |  - /api/v1/inboundmapping |
|          | information at |                           |
|          | endpoint       |                           |
+----------+----------------+---------------------------+

The steps to obtain the API Token key and using the different curl commands are listen below.

Note: Make sure to to login to your instance via ssh.

Getting Your Token
^^^^^^^^^^^^^^^^^^

::

  DSIP_TOKEN=$(cat /opt/dsiprouter/gui/settings.py | grep API_TOKEN | cut -d "'" -f 2)
|

Executing Kamailio stats API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::
  
  curl -H "Authorization: Bearer $DSIP_TOKEN" 
  -X GET http://demo.dsiprouter.org:5000/api/v1/kamailio/stats
|

One Line Version:
::
  
  curl -H "Authorization: Bearer $DSIP_TOKEN" -X GET http://<addressOfYourInstance>:5000/api/v1/kamailio/stats
|

Executing Lease Point API
^^^^^^^^^^^^^^^^^^^^^^^^^
Getting the endlease
::
 
 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" 
 -X GET "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease?ttl=15&email=mack@dsiprouter.org"
|

One Line Version:
::

 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X GET "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease?ttl=15&email=mack@dsiprouter.org"
|

Revoking and replacing with your own lease ID

::
 
 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" 
 -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/1/revoke"
|

One Line Version:
::

 curl -H "Authorization: Bearer $DSIP_TOKEN" -H "Content-Type: application/json" -X PUT "http://demo.dsiprouter.org:5000/api/v1/endpoint/lease/1/revoke"
|

Inbound Mapping Valid commands
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=1000000" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=1000000" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=abcdef" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" 
    -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=abcdef" -o /dev/null) -ne 200 ] && return 1
|

One Line Version:
::

    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=1000000" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=1000000" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=abcdef" -o /dev/null) -ne 200 ] && return 1
    
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=abcdef" -o /dev/null) -ne 200 ] && return 1
|
