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
    cos = "" # Class of Service

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
        #Todo: Check if the domain exists before creating it
        # call it in any place of your program
        # before working with UUID objects in PostgreSQL
        psycopg2.extras.register_uuid()
        domain_uuid = uuid.uuid4()
        cur = self.db.cursor()

        # Check for Duplicate domains
        cur.execute("""select domain_name from v_domains where domain_name = %s""",(data['name'],))
        rows = cur.fetchall()
        if len(rows) > 0:
            raise Exception ("The domain already exists")
            return

        # Create the new domain
        cur.execute("""insert into v_domains (domain_uuid,domain_name,domain_enabled,domain_description) \
                    values (%s,%s,%s,%s)""",(domain_uuid,data['name'],data['enabled'],data['description']))
        self.db.commit()
        return domain_uuid
        cur.close()

    def read(self,domain_id=None):
        cur = self.db.cursor()
        query = "select domain_uuid,domain_name,domain_enabled,domain_description from v_domains"
        values = []

        if domain_id:
            query = query + " where domain_uuid = %s"
            values.append(domain_id)

        cur.execute(query,(values))
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




    def update(self,data):
        cur = self.db.cursor()
        # Convert UUID string to UUID type
        domain_uuid=data['domain_id']
        # Get the current data for the domain from the database
        current_data = self.read(domain_uuid)
        # Update the current data with the new data
        if len(current_data) >= 1:
            current_data[0]['name'] = data['name']
            current_data[0]['enabled'] = data['enabled']
            current_data[0]['description'] = data['description']

            cur.execute("""update v_domains set domain_name= %s,domain_enabled = %s,domain_description = %s where domain_uuid= %s""", \
                    (current_data[0]['name'],current_data[0]['enabled'],current_data[0]['description'],domain_uuid))
            rows = cur.rowcount
            self.db.commit()

        cur.close()
        return True


    def delete(self,domain_id):
        #Todo: Check if the domain exists before creating it
        # call it in any place of your program
        # before working with UUID objects in PostgreSQL
        psycopg2.extras.register_uuid()
        domain_uuid = uuid.uuid4()
        cur = self.db.cursor()

        # Check for Duplicate domains
        cur.execute("""delete from v_domains where domain_uuid = %s""",(domain_id,))
        self.db.commit()
        cur.close()
        return True

    def getExtensions():
        pass


class extension():

    extension_id=""
    domain_id=""
    account_code=""
    number=""
    password=""
    outbound_caller_number=""
    outbound_caller_name=""
    vm_enabled=True
    vm_password=""
    vm_notify_email=""
    enabled=False
    call_timeout=30

    def __init__(self):
        pass

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
            sort_keys=True, indent=4)

class extensions():

    mediaserver=None
    domain=None
    domain_name=''
    domain_uuid=''
    db=''
    extension_list = []

    def __init__(self, mediaserver, domain ,extension=None):
        self.mediaserver = mediaserver
        self.db = self.mediaserver.getConnection()
        self.domain = domain
        self.domain_uuid = self.domain['domain_id']
        self.domain_name = self.domain['name']

    def create(self,data):
        psycopg2.extras.register_uuid()
        extension_uuid = uuid.uuid4()
        cur = self.db.cursor()
        cur.execute("""insert into v_extensions (extension_uuid,domain_uuid,extension,password, \
                    user_context,call_timeout,enabled,outbound_caller_id_number, \
                    outbound_caller_id_name,accountcode) \
                    values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", \
                    (extension_uuid, self.domain_uuid, data.number, \
                    data.password, self.domain['name'], data.call_timeout, data.enabled, \
                    data.outbound_caller_number,data.outbound_caller_name,data.account_code))

        self.db.commit()
        cur.close()


    def read(self, extension_id=None):
        cur = self.db.cursor()
        query = "select extension_uuid,domain_uuid,extension,password,user_context,call_timeout, \
        enabled,outbound_caller_id_number,outbound_caller_id_name, accountcode from v_extensions where domain_uuid = %s"
        values = [self.domain_uuid]

        if extension_id:
            query = query + " and extension_uuid = %s"
            values.append(extension_id)

        cur.execute(query,(values))
        rows = cur.fetchall()
        if rows is not None:
            for row in rows:
                d = {}
                d['extensions_id'] = row[0]
                d['domain_uuid']= row[1]
                d['number'] = row[2]
                #d['password'] = row[3]
                d['user_context'] = row[4]
                d['call_timeout'] = row[5]
                d['enabled'] = row[6]
                d['outbound_caller_number'] = row[7]
                d['outbound_caller_name'] = row[8]
                d['account_code'] = row[9]
                self.extension_list.append(d)

        return self.extension_list

    def update():
        pass

    def delete():
        pass
