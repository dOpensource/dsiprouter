-- update speed_dial table to fit our storage requirements
ALTER TABLE speed_dial
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));
