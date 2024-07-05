UPDATE `dr_gateways` SET `attrs` = IF(
  (CHAR_LENGTH(attrs) - CHAR_LENGTH(REPLACE(attrs, ',', ''))) = 2,
  CONCAT(SUBSTRING_INDEX(`attrs`, ',', 3), ',proxy,proxy'),
  CONCAT(SUBSTRING_INDEX(`attrs`, ',', 2), ',,proxy,proxy')
);

UPDATE `dispatcher` SET `attrs` = IF(
  `attrs` REGEXP 'weight=([0-9]+)', CONCAT('signalling=proxy;media=proxy;rweight=',
  CAST((REGEXP_REPLACE(`attrs`, '.*weight=([0-9]+).*', '\\1') / 100) AS CHAR)),
  'signalling=proxy;media=proxy;rweight=0'
);

INSERT INTO `dsip_call_settings` (`gwgroupid`, `limit`)
SELECT CAST(`gwgroupid` AS UNSIGNED), CAST(`limit` AS UNSIGNED)
FROM `dsip_calllimit`;
DROP TABLE `dsip_calllimit`;