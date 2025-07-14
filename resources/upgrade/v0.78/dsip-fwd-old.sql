DROP TABLE IF EXISTS dsip_prefix_mapping;
DROP VIEW IF EXISTS dsip_prefix_mapping;
CREATE VIEW dsip_prefix_mapping AS
  SELECT
    prefix,
    CAST(ruleid AS char) AS ruleid,
    CAST(priority AS char) AS priority,
    '0' AS key_type,
    '0' AS value_type
  FROM dr_rules;