# FusionPBX Plugin for the Media Server api
import psycopg2
import psycopg2.extras
import json
import uuid




class mediaserver():

    hostname=''
    port=''
    auth_type=''
    username=''
    password=''
    dbname="fusionpbx"
    db=''


    def __init__(self, config):
        self.hostname =config.hostname
        self.port = config.port
        self.auth_type = config.auth_type
        self.username = config.username
        self.password = config.password
        self.dbname = config.dbname

    def testConnection(self):
        print("testConnection")
        pass

    def getConnection(self):
        try:
            db = psycopg2.connect(host=self.hostname,port=self.port,user=self.username,password=self.password,dbname=self.dbname)
            if db is not None:
                print("Connection to FusionPBX: {} database was successful".format(self.hostname))
                return db

        except Exception as ex:
            raise

    def closeConnection(self):
        db.close()

class domain():
    domain_id=""
    name = ""
    enabled = ""
    description = ""

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
            sort_keys=True, indent=4)

class domains():

    mediaserver=''
    db=''
    domain_list = []

    def __init__(self, mediaserver):
        self.mediaserver = mediaserver
        self.db = self.mediaserver.getConnection()

    def create(self,data):
        # call it in any place of your program
        # before working with UUID objects in PostgreSQL
        psycopg2.extras.register_uuid()
        domain_uuid = uuid.uuid4()
        cur = self.db.cursor()
        cur.execute("""insert into v_domains (domain_uuid,domain_name,domain_enabled,domain_description) \
                    values (%s,%s,%s,%s)""",(domain_uuid,data['name'],data['enabled'],data['description']))
        self.db.commit()
        cur.close()

    def getDomain(self,domain_name=None):
        cur = self.db.cursor()
        cur.execute("""select domain_uuid,domain_name,domain_enabled,domain_description from v_domains where domain_enabled='true'""")
        rows = cur.fetchall()
        if rows is not None:
            for row in rows:
                d = {}
                d['domain_id'] = row[0]
                d['name']= row[1]
                d['enabled'] = row[2]
                d['description'] = row[3]

                self.domain_list.append(d)

        return self.domain_list




    def update():
        pass

    def delete():
        pass

    def getExtensions():
        pass

class extension():

    mediaserver=''
    domain=''

    def __init__(self, mediaserver, domain):
        self.mediaserver = mediaserver
        self.domain = domain

    def createExtension():
        pass

    def getExtension():
        pass

    def updateExtension():
        pass

    def deleteExtension():
        pass
