# FusionPBX Plugin for the Media Server api
import psycopg2

class mediaserver():

    hostname=''
    port=''
    auth_type=''
    username=''
    password=''
    dbname="fusionpbx"


    def __init__(self, hostname,username,password,dbname,port='5432',auth_type=None):
        self.hostname = hostname
        self.port = port
        self.auth_type = auth_type
        self.username = username
        self.password = password
        self.dbname = dbname

    def testConnection(self):
        pass

    def getConnection(self):
        try:
            db = psycopg2.connect(host=self.hostname,port=self.port,user=self.username,password=self.password,dbname=self.dbname)
            if db is not None:
                print("Connection to FusionPBX:{} database was successful".format(self.hostname))
                return db

        except Exception as ex:
            raise

    def getDomains():
        return domain(mediaserver)

    def closeConnection(self):
        pass

class domain():

    mediaserver=''

    def __init__(self, mediaserver):
        self.mediaserver = mediaserver

    def createDomain():
        pass

    def getDomain():
        pass

    def updateDomain():
        pass

    def deleteDomain():
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
