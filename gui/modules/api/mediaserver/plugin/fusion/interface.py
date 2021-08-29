# FusionPBX Plugin for the Media Server api
import psycopg2
import psycopg2.extras
import json
import uuid


# Defining a dialplan object, which allows you to define how the
# dialplan within a domain behaves
class cos_dialplan():

    name = None
    dialplan_xml = None

    def __init__(self):
        self.dialplan_xml = []

    def add(self,data):
        dialplan_entry = {}
        dialplan_entry['name'] = data['name']
        dialplan_entry['number'] = data['number']
        dialplan_entry['continue'] = data['continue']
        dialplan_entry['order'] = data['order']
        dialplan_entry['description'] = data['description']
        dialplan_entry['enabled'] = data['enabled']
        dialplan_entry['hostname'] = data['hostname']
        dialplan_entry['logic'] = data['logic']
        self.dialplan_xml.append(dialplan_entry)



class cos():

    domain_uuid=""
    db = ""
    dialplan_list = []
    domain = None

    def __init__(self, domain,data=None):
        if domain.db:
            self.db = domain.db
        self.domain_uuid = domain.domain_id
        self.domain = domain


        # Load up some default CoS definitions

        # The default class of service will use the global dialplan within FUSIONPBX
        # In other words no changes to the Domain dialplan manager
        cos_default = cos_dialplan()
        cos_default.name="default"
        cos_default.dialplan_xml = None
        self.dialplan_list.append(cos_default)

        # This class of service will disable inbound caller id
        cos_standard = cos_dialplan()
        cos_standard.name="standard"
        entry = {}
        entry['name'] = "block_caller_id"
        entry['number'] = ""
        entry['continue'] = "true"
        entry['order'] = 700
        entry['enabled'] = "true"
        entry['description'] = "Block inbound caller id"
        entry['hostname'] = ""
        entry['logic'] = "<extension name=\"local_extension\" continue=\"true\" uuid=\"fbba5244-7453-4390-8976-2c307140529g\"> \
            <condition field=\"${user_exists}\" expression=\"true\"> \
               <action application=\"export\" data=\"sip_cid_type=none\"/> \
               <action application=\"export\" data=\"origination_caller_id_name=Blocked\"/> \
               <action application=\"export\" data=\"origination_caller_id_number=0000000000\"/> \
            </condition> \
            </extension>"
        cos_standard.add(entry)
        self.dialplan_list.append(cos_standard)

        if data is not None and 'settings' in data:
            domain_settings = data['settings']
            cos_settings = cos_dialplan()
            cos_settings.name="domain_settings"
            entry = {}
            entry['name'] = "domain_settings"
            entry['number'] = ""
            entry['continue'] = "true"
            entry['order'] = 20
            entry['enabled'] = "true"
            entry['description'] = "Domain Settings"
            entry['hostname'] = ""
            entry['logic'] = "<extension name=\"domain_settings\" continue=\"true\" uuid=\"af2cd91f-1db2-4742-b8c2-ef519ba6e8b5\"> \
    	             <condition field=\"\" expression=\"\">  \
    		               <action application=\"set\" data=\"default_language={}\"/> \
    		               <action application=\"set\" data=\"default_dialect={}\"/> \
    		               <action application=\"set\" data=\"default_voice={}\"/> \
    	             </condition> \
                     </extension>".format(domain_settings['default_language'],domain_settings['default_dialect'],domain_settings['default_voice'])
            cos_settings.add(entry)
            self.dialplan_list.append(cos_settings)


    def create(self, name):
        psycopg2.extras.register_uuid()
        app_uuid = uuid.uuid4()
        cur = self.db.cursor()

        for cos_dp in self.dialplan_list:
            print("{},{}".format(cos_dp.name,name))
            if cos_dp.name == name:
                if cos_dp.dialplan_xml == None:
                    continue
                for xml in cos_dp.dialplan_xml:
                    dialplan_uuid = uuid.uuid4()
                    query = "insert into v_dialplans (domain_uuid,dialplan_uuid,app_uuid,dialplan_context, \
                            dialplan_name,dialplan_number,dialplan_continue,dialplan_order,dialplan_enabled, \
                            dialplan_description, hostname, dialplan_xml) values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"



                    values = [self.domain_uuid,dialplan_uuid,app_uuid,self.domain.name, \
                            xml['name'], xml['number'], xml['continue'], \
                            xml['order'], xml['enabled'],xml['description'], \
                            xml['hostname'],xml['logic']]

                    cur.execute(query,values)

                self.db.commit()

        cur.close()

        def delete(self):
            psycopg2.extras.register_uuid()
            cur = self.db.cursor()

            cur.execute("""delete from v_dialplans where domain_uuid = %s""",(self.domain_uuid))

            self.db.commit()
            cur.close()
            return True


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
    db = None

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
        d = domain()
        d.domain_id = domain_uuid
        d.name = data['name']
        d.enabled = data['enabled']
        d.description = data['description']
        d.db = self.db
        d.cos = data['cos']
        cur.close()
        return d


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
                d['domain_uuid'] = row[0]
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

        # Delete from domains
        cur.execute("""delete from v_domains where domain_uuid = %s""",(domain_id,))

        # Delete the inbound dialplan for the domain
        cur.execute("""delete from v_dialplans where domain_uuid = %s""",(domain_id,))


        self.db.commit()
        cur.close()
        return True

    def getExtensions():
        pass






class extension():

    extension_id=""
    domain_id=""
    account_code=""
    extension=""
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
        voicemail_uuid = uuid.uuid4()
        cur = self.db.cursor()
        cur.execute("""insert into v_extensions (extension_uuid,domain_uuid,extension,password, \
                    user_context,call_timeout,enabled,outbound_caller_id_number, \
                    outbound_caller_id_name,accountcode) \
                    values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", \
                    (extension_uuid, self.domain_uuid, data.extension, \
                    data.password, self.domain['name'], data.call_timeout, data.enabled, \
                    data.outbound_caller_number,data.outbound_caller_name,data.account_code))

        # Create voicemail box
        query = "insert into v_voicemails (domain_uuid,voicemail_uuid,voicemail_id, \
                voicemail_password,greeting_id,voicemail_alternate_greet_id, \
                voicemail_mail_to,voicemail_sms_to,voicemail_transcription_enabled,voicemail_attach_file, \
                voicemail_file,voicemail_local_after_email,voicemail_enabled,voicemail_description, \
                voicemail_name_base64,voicemail_tutorial) \
                values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) "

        values = [self.domain_uuid,voicemail_uuid, \
                 data.extension,data.vm_password,None,None,data.vm_notify_email,None,None,None,'attach',"true", data.vm_enabled,None,None,None]

        cur.execute(query,values)

        self.db.commit()
        cur.close()


    def read(self, extension_id=None):
        cur = self.db.cursor()
        query = "select extension_uuid,domain_uuid,extension,password,user_context,call_timeout::integer as call_timeout, \
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
                d['extension'] = row[2]
                #d['password'] = row[3]
                d['user_context'] = row[4]
                d['call_timeout'] = row[5]
                d['enabled'] = row[6]
                d['outbound_caller_number'] = row[7]
                d['outbound_caller_name'] = row[8]
                d['account_code'] = row[9]
                self.extension_list.append(d)

        return self.extension_list

    def update(self,data):
        psycopg2.extras.register_uuid()
        cur = self.db.cursor()
        query="update v_extensions set "
        values=[]
        db_data = {}

        #Map canaical format to database format
        db_data['domain_uuid'] = data['domain_id']
        db_data['extension'] = data['extension']
        db_data['password'] = data['password']
        db_data['enabled'] = data['enabled']
        db_data['accountcode'] = data['account_code']
        db_data['outbound_caller_id_number'] = data['outbound_caller_number']
        db_data['outbound_caller_id_name'] = data['outbound_caller_name']
        db_data['call_timeout'] = data['call_timeout']

        for element in db_data:
            # Don't process Voice Mail Attributes
            if "vm_" in element:
                continue
            query = query + "{} = %s,".format(element)
            values.append(db_data[element])

        # Remove the last comma
        if query[len(query)-1] == ',':
            query = query[:-1]

        query = query + " where extension_uuid = '{}'".format(self.getExtensionID(db_data['extension']))

        print(query)
        print(values)
        cur.execute(query,(values))


        self.db.commit()
        cur.close()

    def getExtensionID(self,extension):
        cur = self.db.cursor()
        query = "select extension_uuid from v_extensions where domain_uuid = %s and extension = %s"
        values = [self.domain_uuid,extension]

        cur.execute(query,(values))
        rows = cur.fetchall()
        if rows is not None:
            for row in rows:
                return row[0]

        cur.close()

    def delete(self,extension):
        #Todo: Check if the domain exists before creating it
        # call it in any place of your program
        # before working with UUID objects in PostgreSQL
        psycopg2.extras.register_uuid()
        domain_uuid = uuid.uuid4()
        cur = self.db.cursor()


        cur.execute("""delete from v_extensions where domain_uuid = %s and extension = %s""",(self.domain_uuid,extension))
        cur.execute("""delete from v_voicemails where domain_uuid = %s and voicemail_id = %s""",(self.domain_uuid,extension))
        self.db.commit()
        cur.close()
        return True
