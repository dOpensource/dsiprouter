## CHANGELOG



### Fix Carrier Update Changing Reload Button

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Thu, 26 Mar 2020 16:25:53 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update carriers.html to propagate reload state
- Resolves #15


---


### Fix Carrier Address Mismatch Issue

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Thu, 26 Mar 2020 15:31:27 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update dr_gateways to track address entry id
- Resolves #18


---


### Set KAM_DB_PASS to the default value of kamailiorw

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Wed, 25 Mar 2020 11:11:14 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed a regression

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Wed, 25 Mar 2020 10:25:07 +0000  
> Author: root (root@dSIP060entNightly-0.localdomain)  
> Committer: root (root@dSIP060entNightly-0.localdomain)  



---


### TLS Support - Added support that will enable TLS on initial install - Added support to install the proper Kamailio modules for Debian - Added logic to generate a self-signed certitifcate during install

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Wed, 25 Mar 2020 00:18:39 +0000  
> Author: root (root@dSIP060entNightly-0.localdomain)  
> Committer: root (root@dSIP060entNightly-0.localdomain)  



---


### Update mysqldump Commands to Handle More Use Cases

> Branches Affected: v0.60+ent  
> Tags Affected: v0.60+ent-beta  
> Date: Mon, 23 Mar 2020 14:04:50 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update mysql dump and commands to remove definer and MyISAM
- update mysql dump and restore commands in api to be more secure
- resolves #11


---


### Increase Kamailio Max Loop Count

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Mon, 23 Mar 2020 10:25:46 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #8


---


### Fix inbound mapping import issues

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Fri, 20 Mar 2020 14:10:00 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Stability Fixes and Cluster Sync/Install Updates

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Fri, 20 Mar 2020 11:53:44 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update pbx invite timeout on 180,181,183 response
- update cdr email to send only last month of cdr's
- disable mysql service on remote db configuration
- fix redirection for isinstance checks
- fix mysql service linking
- update kamctlrc to include DB settings
- fix issues installing with remote db
- add setkamdbconfig command to allow changing db configs
- add current work on clusterinstall command


---


### Fix errors in dsiprouter script

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Fri, 13 Mar 2020 13:19:55 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix missing semi-colon
- re-order OS info function


---


### CDR / Backup Feature Fixes

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Fri, 13 Mar 2020 11:51:22 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- change sorting to be done on backend for CDR's
- fix shell quoting issue w/ backup/restore cmds
- handle bad file upload on restore cmd
- auto format api_routes code


---


### Merge v0.55+ent changes into v0.60+ent

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Thu, 12 Mar 2020 16:24:26 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- merge in cdr and backup/restore changes
- various styling / syntax fixes
- make bootstrap-datepicker.css local
- update docker compose file for v0.60
- fix some remaining db session bugs missed b4
- fix dsiprouter syslog not logging pid issue


---


### Merge dmq-feature branch into v0.60+ent

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Thu, 12 Mar 2020 10:37:41 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### DMQ Replication Support and Stability Fixes

> Branches Affected: dmq-feature  
> Tags Affected:   
> Date: Wed, 11 Mar 2020 15:24:25 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- dynamic kam db url updating
- AES implementation update / fix
- allow dsip dummy session to handle scoped session calls
- update api auth to use Accept header instead of User-Agent
- fix cdr start time field
- fix inbound mapping failover fwd description
- allow same endpoint on failover for inbound mappings
- fix mail user / pass ENV variables
- fix git pre/post commit hook
- fix parsing of special chars in kam config db url update
- added dmq replication support for htables and dialogs
- add support for dsip cluster settings synchronization
- add option to install for setting private key
- improved dsiprouter.sh script dependency handling
- allow changing all db options on install via db option
- update comments / TODO's in scripts
- change pkgmgr cmd check to apt-get to be more portable
- changed pbx_invite_timeout to a more reasonable 16sec
- changed kamailio.cfg to tabs, this seemed to be the standard
- fixed discrepancy between kam notification route and api_route
- made primary gwgroup required on inbound mappings
- fixed bug w/ endpoint group not populating in modal
- updated dsip_settings table to support more settings and sync
- added update_dsip_settings procedure w/ auto cluster sync
- fix improper gwid in special cases when insert_dr_gateways triggered
- add resolution of dsip_id in cluster sync mode
- revert change from db.close -> db.remove in dsiprouter.py
- fix naming of failfwd htable entry descriptions
- update inbound mapping query to support primary endpoint group
- add param check to gui login
- update shared_lib.sh to include triggers in merge sql dump
- update shared_lib.sh to remove definer in all sql dumps
- update usage options
- add support for remote cluster installation w/ synced private keys
- add support for setting private key on install
- add support for updating mysql user creds in dsiprouter.sh script
- add header check to api auth
- fixed bad FLT flags in script by moving inline comments in settings.py
- fix improper special character handling in setConfigAttrib func
- revert updateDsipSettingsTable back into dsiprouter.py for new logic
- fixed rtpengine rpm build errors
- add support for building rtpengine ngcp-rtpengine-recording module
- fix bug where strFieldsToDict would throw on bad field
- add chcek for function in objToDict
- add test 20,21 for DNSmasq and DNS resolver functionality
- fix broken Makefile by switching to tabs
- fix broken tests 11,19 by handling encrypted/hashed credentials
- fix bad flag on test 16 causing failure on centos
- add dsiprouter user/group creation during install


---


### Fix Testing Makefile

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Tue, 25 Feb 2020 15:33:22 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Makefile requires tabs, re-tabbed spaces


---


### Fix RTPEngine Kernel Header Install Issue

> Branches Affected: dmq-feature  
> Tags Affected:   
> Date: Tue, 25 Feb 2020 14:54:46 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- find current kernels headers instead of installing new kernel


---


### Fix RTPEngine Kernel Header Install Issue

> Branches Affected: v0.60+ent  
> Tags Affected:   
> Date: Tue, 25 Feb 2020 14:54:46 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- find current kernels headers instead of installing new kernel


---


### V0.60 Bug Fixes

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Feb 2020 10:55:29 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- dynamic kam db url updating
- AES implementation update / fix
- allow dsip dummy session to handle scoped session calls
- update api auth to use Accept header instead of User-Agent
- fix cdr start time field
- fix inbound mapping failover fwd description
- allow same endpoint on failover for inbound mappings
- fix mail user / pass ENV variables
- fix git pre/post commit hook
- fix parsing of special chars in kam config db url update


---


### Initial changes to Inbound DID Mapping

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected: v0.55+ent  
> Date: Tue, 31 Dec 2019 00:14:32 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issue with the CDR page giving an error when no CDR records are returned

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Mon, 23 Dec 2019 10:27:28 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Endpoint Groups: Added support for generating a password when selecting Username/Password Auth

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Thu, 19 Dec 2019 13:24:36 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### database dump for v0.55+ent

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Sun, 1 Dec 2019 23:20:18 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for 0.55+ent

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Sun, 1 Dec 2019 18:14:54 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### The Fail Forward will adhere to Call Limits defined by the EndPoint Group

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Sun, 1 Dec 2019 23:05:28 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for sending automated CDR reports at a certain time

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Sat, 30 Nov 2019 17:31:50 +0000  
> Author: root (root@dSIPMackEnt-0.localdomain)  
> Committer: root (root@dSIPMackEnt-0.localdomain)  



---


### Updated the Backup and Restore GUI

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Mon, 25 Nov 2019 19:19:37 +0000  
> Author: root (root@dSIPMackEnt-0.localdomain)  
> Committer: root (root@dSIPMackEnt-0.localdomain)  



---


### 0.55 Enchancements - Add the from header to the list of fields - CDR display 100 entries by default, not 10 - Ability to backup/restore the config in it’s entirety

> Branches Affected: v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Wed, 20 Nov 2019 13:09:16 +0000  
> Author: root (root@dSIPMackEnt-0.localdomain)  
> Committer: root (root@dSIPMackEnt-0.localdomain)  



---


### Fix pre-commit hook

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 8 Oct 2019 06:20:48 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix bug where git stash apply would result in conflicts


---


### Increase Efficiency of CHANGELOG creation

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 8 Oct 2019 03:26:36 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- updates to post-commit hook made 25% execution time decrease


---


### Add dsiprouter to list of tracked services for consul

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Sat, 5 Oct 2019 19:07:46 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### DB Session Management Updates and Feature Additions

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Fri, 4 Oct 2019 20:37:33 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- overhaul DB session management architecture to support multithreading
- update app to close all db sessions and connections when stopping
- update galera, group replication, and kamcluster scripts to fix some small install bugs
- update cluster install scripts to support firewalld
- add support for consul cluster installation and configuration
- update exception and endpoint debug functions to have more sane defaults
- move filehandling.py to util module
- fix syslogging bugs in dsiprouter
- update dsiprouter syslog format to be more useful
- fix various bugs in api_routes code
- fix various bugs related to incorrect session handling
- add utility functions ti shared_lib for HA scripts
- fix regression with kamailio config updates on install
- add DummySession class to fix exception handling logic flow
- fix enterprise_enabled global to really be global


---


### Merge Commit c88b214251333b7350b10b27fa2dae683ef3b602 From OSS Repo

> Branches Affected: v0.523+ent  
> Tags Affected: v0.523+ent-rel  
> Date: Wed, 2 Oct 2019 16:59:11 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Merge Commit c88b214251333b7350b10b27fa2dae683ef3b602 From OSS Repo

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Wed, 2 Oct 2019 16:59:11 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Update RTPEngine Default Config

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 1 Oct 2019 17:58:13 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- change default config to use explicit ip definition to avoid confusion


---


### Update Enterprise and OSS Features

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 1 Oct 2019 16:40:26 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- merge HA branch into v0.60+ent
- improve portability and reliability of HA install scripts
- fix iptables save bug in HA install
- fix merging functions in HA install
- add new standardized git workflow for contributors and option to install in repo
- add / update git hooks: pre-commit, post-commit, prepare-commit-msg, commit-msg
- add / upfate git configs: .gitignore, .gitattributes, .gitconfig
- add merge conflict drivers for git hook generated files, such as CHANGELOG
- add full support for storing settings in DB with security
- add asymmetric, symmetric, and hashing functions
- add setcredentials command for convenience
- add support for settings updates through domain sockets
- add support for settings updates through prcoess signaling (reload)
- add functions to support ipc with dsiprouter process
- add support for hot reload of updated settings
- add option to enable lcr on install
- update in progress work on AA Group Replication install
- update asterisk prefix conversions to be reusable and moved to conversions.py
- update all credentials and settings to be stored securely
- update support for settings updates through env variables to only debug mode
- update READEME to reflect enterprise version and display enterprise features
- update a couple shared.py functions to be more robust
- update kam config update functions to support all the dynamic settings
- remove deprecated lcr module (it is already part of core dsiprouter)


---


### Call Detail Records: - Records are not sorted by call start time

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Tue, 1 Oct 2019 18:49:52 +0000  
> Author: root (root@dSIP0523entNightly-0.localdomain)  
> Committer: root (root@dSIP0523entNightly-0.localdomain)  



---


### Slight Tweak to dr_gateways trigger

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 1 Oct 2019 14:06:23 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update trigger to support multi-row inserts


---


### Slight Tweak to dr_gateways trigger

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Tue, 1 Oct 2019 14:06:23 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update trigger to support multi-row inserts


---


### Merge branch v0.523+ent into v0.60+ent

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Mon, 30 Sep 2019 20:51:38 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Additional bug fixes

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Mon, 30 Sep 2019 19:29:27 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update call limit to allow 0 (user can block an endpoint group this way)
- fix bug with dr_gateways trigger not firing
- fix bug where non servernat instances won't bind to any address
- fix bug with call limits htable being initialized to zero
- move event routes to more suitable location in config
- add dr_gateways update trigger
- update kamailio.sql testing dump
- cleanup kam config a bit


---


### Update toggleElemDisabled

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Mon, 30 Sep 2019 15:39:28 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- allow toggleElemDisabled to specify which element to disable cursor
- update inboundmapping.js to choose child elem for disabled elems


---


### Fix Regressions and Merge Recent Commits

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Mon, 30 Sep 2019 13:42:37 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix commit fc5f80d583c5f2513546798d511ca9fc6c57d4dc
- fix commit 9c92a5cbdabfd56add520408b82b0a324a78571b
- resolve regressions and merge commit 3c75d41c1296d99e63117d6d15ae625a69f08935
- rollback commit 50698c1c2a15952390b77ff594a716fa88228231
- fix up ALL kamailio logging funcs
- update dsip_token in updateKamConfig func
- resolves issue #4
- resolves issue #5
- resolves issue #6


---


### Bug Fixes and Forwarding Feature Update

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Thu, 26 Sep 2019 23:37:28 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update dsip_lib.sh kam config funcs to use a better separator
- update dr_gateways db mapping class to fit new updates
- update sql files to match utf-8 encoding from previous commit
- update dsip_forwarding.sql to use DSIP_ID set at install
- update kam to track src and dest gwgroup for call limiting
- update kam SEND_NOTIFICATION route to support dynamic gwid and gwgroupid
- create trigger for dr_gateways to support feature updates
- fix rtpengine install detection (typo)
- fix and improve various sql queries in resistrar


---


### Bug Fixes and Forwarding Feature Update

> Branches Affected: v0.523+ent,v0.55+ent,v0.55+ent_didws  
> Tags Affected:   
> Date: Thu, 26 Sep 2019 13:13:25 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update dsip_lib.sh kam config funcs to use a better separator
- update dr_gateways db mapping class to fit new updates
- update sql files to match utf-8 encoding from previous commit
- update dsip_forwarding.sql to use DSIP_ID set at install
- update kam to track src and dest gwgroup for call limiting
- update kam SEND_NOTIFICATION route to support dynamic gwid and gwgroupid
- create trigger for dr_gateways to support feature updates
- fix rtpengine install detection (typo)
- fix and improve various sql queries in resistrar


---


### Update to DID Forwarding

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 23 Sep 2019 19:25:54 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add feature to allow DID routing without specifying gwgroup
- update inbound mapping route to accomodate new feature
- update gwgroup selection to allow default option
- update toggleElemDisabled() to be more robust
- change hardfwd toggle button to set gwgroup selection to default option
- move inbound mapping js logic from main to its own file
- fix bug where failover forwarding would overwrite fwd info


---


### Add Security Features and Database Settings Update

> Branches Affected: dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Fri, 20 Sep 2019 16:01:15 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add automatic db/file settings update (on startup) based on mode
- add database dump for v0.60+ent
- add security functions for hashing (pbkdf2_hmac) and encrpyting (AES256) credentials
- add secure credential usage to db connection functions
- add setcredentials command to allow user to set credentials securely using script
- add root priviledge check to dsiprouter script
- add securing permissions on kam cfg to dsiprouter script
- add private AES key generation to dsiprouter script
- add option to configure kam db hosts from install command
- add option to configure dsip id from install command
- update getConfigAttrib() and setConfigAttrib() to support byte string literals
- update kam cfg update functions to use a better delimiter when parsing
- update install script to secure credentials by default
- update updateConfig() function to support byte string literals
- update MakeFile to run dsiprouter in debug mode and allow credential hot swapping
- update testing scripts to use credential hot swapping
- update install script to be more efficient by isolating a few functions
- update displayLoginIfno() to be more reliable and show kam credentials
- update dsip_forwarding.sql to support multiple dsiprouter instances
- change secure credential env loading only to debug mode
- change dsip/api/mail credentials auth to use encrypted credentials
- change dsip credentials auth to compare hashes
- change default db characterset to utf-8 (should always be used moving forward)
- change default admin password generation to use /dev/urandom
- fix kam cfg DBLUSTER settings update logic
- fix kam cfg DBURL settings update logic
- fix mail default sender bug
- fix byte string storage bug by adding encoding/decoding to security functions
- fix table detection bug when running installSQL() in a few modules
- fix schema load order for dsip_forwarding.sql
- fix kam cfg symlink not created issue
- fix is rtpengine installed check


---


### Forwarding fixes and Misc Updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 13 Sep 2019 11:35:41 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix forwarding dr_groupid update
- allow fwding rule create/delete on update
- fix outbound route dr_groupid filtering
- update kamreload cmd with reload for new htables
- update harfwd and failfwd dr_rule matching on dr_groupid
- clean up kam config
- reset defaults to prod values


---


### Fixes - Fixed the Endpoint Group Modal - Fixed issues with the Call Limit not working with User/Pass Registration - Fixed issues with the API

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 13 Sep 2019 02:17:08 +0000  
> Author: root (root@dev-siprouter01.ynyybpir3miebggok1eqcyxpaf.gx.internal.cloudapp.net)  
> Committer: root (root@dev-siprouter01.ynyybpir3miebggok1eqcyxpaf.gx.internal.cloudapp.net)  



---


### v0523 Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Sep 2019 20:03:40 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed invalid GCE instance detection
- fix hardfwd and failfwd always insert issue
- fix typo in inbound mapping route
- fix inbound mapping modal update for fwd's
- fix hardfwd and failfwd matching logic
- fix inbound mapping edit modal fwd buttons toggle update
- added prefix mapping htable and db view
- added dsip_settings db table with a subset of the settings
- refactor username/password to follow naming convention
- added new features to install process
- added sql dump of v0.523+ent to testing sql files


---


### v0523 Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Sep 2019 20:03:40 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed invalid GCE instance detection
- fix hardfwd and failfwd always insert issue
- fix typo in inbound mapping route
- fix inbound mapping modal update for fwd's
- fix hardfwd and failfwd matching logic
- fix inbound mapping edit modal fwd buttons toggle update
- added prefix mapping htable and db view
- added dsip_settings db table with a subset of the settings
- refactor username/password to follow naming convention
- added new features to install process
- added sql dump of v0.523+ent to testing sql files


---


### Added support for dynamically setting up DR gateways and gateway list when an endpont registers

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Sep 2019 13:31:06 +0000  
> Author: root (root@dev-siprouter01.ynyybpir3miebggok1eqcyxpaf.gx.internal.cloudapp.net)  
> Committer: root (root@dev-siprouter01.ynyybpir3miebggok1eqcyxpaf.gx.internal.cloudapp.net)  



---


### Fixed a regression in the Carrier Groups Add Carrier Modal.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 5 Sep 2019 07:23:48 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Refactored the Endpoint Groups

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Aug 2019 11:49:12 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### The DSIP_API_TOKEN value will be admin before install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Aug 2019 07:46:37 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issues that resulted from the merge

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Aug 2019 07:42:15 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed merge issue

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Aug 2019 03:30:54 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Enhancements - Added CDR's to the GUI and via a RESTFul endpoint - Added the ability to update an endpont group record

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Aug 2019 03:15:15 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


###   - update call limit to use gwgroup   - fix hardfwd and failfwd routing logic   - update notification feature to use bearer token   - fix looping bug with failover fwd   - move enpoint groups js to fix conflict   - add insert,update,delete triggers for gw2gwroup table   - update dsip fwding to match on prefix instead of gwgroup   - make gui templates more standardized (description field)   - update inbound mapping to use gwgroups   - add hardfwd and failfwd to inbound mapping   - change templates to show hostname support in drouting   - NOTE: inbound mapping updated but still needs work   - update kam reload in api to match gui   - fix misc issues in api_routes   - add new icons for forwarding   - clear add modals when opening again

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Aug 2019 01:49:27 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### EndpointGroup Bug Fixes and CDR API - Fixed issues with saving and deleting EndpointGroups - Implemented a CDR RestFul API for requesting Call Detail Record (CDR) Information

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Aug 2019 16:45:07 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed API Token Security function

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Aug 2019 13:42:34 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Merging in Notificaition changes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Aug 2019 08:50:04 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### EndpointGroups - Added API's for updating and deleting EndpointGroups - Added the supporting UI components

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Aug 2019 08:34:21 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Add Enterprise Features Backend Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 25 Aug 2019 18:45:59 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- make notifications a separate callable route
- add support for endpoint failure notifications
- update dsip_hardfwd table
- update dsip_failfwd table
- improve email notification messages
- add improvements to flag handling in kamailio routes
- add support for hard forwarding to DID
- add support for failover forwarding to DID
- update inbound mapping lcr flag handling
- update some defaults for TESTING in settings.py (remove for production)
- fix missing servernat option for configurekam command in dsiprouter.sh
- update command options in dsiprouter.sh
- fix #!ifdef mismatch in kamailio.cfg


---


### Notification API Feature Backend Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Aug 2019 21:44:47 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add kamailio route for notifications / http requests
- add gw2gwroup table
- add tables for hard forwarding and failover forwarding
- add email notification support
- add file upload support
- add async func wrapper
- add endpoint for notifications to API
- add email settings in settings.py
- move API security functions to API routes
- add http_async_client module to install scripts


---


### Added support for adding endpoints within an Endpoint Group

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Aug 2019 11:00:09 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added database table for gateway to gateway group lookup - gwip2gwgroup

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 15:28:24 +0000  
> Author: root (root@dsip0523entMack.localdomain)  
> Committer: root (root@dsip0523entMack.localdomain)  



---


### Fixed issue with merge - forgot to fix conflict

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 07:58:18 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issue with merge - forgot to fix conflict

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 07:55:41 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issues with the Endpoint API and dSIPNotification SQL

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 07:45:30 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the mail settins

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 02:56:42 +0000  
> Author: root (root@dsip0523entMerge.localdomain)  
> Committer: root (root@dsip0523entMerge.localdomain)  



---


### Fixed the version number

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 02:47:05 +0000  
> Author: root (root@dsip0523entMerge.localdomain)  
> Committer: root (root@dsip0523entMerge.localdomain)  



---


### Fixed minor issues: - dsip_calllimit table was not being installed at install time - The email settings for the notifiation service was not in the settings.py file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 02:45:09 +0000  
> Author: root (root@dsip0523entMerge.localdomain)  
> Committer: root (root@dsip0523entMerge.localdomain)  



---


### Docker Compose: - Added the dsip_notification schema to the SQL file that is used for priming the database of the MySQL container

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 21 Aug 2019 02:07:39 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Docker Compose: - Added the dsip_notification schema to the SQL file that is used for priming the database of the MySQL container

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Aug 2019 21:50:20 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for adding endpoints

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Aug 2019 08:10:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic to store an endpoint group

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Aug 2019 07:01:53 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Create RESTFul API to add an endpoint group

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Aug 2019 14:47:11 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issues with the docker compose changes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Aug 2019 14:39:05 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic to create the Call Limit Schema

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 13 Aug 2019 02:45:45 +0000  
> Author: root (root@dsip0523entMack-0.localdomain)  
> Committer: root (root@dsip0523entMack-0.localdomain)  



---


### Updated to handle different version of Python being already installed on the system

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 12 Aug 2019 12:49:25 +0000  
> Author: root (root@ip-172-31-23-165.us-east-2.compute.internal)  
> Committer: root (root@ip-172-31-23-165.us-east-2.compute.internal)  



---


### FusionPBX Provisioning Services: - The docker container now starts up with a self signed cert

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.523-rel  
> Date: Wed, 7 Aug 2019 12:00:45 +0000  
> Author: root (root@dsip0523-qa-0.localdomain)  
> Committer: root (root@dsip0523-qa-0.localdomain)  



---


### Fixed an self-signed cert configurtion. The Country portion was set to USA, versus US

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Aug 2019 05:21:11 +0000  
> Author: Mack Hendricks (mack@goflyball.com)  
> Committer: Mack Hendricks (mack@goflyball.com)  



---


### Carrier Groups: - Fixed an error that occured when creating a carrier that used Username/Password auth

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Aug 2019 04:47:40 +0000  
> Author: root (root@dsip0523qa-0.localdomain)  
> Committer: root (root@dsip0523qa-0.localdomain)  



---


### Domains - Local Subscriber: - Fixed authentication logic.  It will now properly authenticate against the subscriber table

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.523-beta1  
> Date: Mon, 5 Aug 2019 22:09:48 +0000  
> Author: root (root@dsip0523qa-0.localdomain)  
> Committer: root (root@dsip0523qa-0.localdomain)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 06:36:16 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 06:33:53 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 06:33:26 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 05:44:29 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Domain Mapping: - Added the domain_list_hash field to support syncing with FusioinPBX

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 02:34:49 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update upgrade_0.522_to_0.523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:33:23 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade_0.522_to_0.523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:29:26 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade_0.522_to_0.523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:27:32 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade_0.522_to_0.523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:25:54 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Rename upgrade_0522_to_0523.rst to upgrade_0.522_to_0.523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:23:35 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:18:18 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:17:42 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:17:25 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:14:53 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:13:08 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:08:59 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:07:02 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create upgrade_0522_to_0523.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:06:16 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Rename upgrade.rst to upgrade_0.50_to_0.51.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 22:04:44 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Changed the table of contents

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 4 Aug 2019 21:57:21 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Moved the API section from the bottom.


---


### FusionPBX Domain Routing Sync: - Added logic that will generate a hash of domain names during the sync.  The sync will only run if the hash changes - Added logic to create a self-signed certificate for nginx.  This will allow the service to start up using SSL  Fixes #193

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 01:47:29 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### FusionPBX Domain Routing Sync: - Added logic that will generate a hash of domain names during the sync.  The sync will only run if the hash changes - Added logic to create a self-signed certificate for nginx.  This will allow the service to start up using SSL

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Aug 2019 01:42:28 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Domain Support for Local Subscriber Table - Added logic to reload the dispatcher table - Added logic to probe each server defined within a Domain

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 3 Aug 2019 00:30:10 +0000  
> Author: root (root@demo-dsiprouter-0.localdomain)  
> Committer: root (root@demo-dsiprouter-0.localdomain)  



---


### PBX INVITE TIMER - Changed the logic so that INVITE messages from PBX's that receive a SIP 100 message will be assigned a different INVITE timer timeout - Fixes #195

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 1 Aug 2019 11:14:01 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### PBX INVITE TIMER -  Increased the INVITE TIMER by two once we see a SIP 100 Message. This will give the endpoint more time to respond to the invite and it will trigger the secondary server if it doesn't answer - Fixes #195

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 31 Jul 2019 06:35:11 +0000  
> Author: root (root@dsip0523-0.localdomain)  
> Committer: root (root@dsip0523-0.localdomain)  



---


### Redesign of PBX page: - The term PBX is switched to Endpoint to represent a more generic use - Added tabs to the Add modal for each configuration area

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 30 Jul 2019 19:17:07 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Docker support  - Added dockerfiles for dSIPRouter and MySQL  - Added a docker-compose configuration to allow the dSIPRouter GUI to spin up with a docker-compose up  - Added environment variables to allow the dSIP usernamae, password and kamailio database settings can be set on runtime

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 29 Jul 2019 14:29:50 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Refactoring the PBX/Endpoint page

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 26 Jul 2019 01:42:05 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Disabled verbose output for a test

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.5221-rel  
> Date: Wed, 24 Jul 2019 13:30:30 +0000  
> Author: Mack Hendricks (mack@goflyball.com)  
> Committer: Mack Hendricks (mack@goflyball.com)  



---


### Removed the ExecStart command that was reseting the dSIPRouter password to the instanceid of the instance.  Except for Amazon images

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 24 Jul 2019 13:25:47 +0000  
> Author: Mack Hendricks (mack@goflyball.com)  
> Committer: Mack Hendricks (mack@goflyball.com)  



---


### Python repo issue - > The yum package manager couldn't install python36u-pip because of a conflict with the python36 packages > which are in the epel-release repo.  We now remove the python36 libraries and install Python from the ius repo

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 23 Jul 2019 16:11:44 +0000  
> Author: root (root@dsip-centOS7.6)  
> Committer: root (root@dsip-centOS7.6)  



---


### Added Call Limit Support to the Kamailio configuration and fixed the dSIPRouter logic to handle it

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 22 Jul 2019 11:17:17 +0000  
> Author: root (root@dsip0522ent-0.localdomain)  
> Committer: root (root@dsip0522ent-0.localdomain)  



---


### Added logic to manage call limits

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 19 Jul 2019 14:19:19 +0000  
> Author: root (root@dsip0522ent-0.localdomain)  
> Committer: root (root@dsip0522ent-0.localdomain)  



---


### First commit of enterprise

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 18 Jul 2019 19:10:43 +0000  
> Author: root (root@dsip0522ent-0.localdomain)  
> Committer: root (root@dsip0522ent-0.localdomain)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 18:49:23 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update Docs

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 17:21:15 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix couple broken links
- fix `api.rst`


---


### Update API Docs

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 16:36:46 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 16:10:17 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Merge Documentation Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 15:30:09 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 15:08:56 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fix inconsistencies in documentation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 14:54:12 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Merge Documentation Changes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 13:17:11 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Update api.rst


---


### Merge documentation Updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 13:13:52 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Update domains.rst


---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:40:51 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:30:49 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:29:43 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:20:48 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:10:39 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 11:01:13 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update and rename API.rst to api.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 10:58:19 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update Inbound Mapping Endpoint

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 10:55:01 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- change endpoint path to /api/v1/inboundmapping


---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 10:39:17 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 10:38:37 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create API.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 3 Jul 2019 10:26:08 -0400  
> Author: Omari S. King (46901954+OmariKing@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Make Primary PBX Required in GUI

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 2 Jul 2019 21:50:58 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #181
- make select field for primary pbx required in front end


---


### Inbound DID Mapping Through API

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 2 Jul 2019 21:02:21 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #77
- create new API DID Mapping endpoint for GET,POST,PUT,DELETE
- add tests to API test `19.sh`
- fix creation of duplicate inbound DID's
- update exception handling to be more useful
- update globals
- add TODO comments
- update rowToDict function
- make `error.html` prettier / more palatable


---


### Default to IPv4

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Jul 2019 12:32:07 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #183
- set ip resolution to ipv4 by default
- note: ipv6 support is not fully supported yet


---


### Fix Debian v09 mysqlclient Dependency Regression

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Jun 2019 19:53:54 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add case for new package name default-libmysqlclient-dev


---


### Fix Debian v09 mysqlclient Dependency Regression

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Jun 2019 19:53:54 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add case for new package name default-libmysqlclient-dev


---


### testing: Fixed Domain Pass-Thru using FreePBX test - The test will run the test on the externalip that it finds and then will try to run it on the internalip

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Jun 2019 16:06:18 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### testing: Fixed Domain Pass-Thru using FreePBX test - The test will run the test on the externalip that it finds and then will try to run it on the internalip

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Jun 2019 16:03:47 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Merge v0.522 commits onto v0.523

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Jun 2019 14:15:09 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Remove Unused Billing Calls in Kamailio Config

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Jun 2019 12:35:12 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #182
- Resolves #88
- commented out call to kamailio_rating in kam cfg


---


### Allow Excluding Libraries in Requirements git Hook

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Jun 2019 11:42:59 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update pre-commit hook to allow exluding libraries
- add docker_py to excluded libraries


---


### Kam Cluster Stability Improvements

> Branches Affected: HA,dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Mar 2019 10:48:56 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update resource wait times for pcs


---


### Fix Cloud Stability Issues

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 26 Jun 2019 17:37:31 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix sipsak install fail due to memory allocation errors
- fix apt and yum locking errors on install
- fix dependency mismatching for mysldb
- upadate requirements hook to allow non stdlib deps
- add initial support getting GCE, AZURE, and DO images
- fix centos false positive build errors
- cleanup dsiprouter install debug statements
- fix motd banner for centos and debian < v9
- fix debian user password reset on cloud images
- added a couple TODO's for install scripts


---


### Update requirements.txt

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Jun 2019 07:57:40 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Putting back the required libraries


---


### Security Bug Modification

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 25 Jun 2019 18:00:12 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- ammending commit c8756c929ccce9793a1e1717439a257c97f22203
- Resolves #185
- add host check
- allow cloud-init to re-add keys


---


### kamailio.cfg: The SERVERNAT mode will now cause Kamailio to listen on TCP at 127.0.0.1:5060

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 26 Jun 2019 18:09:28 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update kamailio51_dsiprouter.cfg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Jun 2019 13:02:29 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

Changing the INVITE timer to a more standard timeout of 32 secs


---


### Update kamailio51_dsiprouter.cfg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Jun 2019 13:02:29 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Changing the INVITE timer to a more standard timeout of 32 secs


---


### Cloud Config Security Updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Jun 2019 12:25:40 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #185
- fix cloud-init overwriting sshd_config
- add ASLR check
- fix grub prompt issue in snapshot configs for ubuntu
- switch cloud build script to v0.522


---


### Rewrote the reload API

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 31 May 2019 05:30:36 +0000  
> Author: root (root@ip-172-31-13-3.us-east-2.compute.internal)  
> Committer: root (root@ip-172-31-13-3.us-east-2.compute.internal)  



---


### Set it back so that it binds to all interfaces. This will cause the dashboard not to work on some OS builds

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.522-rel  
> Date: Tue, 28 May 2019 08:50:12 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### -Fixed the provisioning server template to default to 443 -Fixed the fusionpbx sync script to handle 443 properly

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 May 2019 08:36:16 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Use python docker module versus docker_py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 May 2019 07:07:40 +0000  
> Author: root (root@p0.detroitpbx.com)  
> Committer: root (root@p0.detroitpbx.com)  



---


### Fixed an error that occurs when there are no FusionPBX sources to sync domain info

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 26 May 2019 17:14:31 +0000  
> Author: root (root@demo-dsiprouter-0.localdomain)  
> Committer: root (root@demo-dsiprouter-0.localdomain)  



---


### Fixed a typo

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 25 May 2019 10:01:48 +0000  
> Author: root (root@demo-dsiprouter-0.localdomain)  
> Committer: root (root@demo-dsiprouter-0.localdomain)  



---


### Fixed an issue with listening on udp and tcp ports

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 25 May 2019 09:29:37 +0000  
> Author: root (root@demo-dsiprouter-0.localdomain)  
> Committer: root (root@demo-dsiprouter-0.localdomain)  



---


### Explicitly added a listen attribute for tcp. Fixed issue #170

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 22 May 2019 15:54:05 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed #164

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 20 May 2019 19:58:01 +0000  
> Author: root (root@OmariDev-0.localdomain)  
> Committer: root (root@OmariDev-0.localdomain)  



---


### Fixed a regression from Primary/Secondary Failover Enhancement

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 17 May 2019 17:59:45 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 16 May 2019 13:39:24 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### #163 fixed

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 15 May 2019 20:16:27 +0000  
> Author: root (root@OmariDev-0.localdomain)  
> Committer: root (root@OmariDev-0.localdomain)  



---


### - The admin password is now being set properly on Debian - non AWS - Fixed the spacing when displaying the password info

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 15 May 2019 07:57:23 +0000  
> Author: root (root@dSIPRouterJenkins-0.localdomain)  
> Committer: root (root@dSIPRouterJenkins-0.localdomain)  



---


### fixed #160

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 14 May 2019 21:24:08 +0000  
> Author: root (root@OmariDev-0.localdomain)  
> Committer: root (root@OmariDev-0.localdomain)  



---


### Added the ability to clean up expired leases to our system wide cron script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 14 May 2019 11:23:07 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Startup and General Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 14 May 2019 07:16:21 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix dsiprouter startup issue on centos and amazon linux
- fix ssh server security holes
- add git contributing pre-commit hook
- update cloud instance checks
- fix ubuntu unattended upgrade dialog issue
- add custom MOTD banner
- revert debug settings to production as default
- improve ipv4 and ipv6 checks


---


### Fixed LCR bug, Added a configuration parameter that allows the PBX INVITE timer to be changed globally during runtime

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 10 May 2019 21:57:14 +0000  
> Author: root (root@dSIPRouterMackTest-0.localdomain)  
> Committer: root (root@dSIPRouterMackTest-0.localdomain)  



---


### Updated the .gitignore file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 10 May 2019 21:54:48 +0000  
> Author: root (root@dSIPRouterMackTest-0.localdomain)  
> Committer: root (root@dSIPRouterMackTest-0.localdomain)  



---


### Removed old files

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 10 May 2019 21:50:09 +0000  
> Author: root (root@dSIPRouterMackTest-0.localdomain)  
> Committer: root (root@dSIPRouterMackTest-0.localdomain)  



---


### Edits to carriergroups.js

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 10 May 2019 17:08:55 +0000  
> Author: root (root@OmariDev-0.localdomain)  
> Committer: root (root@OmariDev-0.localdomain)  



---


### Added initial support for a Kamailio Reload API

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 9 May 2019 02:17:14 +0000  
> Author: root (root@dSIPRouterMackTest-0.localdomain)  
> Committer: root (root@dSIPRouterMackTest-0.localdomain)  



---


### Enabled the reload button when enabling and disabling an endpoint for maintenance

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 8 May 2019 10:02:25 +0000  
> Author: root (root@dSIPRouterMackTest-0.localdomain)  
> Committer: root (root@dSIPRouterMackTest-0.localdomain)  



---


### Added dsiprouter.sh to /usr/local/bin via a symbolic link

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 8 May 2019 08:37:26 +0000  
> Author: root (root@dSIPRouterJenkins-0.localdomain)  
> Committer: root (root@dSIPRouterJenkins-0.localdomain)  



---


### Fixed an issue with creating new carriergroups

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 8 May 2019 07:50:00 +0000  
> Author: root (root@dSIPRouterJenkins-0.localdomain)  
> Committer: root (root@dSIPRouterJenkins-0.localdomain)  



---


### Added final logic to support gui and backend support for PBX failover and Endpoint Maintence

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 7 May 2019 02:17:34 +0000  
> Author: root (root@dSIPRouterMack0522-0.localdomain)  
> Committer: root (root@dSIPRouterMack0522-0.localdomain)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 6 May 2019 13:30:04 -0400  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 6 May 2019 13:16:21 -0400  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added logic to update the endpoint api, added logic to display an indicator when a pbx is in maintenance mode

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 6 May 2019 16:22:22 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added API for updating an endpoint and ability to put an endpoint in maintenance mode

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 3 May 2019 18:54:00 +0000  
> Author: root (root@dSIPRouterMack0522-0.localdomain)  
> Committer: root (root@dSIPRouterMack0522-0.localdomain)  



---


### Added the ability to REVOKE a lease

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 30 Apr 2019 08:24:14 +0000  
> Author: root (root@dSIPRouterMack0522-0.localdomain)  
> Committer: root (root@dSIPRouterMack0522-0.localdomain)  



---


### Turned off debugging

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 30 Apr 2019 06:29:05 +0000  
> Author: root (root@dSIPRouterMack0522-0.localdomain)  
> Committer: root (root@dSIPRouterMack0522-0.localdomain)  



---


### Initial commit of the install script for the API module

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 29 Apr 2019 21:24:59 +0000  
> Author: root (root@dSIPRouterMack0.522-0)  
> Committer: root (root@dSIPRouterMack0.522-0)  



---


### Removed dashboard.js from root directory

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 29 Apr 2019 21:07:31 +0000  
> Author: root (root@dSIPRouterMack0.522-0)  
> Committer: root (root@dSIPRouterMack0.522-0)  



---


### Inbound DID's will try the Primary and then the Secondary PBX.  The user will receive a 502 Service not available if both fail

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 29 Apr 2019 21:04:03 +0000  
> Author: root (root@dSIPRouterMack0.522-0)  
> Committer: root (root@dSIPRouterMack0.522-0)  



---


### Initial commit of the Endpoint API

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 29 Apr 2019 20:42:45 +0000  
> Author: root (root@dSIPRouterMack0.522-0)  
> Committer: root (root@dSIPRouterMack0.522-0)  



---


### Added a security model for our API framework

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 28 Apr 2019 03:53:21 +0000  
> Author: root (root@dSIPRouterMack0522-0.localdomain)  
> Committer: root (root@dSIPRouterMack0522-0.localdomain)  



---


### Removed AMI changes that were made - going back to the orig

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 22 Apr 2019 00:04:46 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Temporarily Removing AMI Checks to get Jenkins working

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 21 Apr 2019 23:59:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Adding parameter to curl command for AMI check

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 21 Apr 2019 23:49:26 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 21 Apr 2019 23:00:16 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 17 Apr 2019 07:19:41 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed #130 - l_username field of the uac_reg table will be populated with the gateway group id.  This will get rid of the error messages in the Kamailio log

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 16 Apr 2019 11:18:50 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Added the default value for l_username so that the system has it during bootup

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 16 Apr 2019 11:08:55 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Added unit test to test if known carrier ip's are being blocked by the PIKE module Fixed #148

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 15 Apr 2019 19:19:47 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Working unit test for Domain Pass-Thru using FreePBX

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 15 Apr 2019 10:49:32 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 14 Apr 2019 18:57:49 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added basic exception handling

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 14 Apr 2019 19:07:11 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Removed the old docker-py python library

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 14 Apr 2019 18:46:04 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Fixed #144 and fixed a regression with the FusionPBX Enable/Disable button in the PBX section

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 14 Apr 2019 18:16:36 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Removed the old docker-py library and added the docker

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 14 Apr 2019 03:41:11 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Initial commit of unit test 17, which will be used for testing Domain Pass-Thru

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 13 Apr 2019 23:49:13 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Fixed the Reload Kamailio button so that it reload the Domain module when pressed

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 13 Apr 2019 21:58:02 +0000  
> Author: root (root@dSIPRouterMack-0.localdomain)  
> Committer: root (root@dSIPRouterMack-0.localdomain)  



---


### Fixed #145, Fixed #139, Fixed #142 - The Domain functionality has been fixed.  Adding, Removing and Deleting DDomains has been fixed.  Also, the parameter needed to route traffic when using pass-thru authentication has been fixed

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 13 Apr 2019 17:24:37 +0000  
> Author: root (root@dSIPRouterNicole2.localdomain)  
> Committer: root (root@dSIPRouterNicole2.localdomain)  



---


### Added sngrep back to Debian 8 and 9 installs.  Fixed #147

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 11 Apr 2019 14:44:47 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the AWS test

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 11 Apr 2019 09:59:33 +0000  
> Author: root (root@ip-172-31-18-84.ec2.internal)  
> Committer: root (root@ip-172-31-18-84.ec2.internal)  



---


### Removed the test exit command from the install script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 11 Apr 2019 09:50:05 +0000  
> Author: root (root@ip-172-31-18-84.ec2.internal)  
> Committer: root (root@ip-172-31-18-84.ec2.internal)  



---


### Fixed the function in the testing harness that's responsible for validating if an instance is an EC2 instance on Amazon

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 11 Apr 2019 03:54:00 +0000  
> Author: Mack Hendricks (mack@dopensource.comm)  
> Committer: Mack Hendricks (mack@dopensource.comm)  



---


### Fixed the URL endpont used to validate if the instance is an EC2 instancing running on Amazon

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 11 Apr 2019 03:52:47 +0000  
> Author: Mack Hendricks (mack@dopensource.comm)  
> Committer: Mack Hendricks (mack@dopensource.comm)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 07:11:11 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 07:10:32 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 07:10:04 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:47:40 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:45:55 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:45:31 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:42:59 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:40:42 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:38:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:35:20 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:25:09 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:55:36 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:52:35 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:49:43 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:31:37 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Update debian_install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 31 Mar 2019 10:55:37 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  



---


### Updated Debian Install Docs

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 31 Mar 2019 10:54:02 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@dSIPRouterMackMaster-0.localdomain)  

Modified the docs to reflect the new install options


---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:47:40 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:45:55 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:45:31 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:42:59 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:40:42 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:38:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:35:20 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 06:25:09 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:55:36 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:52:35 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:49:43 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 1 Apr 2019 05:31:37 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update debian_install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 31 Mar 2019 10:55:37 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Updated Debian Install Docs

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 31 Mar 2019 10:54:02 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Modified the docs to reflect the new install options


---


### Initial commit of an active Dashboard

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 30 Mar 2019 23:48:14 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### Final AMI Updates for Release v0.52

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 27 Mar 2019 21:29:11 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix double password reset issue
- cleanup unneeded extra files
- update dsiprouter service
- allow color printing function use inline
- added and updated comments / TODO's
- allow DB driver selection
- fix uninstall dsiprouter to not fail on pip cmd
- fix configurePythonSettings issue
- add support for debian8 (jessie)
- add support for ubuntu 16.04 (xenial)
- add support for amazon linux 2
- fix false negatives on install starting services
- add color to usage cmd output


---


### Update dsiprouter.sh

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 27 Mar 2019 03:27:16 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Removed generatePassword from the displayLoginInfo function


---


### Update Version Number for Release v0.52

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Mar 2019 09:59:59 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


###   - Fixes #103   - deprecate Debian v7   - deprecate Debian v8   - change CentOS RTPEngine install to RPM build   - fix startup issues with dsip-init service on AWS   - added dpkg defaults during script execution

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Mar 2019 08:12:01 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Merge feature-ami Branch Into dev Branch

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 25 Mar 2019 15:41:44 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- rename JSONRPC test to `16.sh`
- merge feature-ami commits onto dev branch


---


### Fixup Firewalld Commands

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 25 Mar 2019 15:01:28 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add tcp port for jsonrpc access
- cleanup centos commands


---


###   - fix mariadb centos startup regression   - fix module sql install username conflict   - set default for ssl variables to avoid errors   - move displaying login info back to after logo   - update a few sed cmds to be more reliable

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 25 Mar 2019 14:49:38 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### AMI Feature Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 25 Mar 2019 10:53:34 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update AMI funtions to run with systemd
- add seperate log file for dsip cloud installs
- fix broken paths
- make kam cfg actual readable (spaces not tabs)
- add test for syslog service
- add test for AMI requirements
- add test for dsip GUI login
- add dev files for next tests to make
- fix test sorting to work past 10
- add work on custom redirection function
- fix login logic in routes and HTTP return codes


---


### Added a unit test to validate that JSON over HTTP access to Kamailio RPC Commands is working correctly

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 23 Mar 2019 12:01:01 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### Added supported jsonrpc over http on tcp port 5060

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 23 Mar 2019 03:48:17 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### Moved the creation of the LCR schema to the main install script and deprecated the LCR module

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 23 Mar 2019 00:10:40 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### Fixed a regression with the gateway list import

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 22 Mar 2019 23:36:42 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### Fixed a regression with dr_gw_lists not being copied over to the /tmp/defaults directory

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 22 Mar 2019 22:47:42 +0000  
> Author: root (root@dSIPRouterMackDev-0.localdomain)  
> Committer: root (root@dSIPRouterMackDev-0.localdomain)  



---


### dSIPRouter Installation Overhaul

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 21 Mar 2019 12:31:35 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #42
- Resolves #103
- add localhost to bind addresses for testing
- wrap LCR routing in #!ifdef WITH_LCR
- fix RTPEngine service startup issue
- update rtpengine service file
- update dsiprouter service file
- add debian support for rtpengine systemd service
- add debian support for kernel packet forwarding
- fix non-root user kernel packet forwarding support
- make rtpengine service namespace cross platform compat
- make centos mariadb service namespace alias to mysql.service
- fix tests for reg, auth, and DOS
- create service check tests
- update test formatting to be cleaner
- update tests documentation
- update test Makefile to sort test execution
- fix debian AMI instable repo lists
- make getExternalIP function match logic from shared.py
- create structure for systemd startup dependencies
- add dsip-init systemd resource
- fix AMI image creation service startup issues
- add detailed debugging options in dsiprouter.sh
- add colored output and cleanup script output
- fix python dependency removal order in uninstall funcs
- add dependency installation for sipsak
- finish separating service install logic to independent functions
- update install/uninstall options to allow for independent installs
- improve path check logic to avoid duplicates
- fix dr_gw_lists import regression (path issue)
- change logo color (no orange in 8-bit so we use cyan now)


---


### Allow Domain Editing

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Mar 2019 18:21:32 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #87
- simplify domain routing
- allow editing in domain route
- update pre commit script


---


### Update kamailio51_dsiprouter.tpl

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Mar 2019 11:57:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fix for Google Cloud Mysql

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 15 Mar 2019 16:15:22 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #47
- add defaults for carrier form
- remove uneeded DB drivers


---


### Fix Regressions

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Mar 2019 21:55:41 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- re-add configureKamailio command to install
- fix DSIP_KAMAILIO_CONFIG_FILE path
- remove uneeded kam code from hotfix


---


### Fix DID Notes DB Update

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Mar 2019 21:27:03 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #123
- set form defaults on db update for inbound did route


---


### General Updates Cleanup Repo

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Mar 2019 10:42:40 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- move rtpengine install to seperate dir
- update git resources
- fix merging issues with modules
- seperate kamailio install function and logic
- add printing functions / colors to install
- update requirements.txt install for stability
- add mysql imports for pipreqs pre-commit updates
- update module sql merging


---


### Tighten Install for Release

> Branches Affected: HA,dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Mar 2019 10:24:40 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix cluster resource waiting stability
- fix intermittent route editing issue
- add centos support for galera replication
- fix centos plugin auth issues


---


### Added support for emergency numbers 911-999 Fixes: #121

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Mar 2019 23:06:11 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### LCR Dynamic Prefix Routing

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Mar 2019 18:07:06 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #122
- add dynamic routing for LCR module (similar to dRouting matches)
- make LCR prefix length configurable in kam config
- update both kamailio template and config files
- general cleanup on kam configs
- update internal IP resolution
- update PATH resolution (fix logic bug)
- fix dsiprouter logrotate path


---


### Add 2 new HA Features

> Branches Affected: HA,dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Mar 2019 10:14:31 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- mysql galera replication
- pacemaker / corosync cluster with floating ip


---


### Make Project root more reliable

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Mar 2019 16:05:08 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add redundancy checking for project root dir


---


### Update Internal IP Resolution

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Mar 2019 23:19:55 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- changed internal ip resolution based on default route
- fix rtpengine config update function
- add rtpcfg variable for later use


---


### Fix kamailio configure Bugs

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Mar 2019 19:25:15 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- drop dr_custom_rules on fresh kam configure
- remove hung locks when adding user


---


### Bug Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Mar 2019 16:02:37 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add curl timeout on AWS check
- make PBX local digit length check globalls configurable
- fix typos
- fix line breaks
- automate merging table data during install


---


### Add Mysql Replication Scripts

> Branches Affected: HA,dmq-feature,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Feb 2019 11:58:06 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- support for group replication
- support for galera replication
- mysql size check script added


---


### Update kamailio51_dsiprouter.tpl

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 21 Feb 2019 16:43:09 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Set the domain flag: register_myself to 0.  This flag was causing Kamailio to get stuck in a continuous loop  when receiving an ACK from an endpoint.  This is due to the fact that Kamailio sees the domains in the domains table reside on the Kamailio server with the register_myself flag being set to 1


---


### Add Useful Scripts To Resources

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 20 Feb 2019 15:12:14 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add changelog merging script
- add some python testing scripts


---


### Update RTPengine On Reload and Install Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 19 Feb 2019 10:50:46 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #115
- update rtpengine config on reboot
- fix misc issues with install script
- fix adding user issue
- update exception function


---


### Initial commit

> Branches Affected: HA,dmq-feature,master,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 15 Feb 2019 16:31:20 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Feb 2019 09:55:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 17:48:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 17:42:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 17:37:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 15:25:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 15:23:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update ngcp-rtpengine-daemon.init

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Feb 2019 13:41:59 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

Fixed an issue with a redirect


---


### Fix Bugs in GUI

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 11 Feb 2019 17:28:28 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix datatable auto width resolution issue
- fix db connection issue
- add dsiprouter flag definitions


---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 23:17:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 23:09:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 23:03:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 23:01:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 22:31:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 22:22:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 22:20:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 22:18:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Feb 2019 14:47:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Inbound DID and Fail2Ban Update

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 22:31:55 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #100
- Resolves #54
- add support for secondary pbx inbound route
- DID failover is supported by adding another rule
- add fail2ban instructions to domain and pbx pages
- small syntax fixes
- update combobox and fix issues
- update inboundroutes routing and DB model


---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 16:02:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 15:24:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### AMI Provisioning Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 14:30:28 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix PATH on install
- dynamic kam config update
- add updatekamconfig cli option
- fix for debian 8 debhelper issue
- fix kamailio and rtpengine user creation
- fix rtpengine default conf file location
- fix firewalld centos ami issue
- fix merge issues (install,installSipsak)
- minor improvements to syslog handler


---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 10:01:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Adds the ability to change the name of the server presented to clients

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Feb 2019 21:28:15 -0700  
> Author: matmurdock (mat.murdock@gmail.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed firewall issues

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 01:18:41 +0000  
> Author: root (root@ip-172-31-11-14.us-east-2.compute.internal)  
> Committer: root (root@ip-172-31-11-14.us-east-2.compute.internal)  



---


### Changed order that firewalld rules are being added.  This is workaround for cloud-init

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 7 Feb 2019 00:31:15 +0000  
> Author: root (root@ip-172-31-31-55.us-east-2.compute.internal)  
> Committer: root (root@ip-172-31-31-55.us-east-2.compute.internal)  



---


### Added fix to the centos 7 kamailio install so that firewall rules can be added

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Feb 2019 23:33:58 +0000  
> Author: root (root@ip-172-31-38-36.us-east-2.compute.internal)  
> Committer: root (root@ip-172-31-38-36.us-east-2.compute.internal)  



---


### Inbound DID Mapping Sort By Name

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Feb 2019 17:36:14 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #76
- sort pbx select list on pbx name
- enable combobox for imported did's
- fix autoselect on add / import did modal


---


### Remove Carrier From gwlist On Delete

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Feb 2019 15:17:34 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #7
- carriers removed from all related dr_rules gwlists on delete
- create alert and warn user that related rules will be updated


---


### Fix Carrier Modal Actions

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Feb 2019 12:28:13 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #96
- replace data-tables ver w/ standalone library
- rename imports


---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Feb 2019 10:41:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed a regression that caused the password not to be set correct when installed on a non-AMI

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Feb 2019 19:30:53 +0000  
> Author: root (root@dSIPRouterMackAMI.localdomain)  
> Committer: root (root@dSIPRouterMackAMI.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Feb 2019 10:23:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed testing scripts

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Feb 2019 06:49:27 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for NOTIFY messages from PBX - which is used to update MWI

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 21:30:19 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 12:34:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 12:13:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 12:09:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 12:01:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 11:44:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 11:34:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 11:31:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 11:29:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 11:11:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Rename troubleshooting.rst.txt to troubleshooting.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 10:27:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update troubleshooting.rst.txt

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 10:25:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update troubleshooting.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 09:45:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Rename troubleshooting.rst.txt to troubleshooting.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 09:40:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the directory path that points to the rsyslog and logrotate settings

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 10:59:09 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Moved the logrotate and syslog to the resouces directory

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Feb 2019 10:05:36 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Unit test for testing Denial of Service (DoS) Attacks

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 1 Feb 2019 11:37:20 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Fixed the SQL script so that it works with the newer versions of MariaDB

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 1 Feb 2019 11:31:56 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Fixed issue with enabling PIKE

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 17:39:16 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 12:29:28 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 12:28:47 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Moved the server_signature parameter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 17:01:01 +0000  
> Author: root (root@dsiprouterMackKamsec.localdomain)  
> Committer: root (root@dsiprouterMackKamsec.localdomain)  



---


### Added a record route before relaying to endpoints to ensure they route all traffic thru the proxy

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 10:36:18 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Added commit 776f17bd9ba1cb7a623803a4bc3f54e6d5954565 by MatMurdock into the template file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 10:15:53 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Fixed an issue with the initial startup of RTPEngine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 09:54:58 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Fixed an issue with dsiprouter.sh running commands in the wrong directory.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 08:55:10 +0000  
> Author: root (root@dsiprouterMackMaster.localdomain)  
> Committer: root (root@dsiprouterMackMaster.localdomain)  



---


### Removed set -x

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 02:58:09 +0000  
> Author: root (root@dsiprouterMackDocs.localdomain)  
> Committer: root (root@dsiprouterMackDocs.localdomain)  



---


### Remove the yaml file used for to host our website originally

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 02:56:26 +0000  
> Author: root (root@dsiprouterMackDocs.localdomain)  
> Committer: root (root@dsiprouterMackDocs.localdomain)  



---


### Fixed a regression that caused sipsak to be installed each time dSIPRouter started

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 31 Jan 2019 02:52:24 +0000  
> Author: root (root@dsiprouterMackDocs.localdomain)  
> Committer: root (root@dsiprouterMackDocs.localdomain)  



---


### Started the development of a test plan for Carrier Registration

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 30 Jan 2019 19:59:01 +0000  
> Author: root (root@dsiprouterDroplet.localdomain)  
> Committer: root (root@dsiprouterDroplet.localdomain)  



---


### AMI Startup Fixes and General Maintenance

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 30 Jan 2019 05:07:37 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #103
- change rtpengine install to be last
- update usage options
- update command line options
- misc formatting improvements
- fix centos ami kam repo issue
- fix centos kamilio startup issue
- fix rtpengine startup issue
- fix debian ami sources issue
- separate rtpengine source repo from project dir
- fix rtpengine kernel packet forwarding issue
- add location dependent redundancy checks in dsiprouter.sh
- improve reliability of dynamic ip resolution
- general cleanup in dsiprouter.sh
- overhaul of arg / option parsing
- improve usage readability
- update usage options


---


### Delete unneeded files

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 29 Jan 2019 23:19:04 +0000  
> Author: root (root@dsiprouterDroplet.localdomain)  
> Committer: root (root@dsiprouterDroplet.localdomain)  



---


### - Added a basic Unit Testing Framework to allow us to test core dSIPRouter functionality - Fixed an issue with CDR's that will allow the SQL needed for CDR's to be ran during install - Added logic to install Sipsak for running Unit Testing and for users that want to troubleshoot SIP message without having a SIP client

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 29 Jan 2019 22:31:59 +0000  
> Author: root (root@dsiprouterDroplet.localdomain)  
> Committer: root (root@dsiprouterDroplet.localdomain)  



---


### Syslog Logging Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 29 Jan 2019 10:44:44 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed syslog config files
- seperate syslog configs in install process
- redirect rtpengine daemon output to syslog
- move syslog log handler to top of imports
- support redirecting stdout / sterr to syslog
- fix function naming to match
- add signal handler func
- add nohup signal handling to python app


---


### Update Logging

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 25 Jan 2019 17:13:50 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- move all logging to syslog
- move all log rotation to logrotate
- add syslog and logrotate as dependencies
- update and create syslog configs for each service
- add werkzurg and sqlalchemy log handlers from pull #36
- add syslog support for dsiprouter app
- add script header in comments
- update app DEBUG variable dynamically


---


### Added ability for 7 Digit numbers

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 25 Jan 2019 14:58:25 -0700  
> Author: Mat Murdock (mat.murdock@gmail.com)  
> Committer: Mat Murdock (mat.murdock@gmail.com)  



---


### Create troubleshooting.rst.txt

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 25 Jan 2019 16:12:07 -0500  
> Author: Nicole (ncannon@goflyball.com)  
> Committer: Nicole (ncannon@goflyball.com)  

- Created documentation for troubeshooting  dSIPRouter, Kamailio and rtpengine when turning logging on and off.
- Includes information:
1 how to turn it on
2. how do to turn it off
3. location of the log files
4. how do i configure it
5. References


---


### Added logic to lookup the uac registration info based on the source ip coming from the carrier since I couldn't grab the realm - Fixed issue #98

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 25 Jan 2019 00:46:48 +0000  
> Author: root (root@dsiprouter.localdomain)  
> Committer: root (root@dsiprouter.localdomain)  



---


### Update global_outbound_routes.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 22 Jan 2019 11:42:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added Pike and disbabled User Agent String

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 18 Jan 2019 22:40:54 +0000  
> Author: root (root@debian-s-1vcpu-1gb-tor1-01.localdomain)  
> Committer: root (root@debian-s-1vcpu-1gb-tor1-01.localdomain)  



---


### Added Pike and disbabled User Agent String

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 18 Jan 2019 22:18:54 +0000  
> Author: root (root@debian-s-1vcpu-1gb-tor1-01.localdomain)  
> Committer: root (root@debian-s-1vcpu-1gb-tor1-01.localdomain)  



---


### ChanSIP Documentation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 Jan 2019 13:33:50 -0500  
> Author: Nicole (ncannon@goflyball.com)  
> Committer: Nicole (ncannon@goflyball.com)  

- added images for chan sip
- added work flow for chan sip


---


### Install Script Fixes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 14 Jan 2019 17:21:32 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Fix project path for absolute path resolution
- Fix cron jobs for empty crontab use case


---


### Install Script Improvement

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 14 Jan 2019 15:19:01 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- create cronAppend and cronRemove library functions
- replace overwriting cron commands
- change permissions on git hook


---


### Merge with Master

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 14 Jan 2019 14:29:25 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Merge with Master branch
- update ami build to clone from feature branch


---


### AMI updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 10 Jan 2019 13:12:12 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add getInstanceID to library script
- allow independent execution of changelog hook
- update ami bootstrap commands to be more robust
- fix debian ami sys-maint user bug
- fix PID check for startup process
- fix python version check bug
- added comments


---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 9 Jan 2019 15:46:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add Changelog

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 9 Jan 2019 09:27:47 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #81
- Add changelog markdown file
- Add git hook for generating changelog


---


### Update to Commit 2e7acf4

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 7 Jan 2019 16:42:13 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- move AMI checks for debian before end of function
- to ensure we do not return false positive to calling script


---


### AWS Image Debian Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 7 Jan 2019 16:34:28 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add support for debian AMI build
- apply AWS AMI policies for debian build


---


### External IP BUG fix

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 4 Jan 2019 15:35:12 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- catch errors on external IP resolution failure
- add commandline option for setting external ip
- change permisions on ami build script


---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 3 Jan 2019 23:29:41 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Updates for AMI install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 2 Jan 2019 09:21:48 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- update debian-based install for unattended install


---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 29 Dec 2018 14:47:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the install function so that dSIPRouter starts up after the install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 29 Dec 2018 19:13:47 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 18:17:17 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 18:16:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an issue that stoped dSIPRouter from starting up after the install.  Also, started to decouple the dSIPRouter UI from the rest of the install - Docker here we come

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 23:14:33 +0000  
> Author: root (mack@dsiprouter.org)  
> Committer: root (mack@dsiprouter.org)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 16:44:29 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 16:26:47 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 09:29:15 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 09:27:50 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:55:49 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:49:36 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:48:39 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:48:15 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create centos-install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:45:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:44:38 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update debian_install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:43:17 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:41:57 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create debian_install.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:35:38 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:34:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the CentOS 7 install so that MariaDB starts before Kamailio

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 13:31:54 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Fixed RTPEngine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 10:04:49 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Removed the yum update from the RTPEngine install section for CentOS - it was causing us to reboot before completing the install of RTPEngine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 09:03:40 +0000  
> Author: root (mack.hendricks@gmail.com)  
> Committer: root (mack.hendricks@gmail.com)  



---


### Fixed issues with installing on CentOS 7

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 28 Dec 2018 08:30:51 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Fixed the hostname of the service that provides the external ip of the server

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Dec 2018 20:23:43 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Fixed the hostname of the service that provides the external ip of the server

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 27 Dec 2018 20:23:43 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### AMI build updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 16:35:14 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add ami build script for v0.52
- fix firewalld not started bug
- change rtpengine install to bootstrap on restart of AMI image
- fix rc.local format bug from last commit
- add descriptive comments
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### AMI image pw reset fix

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 13:50:05 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix AMI pw reset bug


---


### Fix AMI bootstrap file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 13:32:35 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed bootstrap file test


---


### Updates for AMI image install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 12:34:30 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix bootstrap file not to interfere with other cmds
- fix centos rtpengine install
- make centos rtpengine failure stop install


---


### Fixes to AMI image support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 11:50:49 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fix logical check for bootstrap file
- add cmdExists function to dsip_lib


---


### Updated restart message for AMI instances.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 11:34:04 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Add support for AMI images

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 21 Dec 2018 11:21:36 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- add support for installing on AMI images
- fixed small typos in install script
- fixed error message when restarting process
- fixed centos kernel headers install issue


---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.511-rel  
> Date: Wed, 19 Dec 2018 15:03:28 -0600  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:18:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:12:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:11:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:10:04 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:07:45 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:05:32 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:59:21 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:57:55 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:57:05 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 06:59:11 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 06:57:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: root (root@debian-post51.localdomain)  



---


### Fixed the BYE issue #56 for FusionPBX as well

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 19:05:34 +0000  
> Author: root (root@debian-post51.localdomain)  
> Committer: root (root@debian-post51.localdomain)  



---


### Fixed issue #56

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 17:40:05 +0000  
> Author: root (root@demo-dsiprouter.localdomain)  
> Committer: root (root@demo-dsiprouter.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:29:40 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:20:09 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:18:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:12:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:11:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:10:04 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:07:45 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 10:05:32 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:59:21 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:57:55 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 09:57:05 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 08:56:39 -0600  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 06:59:11 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 06:57:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added files for documenting FreePBX - Pass Thru

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 19 Dec 2018 05:53:52 -0600  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 18 Dec 2018 05:43:29 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 18 Dec 2018 05:28:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Dec 2018 10:22:00 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Dec 2018 10:21:30 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed domain support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Dec 2018 12:02:33 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Dec 2018 04:37:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:46:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:41:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:35:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:15:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:13:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:12:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:11:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 15:01:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:59:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:51:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:49:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:21:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:18:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create upgrade.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:14:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 14:12:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:40:17 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:39:57 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:13:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:11:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:08:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:06:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 13:04:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 12:55:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the Global Outbound Route issue that prevented routes from being saved

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 17:50:50 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 12:50:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 12:48:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 12:02:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:58:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:29:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:25:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:25:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:22:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 11:21:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 14 Dec 2018 10:34:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:34:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:33:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:11:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:10:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:05:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:04:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 21:03:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:51:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:50:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:45:03 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:43:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:41:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:38:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:36:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:32:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:19:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:17:17 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:15:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 20:11:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 13:06:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 13:03:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 13:00:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 11:17:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:43:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:16:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:12:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:08:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:06:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:02:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 10:01:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 09:58:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 09:57:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 09:55:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 09:54:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed Javascript error

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 13 Dec 2018 14:22:16 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Rename Resources.rst to resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 15:20:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update Resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 15:19:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update Resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:58:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:58:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update Resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:53:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create Resources.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:46:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:24:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 12 Dec 2018 13:17:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed issues with FusionPBX Sync and the ability to delete PBX's

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 22:13:47 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:16:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:15:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:13:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:11:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:09:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 12:05:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 11 Dec 2018 09:34:03 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 10 Dec 2018 15:30:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the creation of static routes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 9 Dec 2018 13:08:25 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Simplfied the Multidomain support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 19:56:09 +0000  
> Author: root (root@debian-dsip-test.localdomain)  
> Committer: root (root@debian-dsip-test.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 12:24:48 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 12:21:50 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Changes to fix the GUI

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 16:58:59 +0000  
> Author: root (root@debian-v51.localdomain)  
> Committer: root (root@debian-v51.localdomain)  



---


### Fixed an issue Javascript error that was preventing Fusion Support toggle button from working

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 15:49:54 +0000  
> Author: root (root@debian-v51.localdomain)  
> Committer: root (root@debian-v51.localdomain)  



---


### Fixed an issue with datatables that was causing a JS error

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 8 Dec 2018 14:46:09 +0000  
> Author: root (root@debian-v51.localdomain)  
> Committer: root (root@debian-v51.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:54:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:44:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:43:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:37:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update install_option

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:33:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:30:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create install_option

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 22:29:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 19:30:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 19:25:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 17:52:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 15:37:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 15:35:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 14:48:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 14:40:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 14:37:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:54:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:53:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:51:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:48:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:48:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete list_of_domains1.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:46:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:43:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:41:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 10:38:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 09:11:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 09:09:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 09:09:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 09:01:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 09:00:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Dec 2018 08:59:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:17:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:17:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:14:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:12:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:11:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:10:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:08:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:06:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:05:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:05:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:04:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:03:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 15:01:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:56:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:55:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:54:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete zoiper_example.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:54:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:53:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:49:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:47:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:46:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:44:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:26:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:12:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:06:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:05:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 14:05:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:12:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:11:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:11:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:07:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:06:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:06:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:05:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:05:17 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 13:04:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:57:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:55:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:54:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete 11d_dialplan2.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:53:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dialplan_11.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:53:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:52:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:51:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:50:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:49:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:45:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:43:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:42:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:36:03 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:34:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:30:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:26:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:20:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:20:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 12:19:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:56:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:19:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:17:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:17:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:16:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:15:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:13:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:11:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:11:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:11:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:09:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:08:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:07:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:06:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:05:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:04:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:02:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 11:00:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:56:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:29:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:28:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:27:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:22:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:21:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete 11d_dialplan2.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 10:19:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Dec 2018 09:42:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an issue with sync'ing with FusionPBX servers

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 21:40:25 +0000  
> Author: root (root@debian-v51.localdomain)  
> Committer: root (root@debian-v51.localdomain)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:10:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:09:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:08:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:08:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:07:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:06:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:06:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:05:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:05:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:04:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:03:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:02:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:02:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:01:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:01:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:01:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 16:00:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:59:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:50:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:49:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:49:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:48:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:46:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:45:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:44:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:40:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:40:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:39:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:38:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:37:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:33:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:33:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:32:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:27:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:26:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:25:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 15:24:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update and rename uninstalling.rst to command_line_options.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 12:39:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 12:38:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 12:09:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update uninstalling.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 12:05:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update uninstalling.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 12:04:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update and rename uninstalling dSIPRouter.rst to uninstalling.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 11:54:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create uninstalling dSIPRouter.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 11:52:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 11:50:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 11:49:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Dec 2018 11:48:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:59:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:57:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:47:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dialplan_11d.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:41:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:36:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:35:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 14:27:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:26:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:24:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:20:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:17:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:04:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 10:02:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 09:46:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Dec 2018 09:43:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:48:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:18:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:16:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:15:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:13:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:11:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:10:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete fusionpbx_hosting2.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 14:09:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:59:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:58:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:56:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:55:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:53:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:50:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:49:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:47:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:45:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:44:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:43:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:42:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:39:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:34:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:33:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:30:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:28:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:26:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:22:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:22:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:20:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:19:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete 11d_dialplan_2.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:19:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 13:18:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 12:29:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 12:28:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 12:03:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 11:54:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 11:52:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 11:48:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 11:38:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 3 Dec 2018 11:23:17 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:34:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:30:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:28:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:07:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:03:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 30 Nov 2018 11:01:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 14:20:03 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 14:17:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 14:17:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:42:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:41:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:37:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:36:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:33:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:31:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:31:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:26:54 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:23:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 13:02:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:57:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:56:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:55:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:54:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:51:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:50:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:48:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:45:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:43:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:41:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:38:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:35:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:34:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:33:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:30:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:25:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:23:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:22:30 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 12:21:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 10:42:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 29 Nov 2018 10:40:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 16:02:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update global_outbound_routes.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 16:00:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:53:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:35:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:35:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:32:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:31:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:26:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:25:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:24:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:23:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:21:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:20:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:19:03 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:15:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 15:09:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 14:23:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 14:19:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 14:05:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 14:03:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 13:01:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 13:00:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:58:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:57:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:52:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:51:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:47:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:45:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:40:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:33:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:28:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 12:27:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 28 Nov 2018 09:34:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:43:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:42:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:38:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:37:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:36:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:34:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete IP authenication.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:34:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:34:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:30:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:08:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:07:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 15:05:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 14:56:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 10:43:19 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update global_outbound_routes.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 10:03:20 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create global_outbound_routes.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 10:02:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 10:01:52 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 09:58:34 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 09:45:20 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 09:43:18 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 09:26:36 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Letsencrypt will not work since the machine doesn't have a routeable domain name

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Nov 2018 00:22:51 +0000  
> Author: mhendricks (root@debian-dsip-51-build.localdomain)  
> Committer: mhendricks (root@debian-dsip-51-build.localdomain)  



---


### Fixed some more conflicts with datatables.js

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Nov 2018 20:54:13 +0000  
> Author: mhendricks (root@debian-dsip-51-build.localdomain)  
> Committer: mhendricks (root@debian-dsip-51-build.localdomain)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Nov 2018 15:07:45 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Nov 2018 15:00:14 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Nov 2018 14:40:39 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete sip_trunking_freepbx_pjsip.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 26 Nov 2018 14:34:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 14:50:49 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 14:50:11 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 14:49:29 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 13:21:59 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 13:19:48 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 13:15:29 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 13:14:37 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 13:12:52 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Nov 2018 08:37:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Applied a patch to deal with the stale database connections, Fixed Carrier Registraton so that the Registrar Server IP is addeded to the Address table, Fixed a conflict with the datatables javascript file that was preventing other javascript from operating correctly

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Nov 2018 04:00:41 +0000  
> Author: mhendricks (root@debian-dsip-51-build.localdomain)  
> Committer: mhendricks (root@debian-dsip-51-build.localdomain)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 14:46:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 13:10:42 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 13:04:50 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 13:02:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 13:00:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 13:00:02 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 12:35:30 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create use-cases.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 16 Nov 2018 12:33:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add SSL configuratoin to install script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 18:29:46 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- added ssl default configuration to install process


---


### Fixed an issue that prevented the nginx docker image from starting after the server is rebooted

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 22:54:23 +0000  
> Author: root (root@debian-dsip-51-build.localdomain)  
> Committer: root (root@debian-dsip-51-build.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 14:58:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 14:56:47 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 14:54:40 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 14:53:00 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 14:50:33 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Turned off the debug statement

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.51-rc1  
> Date: Thu, 15 Nov 2018 11:57:05 +0000  
> Author: root (root@dSIPRouter-v051-build.localdomain)  
> Committer: root (root@dSIPRouter-v051-build.localdomain)  



---


### Update dsiprouter.sh

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 06:50:58 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed installer on Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 15 Nov 2018 11:39:56 +0000  
> Author: root (root@dSIPRouter-v051-build.localdomain)  
> Committer: root (root@dSIPRouter-v051-build.localdomain)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 13 Nov 2018 19:42:43 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 13 Nov 2018 19:37:33 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 13 Nov 2018 19:12:03 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:56:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:55:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:14:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:10:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:09:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:02:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 14:00:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:57:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:56:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:54:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:51:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:46:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:44:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:43:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:18:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:16:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:12:47 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 13:11:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:27:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:19:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:17:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete list_of_domains.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:16:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete add_new_domain2.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:16:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:05:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:04:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 12:01:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 11:57:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Nov 2018 11:50:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:53:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:51:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:49:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:46:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:45:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:43:28 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:42:50 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:32:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:32:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:31:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:30:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:29:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:29:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:28:40 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:26:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:25:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:24:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:23:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:22:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:20:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:19:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:11:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:10:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:10:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 15:09:27 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:51:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:50:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:50:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:49:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:47:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete add_carrier_details.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:46:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete add_new_carrier_details.JPG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:45:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:44:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:44:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:42:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 14:37:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:28:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:25:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:20:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:19:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:18:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:16:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:15:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 11:02:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 10:56:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:19:02 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:16:38 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:12:44 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:09:13 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:08:41 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:08:23 -0800  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:32:40 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:23:15 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 07:06:50 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 06:58:12 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 8 Nov 2018 06:55:24 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:21:13 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:19:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete list_of_domains.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:19:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:16:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:15:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:03:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 15:02:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:58:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:56:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:56:12 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:40:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:39:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:38:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:37:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:35:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:20:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:20:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:20:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:19:17 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:18:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:17:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:14:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:08:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:03:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 14:02:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:59:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:58:33 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:57:09 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:52:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:51:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:47:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:46:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:45:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete add_carrier_details.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:13:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:09:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:08:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:01:46 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:00:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 13:00:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:58:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:57:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:57:22 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:52:17 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:47:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:45:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:44:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:43:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:42:15 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:38:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:35:37 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 12:31:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create domains.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 10:25:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Nov 2018 10:03:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 21:04:54 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_PBX_ADD_New_PBX.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 21:04:32 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 21:02:41 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_PBX_ADD_New_PBX.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 21:02:17 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:58:16 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_dashboard.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:57:58 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:57:31 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_PBX_Add.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:57:13 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:56:42 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_PBX_ADD_New_PBX.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:56:21 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:55:37 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_IN_Manual_Add.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:55:19 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:54:42 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_IN_Import_DID.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:54:15 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:53:28 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_IN_DID_Map.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:53:03 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:40:18 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:31:15 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:29:05 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:23:05 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:14:20 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 20:07:53 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 19:56:22 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 19:56:12 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dSIP_IN_Manual_Add.png

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 19:55:49 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 19:46:07 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:32:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:23:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:22:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:21:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:21:11 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:20:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:19:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:18:53 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:18:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:16:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:14:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:11:44 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:11:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:10:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 16:06:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:55:10 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:46:15 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:45:16 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:44:02 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dsiprouter-carriers.jpg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:42:34 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:40:41 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 15:39:43 -0500  
> Author: jornsby (44816622+jornsby@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:36:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:35:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:29:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete config pic.PNG

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:28:38 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:26:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:25:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:20:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:13:24 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:12:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:12:18 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:11:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:10:26 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 14:05:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:57:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:15:55 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:14:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:13:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:11:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:09:14 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:08:39 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 13:07:59 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:51:20 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:50:43 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:49:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:42:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:38:07 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:35:21 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 12:19:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed a number of GUI related issues and fixed issues with sort and search

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 11:58:54 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:45:33 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:43:23 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:42:56 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:42:16 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:34:47 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create pbxs_and_endpoints.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:32:36 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:29:25 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:27:25 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:24:48 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Rename configuring.rst to carrier_groups.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:24:06 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:20:11 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:17:50 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create configuring.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:12:18 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:01:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 06:00:54 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:59:05 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:57:19 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:54:18 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:52:57 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:46:33 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:43:39 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:37:44 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:36:12 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:33:26 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:30:21 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:26:09 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:16:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:16:01 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create installing.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 6 Nov 2018 05:15:20 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 15:09:34 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 15:07:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:54:25 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:49:08 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:41:10 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:39:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:38:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:36:31 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:28:04 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:26:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:23:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:20:36 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:19:02 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 14:14:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:58:16 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:53:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:51:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:44:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:33:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 13:27:06 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:45:23 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:44:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:41:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:38:42 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:35:32 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:34:57 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:32:51 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:30:00 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:13:41 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:09:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:08:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 12:05:52 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:59:29 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:57:01 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:55:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:54:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:51:58 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:46:49 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:33:19 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:30:35 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:27:45 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:25:48 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 11:23:05 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 10:38:56 -0500  
> Author: ncannon01 (44709249+ncannon01@users.noreply.github.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:33:09 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:31:49 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:30:16 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:26:13 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:24:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:24:17 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:20:39 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Nov 2018 09:16:01 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:37:21 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:34:45 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:31:30 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:26:43 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:26:03 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:24:07 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 14:18:50 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 13:29:48 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Create index.rst

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Nov 2018 13:10:31 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added the notes field to the add and edit modal's for Inbound Mappings

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 1 Nov 2018 11:55:07 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Added support for importing one of more DID's Issue #84

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 1 Nov 2018 04:31:47 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Added support for sorting, searching and pagination to the domain page.  This sort can also be added to other pages as well since the library is now added Issue #84

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 30 Oct 2018 04:07:50 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Update CONTRIBUTING.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 24 Oct 2018 16:00:59 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update CONTRIBUTING.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 24 Oct 2018 15:59:39 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added Domain Management features and added a new approach to adding modules to dSIPRouter, which will be documented in the Contribution Guide.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 22 Oct 2018 09:26:48 +0000  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  

- Static and Dynamic domains can be displayed in the GUI.
- Added a UnitTest to validate the Domain Management Services


---


### Merge asterisk-realtime and latest updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Sep 2018 20:14:59 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- allow cluster db installation config
- auto update cluster params in kamconfig
- condense kamconfig files (using ifdefs)
- merge current SIPWISE kamconfig
- merge asterisk-realtime branch
- fix NAT issues
- auto update kamversion in kamconfig
- upgrade version / release functions
- improve install script util functions
- add import library to install script
- section out user configurable settings
- make install script vars easier to use
- remove placeholder in docs
- add TODO statements
- add current asterisk-realtime resources
- add possible rtpengine fix in resources
- add module install echo statements
- allow SSL keys on debug
- update OS dependencies
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Create CONTRIBUTING.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Sep 2018 00:10:20 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  

initial guide


---


### Added support for working with a Kamailio subscriber table and tested it against FreePBX

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 26 Sep 2018 14:17:05 -0400  
> Author: root (root@kamailio3.kamailo3@lhsip.com)  
> Committer: root (root@kamailio3.kamailo3@lhsip.com)  



---


### Added support for enriching sip headers and added record_route support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Sep 2018 12:46:52 +0200  
> Author: root (root@reg-01.voipmuch.com)  
> Committer: root (root@reg-01.voipmuch.com)  



---


### Using sippasswd field within Asterisk Realtime to validate user passwords

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 24 Sep 2018 09:59:23 +0200  
> Author: root (root@reg-01.voipmuch.com)  
> Committer: root (root@reg-01.voipmuch.com)  



---


### weezy was specified instead of stretch

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 23 Sep 2018 18:50:20 +0200  
> Author: root (root@reg-01.voipmuch.com)  
> Committer: root (root@reg-01.voipmuch.com)  



---


### Initial commit for Asterisk Realtime Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 23 Sep 2018 15:27:06 +0000  
> Author: root (root@dsiprouter-dev.localdomain)  
> Committer: root (root@dsiprouter-dev.localdomain)  



---


### Add CentOS support v0.51

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 10 Sep 2018 20:15:22 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #30
- Resolves #69
- merge changes with v5.1
- remove python prompt
- change validate to allow centos v7
- add centos checks in install functions
- fix distro / OS version checks
- fix centos uninstall funcs
- automate kamdbctl password prompt (edit config)
- add module install support for centos
- unset exported vars/funcs on exit (cleanup)
- get rid of kamailio db prompt
- allow debug in all commands (1st param only)
- various fixes for install scripts
- add util / library script
- improve distro version checks
- fixes for db error handling in dsiprouter.py
- re-add serving https through ssl certs (settings.py)
- improve file parsing in updateConfig()
- fix default mysql csv's (broken from last commit)
- enable cdrs by default
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Changed the default role in Kamailio to '' for all

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Sep 2018 01:03:43 -0500  
> Author: root (root@969092-extapp1.inemsoft.com)  
> Committer: root (root@969092-extapp1.inemsoft.com)  



---


### Raw fixes for centos 7 support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 7 Sep 2018 00:05:37 -0500  
> Author: root (root@969092-extapp1.inemsoft.com)  
> Committer: root (root@969092-extapp1.inemsoft.com)  



---


### Adding support for centos 7

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Sep 2018 17:54:35 -0500  
> Author: root (root@969092-extapp1.inemsoft.com)  
> Committer: root (root@969092-extapp1.inemsoft.com)  



---


### Added support for centos 7

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Sep 2018 17:20:57 -0500  
> Author: root (root@969092-extapp1.inemsoft.com)  
> Committer: root (root@969092-extapp1.inemsoft.com)  



---


### Adding support back for centOS 7

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 6 Sep 2018 17:03:58 -0500  
> Author: root (root@969092-extapp1.inemsoft.com)  
> Committer: root (root@969092-extapp1.inemsoft.com)  



---


### Provided comments in settings.py and added support for giving dSIPRouter roles

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 5 Sep 2018 06:54:27 -0400  
> Author: root (root@kamailio3.kamailo3@lhsip.com)  
> Committer: root (root@kamailio3.kamailo3@lhsip.com)  



---


### Added support for Roles.  Now a dSIPRouter instance can have a Role in the tolopology

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Sep 2018 04:40:53 -0400  
> Author: root (root@kamailio2.lhsip.com)  
> Committer: root (root@kamailio2.lhsip.com)  



---


### Fixed an issue with SSL properties not being pulled corrected from the settings.py file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Sep 2018 03:14:59 -0400  
> Author: root (root@kamailio3.kamailo3@lhsip.com)  
> Committer: root (root@kamailio3.kamailo3@lhsip.com)  



---


### Fixed an issue with SSL properties not being pulled corrected from the settings.py file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Sep 2018 03:11:02 -0400  
> Author: root (root@kamailio3.kamailo3@lhsip.com)  
> Committer: root (root@kamailio3.kamailo3@lhsip.com)  



---


### Changes to support single tenant

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 4 Sep 2018 03:00:25 -0400  
> Author: root (root@kamailio3.kamailo3@lhsip.com)  
> Committer: root (root@kamailio3.kamailo3@lhsip.com)  



---


### Fixed #71 - Added support for GUI Session timeout activity Fixed #72 - Cleaned up exception code around database connection

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 2 Sep 2018 14:20:45 +0000  
> Author: root (root@demo-dsiprouter.localdomain)  
> Committer: root (root@demo-dsiprouter.localdomain)  



---


### Freepbx & Flowroute Feature Release v0.51

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 Aug 2018 23:59:18 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- Resolves #1
- Resolves #65
- add pbx registration forwarding
- add single tenant pbx domain routing
- add flowroute did importing
- fix fusionpbx conflicts with domain table
- add generic multidomain pbx support
- add syntax highliting in <code> blocks
- add / optimize css vendor prefixes (autoprefix)
- add combobox widget to inboundmapping view
- add new icons for combobox widget
- improved element disable functions
- improved error view allowing debug messages
- add custom domain tables to install script
- fix nat reply bug in kamailio configs
- merge new updates into kam44 config file
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Updated the logo's

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 Aug 2018 14:00:15 +0000  
> Author: root (root@dsiprouter-v50-final.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Fixed the PBX screen to ensure that ip auth is working, added fusionpbx as the default fusionpbx database username

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 Aug 2018 12:50:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Fixed issue with main navigation not showing the the proper color when a navigation button is not clicked

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 27 Aug 2018 12:03:09 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Updated the login screen

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 27 Aug 2018 11:15:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Fixed the issue with curl not returning the external ip address.  I changed out the URL that was being used to get the external ip address

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 26 Aug 2018 02:50:35 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Cleaned up a duplicate install function

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 24 Aug 2018 11:56:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Revert "Revert "Add UI bug fix commits to v0.50""

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 23 Aug 2018 17:00:25 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Revert "Add UI bug fix commits to v0.50"

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 23 Aug 2018 10:50:30 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Updated the logo's

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.50  
> Date: Tue, 28 Aug 2018 14:00:15 +0000  
> Author: root (root@dsiprouter-v50-final.localdomain)  
> Committer: root (root@dsiprouter-v50-final.localdomain)  



---


### Fixed the PBX screen to ensure that ip auth is working, added fusionpbx as the default fusionpbx database username

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 28 Aug 2018 12:50:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: root (root@dsiprouter-v050.localdomain)  



---


### Fixed issue with main navigation not showing the the proper color when a navigation button is not clicked

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 27 Aug 2018 12:03:09 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: root (root@dsiprouter-v050.localdomain)  



---


### Updated the login screen

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 27 Aug 2018 11:15:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: root (root@dsiprouter-v050.localdomain)  



---


### Fixed the issue with curl not returning the external ip address.  I changed out the URL that was being used to get the external ip address

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 26 Aug 2018 02:50:35 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: root (root@dsiprouter-v050.localdomain)  



---


### Cleaned up a duplicate install function

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 24 Aug 2018 11:56:03 +0000  
> Author: root (root@dsiprouter-v050.localdomain)  
> Committer: root (root@dsiprouter-v050.localdomain)  



---


### Revert "Revert "Add UI bug fix commits to v0.50""

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 23 Aug 2018 17:00:25 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Revert "Add UI bug fix commits to v0.50"

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 23 Aug 2018 10:50:30 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### UI Bug Fixes in v0.50 continued..

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Aug 2018 17:05:18 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed login page styles
- fixed table styles
- fixed update on pbx endpoint
- fixed auth radio toggle
- fixed uacreg import csv values
- fixed update on uac table to enable flag
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### UI Bug Fixes in v0.50

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 10 Aug 2018 19:23:30 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- fixed toggle button listeners
- fixed pbx modal listener (not populating)
- fixed reload button refreshing on ajax call
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Fix runtime error

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 9 Aug 2018 14:07:11 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

- change default server to use multi-threading
- fix hanging comma in dsiprouter.py
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Squash Commits and Merge with Master

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 9 Aug 2018 11:35:31 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  

commit 3eb7182214594dfbbe3701487bb959f0aec4b08d
Merge: 8582913 6bbc7de
Author: Tyler Moore <tmoore@goflyball.com>
Date:   Thu Aug 9 11:12:24 2018 -0400
- Merge remote-tracking branch 'origin/carrier-modal' into carrier-modal
- Conflicts:
- gui/settings.py

commit 85829134650ee4598f3c42db063b00f2ef16b4e8
Author: Tyler Moore <tmoore@goflyball.com>
Date:   Wed Aug 8 22:33:01 2018 -0400

- v.50 Final Commit
- Resolves #1
- Resolves #4
- Resolves #6
- Resolves #55
- Resolves #58
- Resolves #62
- Resolves #63
- various DB query fixes
- carrier delete fix
- debug defaults set for production
- custom icons added
- Jquery queries optimized
- JS library source map files fixed
- HTTP errors fixed
- resolving IP dynamically
- HTML errors fixed
- toggle buttons fixed
- query selector shadowing id's fixed
- radio button listeners fixed
- modal nesting fixed
- modal scrolling fixed
- modal styles fixed
- add exception handling throughout API
- add endpoint debugging when debug enabled
- finish carrier group modal features
- jinja macro additions
- add gateway group configuration defaults
- dr_gw_lists table
- uacreg table
- dr_gateways table (update)
- address table (update)
- install script fixes for kamailio config added
- added group name editing feature
- add conversion functions
- change version number
- many more small bug fixes / tweaks.. see diff
- Signed-off-by: Tyler Moore <tmoore@goflyball.com>

commit 6bbc7defae59a6da1b8c146370621bb845fb9091
Author: Tyler Moore <tmoore@goflyball.com>
Date:   Wed Aug 8 22:33:01 2018 -0400

- v.50 Final Merge
- Resolves #1
- Resolves #4
- Resolves #6
- Resolves #55
- Resolves #58
- Resolves #62
- Resolves #63
- various DB query fixes
- carrier delete fix
- debug defaults set for production
- custom icons added
- Jquery queries optimized
- JS library source map files fixed
- HTTP errors fixed
- resolving IP dynamically
- HTML errors fixed
- toggle buttons fixed
- query selector shadowing id's fixed
- radio button listeners fixed
- modal nesting fixed
- modal scrolling fixed
- modal styles fixed
- add exception handling throughout API
- add endpoint debugging when debug enabled
- finish carrier group modal features
- jinja macro additions
- add gateway group configuration defaults
- dr_gw_lists table
- uacreg table
- dr_gateways table (update)
- address table (update)
- install script fixes for kamailio config added
- added group name editing feature
- add conversion functions
- many more small bug fixes / tweaks.. see diff
- Signed-off-by: Tyler Moore <tmoore@goflyball.com>

commit e14c688bd7b11145061d913a80236da0ad509eb6
Author: Tyler Moore <tmoore@goflyball.com>
Date:   Sun Jul 29 16:31:29 2018 -0400

- Feature Addition: Carrier Groups
- modifiy / resolves #57
- resolves #60
- resolves #9
- This commit is for v0.50
- https://github.com/dOpensource/dsiprouter/tree/v0.50
- Add new carrier gruop route
- Add UAC carrier registration
- Add Voxbone carrier to default
- Various backend additions
- Add support for gw_lists table in DB
- Fix table border in GUI
- Fix GUI hideen modal / input selection bugs
- Fix GUI modal input field data populating
- Add notes for frontend improvements
- Fix update config file
- Add dynamic ip / domain methods
- Various other fixes in commit changes

commit 9e0e97755ad3f87b366b162c13761ab5fec21d38
Author: Tyler Moore <tmoore@goflyball.com>
Date:   Tue Jul 10 20:05:33 2018 -0400

- 57] Feature Addition: Unique Domain Name Per PBX
- resolves #57
- This commit is for v0.50 https://github.com/dOpensource/dsiprouter/tree/v0.50
- See screenshots in: dsiprouter/docs/images/features/pbx_domain

commit b67161169bbba39abb6327c9cefb1ee28961e743
Author: root <root@dsiprouter-dev.localdomain>
Date:   Mon Jul 2 21:21:48 2018 +0000

- Removed the uk_cfk index
Signed-off-by: Tyler Moore <tmoore@goflyball.com>


---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 6 Jul 2018 09:09:59 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 6 Jul 2018 09:09:05 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update kamailio51_dsiprouter.cfg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 3 Jul 2018 17:09:44 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Removed the uk_cfk index

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 2 Jul 2018 21:21:48 +0000  
> Author: root (root@dsiprouter-dev.localdomain)  
> Committer: root (root@dsiprouter-dev.localdomain)  



---


### Removed the uk_cfk index

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 2 Jul 2018 21:21:48 +0000  
> Author: root (root@dsiprouter-dev.localdomain)  
> Committer: root (root@dsiprouter-dev.localdomain)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Jun 2018 04:04:27 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Jun 2018 04:03:13 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 26 Jun 2018 03:57:51 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed the dSIPRouter logo

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 24 Jun 2018 23:47:17 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Removed install script logic out for right now

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 24 Jun 2018 22:37:43 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed the script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 24 Jun 2018 22:21:12 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Added dSIP ascii logo  after the installation process

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 24 Jun 2018 22:19:51 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed an issue with the function that added the firewall rule

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 23 Jun 2018 00:02:24 +0000  
> Author: root (root@p2.detroitpbx.com)  
> Committer: root (root@p2.detroitpbx.com)  



---


### Fixed issues to support Domain Routing with FusionPBX and to support hosting images for endpoint devices like the Polycom

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 22 Jun 2018 15:57:56 +0000  
> Author: root (root@p1.detrotpbx.com)  
> Committer: root (root@p1.detrotpbx.com)  



---


### Added changed to support proper BYE propagation when using Domain Routing with FusionPBX

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Jun 2018 01:00:15 +0000  
> Author: root (root@p1.detrotpbx.com)  
> Committer: root (root@p1.detrotpbx.com)  



---


### Fixed an issue with a missing compiler directive and support for UPDATE SIP messages

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 17 Jun 2018 02:18:09 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Disabled server NAT by default

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 16 Jun 2018 09:39:13 +0000  
> Author: root (root@ip-172-31-53-160.ec2.internal)  
> Committer: root (root@ip-172-31-53-160.ec2.internal)  



---


### Fixed issues with SERVERNAT feature

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Jun 2018 00:58:41 -0500  
> Author: Mack (mack@dopensource.com)  
> Committer: Mack (mack@dopensource.com)  



---


### Fixed an issue with Outbound routes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Jun 2018 03:42:36 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Adding the javasript file for bootstrap validation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 13 Jun 2018 07:18:43 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed some issues with Javascript validation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 12 Jun 2018 20:16:07 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed the rtpengine parameter that specifies the protocol used to communicate between Kamailio and RTPEngine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 12 Jun 2018 14:36:58 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixes #44  issues with installer and logrotate

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 12 Jun 2018 14:16:22 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed issue with install of SERVERNET

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 12 Jun 2018 13:02:31 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Added the 0.41 version

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 12 Jun 2018 12:05:33 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixes 51 - Fixed the update logic when an existing LCR prefix is already defined, but you want to update it

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Jun 2018 22:54:09 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Added some comments and a record_route() when routing to PBX's

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Jun 2018 21:43:50 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Changed the URI to /provision

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Jun 2018 17:07:25 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed an issue that was preventing the docker engine to install properly.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 8 Jun 2018 19:01:35 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixed #51 - Added more exception handling to handle updates

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 6 Jun 2018 18:18:13 -0400  
> Author: root (root@siprtr-1.mercury.net)  
> Committer: root (root@siprtr-1.mercury.net)  



---


### Fixes #52 - Added iptables-save to the list of steps needed to active FusionPBX support.  Without this option the iptables rule will not be added during the next reboot

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Jun 2018 11:24:11 +0000  
> Author: root (root@dsiprouter-v0.41-dev)  
> Committer: root (root@dsiprouter-v0.41-dev)  



---


### Fixes #51 - The update logic for Outbound Routes was refactored

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 5 Jun 2018 07:17:27 -0400  
> Author: root (root@siprtr-1.mercury.net)  
> Committer: root (root@siprtr-1.mercury.net)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 27 May 2018 19:44:18 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 27 May 2018 19:42:49 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixes #49 - SIP OPTION messages will be handled by only replying to them is the source ip address is a defined carrier or pbx/endpoint

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 27 May 2018 07:39:59 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Added configuration files for logrotate so that log files are rotated

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 22 May 2018 15:14:56 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed an issue with dsiprouter command line

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 21 May 2018 11:46:15 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.40  
> Date: Thu, 17 May 2018 10:36:24 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an error with the RTPEngine install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 May 2018 03:40:09 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Set RTPEngine to start after it's installed

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 May 2018 03:29:12 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed the configuration file for setting up RTP Engine on Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 May 2018 03:09:46 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 May 2018 07:11:48 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 May 2018 07:07:40 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 10:40:41 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 10:39:42 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 10:37:01 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 10:32:24 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 10:19:35 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an issue with username/password auth Fixes #39

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 07:40:10 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### New Logo and GUI Fixes - Fixes #40

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 May 2018 07:16:08 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed the csv file so that each carrier contains a name: in the tags/notes column.  This is used to manage the Gateways Fixes #41

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 15 May 2018 23:04:42 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added record routes when calling outbound via carriers to ensure that the BYE is routed back throught Kamailio

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 15 May 2018 22:59:36 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Update address.csv

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 15 May 2018 23:23:00 +0200  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add Support for FusionPBX Provisioning Fixes #26

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 15 May 2018 20:17:39 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added the threaded option to allow the service to startup in multi-threaded mode

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 13 May 2018 23:26:03 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed an issue that prevented the PBX password from being updated

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 9 May 2018 16:22:10 -0400  
> Author: root (release@dopensource.com)  
> Committer: root (release@dopensource.com)  



---


### Added support for automatically adding the PBX ip, port and transport when it registers.  This means that it automatically gets added to the drouting.gateway table and the table is reloaded in real time

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 29 Apr 2018 18:32:49 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.35  
> Date: Tue, 24 Apr 2018 16:38:47 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Change the description of the default outbound routes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 24 Apr 2018 15:59:53 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed an issue with reloading the htable that support the new outbound route logic

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 23 Apr 2018 07:10:18 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added a flag to make te built-in web server multi-threaded

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 14 Apr 2018 08:06:26 -0400  
> Author: root (release@dopensource.com)  
> Committer: root (release@dopensource.com)  



---


### Fixed issue with update and save for LCR

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 6 Apr 2018 11:48:41 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Completed the development of some light weight LCR funcationality

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 6 Apr 2018 03:34:32 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added support for support LCR from a Kamailio prespective

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 5 Apr 2018 05:01:00 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### add header check feature in teleblock route

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 1 Apr 2018 21:32:16 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### add current work on dynamic routing and LCR features

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 1 Apr 2018 21:03:13 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### reformat messy code, fix html errors throughout, complete overhaul of front-end, add multiple outbound routes feature added, started adding backend capablities for dynamic routing, fixed 200 reply bug (endpoint now waits for 200 from carrier)

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 27 Mar 2018 20:01:23 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Fixed issue with rtpengine not starting after installation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.34  
> Date: Sat, 24 Mar 2018 22:43:13 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed typo with VI carriers

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 20:03:01 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Added a fix to resolve firewall issues

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 19:59:13 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed an issue that prevented port 5060 from being added and removed during the install and uninstall process, respectively

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 18:52:49 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### fixed uninstall cmd, add support for debian jessie dsiprouter installation

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 02:17:16 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Fixed issues with Deb 8.9 installer

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 12:55:35 +1100  
> Author: root (root@debian.vixtel.com.au)  
> Committer: root (root@debian.vixtel.com.au)  



---


### Fixed issues with Deb 8.9 installer

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 12:54:22 +1100  
> Author: root (root@debian.vixtel.com.au)  
> Committer: root (root@debian.vixtel.com.au)  



---


### fix broken debian jessie installation issues

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Mar 2018 01:16:53 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 06:31:35 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 06:30:27 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 06:30:03 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 06:25:38 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Updated README and validated the install on Debian 9.4 (Stretch)

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 06:15:44 -0400  
> Author: root (root@dsiprouter.dopensource.com)  
> Committer: root (root@dsiprouter.dopensource.com)  



---


### Fixed the installer issues for Debian 9.x (stretch)

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 23 Mar 2018 05:19:52 -0400  
> Author: root (root@dsiprouter-kam5.dopensource.com)  
> Committer: root (root@dsiprouter-kam5.dopensource.com)  



---


### Fixed RTPProxy issue with Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 22 Mar 2018 00:00:53 -0400  
> Author: root (release@dopensource.com)  
> Committer: root (release@dopensource.com)  



---


### Fixed a missing curly brackets

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Mar 2018 22:40:20 -0400  
> Author: root (release@dopensource.com)  
> Committer: root (release@dopensource.com)  



---


### Fixed a bug with teleblock media enablement

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Mar 2018 17:42:13 -0600  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Fixed a bug that prevented the media server from being enabled

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Mar 2018 16:44:30 -0600  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Fixed the default settings in the Kam 4.4 version of the configuration file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Mar 2018 04:48:01 -0600  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Changed the port back to the default 5000

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 20 Mar 2018 04:23:55 -0600  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Update settings.py

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.34-beta  
> Date: Mon, 19 Mar 2018 06:01:04 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Mar 2018 06:00:25 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Mar 2018 05:57:05 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Mar 2018 05:53:56 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Completed support for Teleblock Service

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 19 Mar 2018 09:51:06 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added GUI Support for Gryphon Teleblock Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 18 Mar 2018 13:30:25 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Create CNAME

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 17 Mar 2018 20:04:06 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Set theme jekyll-theme-architect

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 17 Mar 2018 19:51:32 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Removed a legacy script for stopping dsiprouter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 17 Mar 2018 14:50:44 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added support for Teleblock

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 17 Mar 2018 14:48:59 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### got rid of uneeded replies, fixed formatting

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 14 Mar 2018 14:48:09 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### fixed the "500" reply bug and check status bug

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 13 Mar 2018 15:30:54 -0400  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Update kamailio51_dsiprouter.cfg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.33  
> Date: Mon, 12 Mar 2018 21:04:00 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update kamailio51_dsiprouter.cfg

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 12 Mar 2018 21:03:30 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update stretch.sh

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 21:55:28 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.32  
> Date: Sun, 11 Mar 2018 21:43:45 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 21:34:51 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 21:29:02 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 21:27:56 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 21:26:05 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Updated the README

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 12 Mar 2018 01:20:38 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Prevent the DBROOTPW from being prompted during an install on a fresh machine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 12 Mar 2018 00:53:19 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Completed GUI support for PBX Registration

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 12 Mar 2018 00:29:14 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed the Add PBX with subscriber support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 11 Mar 2018 14:30:30 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### added teleblock blacklisting feature

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 9 Mar 2018 22:03:46 -0500  
> Author: Tyler Moore (tmoore@goflyball.com)  
> Committer: Tyler Moore (tmoore@goflyball.com)  



---


### Added GUI support for allowing a PBX/Endpoint to register

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 7 Mar 2018 05:41:00 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Completed Kamailio support to allow PBX's to register to dSIPRouter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 5 Mar 2018 03:25:26 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added support to allow PBX's to register

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 3 Mar 2018 16:56:11 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Added curl to the packages that needs to tbe downloaded.  Also fixed issue with the dSIPRouter port not being added

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Mar 2018 05:08:18 +0000  
> Author: root (root@disrouter-kam5-dev2.localdomain)  
> Committer: root (root@disrouter-kam5-dev2.localdomain)  



---


### Fixed issues with install script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Mar 2018 04:40:16 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed and validated the debian stretch install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 2 Mar 2018 01:43:22 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Refactoring the install script into more maintainable and testable units

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 25 Feb 2018 07:58:28 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Fixed issues with the Stretch install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Feb 2018 22:06:10 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Adding support for Debian Stretch release

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Feb 2018 20:40:50 +0000  
> Author: root (root@dsiprouter-kam5.localdomain)  
> Committer: root (root@dsiprouter-kam5.localdomain)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 24 Feb 2018 11:56:30 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an issue that prevented Kamailio 4.4 from being installed

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 19 Dec 2017 14:50:24 -0500  
> Author: root (root@debian89)  
> Committer: root (root@debian89)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Dec 2017 20:48:57 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Removed debugging statements from bash scripts and made kamailio restart after the dSIPRouter install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 19 Dec 2017 01:41:58 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Added logic to handle different versios of Kamailio

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 19 Dec 2017 01:26:04 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### fixed the install the uninstall scripts

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 19 Dec 2017 00:28:13 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Dec 2017 19:00:16 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### added support for installing kamailio on debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 18 Dec 2017 23:56:06 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Correct reference to REQ_PYTHON_MAJOR_VER

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Dec 2017 09:55:02 -0500  
> Author: hailthemelody (rainman@hailthemelody.com)  
> Committer: hailthemelody (rainman@hailthemelody.com)  

Was pointing to REQ_PYTHON_VER, which presumable was the previous name of the variable


---


### Correct reference to variable

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Dec 2017 08:44:47 -0500  
> Author: hailthemelody (rainman@hailthemelody.com)  
> Committer: hailthemelody (rainman@hailthemelody.com)  

Was missing "$" and being displayed as text. Now resolves to variable


---


### update the version from 0.30 to 0.31

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.31  
> Date: Mon, 4 Dec 2017 12:12:24 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Dec 2017 07:09:50 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Dec 2017 07:07:36 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed some minor bugs and formatting issues

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 4 Dec 2017 01:19:21 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 3 Dec 2017 17:06:14 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Generate unique password during install

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 3 Dec 2017 22:03:42 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for generating a unique password during the installation process

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 3 Dec 2017 21:59:15 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### restored the format of the file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 2 Dec 2017 11:58:52 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### restored the format of the file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 2 Dec 2017 11:56:20 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the reloadcmd file, but forgot to commit. Fixes #17

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 2 Dec 2017 11:02:45 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the container padding to remove the padding on the left and right. Fixes #12

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 2 Dec 2017 10:28:12 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Enhanced the logic around reloading Kamailio from the GUI.  Thanks to @khorsmann  Fixes #17

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 2 Dec 2017 09:43:40 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed an issue with the Kamailio module path not being populated properly during install.  Close #18 in release 0.31

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 1 Dec 2017 11:36:39 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic that would distinguish between local dialing and external dialing through a carrier when registering endpoints through the SIPProxy.  It's hardcoded so that extensions has to contain 5 or more digits.  Otherwise, it will try to route the call to a carrier

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 25 Nov 2017 06:27:05 -0800  
> Author: root (root@noc-lcb-spxy1.garlic.com)  
> Committer: root (root@noc-lcb-spxy1.garlic.com)  



---


### Fixed issue with ACK's not propagating thru the Kamailio correctedly.  Also, set the retranmission timeout to 10sec when trying to initial a call to an endpoint.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 22 Nov 2017 21:48:45 -0800  
> Author: root (root@noc-lcb-spxy1.garlic.com)  
> Committer: root (root@noc-lcb-spxy1.garlic.com)  



---


### Fixed an issue with endpoints being able to receive calls once registered

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 21 Nov 2017 20:57:26 -0800  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### close 23

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 21 Nov 2017 09:22:21 -0800  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### Fixed an issue with a quote not being specified correctly

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 21 Nov 2017 02:49:41 -0800  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### Will run apt-get update before installing

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 21 Nov 2017 02:45:56 -0800  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### Added a parameter to the save function in the registrar module.  Close #23

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 21 Nov 2017 16:37:15 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed a bug with the commands to enable dSIPRouter to access the FusionPBX DB

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 14 Nov 2017 23:30:37 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 15:02:31 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Updated the release version

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.3  
> Date: Mon, 13 Nov 2017 17:50:18 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Fixed the issue with overwriting the original Kamailio configuration files when installing the product multiple times. Closes #19

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 17:47:30 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Commented out database mapping for the fusionpbx_db_mapping table

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 16:23:29 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Added a library to the install script and fixed an issue with the mysql script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 16:19:11 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 10:37:12 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed an issue with stopping the server

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 15:27:52 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:40:24 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:40:12 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:34:41 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:24:26 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:21:45 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:15:09 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 09:00:39 -0500  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Fixed issues with the install script

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 13 Nov 2017 12:39:15 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Chnaged to support FusionPBX Domain Support

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 12 Nov 2017 15:36:54 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic to sync the Kamailio domain and domain_attrs tables with FusionPBX instances

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 11 Nov 2017 09:40:54 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added Add,Update and Delete support for FusionPBX Domain Support feature

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 5 Nov 2017 08:16:48 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 22 Oct 2017 13:13:26 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added js to enable the FusionPBX toogle button and sytled the label for the toggle button

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 22 Oct 2017 17:10:25 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Initial Support for automatically syncing FusionPBX domains with Kamailio '

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 12 Oct 2017 03:33:42 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added some notes

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Oct 2017 11:24:20 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added an install script for configuring the CDR support within dSIPRouter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Oct 2017 11:16:04 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### update .gitignore fix #15

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 11 Oct 2017 02:43:51 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### add info about configuring DSIProuter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 05:33:56 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### start server on port from settings fix #14

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 05:28:53 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### set DSIP_PORT to variable

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 05:14:06 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### add PIP_CMD for pip3 on debian/ubuntu systems fix #11

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 05:10:03 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### fix typo

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 05:02:55 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### fix markup and typos

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 04:55:13 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### fix command for password change

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 04:53:04 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### add info about License

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 9 Oct 2017 04:48:38 +0300  
> Author: littleguga (fed777os@gmail.com)  
> Committer: littleguga (fed777os@gmail.com)  



---


### Initial commit for the fraud detection module

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 8 Oct 2017 06:03:37 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Add cdrs.sql

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 7 Oct 2017 19:32:48 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### updated cdrs.sql with the new cdr sql file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 7 Oct 2017 19:22:39 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Adding SQL for CDR's

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 5 Oct 2017 21:45:06 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for domain routing (aka multidomain support)

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 29 Sep 2017 20:29:01 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Started to add support for Redhat 7.4

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 27 Sep 2017 17:02:01 -0400  
> Author: root (root@aio.kazoo.com)  
> Committer: root (root@aio.kazoo.com)  



---


### Fixed an issue that might cause the wrong Python executable to be ran

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Fri, 15 Sep 2017 05:09:14 -0600  
> Author: root (mack@dopensource.com)  
> Committer: root (mack@dopensource.com)  



---


### Added support for CDR's to support call direction using a table column called calltype

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 14 Sep 2017 20:46:11 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed it for Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected: v0.2  
> Date: Mon, 11 Sep 2017 18:47:29 -0700  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### Added a library that was need on Debian Jessie 8.8

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 11 Sep 2017 14:12:50 -0700  
> Author: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  
> Committer: dopensource (dopensource@noc-lcb-spxy1.garlic.com)  



---


### Added logic to support stopping of both dsiprouter and rtpengine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 20:08:24 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Added logic to the stop command

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 19:37:15 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Add logic to create a tmpfiles configuration for rtpengine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 19:28:28 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Fixed an issue with the script for installing the RTPEngine on Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 19:01:24 +0000  
> Author: root (root@packer-debian-8-amd64.droplet.local)  
> Committer: root (root@packer-debian-8-amd64.droplet.local)  



---


### Updated the version

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 18:46:27 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic to handle NAT

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 17:54:42 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for NAT when the RTPEngine process is running

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 14:02:02 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Updated the README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 13:20:08 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Changed the RTPEngine port from 7222 to 7722

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 10 Sep 2017 00:16:04 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the installer command line and tested it on CentOS - fixed #8

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 9 Sep 2017 23:48:26 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed the installer command line and tested it on CentOS - Issue #8

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 9 Sep 2017 23:45:58 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Finsihed up the command options

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 9 Sep 2017 22:12:38 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added logic to store the process ID when the dsiprouter process is started

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 27 Aug 2017 05:42:12 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support for installing RTPEngine on Debian

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Tue, 22 Aug 2017 01:34:46 -0400  
> Author: root (root@SR215)  
> Committer: root (root@SR215)  



---


### Added support for installing RTPEngine

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 21 Aug 2017 10:42:46 -0400  
> Author: root (root@SR215)  
> Committer: root (root@SR215)  



---


### will install rtpengine on CentOS7 by default

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 21 Aug 2017 13:44:39 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed an issue with carriers not being assigned to the right address type of carrier

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 17 Aug 2017 17:08:32 -0400  
> Author: root (root@SR215)  
> Committer: root (root@SR215)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 Aug 2017 22:57:07 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Added logic to install dSIPRouter on Debian Jesie

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Wed, 16 Aug 2017 22:50:31 -0400  
> Author: root (root@SR215)  
> Committer: root (root@SR215)  



---


### Turned the Reload Kamailio button into an ajax query that updates a div called message

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Jul 2017 13:55:36 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed issue #2 by adding a div that shows any error messages in the login form

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 30 Jul 2017 00:59:38 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Added support to deal with MySQL expiring db connections after a certain timeframe.

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Thu, 20 Jul 2017 12:08:27 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:30:12 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:28:06 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:26:18 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:25:42 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:14:06 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:12:21 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Delete dsiprouter_outboundrouting

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:10:47 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:09:31 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 12:08:48 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Add files via upload

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 11:54:35 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Adding a docs directory

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 15:49:03 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Fixed an issue with the MySQL DB closing a connection after 8 hours

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 06:56:54 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### added a intro screen

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 04:21:21 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Changed the navigation so that the left hand navigation is one level

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Mon, 17 Jul 2017 01:31:50 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### added execute permissions

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 16 Jul 2017 13:48:36 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Made the kamailio configuration more generic

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sun, 16 Jul 2017 03:06:39 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### fixed an error with the symbolic link with the kamailio.cfg file

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 23:20:35 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:47:13 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:46:28 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:45:03 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:44:19 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Update README.md

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:42:08 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: GitHub (noreply@github.com)  



---


### Initial commit as dsiprouter

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 10:37:01 +0000  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


### Initial commit

> Branches Affected: dmq-feature,v0.523+ent,v0.55+ent,v0.55+ent_didws,v0.60+ent  
> Tags Affected:   
> Date: Sat, 15 Jul 2017 06:30:25 -0400  
> Author: Mack Hendricks (mack@dopensource.com)  
> Committer: Mack Hendricks (mack@dopensource.com)  



---


