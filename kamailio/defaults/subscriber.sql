ALTER TABLE subscriber
  ADD COLUMN email_address varchar(128) NOT NULL DEFAULT '',
  ADD COLUMN rpid varchar(128) NOT NULL DEFAULT '';
