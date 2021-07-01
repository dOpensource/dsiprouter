-- update dr_groups table to fit our storage requirements
ALTER TABLE dr_groups
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));
