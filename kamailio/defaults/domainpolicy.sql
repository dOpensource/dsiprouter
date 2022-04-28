-- update domainpolicy table to fit our storage requirements
ALTER TABLE domainpolicy
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));
