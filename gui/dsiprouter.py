import os, re, json, subprocess, urllib.parse, glob
from flask import Flask, render_template, request, redirect, abort, flash, session, url_for, send_from_directory, g
from flask_script import Manager, Server
from sqlalchemy import case, func
from importlib import reload
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from shared import getInternalIP, getExternalIP, updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields
from database import loadSession, Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, dSIPFusionPBXDB, \
    dSIPLCR, UAC, GatewayGroups
import settings

# global variables
app = Flask(__name__, static_folder="./static", static_url_path="/static")
db = loadSession()
reload_required = False


# TODO: unit testing per component
# TODO: set up logging / log handlers


def showError(type="", code=500):
    return render_template('error.html', type=type), code


@app.route('/')
def index():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)
        else:
            action = request.args.get('action')
            return render_template('dashboard.html', show_add_onload=action, version=settings.VERSION)

    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')


@app.route('/login', methods=['POST'])
def login():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        if form['password'] == settings.PASSWORD and form['username'] == settings.USERNAME:
            session['logged_in'] = True
            session['username'] = form['username']
        else:
            flash('wrong username or password!')
            return redirect(url_for('index'))
        return index()

    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/logout')
def logout():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        session['logged_in'] = False
        return index()

    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/carriergroups')
@app.route('/carriergroups/<int:gwgroup>')
def displayCarrierGroups(gwgroup=None):
    """
    Display the carrier groups in the view
    :param gwgroup:
    """

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
            # res must be a list()
            if gwgroup is not None and gwgroup != "":
                res = [db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                    GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                    UAC.auth_username, UAC.auth_password, UAC.realm).filter(
                    GatewayGroups.id == gwgroup).first()]
            else:
                res = db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                    GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                    UAC.auth_username, UAC.auth_password, UAC.realm).all()

            return render_template('carriergroups.html', rows=res, API_URL=request.url_root)

        else:
            return index()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/carriergroups', methods=['POST'])
def addUpdateCarrierGroups():
    """
    Add or Update a group of carriers
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwgroup = form['gwgroup']
        name = form['name']
        new_name = form['new_name'] if 'new_name' in form else ''
        authtype = form['authtype'] if 'authtype' in form else ''
        auth_username = form['auth_username'] if 'auth_username' in form else ''
        auth_password = form['auth_password'] if 'auth_password' in form else ''
        auth_domain = form['auth_domain'] if 'auth_domain' in form else settings.DOMAIN
        auth_proxy = "sip:{}@{}:5060".format(auth_username, auth_domain)

        # Adding
        if len(gwgroup) <= 0:
            print(name)

            Gwgroup = GatewayGroups(name)
            db.add(Gwgroup)
            db.commit()
            gwgroup = Gwgroup.id

            if authtype == "userpwd":
                Uacreg = UAC(gwgroup, auth_username, auth_password, auth_domain, auth_proxy,
                             settings.EXTERNAL_IP_ADDR, auth_domain)
            else:
                Uacreg = UAC(gwgroup, local_domain=settings.EXTERNAL_IP_ADDR, flags=UAC.FLAGS.REG_DISABLED.value)

            db.add(Uacreg)

        # Updating
        else:
            # config form
            if len(new_name) <= 0:
                Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                fields = strFieldsToDict(Gwgroup.description)
                fields['name'] = name
                Gwgroup.description = dictToStrFields(fields)

            # auth form
            else:
                if authtype == "userpwd":
                    db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                        {'l_username': auth_username, 'r_username': auth_username, 'auth_username': auth_username,
                         'auth_password': auth_password, 'r_domain': auth_domain, 'realm': auth_domain,
                         'auth_proxy': auth_proxy}, synchronize_session=False)

                else:
                    db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                        {'l_username': '', 'r_username': '', 'auth_username': '', 'auth_password': '', 'r_domain': '',
                         'realm': '', 'auth_proxy': '', 'flags': UAC.FLAGS.REG_DISABLED.value}, synchronize_session=False)

        db.commit()
        reload_required = True
        return displayCarrierGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/carriergroupdelete', methods=['POST'])
def deleteCarrierGroups():
    """
    Delete a group of carriers
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwgroup = form['gwgroup']
        gwlist = form['gwlist'] if 'gwlist' in form else ''

        Addrs = db.query(Address).filter(Address.tag.contains("gwgroup:{}".format(gwgroup)))
        Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup)
        Uac = db.query(UAC).filter(UAC.l_uuid == Gwgroup.first().id)

        # validate this group has gateways assigned to it
        if len(gwlist) > 0:
            GWs = db.query(Gateways).filter(Gateways.gwid.in_(list(map(int, gwlist.split(",")))))
            GWs.delete(synchronize_session=False)

        Addrs.delete(synchronize_session=False)
        Gwgroup.delete(synchronize_session=False)
        Uac.delete(synchronize_session=False)

        db.commit()
        reload_required = True
        return displayCarrierGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/carriers')
@app.route('/carriers/<int:gwid>')
@app.route('/carriers/group/<int:gwgroup>')
def displayCarriers(gwid=None, gwgroup=None, newgwid=None):
    """
    Display the carriers table
    :param gwid:
    :param gwgroup:
    """
    print("new gwid: {}".format(newgwid))
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
            # res must be a list()
            if gwgroup is not None:
                Gatewaygroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                # check if any endpoints in group b4 converting to list(int)
                if Gatewaygroup is not None and Gatewaygroup.gwlist != "":
                    gwlist = list(map(int, filter(None, Gatewaygroup.gwlist.split(","))))
                    res = db.query(Gateways).filter(Gateways.gwid.in_(gwlist)).all()
                else:
                    res = []
            elif gwid is not None:
                res = [db.query(Gateways).filter(Gateways.gwid == gwid).first()]
            else:
                res = db.query(Gateways).filter(Gateways.type == settings.FLT_CARRIER).all()

            return render_template('carriers.html', rows=res, gwgroup=gwgroup, new_gwid=newgwid)

        else:
            return index()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/carriers', methods=['POST'])
def addUpdateCarriers():
    """
    Add or Update a carrier
    """

    global reload_required

    newgwid = None

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if 'gwgroup' in form else ''
        name = form['name']
        ip_addr = form['ip_addr']
        strip = form['strip']
        prefix = form['prefix']

        # Adding
        if len(gwid) <= 0:
            if len(gwgroup) > 0:
                Addr = Address(name, ip_addr, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_CARRIER, gwgroup=gwgroup)

                db.add(Gateway)
                db.commit()

                newgwid = Gateway.gwid
                gwid = str(newgwid)
                Gatewaygroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                gwlist = list(filter(None, Gatewaygroup.gwlist.split(",")))
                gwlist.append(gwid)
                Gatewaygroup.gwlist = ','.join(gwlist)

            else:
                Addr = Address(name, ip_addr, 32, settings.FLT_CARRIER)
                Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_CARRIER)
                db.add(Gateway)

            db.add(Addr)

        # Updating
        else:
            Gateway = db.query(Gateways).filter(Gateways.gwid == gwid).first()
            Gateway.address = ip_addr
            Gateway.strip = strip
            Gateway.pri_prefix = prefix
            fields = strFieldsToDict(Gateway.description)
            fields['name'] = name
            Gateway.description = dictToStrFields(fields)

            # make the extra query to find associated gwgroup if needed
            if len(gwgroup) <= 0:
                Gateway = db.query(Gateways).filter(Gateways.gwid == gwid).first()
                fields = strFieldsToDict(Gateway.description)
                gwgroup = fields['gwgroup']

            Addr = db.query(Address).filter(Address.tag.contains('gwgroup:{}'.format(gwgroup))).first()
            Addr.ip_addr = ip_addr
            fields = strFieldsToDict(Addr.tag)
            fields['name'] = name
            Addr.tag = dictToStrFields(fields)

        db.commit()
        reload_required = True
        return displayCarriers(gwgroup=gwgroup, newgwid=newgwid)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/carrierdelete', methods=['POST'])
def deleteCarriers():
    """
    Delete a carrier
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if 'gwgroup' in form else ''
        name = form['name']

        Gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
        # make the extra query to find associated gwgroup if needed
        if len(gwgroup) <= 0:
            Gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
            fields = strFieldsToDict(Gateway.first().description)
            gwgroup = fields['gwgroup']
        Addr = db.query(Address).filter(Address.tag.contains("gwgroup:{}".format(name)))

        Gateway.delete(synchronize_session=False)
        Addr.delete(synchronize_session=False)
        Gatewaygroups = db.execute('SELECT * FROM dr_gw_lists WHERE FIND_IN_SET({}, dr_gw_lists.gwlist)'.format(gwid))
        for Gatewaygroup in Gatewaygroups:
            gwlist = list(filter(None, Gatewaygroup[1].split(",")))
            gwlist.remove(gwid)
            db.query(GatewayGroups).filter(GatewayGroups.id == str(Gatewaygroup[0])).update(
                {'gwlist': ','.join(gwlist)}, synchronize_session=False)

        db.commit()
        reload_required = True
        return displayCarriers(gwgroup=gwgroup)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/pbx')
def displayPBX():
    """
    Display PBX / Endpoints in the view
    """
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
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
                Subscribers.password, Subscribers.domain).filter(Gateways.type == settings.FLT_PBX).all()
            return render_template('pbxs.html', rows=res, DEFAULT_AUTH_DOMAIN=settings.DOMAIN)

        else:
            return index()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/pbx', methods=['POST'])
def addUpdatePBX():
    """
    Add or Update a PBX / Endpoint
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        name = form['name']
        ip_addr = form.get("ip_addr", "")
        strip = form.get('strip', "0")
        prefix = form['prefix']
        authtype = form['authtype']
        fusionpbx_db_enabled = form.get('fusionpbx_db_enabled', "0")
        fusionpbx_db_server = form['fusionpbx_db_server']
        fusionpbx_db_username = form['fusionpbx_db_username']
        fusionpbx_db_password = form['fusionpbx_db_password']
        auth_username = form['auth_username']
        auth_password = form['auth_password']
        auth_domain = form['auth_domain']
        if auth_domain == None or len(auth_domain) <= 0:
            auth_domain = settings.DOMAIN

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
                Subscriber = Subscribers(auth_username, auth_password, auth_domain, Gateway.gwid)
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
                address = db.query(Address).filter(Address.tag.contains("name:{}".format(name)))
                address.delete(synchronize_session=False)

                # Add the username and password that will be used for authentication
                # Check if the entry in the subscriber table already exists
                exists = db.query(Subscribers).filter(Subscribers.rpid == gwid).scalar()
                if exists:
                    db.query(Subscribers).filter(Subscribers.rpid == gwid).update(
                        {'username': auth_username, 'password': auth_password, 'domain': auth_domain, 'rpid': gwid})
                else:
                    Subscriber = Subscribers(auth_username, auth_password, auth_domain, gwid)
                    db.add(Subscriber)
            # Update the Address table with the new ip address
            else:
                db.query(Address).filter(Address.tag.contains("name:{}".format(name))).update({'ip_addr': ip_addr})
                db.commit()

        reload_required = True
        return displayPBX()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/pbxdelete', methods=['POST'])
def deletePBX():
    """
    Delete a PBX / Endpoint
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        name = form['name']

        gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
        gateway.delete(synchronize_session=False)
        address = db.query(Address).filter(Address.tag.contains("name:{}".format(name)))
        address.delete(synchronize_session=False)
        subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwid)
        subscriber.delete(synchronize_session=False)
        address.delete(synchronize_session=False)
        fusionpbxdb = db.query(dSIPFusionPBXDB).filter(dSIPFusionPBXDB.pbx_id == gwid)
        fusionpbxdb.delete(synchronize_session=False)

        db.commit()
        reload_required = True
        return displayPBX()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/inboundmapping')
def displayInboundMapping():
    """
    Displaying of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # group for inbound routes
    groupid = 9000

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
            res = db.execute(
                'select * from dr_rules r,dr_gateways g where r.gwlist = g.gwid and r.groupid = {}'.format(groupid))
            gateways = db.query(Gateways).filter(Gateways.type == settings.FLT_PBX).all()
            return render_template('inboundmapping.html', rows=res, gwlist=gateways)

        else:
            return index()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/inboundmapping', methods=['POST'])
def addInboundMapping():
    """
    Adding and Updating of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # group for inbound routes
        groupid = 9000

        # id in dr_rules table
        ruleid = None
        if form['ruleid']:
            ruleid = form['ruleid']

        # get form data
        gwid = form['gwid']
        prefix = form['prefix']

        # Adding
        if not ruleid:
            IMap = InboundMapping(groupid, prefix, gwid)
            db.add(IMap)

        # Updating
        else:
            db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).update({'prefix': prefix, 'gwlist': gwid})

        db.commit()
        reload_required = True
        return displayInboundMapping()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/inboundmappingdelete', methods=['POST'])
def deleteInboundMapping():
    """
    Deleting of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']
        d = db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid)
        d.delete(synchronize_session=False)

        reload_required = True
        return displayInboundMapping()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/teleblock')
def displayTeleBlock():
    """
    Display teleblock settings in view
    """

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
            teleblock = {}
            teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
            teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
            teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
            teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
            teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT

            return render_template('teleblock.html', teleblock=teleblock)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/teleblock', methods=['POST'])
def addUpdateTeleBlock():
    """
    Update teleblock config file settings
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        if session.get('logged_in'):
            # Update the teleblock settings
            teleblock = {}
            teleblock['TELEBLOCK_GW_ENABLED'] = form.get('gw_enabled', 0)
            teleblock['TELEBLOCK_GW_IP'] = form['gw_ip']
            teleblock['TELEBLOCK_GW_PORT'] = form['gw_port']
            teleblock['TELEBLOCK_MEDIA_IP'] = form['media_ip']
            teleblock['TELEBLOCK_MEDIA_PORT'] = form['media_port']

            updateConfig(settings, teleblock)
            reload(settings)

            reload_required = True
            return displayTeleBlock()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/outboundroutes')
def displayOutboundRoutes():
    """
    Displaying of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # group for outbound routes
    groupid = 8000

    try:
        if (settings.DEBUG):
            debugEndpoint()

        if session.get('logged_in'):
            rows = db.query(OutboundRoutes).filter(
                (OutboundRoutes.groupid == groupid) | (OutboundRoutes.groupid >= 10000)).outerjoin(dSIPLCR,
                                                                                                   dSIPLCR.dr_groupid == OutboundRoutes.groupid).add_columns(
                dSIPLCR.from_prefix, dSIPLCR.cost, dSIPLCR.dr_groupid, OutboundRoutes.ruleid, OutboundRoutes.prefix,
                OutboundRoutes.routeid, OutboundRoutes.gwlist, OutboundRoutes.timerec, OutboundRoutes.priority,
                OutboundRoutes.description)

            teleblock = {}
            teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
            teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
            teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
            teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
            teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT

            return render_template('outboundroutes.html', rows=rows, teleblock=teleblock, custom_routes='')

        else:
            return index()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@app.route('/outboundroutes', methods=['POST'])
def addUpateOutboundRoutes():
    """
    Adding and Updating dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    # set default values
    # from_prefix = ""
    prefix = ""
    timerec = ""
    priority = 0
    routeid = "1"
    gwlist = ""
    description = ""
    # group for the default outbound routes
    default_gwgroup = 8000
    # id in dr_rules table
    ruleid = None
    from_prefix = None
    pattern = None
    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        if session.get('logged_in') is None:
            return index()

        if form['ruleid']:
            ruleid = form['ruleid']

        groupid = form.get('groupid', default_gwgroup)
        if isinstance(groupid, str):
            if len(groupid) == 0 or (groupid == 'None'):
                groupid = 8000

        # get form data
        if form['from_prefix']:
            from_prefix = form['from_prefix']
        if form['prefix']:
            prefix = form['prefix']
        if form['timerec']:
            timerec = form['timerec']
        if form['priority']:
            priority = int(form['priority'])
        routeid = form.get('routeid', "")
        if form['gwlist']:
            gwlist = form['gwlist']
        if form['name']:
            description = 'name:{}'.format(form['name'])

        # Adding
        if not ruleid:
            # if len(from_prefix) > 0 and len(prefix) == 0 :
            #    return displayOutboundRoutes()
            if from_prefix != None:
                print("from_prefix: {}".format(from_prefix))

                # Grab the lastest groupid and increment
                mlcr = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid >= 10000).order_by(dSIPLCR.dr_groupid.desc()).first()
                db.commit()

                # Start LCR routes with a groupid of 10000
                if mlcr is None:
                    groupid = 10000
                else:
                    groupid = int(mlcr.dr_groupid) + 1

                pattern = from_prefix + "-" + prefix

            OMap = OutboundRoutes(groupid=groupid, prefix=prefix, timerec=timerec, priority=priority,
                                  routeid=routeid, gwlist=gwlist, description=description)
            db.add(OMap)
            db.commit()
            db.flush()

            # Add the lcr map
            if pattern != None:
                OLCRMap = dSIPLCR(pattern, from_prefix, groupid)
                db.add(OLCRMap)
                db.commit()
                db.flush()

        # Updating
        else:  # Handle the simple case of a To prefix being updated
            if (from_prefix is None) and (prefix is not None):
                print(groupid)
                oldgroupid = groupid
                if (groupid is None) or (groupid == "None"):
                    groupid = 8000

                # Convert the dr_rule back to a default carrier rule
                db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                    'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                    'routeid': routeid, 'gwlist': gwlist, 'description': description
                })

                # Delete from LCR table using the old group id
                d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == oldgroupid)
                d1.delete(synchronize_session=False)

                db.commit()

            if from_prefix:

                # Setup pattern
                pattern = from_prefix + "-" + prefix

                # Check if pattern already exists
                exists = db.query(dSIPLCR).filter(dSIPLCR.pattern == pattern).scalar()
                if exists:
                    return displayOutboundRoutes()

                elif (prefix is not None) and (groupid == 8000):  # Adding a From prefix to an existing To
                    # Create a new groupid
                    mlcr = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid >= 10000).order_by(
                        dSIPLCR.dr_groupid.desc()).first()
                    db.commit()

                    # Start LCR routes with a groupid of 10000
                    if mlcr is None:
                        groupid = 10000
                    else:
                        groupid = int(mlcr.dr_groupid) + 1

                    # Setup new pattern
                    pattern = from_prefix + "-" + prefix

                    # Add the lcr map
                    if pattern != None:
                        OLCRMap = dSIPLCR(pattern, from_prefix, groupid)
                        db.add(OLCRMap)
                        db.commit()
                        db.flush()

                    db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                        'groupid': groupid, 'prefix': prefix, 'timerec': timerec, 'priority': priority,
                        'routeid': routeid, 'gwlist': gwlist, 'description': description
                    })
                    db.commit()
                elif (int(groupid) >= 10000):  # Update existing pattern
                    db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == groupid).update({
                        'pattern': pattern, 'from_prefix': from_prefix})

                # Update the dr_rules table
                db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                    'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                    'routeid': routeid, 'gwlist': gwlist, 'description': description
                })
                db.commit()

        reload_required = True
        return displayOutboundRoutes()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/outboundroutesdelete', methods=['POST'])
def deleteOutboundRoute():
    """
    Deleting of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']

        OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
        db.commit()

        d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == OMap.groupid)
        d1.delete(synchronize_session=False)

        d = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid)
        d.delete(synchronize_session=False)

        db.commit()
        db.flush()

        reload_required = True
        return displayOutboundRoutes()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        reload_required = False


@app.route('/reloadkam')
def reloadkam():
    """
    Reload kamailio modules
    """

    global reload_required
    prev_reload_val = reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()

        return_code = subprocess.call(['kamcmd', 'permissions.addressReload'])
        return_code += subprocess.call(['kamcmd', 'drouting.reload'])
        return_code += subprocess.call(['kamcmd', 'htable.reload', 'tofromprefix'])
        return_code += subprocess.call(['kamcmd', 'uac.reg_reload'])
        return_code += subprocess.call(
            ['kamcmd', 'cfg.seti', 'teleblock', 'gw_enabled', str(settings.TELEBLOCK_GW_ENABLED)])

        # Enable/Disable Teleblock
        if settings.TELEBLOCK_GW_ENABLED:
            return_code += subprocess.call(
                ['kamcmd', 'cfg.sets', 'teleblock', 'gw_ip', str(settings.TELEBLOCK_GW_IP)])
            return_code += subprocess.call(
                ['kamcmd', 'cfg.seti', 'teleblock', 'gw_port', str(settings.TELEBLOCK_GW_PORT)])
            return_code += subprocess.call(
                ['kamcmd', 'cfg.sets', 'teleblock', 'media_ip', str(settings.TELEBLOCK_MEDIA_IP)])
            return_code += subprocess.call(
                ['kamcmd', 'cfg.seti', 'teleblock', 'media_port', str(settings.TELEBLOCK_MEDIA_PORT)])

        session['last_page'] = request.headers['Referer']

        if return_code == 0:
            status_code = 1
            reload_required = False
        else:
            status_code = 0
            reload_required = prev_reload_val
        return json.dumps({"status": status_code})

    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


# custom jinja filters
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


def imgFilter(name):
    images_url = urllib.parse.urljoin(app.static_url_path, 'images')
    search_path = os.path.join(app.static_folder, 'images', name)
    filenames = glob.glob(search_path + '.*')
    if len(filenames) > 0:
        return urllib.parse.urljoin(images_url, filenames[0])
    else:
        return ""


# custom jinja context processors
@app.context_processor
def injectReloadRquired():
    return dict(reload_required=reload_required)


class CustomServer(Server):
    """ Customize the Flask server with our settings """

    def __init__(self):
        super().__init__(
            host=settings.DSIP_HOST,
            port=settings.DSIP_PORT
        )

        if settings.DEBUG == True:
            self.use_debugger = True
            self.use_reloader = True
            self.ssl_crt = None
            self.ssl_key = None
        else:
            self.use_debugger = None
            self.use_reloader = None
            self.ssl_crt = None if settings.SSL_CERT == "" else settings.SSL_CERT
            self.ssl_key = None if settings.SSL_KEY == "" else settings.SSL_KEY
            self.threaded = True
            self.processes = 1


def init_app(flask_app):
    # Setup the Flask session manager with a random secret key
    flask_app.secret_key = os.urandom(12)

    # Add jinga2 filter
    flask_app.jinja_env.filters["attrFilter"] = attrFilter
    flask_app.jinja_env.filters["yesOrNoFilter"] = yesOrNoFilter
    flask_app.jinja_env.filters["noneFilter"] = noneFilter
    flask_app.jinja_env.filters["imgFilter"] = imgFilter

    # db.init_app(flask_app)
    # db.app = app

    # Dynamically update settings
    fields = {}
    fields['TELEBLOCK_GW_ENABLED'] = 0
    fields['TELEBLOCK_GW_IP'] = '62.34.24.22'
    fields['INTERNAL_IP_ADDR'] = getInternalIP()
    fields['INTERNAL_IP_NET'] = "{}.*".format(getInternalIP().rsplit(".", 1)[0])
    fields['EXTERNAL_IP_ADDR'] = getExternalIP()
    updateConfig(settings, fields)
    reload(settings)

    # configs depending on updated settings go here
    flask_app.env = "development" if settings.DEBUG else "production"
    flask_app.debug = settings.DEBUG

    # Flask App Manager configs
    manager = Manager(app)
    manager.add_command('runserver', CustomServer())

    # start the server
    manager.run()


if __name__ == "__main__":
    init_app(app)
