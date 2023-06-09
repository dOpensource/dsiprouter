-- update dr_rules schema to fit our storage requirements
ALTER TABLE dr_rules
  MODIFY description varchar(255) NOT NULL DEFAULT '';