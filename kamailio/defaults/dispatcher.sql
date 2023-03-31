-- update dispatcher schema to fit our storage requirements
ALTER TABLE dispatcher
  MODIFY description varchar(255) NOT NULL DEFAULT '';