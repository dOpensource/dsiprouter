-- update globalblacklist table to fit our storage requirements
ALTER TABLE globalblacklist
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));
