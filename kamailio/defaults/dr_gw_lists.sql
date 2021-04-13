-- update dr_gw_lists schema to fit our storage requirements
ALTER TABLE dr_gw_lists
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '';
