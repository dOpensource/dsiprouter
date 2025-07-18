# dSIPRouter Platform


[<p align="center"><img src="docs/dsiprouter_300px.png" alt="dSIPRouter Logo" width="300"/></p>](https://dsiprouter.org)


## What is dSIPRouter?

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to use SIP Service Provider platform, which enables three basic use cases:

- **SIP Trunking services:**
Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc.
We have support for IP and credential based authentication.

- **Hosted PBX services:**
Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX.
We have an integration with FusionPBX that make this really easy and scalable!

- **Microsoft Teams Direct Routing (Core Subscription Required):**
We can provide SBC functionality that allows dSIPRouter to interconnect your existing voice infrastructure or VoIP carrier to your Microsoft Teams environment.

- **WebRTC Proxy (Core Subscription Required):**
We can provide functionality that allows dSIPRouter to register WebRTC clients to PBX's that has extensions being exposed as just UDP and TCP.  Hence, becoming a WebRTC Proxy.

The dSIPRouter UI allows you to manage the platform.  We also make it easy to intergrate dSIPRouter into your existing workflow by using our [API](https://www.postman.com/dopensource/workspace/dsiprouter/overview)

**Follow us at [#dsiprouter](https://twitter.com/dsiprouter) on Twitter to get the latest updates on dSIPRouter**

### Project Web Site

Check out our official website [dsiprouter.org](http://dsiprouter.org)

### Demo System

Try out our demo system [demo.dsiprouter.net](https://demo.dsiprouter.net:5000/)

Demo system GUI Credentials:
- username: `admin`
- password: `ZmIwMTdmY2I5NjE4`

Demo system API Credentials:

You can test out the API using the demo system.  We have defined a [Postman](https://www.postman.com/dopensource/workspace/dsiprouter/overview) collection that will make the process easier.  The API token is below:

- bearer token: `9lyrny3HOtwgjR6JIMwRaMej9LijIS835zhVbD8ywHDzXT07Xm6vem1sgfvWkFz3`

### Documentation

You can find our documentation online: [dSIPRouter Documentation](https://dsiprouter.readthedocs.io/en/latest)
For a list of updates and changes refer to our [Changelog](CHANGELOG.md)

### Contributing

See the [Contributing Guidelines](CONTRIBUTING.md) for more details
A current list of contributors can be found [here](CONTRIBUTORS.md)

### Getting Started

You can find the steps to install of support operating systems:

- [Debian Based Systems](https://dsiprouter.readthedocs.io/en/latest/debian_install.html#debian-install)
- [Redhat Based Systems](https://dsiprouter.readthedocs.io/en/latest/rhel_install.html#rhel-install)

### Support

- Free Support: [dSIPRouter Question & Answer Forum](https://groups.google.com/forum/#!forum/dsiprouter)
- Paid Support: [dSIPRouter Support](https://dsiprouter.org/#fh5co-support-section)

### Training

Details on training can be found [here](https://dopensource.com/product/dsiprouter-admin-course/)

### License

- Apache License 2.0, [read more here](LICENSE)

### Supported Features

- Carrier Management
  - Manage carriers as a group
- Endpoint Management
  - Manage endpoints as a group
  - Call Limiting per Endpoint Group
  - Call Detail Records generation per Endpoint Group
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
- High Availablity (Subscription Required)
  - Mysql Active-Active replication
  - Pacemaker / Corosync Active-Passive floating IP
  - Consul DNS Load-balancing and DNS Failover
  - dSIPRouter cluster synchronization
  - Kamailio DMQ replication
- Microsoft Teams Support (Subscription Required)
- WebSockets Enabled by Default
