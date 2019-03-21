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
|1|mysql is started|
|2|dsip-init is started|
|3|kamailio is started|
|4|dsiprouter is started|
|5|rtpengine is started|
|6|PBX and Endpoint Registration|
|7|SIP INVITE with Username/Password Auth|
|8|Denial of Service (DoS) using the Pike module bans ip's|
|9|CDR data is stored on SIP INVITE **(dev)**|
