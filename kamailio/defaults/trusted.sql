-- update trusted table to fit our storage requirements
ALTER TABLE trusted
  MODIFY COLUMN tag varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(tag));
