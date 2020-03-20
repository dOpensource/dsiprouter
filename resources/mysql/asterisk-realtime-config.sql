### asterisk realtime db

# configure asterisk server for realtime DB connections/updates

# explanation and how to configure:
#https://www.voip-info.org/asterisk-realtime/


#https://www.voip-info.org/asterisk-realtime-static

CREATE TABLE `bit_ast_config` (
`id` int(11) NOT NULL auto_increment,
`cat_metric` int(11) NOT NULL default '0',
`var_metric` int(11) NOT NULL default '0',
`commented` int(11) NOT NULL default '0',
`filename` varchar(128) NOT NULL default '',
`category` varchar(128) NOT NULL default 'default',
`var_name` varchar(128) NOT NULL default '',
`var_val` varchar(128) NOT NULL default '',
PRIMARY KEY (`id`),
KEY `filename_comment` (`filename`,`commented`)
);



#https://www.voip-info.org/asterisk-realtime-sip

CREATE TABLE `bit_sip_buddies` (
`id` int(11) NOT NULL auto_increment,
`name` varchar(80) NOT NULL default '',
`host` varchar(31) NOT NULL default '',
`nat` varchar(5) NOT NULL default 'no',
`type` enum('user','peer','friend') NOT NULL default 'friend',
`accountcode` varchar(20) default NULL,
`amaflags` varchar(13) default NULL,
`call-limit` smallint(5) unsigned default NULL,
`callgroup` varchar(10) default NULL,
`callerid` varchar(80) default NULL,
`cancallforward` char(3) default 'yes',
`canreinvite` char(3) default 'yes',
`context` varchar(80) default NULL,
`defaultip` varchar(15) default NULL,
`dtmfmode` varchar(7) default NULL,
`fromuser` varchar(80) default NULL,
`fromdomain` varchar(80) default NULL,
`insecure` varchar(4) default NULL,
`language` char(2) default NULL,
`mailbox` varchar(50) default NULL,
`md5secret` varchar(80) default NULL,
`deny` varchar(95) default NULL,
`permit` varchar(95) default NULL,
`mask` varchar(95) default NULL,
`musiconhold` varchar(100) default NULL,
`pickupgroup` varchar(10) default NULL,
`qualify` char(3) default NULL,
`regexten` varchar(80) default NULL,
`restrictcid` char(3) default NULL,
`rtptimeout` char(3) default NULL,
`rtpholdtimeout` char(3) default NULL,
`secret` varchar(80) default NULL,
`setvar` varchar(100) default NULL,
`disallow` varchar(100) default 'all',
`allow` varchar(100) default 'g729;ilbc;gsm;ulaw;alaw',
`fullcontact` varchar(80) NOT NULL default '',
`ipaddr` varchar(15) NOT NULL default '',
`port` smallint(5) unsigned NOT NULL default '0',
`regserver` varchar(100) default NULL,
`regseconds` int(11) NOT NULL default '0',
`lastms` int(11) NOT NULL default '0',
`username` varchar(80) NOT NULL default '',
`defaultuser` varchar(80) NOT NULL default '',
`subscribecontext` varchar(80) default NULL,
`useragent` varchar(20) default NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `name` (`name`),
KEY `name_2` (`name`)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

## OR ##

#https://wiki.asterisk.org/wiki/display/AST/SIP+Realtime%2C+MySQL+table+structure

CREATE TABLE IF NOT EXISTS `sipfriends` (
`id` int(11) NOT NULL AUTO_INCREMENT,
`name` varchar(10) NOT NULL,
`ipaddr` varchar(15) DEFAULT NULL,
`port` int(5) DEFAULT NULL,
`regseconds` int(11) DEFAULT NULL,
`defaultuser` varchar(10) DEFAULT NULL,
`fullcontact` varchar(35) DEFAULT NULL,
`regserver` varchar(20) DEFAULT NULL,
`useragent` varchar(20) DEFAULT NULL,
`lastms` int(11) DEFAULT NULL,
`host` varchar(40) DEFAULT NULL,
`type` enum('friend','user','peer') DEFAULT NULL,
`context` varchar(40) DEFAULT NULL,
`permit` varchar(40) DEFAULT NULL,
`deny` varchar(40) DEFAULT NULL,
`secret` varchar(40) DEFAULT NULL,
`md5secret` varchar(40) DEFAULT NULL,
`remotesecret` varchar(40) DEFAULT NULL,
`transport` enum('udp','tcp','udp,tcp','tcp,udp') DEFAULT NULL,
`dtmfmode` enum('rfc2833','info','shortinfo','inband','auto') DEFAULT NULL,
`directmedia` enum('yes','no','nonat','update') DEFAULT NULL,
`nat` enum('yes','no','never','route') DEFAULT NULL,
`callgroup` varchar(40) DEFAULT NULL,
`pickupgroup` varchar(40) DEFAULT NULL,
`language` varchar(40) DEFAULT NULL,
`allow` varchar(40) DEFAULT NULL,
`disallow` varchar(40) DEFAULT NULL,
`insecure` varchar(40) DEFAULT NULL,
`trustrpid` enum('yes','no') DEFAULT NULL,
`progressinband` enum('yes','no','never') DEFAULT NULL,
`promiscredir` enum('yes','no') DEFAULT NULL,
`useclientcode` enum('yes','no') DEFAULT NULL,
`accountcode` varchar(40) DEFAULT NULL,
`setvar` varchar(40) DEFAULT NULL,
`callerid` varchar(40) DEFAULT NULL,
`amaflags` varchar(40) DEFAULT NULL,
`callcounter` enum('yes','no') DEFAULT NULL,
`busylevel` int(11) DEFAULT NULL,
`allowoverlap` enum('yes','no') DEFAULT NULL,
`allowsubscribe` enum('yes','no') DEFAULT NULL,
`videosupport` enum('yes','no') DEFAULT NULL,
`maxcallbitrate` int(11) DEFAULT NULL,
`rfc2833compensate` enum('yes','no') DEFAULT NULL,
`mailbox` varchar(40) DEFAULT NULL,
`session-timers` enum('accept','refuse','originate') DEFAULT NULL,
`session-expires` int(11) DEFAULT NULL,
`session-minse` int(11) DEFAULT NULL,
`session-refresher` enum('uac','uas') DEFAULT NULL,
`t38pt_usertpsource` varchar(40) DEFAULT NULL,
`regexten` varchar(40) DEFAULT NULL,
`fromdomain` varchar(40) DEFAULT NULL,
`fromuser` varchar(40) DEFAULT NULL,
`qualify` varchar(40) DEFAULT NULL,
`defaultip` varchar(40) DEFAULT NULL,
`rtptimeout` int(11) DEFAULT NULL,
`rtpholdtimeout` int(11) DEFAULT NULL,
`sendrpid` enum('yes','no') DEFAULT NULL,
`outboundproxy` varchar(40) DEFAULT NULL,
`callbackextension` varchar(40) DEFAULT NULL,
`registertrying` enum('yes','no') DEFAULT NULL,
`timert1` int(11) DEFAULT NULL,
`timerb` int(11) DEFAULT NULL,
`qualifyfreq` int(11) DEFAULT NULL,
`constantssrc` enum('yes','no') DEFAULT NULL,
`contactpermit` varchar(40) DEFAULT NULL,
`contactdeny` varchar(40) DEFAULT NULL,
`usereqphone` enum('yes','no') DEFAULT NULL,
`textsupport` enum('yes','no') DEFAULT NULL,
`faxdetect` enum('yes','no') DEFAULT NULL,
`buggymwi` enum('yes','no') DEFAULT NULL,
`auth` varchar(40) DEFAULT NULL,
`fullname` varchar(40) DEFAULT NULL,
`trunkname` varchar(40) DEFAULT NULL,
`cid_number` varchar(40) DEFAULT NULL,
`callingpres` enum('allowed_not_screened','allowed_passed_screen','allowed_failed_screen','allowed','prohib_not_screened','prohib_passed_screen','prohib_failed_screen','prohib') DEFAULT NULL,
`mohinterpret` varchar(40) DEFAULT NULL,
`mohsuggest` varchar(40) DEFAULT NULL,
`parkinglot` varchar(40) DEFAULT NULL,
`hasvoicemail` enum('yes','no') DEFAULT NULL,
`subscribemwi` enum('yes','no') DEFAULT NULL,
`vmexten` varchar(40) DEFAULT NULL,
`autoframing` enum('yes','no') DEFAULT NULL,
`rtpkeepalive` int(11) DEFAULT NULL,
`call-limit` int(11) DEFAULT NULL,
`g726nonstandard` enum('yes','no') DEFAULT NULL,
`ignoresdpversion` enum('yes','no') DEFAULT NULL,
`allowtransfer` enum('yes','no') DEFAULT NULL,
`dynamic` enum('yes','no') DEFAULT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `name` (`name`),
KEY `ipaddr` (`ipaddr`,`port`),
KEY `host` (`host`,`port`)
) ENGINE=MyISAM;


#https://www.voip-info.org/asterisk-realtime-iax

CREATE TABLE bit_iax_buddies (
name varchar(30) primary key NOT NULL,
username varchar(30),
type varchar(6) NOT NULL,
secret varchar(50),
md5secret varchar(32),
dbsecret varchar(100),
notransfer varchar(10),
inkeys varchar(100),
outkey varchar(100),
auth varchar(100),
accountcode varchar(100),
amaflags varchar(100),
callerid varchar(100),
context varchar(100),
defaultip varchar(15),
host varchar(31) NOT NULL default 'dynamic',
language char(5),
mailbox varchar(50),
deny varchar(95),
permit varchar(95),
qualify varchar(4),
disallow varchar(100),
allow varchar(100),
ipaddr varchar(15),
port integer default 0,
regseconds integer default 0
);
CREATE UNIQUE INDEX bit_iax_buddies_username_idx ON bit_iax_buddies(username);



#https://www.voip-info.org/asterisk-realtime-h323

DROP TABLE IF EXISTS h323_peer;

CREATE TABLE h323_peer(
id BIGINT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(128) NOT NULL UNIQUE,
host VARCHAR(15) DEFAULT NULL ,
secret VARCHAR(64) DEFAULT NULL,
context VARCHAR(64) NOT NULL,
type VARCHAR(6) NOT NULL,
port INT DEFAULT NULL,
permit VARCHAR(128) DEFAULT NULL,
deny VARCHAR(128) DEFAULT NULL,
mailbox VARCHAR(128) DEFAULT NULL,
e164 VARCHAR(128) DEFAULT NULL,
prefix VARCHAR(128) DEFAULT NULL,
allow VARCHAR(128) DEFAULT NULL,
disallow VARCHAR(128) DEFAULT NULL,
dtmfmode VARCHAR(128) DEFAULT NULL,
accountcode INT DEFAULT NULL,
amaflags varchar(13) DEFAULT NULL,
INDEX idx_name(name),
INDEX idx_host(host)
);



#https://www.voip-info.org/asterisk-realtime-voicemail

CREATE TABLE `bit_voicemail` (
 `uniqueid` INT(4) NOT NULL AUTO_INCREMENT,
 `customer_id` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `context` VARCHAR(10) COLLATE utf8_bin NOT NULL,
 `mailbox` VARCHAR(10) COLLATE utf8_bin NOT NULL,
 `password` INT(4) NOT NULL,
 `fullname` VARCHAR(150) COLLATE utf8_bin DEFAULT NULL,
 `email` VARCHAR(50) COLLATE utf8_bin DEFAULT NULL,
 `pager` VARCHAR(50) COLLATE utf8_bin DEFAULT NULL,
 `tz` VARCHAR(10) COLLATE utf8_bin DEFAULT 'central',
 `attach` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'yes',
 `saycid` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'yes',
 `dialout` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `callback` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `review` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `operator` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `envelope` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `sayduration` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `saydurationm` TINYINT(4) NOT NULL DEFAULT '1',
 `sendvoicemail` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `delete` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `nextaftercmd` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'yes',
 `forcename` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `forcegreetings` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
 `hidefromdir` ENUM('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'yes',
 `stamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 `attachfmt` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `searchcontexts` ENUM('yes','no') COLLATE utf8_bin DEFAULT NULL,
 `cidinternalcontexts` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `exitcontext` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `volgain` VARCHAR(4) COLLATE utf8_bin DEFAULT NULL,
 `tempgreetwarn` ENUM('yes','no') COLLATE utf8_bin DEFAULT 'yes',
 `messagewrap` ENUM('yes','no') COLLATE utf8_bin DEFAULT 'no',
 `minpassword` INT(2) DEFAULT '4',
 `vm-password` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-newpassword` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-passchanged` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-reenterpassword` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-mismatch` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-invalid-password` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `vm-pls-try-again` VARCHAR(10) COLLATE utf8_bin DEFAULT NULL,
 `listen-control-forward-key` VARCHAR(2) COLLATE utf8_bin DEFAULT NULL,
 `listen-control-reverse-key` VARCHAR(1) COLLATE utf8_bin DEFAULT NULL,
 `listen-control-pause-key` VARCHAR(1) COLLATE utf8_bin DEFAULT NULL,
 `listen-control-restart-key` VARCHAR(1) COLLATE utf8_bin DEFAULT NULL,
 `listen-control-stop-key` VARCHAR(13) COLLATE utf8_bin DEFAULT NULL,
 `backupdeleted` VARCHAR(3) COLLATE utf8_bin DEFAULT '25',
  PRIMARY KEY  (`uniqueid`),
 KEY `mailbox_context` (`mailbox`,`context`)
) ENGINE=INNODB DEFAULT CHARSET=latin1;



#https://www.voip-info.org/asterisk-realtime-queue

CREATE TABLE queue_table (
name VARCHAR(128) PRIMARY KEY,
musiconhold VARCHAR(128),
announce VARCHAR(128),
context VARCHAR(128),
timeout INT(11),
monitor_join BOOL,
monitor_format VARCHAR(128),
queue_youarenext VARCHAR(128),
queue_thereare VARCHAR(128),
queue_callswaiting VARCHAR(128),
queue_holdtime VARCHAR(128),
queue_minutes VARCHAR(128),
queue_seconds VARCHAR(128),
queue_lessthan VARCHAR(128),
queue_thankyou VARCHAR(128),
queue_reporthold VARCHAR(128),
announce_frequency INT(11),
announce_round_seconds INT(11),
announce_holdtime VARCHAR(128),
retry INT(11),
wrapuptime INT(11),
maxlen INT(11),
servicelevel INT(11),
strategy VARCHAR(128),
joinempty VARCHAR(128),
leavewhenempty VARCHAR(128),
eventmemberstatus BOOL,
eventwhencalled BOOL,
reportholdtime BOOL,
memberdelay INT(11),
weight INT(11),
timeoutrestart BOOL,
periodic_announce VARCHAR(50),
periodic_announce_frequency INT(11),
ringinuse BOOL,
setinterfacevar BOOL
);



#https://www.voip-info.org/asterisk-realtime-extensions

CREATE TABLE `bit_extensions_table` (
`id` int(11) NOT NULL auto_increment,
`context` varchar(20) NOT NULL default '',
`exten` varchar(20) NOT NULL default '',
`priority` tinyint(4) NOT NULL default '0',
`app` varchar(20) NOT NULL default '',
`appdata` varchar(128) NOT NULL default '',
PRIMARY KEY (`context`,`exten`,`priority`),
KEY `id` (`id`)
);



#https://www.voip-info.org/ldap



#https://www.voip-info.org/asterisk-realtime-meetme

CREATE TABLE `bit_meetme` (
`confno` varchar(80) DEFAULT '0' NOT NULL,
`pin` varchar(20) NULL,
`adminpin` varchar(20) NULL,
`members` integer DEFAULT 0 NOT NULL,
PRIMARY KEY (confno)
);



#https://www.voip-info.org/asterisk-realtime-chansccp2

CREATE TABLE `sccpdevices` (
`name` varchar(15) NOT NULL default '',
`type` varchar(45) default NULL,
`autologin` varchar(45) default NULL,
`description` varchar(45) default NULL,
`tzoffset` varchar(45) default NULL,
`transfer` varchar(45) default NULL,
`speeddial` varchar(45) default NULL,
`cfwdall` varchar(45) default NULL,
`cfwdbusy` varchar(45) default NULL,
`dtmfmode` varchar(45) default NULL,
`imageversion` varchar(45) default NULL,
`deny` varchar(45) default NULL,
`permit` varchar(45) default NULL,
`dnd` varchar(45) default NULL,
PRIMARY KEY (`name`)
);

CREATE TABLE `sccplines` (
`name` varchar(45) NOT NULL default '',
`id` varchar(45) default NULL,
`pin` varchar(45) default NULL,
`label` varchar(45) default NULL,
`description` varchar(45) default NULL,
`context` varchar(45) default NULL,
`incominglimit` varchar(45) default NULL,
`transfer` varchar(45) default NULL,
`mailbox` varchar(45) default NULL,
`vmnum` varchar(45) default NULL,
`cid_name` varchar(45) default NULL,
`cid_num` varchar(45) default NULL,
`trnsfvm` varchar(45) default NULL,
`secondary_dialtone_digits` varchar(45) default NULL,
`secondary_dialtone_tone` varchar(45) default NULL,
`musicclass` varchar(45) default NULL,
`language` varchar(45) default NULL,
`accountcode` varchar(45) default NULL,
`rtptos` varchar(45) default NULL,
`echocancel` varchar(45) default NULL,
`silencesuppression` varchar(45) default NULL,
`callgroup` varchar(45) default NULL,
`pickupgroup` varchar(45) default NULL,
`amaflags` varchar(45) default NULL,
PRIMARY KEY (`name`)
);



## another version of realtime db for replication

#http://www.ntegratedsolutions.com/wp-content/uploads/2012/07/Asterisk_MySQL_Cluster_Presentation.pdf

CREATE database asteriskdb;
CREATE TABLE `extensions` (
`id` int(11) NOT NULL auto_increment,
`context` varchar(20) NOT NULL default '',
`exten` varchar(20) NOT NULL default '',
`priority` tinyint(4) NOT NULL default '0',
`app` varchar(20) NOT NULL default '',
`appdata` varchar(128) NOT NULL default '',
`accountcode` varchar(20) default NULL,
`notes` varchar(255) default NULL,
PRIMARY KEY (`context`,`exten`,`priority`),
KEY `id` (`id`)
);
CREATE TABLE `voicemail` (
`uniqueid` int(11) NOT NULL auto_increment,
`customer_id` varchar(11) NOT NULL default '0',
`context` varchar(50) NOT NULL default '',
`mailbox` varchar(11) NOT NULL default '0',
`password` varchar(5) NOT NULL default '0',
`fullname` varchar(150) NOT NULL default '',
`email` varchar(50) NOT NULL default '',
`pager` varchar(50) NOT NULL default '',
`tz` varchar(10) NOT NULL default 'central',
`attach` varchar(4) NOT NULL default 'yes',
`saycid` varchar(4) NOT NULL default 'yes',
`dialout` varchar(10) NOT NULL default '',
`callback` varchar(10) NOT NULL default '',
`review` varchar(4) NOT NULL default 'no',
`operator` varchar(4) NOT NULL default 'no',
`envelope` varchar(4) NOT NULL default 'no',
`sayduration` varchar(4) NOT NULL default 'no',
`saydurationm` tinyint(4) NOT NULL default '1',
`sendvoicemail` varchar(4) NOT NULL default 'no',
`delete` varchar(4) NOT NULL default 'no',
`nextaftercmd` varchar(4) NOT NULL default 'yes',
`forcename` varchar(4) NOT NULL default 'no',
`forcegreetings` varchar(4) NOT NULL default 'no',
`hidefromdir` varchar(4) NOT NULL default 'yes',
PRIMARY KEY (`uniqueid`),
KEY `mailbox_context` (`mailbox`,`context`)
);
CREATE TABLE `sip` (
`id` int(11) NOT NULL auto_increment,
`name` varchar(80) NOT NULL default '',
`accountcode` varchar(20) default NULL,
`amaflags` varchar(13) default NULL,
`callgroup` varchar(10) default NULL,
`callerid` varchar(80) default NULL,
`canreinvite` char(3) default 'yes',
`context` varchar(80) default NULL,
`defaultip` varchar(15) default NULL,
`dtmfmode` varchar(7) default NULL,
`fromuser` varchar(80) default NULL,
`fromdomain` varchar(80) default NULL,
`host` varchar(31) NOT NULL default '',
`insecure` varchar(4) default NULL,
`language` char(2) default NULL,
`mailbox` varchar(50) default NULL,
`md5secret` varchar(80) default NULL,
`nat` varchar(5) NOT NULL default 'no',
`deny` varchar(95) default NULL,
`permit` varchar(95) default NULL,
`mask` varchar(95) default NULL,
`pickupgroup` varchar(10) default NULL,
`port` varchar(5) NOT NULL default '',
`qualify` char(3) default NULL,
`restrictcid` char(1) default NULL,
`rtptimeout` char(3) default NULL,
`rtpholdtimeout` char(3) default NULL,
`secret` varchar(80) default NULL,
`type` varchar(6) NOT NULL default 'friend',
`username` varchar(80) NOT NULL default '',
`disallow` varchar(100) default 'all',
`allow` varchar(100) default 'gsm;ulaw;alaw',
`musiconhold` varchar(100) default NULL,
`regseconds` int(11) NOT NULL default '0',
`ipaddr` varchar(15) NOT NULL default '',
`regexten` varchar(80) NOT NULL default '',
`cancallforward` char(3) default 'yes',
`setvar` varchar(100) NOT NULL default '',
`fullcontact` varchar(80) default NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `name` (`name`),
KEY `name_2` (`name`)
);
CREATE TABLE `pins` (
`id` int(11) NOT NULL auto_increment,
`company` varchar(20) NOT NULL default '',
`pin` varchar(10) NOT NULL default '',
`active` varchar(5) NOT NULL default 'no',
`accountcode` varchar(20) NOT NULL default '',
`notes` varchar(255) default NULL,
PRIMARY KEY (`company`,`pin`),
KEY `id` (`id`)
);

