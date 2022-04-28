-- update dispatcher schema to fit our storage requirements
ALTER TABLE dispatcher
  MODIFY COLUMN attrs varchar(255) NOT NULL DEFAULT '',
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}';
