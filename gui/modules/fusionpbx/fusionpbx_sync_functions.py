import os, psycopg2, hashlib, MySQLdb, subprocess, docker,shutil
from database import dSIPMultiDomainMapping
from util.security import AES_CTR
from util.networking import safeUriToHost, hostToIP

# TODO: error handling here is pretty bad, we need to establish connection from main func and pass conn/cursors to sub funcs
#       I implemented an exmaple in sync_needed() of proper connection / cursor handling, we need to move that to the entry func
#       i.e. run_sync() should utilize the proper handling of the connections/cursors and pass them to sub functions

# Obtain a set of FusionPBX systems that contains domains that Kamailio will route traffic to.
def get_sources(db):
    # Dictionary object to hold the set of source FusionPBX systems
    sources = {}

    # Kamailio Database Parameters
    kam_hostname = db['hostname']
    kam_username = db['username']
    kam_password = db['password']
    kam_database = db['database']

    try:
        db = MySQLdb.connect(host=kam_hostname, user=kam_username, passwd=kam_password, db=kam_database)
        c = db.cursor()
        c.execute(
            """select pbx_id,address as pbx_host,db_host,db_username,db_password,domain_list,domain_list_hash,attr_list,dsip_multidomain_mapping.type from dsip_multidomain_mapping join dr_gw_lists on dsip_multidomain_mapping.pbx_id=dr_gw_lists.id join dr_gateways on dr_gateways.gwid = dr_gw_lists.gwlist where enabled=1""")
        results = c.fetchall()
        db.close()
        for row in results:
            # Store the PBX_ID as the key and the entire row as the value
            sources[row[1]] = row
    except Exception as e:
        print(str(e))

    return sources


# Will remove all of the fusionpbx domain data so that it can be rebuilt
def drop_fusionpbx_domains(source, dest):
    # PBX Domain Mapping Parameters
    pbx_domain_list = source[5]
    pbx_attr_list = source[6]

    # Kamailio Database Parameters
    kam_hostname = dest['hostname']
    kam_username = dest['username']
    kam_password = dest['password']
    kam_database = dest['database']

    pbx_domain_list = list(map(int, filter(None, pbx_domain_list.split(","))))
    pbx_attr_list = list(map(int, filter(None, pbx_attr_list.split(","))))

    kam_conn = None
    kam_curs = None

    try:
        kam_conn = MySQLdb.connect(host=kam_hostname, user=kam_username, passwd=kam_password, db=kam_database)
        kam_curs = kam_conn.cursor()

        if len(pbx_domain_list) > 0:
            kam_curs.execute("""DELETE FROM domain WHERE id IN({})""".format(pbx_domain_list))

        if len(pbx_attr_list) > 0:
            kam_curs.execute("""DELETE FROM domain_attrs WHERE id IN({})""".format(pbx_attr_list))

        kam_conn.commit()
    except Exception as ex:
        error = str(ex)
        try:
            kam_conn.rollback()
            kam_curs.execute("update dsip_multidomain_mapping set syncstatus=4, lastsync=NOW(),syncerror='{}'".format(error))
            kam_conn.commit()
        except:
            pass
        raise ex
    finally:
        if kam_curs is not None:
            kam_curs.close()
        if kam_conn is not None:
            kam_conn.close()

def sync_db(source, dest):
    # FusionPBX Database Parameters
    pbx_id = source[0]
    pbx_host = source[1]
    if ':' in source[2]:
        fpbx_hostname = source[2].split(':')[0]
        fpbx_port = source[2].split(':')[1]
    else:
        fpbx_hostname = source[2]
        fpbx_port = 5432
    fpbx_username = source[3]
    fpbx_password = source[4]
    pbx_domain_list = source[5]
    pbx_attr_list = source[6]
    pbx_type = source[8]
    fpbx_database = 'fusionpbx'

    # Kamailio Database Parameters
    kam_hostname = dest['hostname']
    kam_username = dest['username']
    kam_password = dest['password']
    kam_database = dest['database']

    domain_id_list = []
    attr_id_list = []

    fpbx_conn = None
    fpbx_curs = None
    kam_conn = None
    kam_curs = None

    try:
        # Get a connection to Kamailio Server DB
        kam_conn = MySQLdb.connect(host=kam_hostname, user=kam_username, passwd=kam_password, db=kam_database)
        kam_curs = kam_conn.cursor()
        # Delete existing domain for the pbx
        pbx_domain_list_str = ''.join(str(e) for e in pbx_domain_list)
        if len(pbx_domain_list_str) > 0:
            query = "delete from domain where id in ({})".format(pbx_domain_list_str)
            kam_curs.execute(query)
            pbx_domain_list = ''

        # Trying connecting to PostgresSQL database using a Trust releationship first
        fpbx_conn = psycopg2.connect(dbname=fpbx_database, user=fpbx_username, host=fpbx_hostname, port=fpbx_port, password=fpbx_password)
        if fpbx_conn is not None:
            print("Connection to FusionPBX:{} database was successful".format(fpbx_hostname))
        fpbx_curs = fpbx_conn.cursor()
        fpbx_curs.execute("""select domain_name from v_domains where domain_enabled='true' and domain_name <> %s""",[hostToIP(fpbx_hostname)])
        rows = fpbx_curs.fetchall()
        if rows is not None:
            counter = 0
            domain_name_str = ""

            for row in rows:
                kam_curs.execute("""insert ignore into domain (id,domain,did,last_modified) values (null,%s,%s,NOW())""",
                          (row[0], row[0]))

                if kam_curs.rowcount > 0:
                    kam_curs.execute(
                        """SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN('domain') ORDER BY FIND_IN_SET(TABLE_NAME, 'domain')""")
                    rows_left = kam_curs.fetchall()
                    domain_id_list.append(str(rows_left[0][0] - 1))
                # Delete all domain_attrs for the domain first
                kam_curs.execute("""delete from domain_attrs where did=%s""", [row[0]])
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'pbx_ip',2,%s,NOW())""",
                    (row[0], pbx_host))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'pbx_type',2,%s,NOW())""",

                    (row[0], pbx_type))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'created_by',2,%s,NOW())""",
                    (row[0], pbx_id))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'dispatcher_set_id',2,%s,NOW())""",
                    (row[0], pbx_id))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'dispatcher_reg_alg',2,%s,NOW())""",
                    (row[0], 4))
                kam_curs.execute(

                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'domain_auth',2,%s,NOW())""",
                    (row[0], 'passthru'))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'pbx_list',2,%s,NOW())""",
                    (row[0], pbx_id))
                kam_curs.execute(
                    """insert ignore into domain_attrs (id,did,name,type,value,last_modified) values (null,%s,'description',2,%s,NOW())""",
                    (row[0], 'notes:'))
                counter = counter + 1
                domain_name_str += row[0]

            # Convert to a string seperated by commas
            domain_id_list = ','.join(domain_id_list)

            if not pbx_domain_list:  # if empty string then this is the first set of domains
                pbx_domain_list = domain_id_list
            else:  # adding to an existing list of domains
                pbx_domain_list = pbx_domain_list + "," + domain_id_list

            print("[sync_db] String of domains: {}".format(domain_name_str))

            # Create Hash of the string
            domain_name_str_hash = hashlib.md5(domain_name_str.encode('utf-8')).hexdigest()
            print("[sync_db] Hashed String of domains: {}".format(domain_name_str_hash))

            kam_curs.execute(
                """update dsip_multidomain_mapping set domain_list=%s, domain_list_hash=%s,syncstatus=1, lastsync=NOW(),syncerror='' where pbx_id=%s""",
                (pbx_domain_list, domain_name_str_hash, pbx_id))
            kam_conn.commit()

    except Exception as ex:
        error = str(ex)
        try:
            kam_conn.rollback()
            kam_curs.execute("update dsip_multidomain_mapping set syncstatus=4, lastsync=NOW(),syncerror='{}'".format(error))
            kam_conn.commit()
        except:
            pass
        raise ex
    finally:
        if fpbx_conn is not None:
            fpbx_conn.close()
        if fpbx_curs is not None:
            fpbx_curs.close()
        if kam_curs is not None:
            kam_curs.close()
        if kam_conn is not None:
            kam_conn.close()


def reloadkam(kamcmd_path):
    try:
        # subprocess.call(['kamcmd' ,'permissions.addressReload'])
        # subprocess.call(['kamcmd','drouting.reload'])
        subprocess.call([kamcmd_path, 'domain.reload'])
        return True
    except:
        return False


def update_nginx(sources):
    print("Updating Nginx")

#    # Connect to docker
#    client = docker.from_env()
#    if client is not None:
#        print("Got handle to docker")
#
#    try:
#        # If there isn't any FusionPBX sources then just shutdown the container
#        if len(sources) < 1:
#            containers = client.containers.list()
#            for container in containers:
#                if container.name == "dsiprouter-nginx":
#                    # Stop the container
#                    container.stop()
#                    container.remove(force=True)
#                    print("Stopped nginx container")
#            return
#    except Exception as e:
#        os.remove("./.sync-lock")
#        print(e)

    # Create the Nginx file
    try:
        serverList = ""
        for source in sources:
            serverList += "server " + safeUriToHost(str(source)) + ":443;\n"

        script_dir = os.path.dirname(os.path.abspath(__file__))
    
        # TODO: Marked for removal in next release 
        # Build a config for the docker instance of Nginx
        #input = open(script_dir + "/dsiprouter.nginx.tpl")
        #output = open(script_dir + "/dsiprouter.nginx", "w")
        #output.write(input.read().replace("##SERVERLIST##", serverList))
        #output.close()
        #input.close()
    
        # Build a config for the native Nginx instance

        input = open(script_dir + "/dsiprouter-provisioner.tpl")
        output = open(script_dir + "/dsiprouter-provisioner.conf", "w")
        output.write(input.read().replace("##SERVERLIST##", serverList))
        output.close()
        input.close()

        # Copy config to Native Nginx Server and restart Nginx
        shutil.copy(script_dir + "/dsiprouter-provisioner.conf", '/etc/nginx/sites-enabled/dsiprouter-provisioner.conf')
        os.system('systemctl reload nginx')
    
    except Exception as e:
        os.remove("./.sync-lock")
        print(e)

#    Depricating the use of docker containers - logic will be removed during the next release
#    # Check if dsiprouter-nginx is running. If so, reload nginx
#
#    containers = client.containers.list()
#    print("past container list")
#    for container in containers:
#        if container.name == "dsiprouter-nginx":
#            # Execute a command to reload nginx
#            container.exec_run("nginx -s reload")
#            print("Reloaded nginx")
#            return
#
#    # Start the container if one is not running
#    try:
#        print("trying to create a container")
#        host_volume_path = script_dir + "/dsiprouter.nginx"
#        html_volume_path = script_dir + "/html"
#        cert_volume_path = script_dir + "/certs"
#        # host_volume_path = script_dir
#        print(host_volume_path)
#        # remove the container with a name of dsiprouter-nginx to avoid conflicts if it already exists
#        containerList = client.containers.list('dsiprouter-nginx')
#        containerFound = False
#        for c in containerList:
#            if c.name == "dsiprouter-nginx":
#                containerFound = True
#        if containerFound:
#            print("dsiprouter-nginx found...about to remove it and recreate")
#            container = client.containers.get('dsiprouter-nginx')
#            container.remove()
#        client.containers.run(image='nginx:latest',
#                              name="dsiprouter-nginx",
#                              ports={'80/tcp': '80/tcp', '443/tcp': '443/tcp'},
#                              volumes={
#                                  host_volume_path: {'bind': '/etc/nginx/conf.d/default.conf', 'mode': 'rw'},
#                                  html_volume_path: {'bind': '/etc/nginx/html', 'mode': 'rw'},
#                                  cert_volume_path: {'bind': '/etc/ssl/certs', 'mode': 'rw'}
#                              },
#                              detach=True)
#        print("created a container")
#    except Exception as e:
#        os.remove("./.sync-lock")
#        print(str(e))


def sync_needed(source, dest):
    # FusionPBX Database Parameters
    pbx_id = source[0]

    pbx_host = source[1]
    if ':' in source[2]:
        fpbx_hostname = source[2].split(':')[0]
        fpbx_port = source[2].split(':')[1]
    else:
        fpbx_hostname = source[2]
        fpbx_port = 5432
    fpbx_username = source[3]
    fpbx_password = source[4]
    pbx_domain_list = source[5]
    pbx_domain_list_hash = source[6]
    pbx_attr_list = source[7]
    pbx_type = source[8]
    fpbx_database = 'fusionpbx'

    # Kamailio Database Parameters
    kam_hostname = dest['hostname']
    kam_username = dest['username']
    kam_password = dest['password']
    kam_database = dest['database']

    domain_id_list = []
    attr_id_list = []

    need_sync = True

    fpbx_conn = None
    fpbx_curs = None
    kam_conn = None
    kam_curs = None

    # Trying connecting to the databases
    try:
        # Get a connection to Kamailio Server DB
        kam_conn = MySQLdb.connect(host=kam_hostname, user=kam_username, passwd=kam_password, db=kam_database)
        kam_curs = kam_conn.cursor()
        if kam_curs is not None:
            print("[sync_needed] Connection to Kamailio DB: {} database was successful".format(kam_hostname))

        # Get a connection to the FusionPBX Server
        fpbx_conn = psycopg2.connect(dbname=fpbx_database, user=fpbx_username, host=fpbx_hostname, port=fpbx_port, password=fpbx_password)
        if fpbx_conn is not None:
            print("[sync_needed] Connection to FusionPBX DB: {} database was successful".format(fpbx_hostname))
        fpbx_curs = fpbx_conn.cursor()
        fpbx_curs.execute("""select domain_name from v_domains where domain_enabled='true' and domain_name <> %s""",[hostToIP(fpbx_hostname)])
        rows = fpbx_curs.fetchall()
        if rows is not None:
            domain_name_str = ""

            # Build a string that contains all of the domains
            for row in rows:
                domain_name_str += row[0]

            print("[sync_needed] String of domains: {}".format(domain_name_str))

            # Create Hash of the string
            domain_name_str_hash = hashlib.md5(domain_name_str.encode('utf-8')).hexdigest()
            print("[sync_needed] Hashed String of domains: {}".format(domain_name_str_hash))
            if domain_name_str_hash == pbx_domain_list_hash:
                # Sync not needed.  Will update the syncstatus=2 to denote a domain change was not detected
                kam_curs.execute("""update dsip_multidomain_mapping set syncstatus=2, lastsync=NOW()""")
                kam_conn.commit()
                need_sync = False
        else:
            # No domains yet, so no need to sync
            kam_curs.execute("""update dsip_multidomain_mapping set syncstatus=3, lastsync=NOW()""")
            kam_conn.commit()
            need_sync = False

        return need_sync

    except Exception as e:
        error = str(e)
        print(error)
        try:
            kam_conn.rollback()
            kam_curs.execute("update dsip_multidomain_mapping set syncstatus=4, lastsync=NOW(),syncerror='{}'".format())
            kam_conn.commit()
        except:
            pass
    finally:
        if fpbx_conn is not None:
            fpbx_conn.close()
        if fpbx_curs is not None:
            fpbx_curs.close()
        if kam_curs is not None:
            kam_curs.close()
        if kam_conn is not None:
            kam_conn.close()

def run_sync(settings):
    try:
        # Set the system where sync'd data will be stored.
        # The Kamailio DB in our case

        # If already running - don't run
        if os.path.isfile("./.sync-lock"):
            print("Already running")
            return
        else:
            f = open("./.sync-lock", "w+")
            f.close()

        # need to decrypt password if encrypted
        if isinstance(settings.KAM_DB_PASS, bytes):
            kam_password = AES_CTR.decrypt(settings.KAM_DB_PASS)
        else:
            kam_password = settings.KAM_DB_PASS

        dest = {}
        dest['hostname'] = settings.KAM_DB_HOST
        dest['username'] = settings.KAM_DB_USER
        dest['password'] = kam_password
        dest['database'] = settings.KAM_DB_NAME

        # Get the list of FusionPBX's that needs to be sync'd
        sources = get_sources(dest)

        # Loop thru each FusionPBX system and start the sync
        for key in sources:
            if sync_needed(sources[key], dest):
                #drop_fusionpbx_domains(sources[key], dest)
                sync_db(sources[key], dest)
            else:
                print("[run_sync] No changes - no sync needed for source: {}".format(sources[key][1]))

        # Reload Kamailio
        reloadkam(settings.KAM_KAMCMD_PATH)

        # Update Nginx configuration file for HTTP Provisioning and start docker container if we have FusionPBX systems
        # update_nginx(sources[key])
        if sources is not None and len(sources) > 0:
            sources = list(sources.keys())
            update_nginx(sources)
    except Exception as e:
        print(str(e))
    finally:
        # Remove lock file
        os.remove("./.sync-lock")
