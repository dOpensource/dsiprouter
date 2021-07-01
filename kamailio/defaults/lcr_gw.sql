-- update lcr_gw table to fit our storage requirements
ALTER TABLE lcr_gw
  MODIFY COLUMN tag varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(tag));
