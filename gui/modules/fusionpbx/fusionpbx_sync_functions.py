import psycopg2
#import sys
#import pprint
import MySQLdb


#Sources are in MySQL
def get_sources():
    
    hostname = 'localhost'
    username = 'kamailio'
    password = 'kamailiorw'
    database = 'kamailio'
    sources = {}

    try:
        db=MySQLdb.connect(host=hostname, user=username, passwd=password, db=database)
        c=db.cursor()
        c.execute("""select pbx_id,address as pbx_ip,db_ip,db_username,db_password from dsip_fusionpbx_db join dr_gateways on dsip_fusionpbx_db.pbx_id=dr_gateways.gwid;""")
        results =c.fetchall()
        for row in results:
            #Store the PBX_ID as the key and the entire row as the value
            sources[row[1]] =row
    except Exception as e:
        print(e)

    return sources

def sync_db(source,dest):
   
    #FusionPBX Database Parameters 
    pbx_id =source[0]
    pbx_ip =source[1]
    fpbx_hostname=source[2]
    fpbx_username=source[3]
    fpbx_password=source[4]
    fpbx_database = 'fusionpbx'

    #Kamailio Database Parameters
    kam_hostname=dest['hostname']
    kam_username=dest['username']
    kam_password=dest['password']
    kam_database=dest['database']
     

    #Trying connecting to PostgresSQL database using a Trust releationship first
    try:
        conn = psycopg2.connect(dbname=fpbx_database, user=fpbx_username, host=fpbx_hostname, password=fpbx_password)
        cur = conn.cursor()
        cur.execute("""select domain_name from v_domains where domain_enabled='true'""")
        rows = cur.fetchall()
        if rows is not None:
            #Get a connection to MySQL
            db=MySQLdb.connect(host=kam_hostname, user=kam_username, passwd=kam_password, db=kam_database)
            c=db.cursor()
            for row in rows:
                c.execute("""insert ignore into domain (id,domain,did) values (null,%s,%s)""", (row[0],row[0]))
                #c.execute("""delete from domain_attrs where did=%s""",(row[0]))
                c.execute("""insert ignore into domain_attrs (id,did,name,type,value) values (null,%s,'pbx_ip',2,%s)""", (row[0],pbx_ip))
                
            db.commit()                
    except Exception as e:
        print(e)

def main():
   
    #Get the list of FusionPBX's that needs to be sync'd
    sources = get_sources()
   
    #Set destination server settings
    dest={}
    dest['hostname']='localhost'
    dest['username']='kamailio'
    dest['password']='kamailiorw'
    dest['database']='kamailio'

 
    #Loop thru each FusionPBX system and start the sync
    for key in sources:
        sync_db(sources[key],dest)

if __name__== "__main__":
    main()
