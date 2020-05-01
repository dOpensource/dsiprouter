# dSIPRouter

## What is dSIPRouter?

dSIPRouter allows you to quickly turn [Kamailio](https://www.kamailio.org/) into an easy to use SIP Service Provider platform, which enables three basic use cases:

- **SIP Trunking services:** Provide services to customers that have an on-premise PBX such as FreePBX, FusionPBX, Avaya, etc.  We have support for IP and credential based authentication.

- **Hosted PBX services:** Proxy SIP Endpoint requests to a multi-tenant PBX such as FusionPBX or single-tenant such as FreePBX. We have an integration with FusionPBX that make this really easy and scalable!

- **Microsoft Teams Direct Routing (Subscription Required):** Can act as proxy between Microsoft Teams and your existing SIP Infrastructure.  It can handle inbound and outbound calling.

 
The following features are currently supported:

- Microsoft Teams Direct Routing
- FusionPBX Proxy with Auth Domain Support
- SIPS to SIP (aka TLS to UDP Proxy)
- Mysql Active-Active replication
- Pacemaker / Corosync Active-Passive floating IP
- Call Limits
- Over Call Limit Notifications
- Endpoint Failure Notifications
- Failover to a DID
- HardForward Inbound DID to an external number
- Call Detail Records per Endpoint


**Follow us at [#dsiprouter](https://twitter.com/dsiprouter) on Twitter to get the latest updates on dSIPRouter**

### Project Web Site

http://dsiprouter.org

### Demo System

You can checkout our demo system, which is located here:

[http://demo.dsiprouter.org:5000](http://demo.dsiprouter.org:5000)

username: admin

password: ZmIwMTdmY2I5NjE4

API Token: 9lyrny3HOtwgjR6JIMwRaMej9LijIS835zhVbD8ywHDzXT07Xm6vem1sgfvWkFz3

### HA Installation Notes

The highly available mysql and pacemaker modules are installed seperately at this time:

- Both modules are deployed from an edge server that must connect through ssh to all nodes
- Currently 2 node clusters have been thoroughly tested but there is no limit to cluster size.

Supported SSH authentication methods for cluster configuration:

1. public key
2. password

### Documentation

You can find our documentation here: [dSIPRouter Documentation](https://dsiprouter.readthedocs.io/en/latest)

### Support

Free Support: [dSIPRouter Question & Answer Forum](https://groups.google.com/forum/#!forum/dsiprouter)

Paid Support: [dSIPRouter Support](http://dsiprouter.org/#fh5co-support-section)

### Training

Details on training can be found [here](https://dopensource.com/product/dsiprouter-admin-course/)

### License

* Apache License 2.0, [read more here](./LICENSE)
