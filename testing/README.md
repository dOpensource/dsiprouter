# Testing dSIPRouter

This directory contains a number of scripts that contains Unit Test for testing dSIPRouter
functionality.  

## Execute all Unit Tests

```
make all
```

## Execute a Single Unit Tests

```
make run UNIT=1.sh
```

## List of Unit Tests

Contains the Unittest number and a description of what the tests validates

|      Unittest Number      |             Test Description             |
|:-------------------------:|:----------------------------------------:|
|0|syslog is started|
|1|mysql is started|
|2|dsip-init is started|
|3|kamailio is started|
|4|dsiprouter is started|
|5|rtpengine is started|
|6|PBX and Endpoint Registration|
|7|SIP INVITE with Username/Password Auth|
|8|DoS and SIP Security - Block Unknown IP|
|9|CDR data is stored on SIP INVITE **(dev)**|
|10|AWS instance deployment requirements satisfied|
|11|dSIPRouter GUI login|
|12|dSIP Custom Routing|
|13|FusionPBX Sync Module|
|14|Domain Auth|
|15|Flowroute DID Sync Module|
|16|Sending JSONRPC Commands to Kamailio|
|17|Domain Pass-Thru using FreePBX|
|18|DoS and SIP Security - Doesn't Block Known Carrier IP(s)|
|19|dSIPRouter API|
|20|DNSmasq is started|
|21|DNS Resolver Test|
**More to come
