-- update address schema
ALTER TABLE dr_gateways
  MODIFY tag varchar(255) NOT NULL DEFAULT '';