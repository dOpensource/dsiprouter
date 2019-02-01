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

Unittest Number | Test Description
================|=====================
1|Used for testing if Kamailio is started
2|Testing PBX and Endpoint Registration
3|Send a call thru a carrier that we use Username/Password Auth (still is dev)
4|Denial of Service (DoS) using the Pike module with a Htable to store the banned ip's
