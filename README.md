# dSIPRouter Enterprise

Provides enterprise features for the dsiprouter platform, in independent modules.
The following features are currently supported:

- mysql Active-Active replication
- pacemaker / corosync Active-Passive floating IP

## Installation Notes

- Each module deploys from an edge server that can connect through ssh to all nodes
- Currently 2 node clusters are tested

### SSH Authentication Methods

1. public key
2. password
