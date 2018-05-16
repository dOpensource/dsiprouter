from flask import Flask, render_template, request, redirect, abort, flash, session, url_for,send_from_directory
from flask_script import Manager
import settings
from importlib import reload
from shared import *
from database import loadSession, Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, dSIPFusionPBXDB, dSIPLCR
import os
import subprocess
import json

app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.debug = settings.DEBUG
# app.add_template_filter()
db = loadSession()


@app.route('/')
def index():
    if not session.get('logged_in'):
        return render_template('index.html', version=settings.VERSION)
    else:
        action = request.args.get('action')
        return render_template('dashboard.html', show_add_onload=action, version=settings.VERSION)

@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

@app.route('/login', methods=['POST'])
def login():
    if request.form['password'] == settings.PASSWORD and request.form['username'] == settings.USERNAME:
        session['logged_in'] = True
        session['username'] = request.form['username']
    else:
        flash('wrong username or password!')
        return redirect(url_for('index'))
    return index()


@app.route('/logout')
def logout():
    session['logged_in'] = False
    return index()


@app.route('/carriers')
def displayCarriers(db_err=0):
    if session.get('logged_in'):
        try:
            res = db.query(Gateways).filter(Gateways.type == settings.FLT_CARRIER).all()
            return render_template('carriers.html', rows=res)
        except:
            db.rollback()
            if db_err <= 3:
                # Try again
                db_err = db_err + 1
                print(db_err)
                return displayCarriers(db_err);
            else:
                return render_template('error.html', type="db")
    else:
        return index()


@app.route('/carriers', methods=['POST'])
def addUpdateCarriers():
    gwid = request.form['gwid']
    name = request.form['name']
    ip_addr = request.form['ip_addr']
    strip = request.form['strip']
    prefix = request.form['prefix']
    # Adding
    if len(gwid) <= 0:
        print(name)
        Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_CARRIER)
        Addr = Address(name, ip_addr, 32, settings.FLT_CARRIER)

        try:
            db.add(Gateway)
            db.add(Addr)
            db.commit()
            return displayCarriers()
        except:
            db.rollback()
            return render_template('error.html', type="db")
    # Updating
    else:
        db.query(Gateways).filter(Gateways.gwid == gwid).update(
            {'description': "name:" + name, 'address': ip_addr, 'strip': strip, 'pri_prefix': prefix})
        # TODO: You will end up with multiple Address records -will fix
        Addr = Address(name, ip_addr, 32, settings.FLT_CARRIER)
        try:
            db.add(Addr)
            db.commit()
            return displayCarriers()
        except:
            db.rollback()
            return render_template('error.html', type="db")


@app.route('/carrierdelete', methods=['POST'])
def deleteCarriers():
    gwid = request.form['gwid']
    name = request.form['name']
    d = db.query(Gateways).filter(Gateways.gwid == gwid)
    d.delete(synchronize_session=False)
    a = db.query(Address).filter(Address.tag == 'name:' + name)
    a.delete(synchronize_session=False)
    db.commit()
    return displayCarriers()


@app.route('/pbx')
def displayPBX(db_err=0):
    if session.get('logged_in'):
        try:
            # res = db.query(Gateways).outerjoin(dSIPFusionPBXDB,Gateways.gwid == dSIPFusionPBXDB.pbx_id).add_columns(Gateways.gwid,Gateways.description,Gateways.address,Gateways.strip,Gateways.pri_prefix,dSIPFusionPBXDB.enabled, dSIPFusionPBXDB.db_ip, dSIPFusionPBXDB.db_username,dSIPFusionPBXDB.db_password).filter(Gateways.type==settings.FLT_PBX).all()
            res = db.query(Gateways).outerjoin(dSIPFusionPBXDB, Gateways.gwid == dSIPFusionPBXDB.pbx_id).outerjoin(
                Subscribers, Gateways.gwid == Subscribers.rpid).add_columns(
                Gateways.gwid, Gateways.description,
                Gateways.address, Gateways.strip,
                Gateways.pri_prefix,
                dSIPFusionPBXDB.enabled,
                dSIPFusionPBXDB.db_ip,
                dSIPFusionPBXDB.db_username,
                dSIPFusionPBXDB.db_password,
                Subscribers.rpid, Subscribers.username,
                Subscribers.password).filter(Gateways.type == settings.FLT_PBX).all()
            return render_template('pbxs.html', rows=res, DEFAULT_AUTH_DOMAIN=settings.DOMAIN)
        except:
            if db_err <= 3:
                db.rollback()
                db_err = db_err + 1
                return displayPBX(db_err)
            else:
                return render_template('error.html', type="db")
    else:
        return index()


@app.route('/pbx', methods=['POST'])
def addUpdatePBX():
    gwid = request.form['gwid']
    name = request.form['name']
    ip_addr = request.form.get("ip_addr","")
    strip = request.form.get('strip',"0")
    prefix = request.form['prefix']
    authtype = request.form['authtype']
    fusionpbx_db_enabled = request.form.get('fusionpbx_db_enabled', "0")
    fusionpbx_db_server = request.form['fusionpbx_db_server']
    fusionpbx_db_username = request.form['fusionpbx_db_username']
    fusionpbx_db_password = request.form['fusionpbx_db_password']
    pbx_username = request.form['pbx_username']
    pbx_password = request.form['pbx_password']

    print("fusionpbx_db_enabled: %s", fusionpbx_db_enabled)
    # Adding
    if len(gwid) <= 0:
        print(name)
        Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)
        db.add(Gateway)
        db.flush()
        if authtype == "ip":
            Addr = Address(name, ip_addr, 32, settings.FLT_PBX)
            db.add(Addr)
        else:

            Subscriber = Subscribers(pbx_username, pbx_password, settings.DOMAIN, Gateway.gwid)
            db.add(Subscriber)

        db.commit()
        db.refresh(Gateway)
        if fusionpbx_db_enabled == "1":
            print('*****This fusionpbx_db_server:' + fusionpbx_db_server)
            FusionPBXDB = dSIPFusionPBXDB(Gateway.gwid, fusionpbx_db_server, fusionpbx_db_username,
                                          fusionpbx_db_password, int(fusionpbx_db_enabled))
            # Add another Gateway that represents the External interface, which is 5080 by default
            name = name + " external"
            # Test ip address to see if it contains a port number
            index = ip_addr.find(":")
            if index > 0:
                ip_addr = ip_addr[:index - 1]
                ip_addr = ip_addr + ":5080"
                Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)
            else:
                ip_addr = ip_addr + ":5080"
                Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)

            db.add(Gateway)
            db.add(FusionPBXDB)
            db.commit()
        return displayPBX()
    # Updating
    else:
        # Update the Gateway table
        db.query(Gateways).filter(Gateways.gwid == gwid).update(
            {'description': "name:" + name, 'address': ip_addr, 'strip': strip, 'pri_prefix': prefix})
        # Update FusionPBX tables
        exists = db.query(dSIPFusionPBXDB).filter(dSIPFusionPBXDB.pbx_id == gwid).scalar()
        if exists:
            db.query(dSIPFusionPBXDB).filter(dSIPFusionPBXDB.pbx_id == gwid).update(
                {'pbx_id': gwid, 'db_ip': fusionpbx_db_server, 'db_username': fusionpbx_db_username,
                 'db_password': fusionpbx_db_password, 'enabled': fusionpbx_db_enabled})
        else:
            FusionPBXDB = dSIPFusionPBXDB(gwid, fusionpbx_db_server, fusionpbx_db_username, fusionpbx_db_password,
                                          int(fusionpbx_db_enabled))
            db.add(FusionPBXDB)

        # Update Subscribers table auth credentials are being used
        if authtype == "userpwd":

            # Remove ip address from address table
            address = db.query(Address).filter(Address.tag == 'name:' + name)
            address.delete(synchronize_session=False)

            # Add the username and password that will be used for authentication
            # Check if the entry in the subscriber table already exists
            exists = db.query(Subscribers).filter(Subscribers.rpid == gwid).scalar()
            if exists:
                db.query(Subscribers).filter(Subscribers.rpid == gwid).update(
                    {'username': pbx_username, 'password': pbx_password, 'rpid': gwid})
            else:
                Subscriber = Subscribers(pbx_username, pbx_password, settings.DOMAIN, gwid)
                db.add(Subscriber)
        else: #Update the Address table with the new ip address
                db.query(Address).filter(Address.tag == "name:" + name).update({'ip_addr': ip_addr})
        db.commit()
        return displayPBX()


@app.route('/pbxdelete', methods=['POST'])
def deletePBX():
    gwid = request.form['gwid']
    name = request.form['name']
    gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
    gateway.delete(synchronize_session=False)
    address = db.query(Address).filter(Address.tag == 'name:' + name)
    address.delete(synchronize_session=False)
    subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwid)
    subscriber.delete(synchronize_session=False)
    address.delete(synchronize_session=False)
    fusionpbxdb = db.query(dSIPFusionPBXDB).filter(dSIPFusionPBXDB.pbx_id == gwid)
    fusionpbxdb.delete(synchronize_session=False)
    db.commit()
    return displayPBX()


@app.route('/inboundmapping')
def displayInboundMapping(db_err=0):
    """
    Displaying of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # group for inbound routes
    groupid = 9000

    if session.get('logged_in'):
        try:
            res = db.execute(
                'select * from dr_rules r,dr_gateways g where r.gwlist = g.gwid and r.groupid = {}'.format(groupid))
            gateways = db.query(Gateways).filter(Gateways.type == settings.FLT_PBX).all()
            return render_template('inboundmapping.html', rows=res, gwlist=gateways)
        except:
            if db_err <= 3:
                db.rollback()
                db_err = db_err + 1
                return displayInboundMapping(db_err)
            else:
                return render_template('error.html', type="db")

    else:
        return index()


@app.route('/inboundmapping', methods=['POST'])
def addInboundMapping():
    """
    Adding and Updating of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # group for inbound routes
    groupid = 9000

    # id in dr_rules table
    ruleid = None
    if request.form['ruleid']:
        ruleid = request.form['ruleid']

    # get form data
    gwid = request.form['gwid']
    prefix = request.form['prefix']

    # Adding
    if not ruleid:
        IMap = InboundMapping(groupid, prefix, gwid)
        db.add(IMap)
        db.commit()
    # Updating
    else:
        db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).update({'prefix': prefix, 'gwlist': gwid})
        db.commit()
    return displayInboundMapping()


@app.route('/inboundmappingdelete', methods=['POST'])
def deleteInboundMapping():
    """
    Deleting of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    ruleid = request.form['ruleid']
    d = db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid)
    d.delete(synchronize_session=False)
    return displayInboundMapping()


@app.route('/teleblock')
def displayTeleBlock(db_err=0):


    if session.get('logged_in'):
        try:

            teleblock = {}
            teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
            teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
            teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
            teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
            teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT

            return render_template('teleblock.html', teleblock=teleblock)
        
        except:
         
            return render_template('error.html', type="db")         

@app.route('/teleblock', methods=['POST'])
def addUpdateTeleBlock(db_err=0):


    if session.get('logged_in'):
        try:
 
            # Update the teleblock settings
            teleblock = {}
            teleblock['TELEBLOCK_GW_ENABLED'] = request.form.get('gw_enabled', 0)
            teleblock['TELEBLOCK_GW_IP'] = request.form['gw_ip']
            teleblock['TELEBLOCK_GW_PORT'] = request.form['gw_port']
            teleblock['TELEBLOCK_MEDIA_IP'] = request.form['media_ip']
            teleblock['TELEBLOCK_MEDIA_PORT'] = request.form['media_port']

            updateConfigFile('gui/settings.py', teleblock)
            reload(settings)
            return displayTeleBlock()

        except:

            return render_template('error.html', type="db")

@app.route('/outboundroutes')
def displayOutboundRoutes(db_err=0):
    """
    Displaying of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # group for outbound routes
    groupid = 8000

    if session.get('logged_in'):
        try:
            rows = db.query(OutboundRoutes).filter((OutboundRoutes.groupid == groupid) | (OutboundRoutes.groupid >= 10000)).outerjoin(dSIPLCR, dSIPLCR.dr_groupid == OutboundRoutes.groupid).add_columns(dSIPLCR.from_prefix,dSIPLCR.cost,OutboundRoutes.ruleid, OutboundRoutes.prefix,OutboundRoutes.routeid,OutboundRoutes.gwlist,OutboundRoutes.timerec,OutboundRoutes.priority,OutboundRoutes.description)

            teleblock = {}
            teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
            teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
            teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
            teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
            teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT


            return render_template('outboundroutes.html', rows=rows, teleblock=teleblock, custom_routes='')
        except:
            if db_err <= 3:
                db.rollback()
                db_err = db_err + 1
                return displayOutboundRoutes(db_err)
            else:
                return render_template('error.html', type="db")
    else:
        return index()


@app.route('/outboundroutes', methods=['POST'])
def addUpateOutboundRoutes():
    """
    Adding and Updating dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    if session.get('logged_in') is None:
        return index()

    # group for the default outbound routes
    groupid = 8000

    # id in dr_rules table
    ruleid = None
    from_prefix = None
    pattern = None

    if request.form['ruleid']:
        ruleid = request.form['ruleid']

    # set default values
    prefix = ""
    timerec = ""
    priority = 0
    routeid = "1"
    gwlist = ""
    description = ""

    # get form data
    if request.form['from_prefix']:
        from_prefix = request.form['from_prefix']
    if request.form['prefix']:
        prefix = request.form['prefix']
    if request.form['timerec']:
        timerec = request.form['timerec']
    if request.form['priority']:
        priority = int(request.form['priority'])
    routeid = request.form.get('routeid',"")
    if request.form['gwlist']:
        gwlist = request.form['gwlist']
    if request.form['name']:
        description = 'name:{}'.format(request.form['name'])


    # Adding
    if not ruleid:
        if from_prefix != None :
            print("from_prefix: {}".format(from_prefix))
            #return displayOutboundRoutes()
            # Grab the lastest groupid and increment
            mlcr = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid >= 10000).order_by(dSIPLCR.dr_groupid.desc()).first()
            db.commit()

           #Start LCR routes with a groupid of 10000 
            if mlcr is None:
                groupid=10000
            else:
                groupid=int(mlcr.dr_groupid)+1
            
            pattern = from_prefix + "-" + prefix

        OMap = OutboundRoutes(groupid=groupid, prefix=prefix, timerec=timerec, priority=priority,
                              routeid=routeid, gwlist=gwlist, description=description)
        db.add(OMap)
        db.commit()
        db.flush()

	#Add the lcr map
        if pattern != None:
            OLCRMap = dSIPLCR(pattern,from_prefix,groupid)
            db.add(OLCRMap)
            db.commit()
            db.flush()

    # Updating
    else:
        OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
            'prefix': prefix, 'timerec': timerec, 'priority': priority,
            'routeid': routeid, 'gwlist': gwlist, 'description': description
        })
        db.commit()
	
        if from_prefix:
            #Update the existing LCR mapping

            # Setup new pattern
            pattern = from_prefix + "-" + prefix

            OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
            db.commit()

            db.query(dSIPLCR).filter(dSIPLCR.dr_groupid==OMap.groupid).update({
              'pattern': pattern, 'from_prefix': from_prefix})
            db.commit()

    return displayOutboundRoutes()


@app.route('/outboundroutesdelete', methods=['POST'])
def deleteOutboundRoute():
    """
    Deleting of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """
    

    ruleid = request.form['ruleid']

    OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
    db.commit()

    d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid==OMap.groupid)
    d1.delete(synchronize_session=False)

    d = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid)
    d.delete(synchronize_session=False)
   
    db.commit() 
    db.flush()
    return displayOutboundRoutes()


@app.route('/reloadkam')
def reloadkam():
    return_code = subprocess.call(['kamcmd', 'permissions.addressReload'])
    return_code += subprocess.call(['kamcmd', 'drouting.reload'])
    return_code += subprocess.call(['kamcmd', 'htable.reload', 'tofromprefix'])
    return_code += subprocess.call(
        ['kamcmd', 'cfg.seti', 'teleblock', 'gw_enabled', str(settings.TELEBLOCK_GW_ENABLED)])

    # Enable/Disable Teleblock
    if settings.TELEBLOCK_GW_ENABLED:
        return_code += subprocess.call(['kamcmd', 'cfg.sets', 'teleblock', 'gw_ip', str(settings.TELEBLOCK_GW_IP)])
        return_code += subprocess.call(['kamcmd', 'cfg.seti', 'teleblock', 'gw_port', str(settings.TELEBLOCK_GW_PORT)])
        return_code += subprocess.call(
            ['kamcmd', 'cfg.sets', 'teleblock', 'media_ip', str(settings.TELEBLOCK_MEDIA_IP)])
        return_code += subprocess.call(
            ['kamcmd', 'cfg.seti', 'teleblock', 'media_port', str(settings.TELEBLOCK_MEDIA_PORT)])

    session['last_page'] = request.headers['Referer']
    if return_code == 0:
        status_code = 1
    else:
        status_code = 0
    return json.dumps({"status": status_code})


manager = Manager(app)


def init_app(flask_app):
    # Setup the Flask session manager with a random secret key
    flask_app.secret_key = os.urandom(12)

    # Add jinga2 filter
    app.jinja_env.filters["attrFilter"] = attrFilter
    app.jinja_env.filters["yesOrNoFilter"] = yesOrNoFilter
    app.jinja_env.filters["noneFilter"] = noneFilter

    # db.init_app(flask_app)
    # db.app = app

    manager.run()


def yesOrNoFilter(list, field):
    if list == 1:
        return "Yes"
    else:
        return "No"


def noneFilter(list):
    if list is None:
        return ""
    else:
        return list


def attrFilter(list, field):
    if ":" in list:
        d = dict(item.split(":") for item in list.split(","))
        try:
            return d[field]
        except:
            return
    else:
        return list


if __name__ == "__main__":
    init_app(app)
