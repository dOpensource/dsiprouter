-- update schema for subscribers table
ALTER TABLE subscriber
  ADD email_address varchar(128) NOT NULL DEFAULT '',
  ADD rpid varchar(128) NOT NULL DEFAULT '';