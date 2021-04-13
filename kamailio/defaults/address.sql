-- update address table to fit our storage requirements
ALTER TABLE address
  MODIFY COLUMN tag varchar(255) NOT NULL DEFAULT '';
