-- update address schema
ALTER TABLE address
  MODIFY tag varchar(255) NOT NULL DEFAULT '';