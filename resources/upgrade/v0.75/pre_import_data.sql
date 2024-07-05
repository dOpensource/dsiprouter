CREATE TABLE `dsip_calllimit` (
    `gwgroupid` varchar(64) NOT NULL,
    `limit` varchar(64) NOT NULL DEFAULT '0',
    `status` tinyint(1) NOT NULL DEFAULT 1,
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;