CREATE TABLE `dsip_calllimit` (
	  `gwid` varchar(64) NOT NULL DEFAULT '',
	  `key_type` varchar(64) NOT NULL DEFAULT '0',
	  `limit` varchar(64) NOT NULL DEFAULT '',
	  `value_type` varchar(64) NOT NULL DEFAULT '0',
	  `status` tinyint(4) NOT NULL DEFAULT '1',
	  PRIMARY KEY (`gwid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
