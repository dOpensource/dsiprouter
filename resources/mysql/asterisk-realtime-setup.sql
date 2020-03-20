use kamailio;
insert into domain values (null,'test.ca','test.ca',NOW());
/* Most likely we will need to add a setid to this table so that we can load balance between multiple PBX's */
insert into dsip_domain_mapping values (null,0,1,'','',1);
/*  Type 0=integer 2=string */
insert into domain_attrs values (null,'test.ca','dispatcher_setid',0,'1',NOW());
insert into domain_attrs values (null,'test.ca','dispatcher_inv_alg',0,'4',NOW());
insert into domain_attrs values (null,'test.ca','dispatcher_reg_alg',0,'4',NOW());
insert into domain_attrs values (null,'test.ca','db_host',2,'realtime-settings.mysql.database.test.ca',NOW());
insert into domain_attrs values (null,'test.ca','db_user',2,'vmrealtime@realtime-settings',NOW());
insert into domain_attrs values (null,'test.ca','db_pass',2,'SecretPasssword',NOW());
insert into domain_attrs values (null,'test.ca','db_name',2,'asterisk',NOW());
insert into domain_attrs values (null,'test.ca','db_table',2,'sipusers',NOW());
insert into domain_attrs values (null,'test.ca','db_userfield',2,'name',NOW());
insert into domain_attrs values (null,'test.ca','db_passfield',2,'secret',NOW());
insert into domain_attrs values (null,'test.ca','db_pass_alg',2,'secret',NOW());


/* dispatcher with Setid being 1 */
insert into dispatcher values (null,1,'sip:208.79.81.99',0,0,'','');
insert into dispatcher values (null,1,'sip:192.73.246.131',0,0,'','');
insert into dispatcher values (null,1,'sip:162.248.220.121',0,0,'','');

