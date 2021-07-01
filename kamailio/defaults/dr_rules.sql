-- update dr_rules schema to fit our storage requirements
ALTER TABLE dr_rules
  MODIFY COLUMN routeid varchar(255) NOT NULL,
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));
