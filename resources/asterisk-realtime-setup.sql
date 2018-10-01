use kamailio;
insert into domain values (null,'voipmuch.ca','voipmuch.ca',NOW());
/* Most likely we will need to add a setid to this table so that we can load balance between multiple PBX's */
insert into dsip_domain_mapping values (null,0,1,'','',1);
/*  Type 0=integer 2=string */
insert into domain_attrs values (null,'voipmuch.ca','dispatcher_setid',0,'1',NOW());
insert into domain_attrs values (null,'voipmuch.ca','dispatcher_inv_alg',0,'4',NOW());
insert into domain_attrs values (null,'voipmuch.ca','dispatcher_reg_alg',0,'4',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_host',2,'realtime-settings.mysql.database.azure.com',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_user',2,'vmrealtime@realtime-settings',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_pass',2,'uhDNdhbf82rrb2Ddnfb266q3NAPcn2',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_name',2,'asterisk',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_table',2,'sipusers',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_userfield',2,'name',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_passfield',2,'secret',NOW());
insert into domain_attrs values (null,'voipmuch.ca','db_pass_alg',2,'secret',NOW());


/* dispatcher with Setid being 1 */
insert into dispatcher values (null,1,'sip:208.79.81.98',0,0,'','');
insert into dispatcher values (null,1,'sip:192.73.246.130',0,0,'','');
insert into dispatcher values (null,1,'sip:162.248.220.194',0,0,'','');

