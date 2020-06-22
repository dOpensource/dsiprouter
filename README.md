# dSIPRouter Platform

> VoIP Service Management Simplified

## Supported Features

- Carrier Management
  - Manage carriers as a group
- Endpoint Management
  - Manage endpoints as a group
  - Call Limiting per Endpoint Group
  - Call Detail Records generation per Endpoint Group
- High Availablity
  - Mysql Active-Active replication
  - Pacemaker / Corosync Active-Passive floating IP
  - Consul DNS Load-balancing and DNS Failover
  - dSIPRouter cluster synchronization
  - Kamailio DMQ replication
- Notification System
  - Over Call Limit Notifications
  - Endpoint Failure Notifications
  - Call Detail Record Notifications
- Enhanced DID Management
  - DID Failover to a Carrier/Endpoint Group or DID
  - DID Hard Forwarding to a Carrier/Endpoint Group or DID
  - Flowroute DID synchronization
- Enhanced Route Management
  - FusionPBX Domain Routing Enhancements
  - Outbound / Inbound DID prefix routing
  - Least Cost Locality Outbound routing
  - Load balancing / sequential routing via groups
  - Integration with your own custom Kamailio routes
  - E911 Priority routing
  - Local Extension routing
  - Voicemail routing
- Security
  - TLS Enabled by Default
  - Rate-limiting / DOS protection
  - Teleblock blacklist support
- Microsoft Teams Support (Subscription Required)
- WebSockets Enabled by Default
- Kamailio 5.3 Support
- RTPEngine Version 6.1 Support

## What is dSIPRouter?

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to use SIP Service Provider platform, which enables two basic use cases:

- **SIP Trunking services:**
Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc.
We have support for IP and credential based authentication.

- **Hosted PBX services:**
Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX.
We have an integration with FusionPBX that make this really easy and scalable!

- **Microsoft Teams Direct Routing:**
We can provide SBC functionality that allows dSIPRouter to interconnect your existing voice infrastructure or VoIP carrier to your Microsoft Teams environment.

- **Web Management Services**
Provide customers the ability to manage signaling, routes, security, CRM, CDR's, logging, and more from the dSIPRouter GUI.
We also make these services available to developers through the dSIPRouter API.

**Follow us at [#dsiprouter](https://twitter.com/dsiprouter) on Twitter to get the latest updates on dSIPRouter**

### Project Web Site

Check out our official website [dsiprouter.org](http://dsiprouter.org)

### Demo System

Try out our demo system [demo.dsiprouter.org](https://demo.dsiprouter.org:5000/)

Demo system GUI Credentials:
- username: `admin`
- password: `ZmIwMTdmY2I5NjE4`

Demo system API Credentials:
- bearer token: `9lyrny3HOtwgjR6JIMwRaMej9LijIS835zhVbD8ywHDzXT07Xm6vem1sgfvWkFz3`

### HA Installation Notes

The highly available mysql and pacemaker modules are installed seperately at this time:

- Both modules are deployed from an edge server that must connect through ssh to all nodes
- Currently 2 node clusters have been thoroughly tested but there is no limit to cluster size.

Supported SSH authentication methods for cluster configuration:

1. public key
2. password

### Documentation

You can find our documentation online: [dSIPRouter Documentation](https://dsiprouter.readthedocs.io/en/latest)
For a list of updates and changes refer to our [Changelog](CHANGELOG.md)

### Contributing

See the [Contributing Guidelines](CONTRIBUTING.md) for more details
A current list of contributors can be found [here](CONTRIBUTORS.md)

### Support

Free Support: [dSIPRouter Question & Answer Forum](https://groups.google.com/forum/#!forum/dsiprouter)
Paid Support: [dSIPRouter Support](https://dsiprouter.org/#fh5co-support-section)

### Training

Details on training can be found [here](https://dopensource.com/product/dsiprouter-admin-course/)

### License

- Apache License 2.0, [read more here](LICENSE)
