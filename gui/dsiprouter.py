#!/usr/bin/env python3

# make sure the generated source files are imported instead of the template ones
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

# all of our standard and project file imports
import os, re, json, subprocess, urllib.parse, glob, datetime, csv, logging, signal, bjoern
from functools import wraps
from copy import copy
from collections import OrderedDict
from importlib import reload
from flask import Flask, render_template, request, redirect, jsonify, flash, session, url_for, send_from_directory, Blueprint
from flask_script import Manager, Server
from flask_wtf.csrf import CSRFProtect
from itsdangerous import URLSafeTimedSerializer
from sqlalchemy import func, exc as sql_exceptions
from sqlalchemy.orm import load_only
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import secure_filename
from werkzeug.middleware.proxy_fix import ProxyFix
from sysloginit import initSyslogLogger
from shared import getInternalIP, getExternalIP, updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields, allowed_file, showError, hostToIP, IO, objToDict, StatusCodes, \
    safeUriToHost, safeFormatSipUri, safeStripPort
from database import db_engine, SessionLoader, DummySession, Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, \
    dSIPLCR, UAC, GatewayGroups, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, dSIPMaintModes, \
    dSIPCallLimits, dSIPHardFwd, dSIPFailFwd
from modules import flowroute
from modules.domain.domain_routes import domains
from modules.api.api_routes import api
from modules.api.mediaserver.routes import mediaserver
from modules.api.carriergroups.routes import carriergroups, addCarrierGroups
from modules.api.kamailio.functions import reloadKamailio
from util.security import Credentials, AES_CTR, urandomChars
from util.ipc import createSettingsManager
from util.parse_json import CreateEncoder
import globals
import settings


# TODO: unit testing per component
# TODO: many of these routes could use some updating...
#       possibly look into this as well when reworking the architecture for API

# module variables
app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.register_blueprint(domains)
app.register_blueprint(api)
app.register_blueprint(mediaserver)
app.register_blueprint(carriergroups)
app.register_blueprint(Blueprint('docs', 'docs', static_url_path='/docs', static_folder=settings.DSIP_DOCS_DIR))
csrf = CSRFProtect(app)
csrf.exempt(api)
csrf.exempt(mediaserver)
csrf.exempt(carriergroups)
numbers_api = flowroute.Numbers()
shared_settings = objToDict(settings)
settings_manager = createSettingsManager(shared_settings)

@app.before_first_request
def before_first_request():
    # replace werkzeug and sqlalchemy loggers
    log_handler = initSyslogLogger()
    replaceAppLoggers(log_handler)

@app.before_request
def before_request():
    # set the session lifetime to gui inactive timeout
    # if we are in debug mode force it to last for entire day
    session.permanent = True
    if settings.DEBUG:
        app.permanent_session_lifetime = datetime.timedelta(days=1)
    else:
        app.permanent_session_lifetime = datetime.timedelta(minutes=settings.GUI_INACTIVE_TIMEOUT)
    session.modified = True

@api.before_request
def api_before_request():
    # for ua to api w/ api token disable csrf
    # we only want csrf checks on service to service requests
    if 'Authorization' not in request.headers:
        csrf.protect()

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
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/error')
def displayError():
    type = request.args.get("type", "")
    code = int(request.args.get("code", StatusCodes.HTTP_INTERNAL_SERVER_ERROR))
    msg = request.args.get("msg", None)
    return showError(type, code, msg)

@app.route('/backupandrestore')
def backupandrestore():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)
        else:
            action = request.args.get('action')
            return render_template('backupandrestore.html', show_add_onload=action, version=settings.VERSION)

    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)

@app.route('/certificates')
def certificates():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)
        else:
            action = request.args.get('action')
            return render_template('certificates.html', show_add_onload=action, version=settings.VERSION)

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

@app.route('/login', methods=['GET', 'POST'])
def login():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        # redirect GET requests to index
        if request.method == 'GET':
            return redirect(url_for('index'))

        form = stripDictVals(request.form.to_dict())
        if 'username' not in form or 'password' not in form:
            raise http_exceptions.BadRequest('Username and Password are required')
        elif not isinstance(form['username'], str) or not isinstance(form['password'], str):
            raise http_exceptions.BadRequest('Username or Password is malformed')

        # Get Environment Variables if in debug mode
        # This is the only case we allow plain text password comparison
        if settings.DEBUG:
            settings.DSIP_USERNAME = os.getenv('DSIP_USERNAME', settings.DSIP_USERNAME)
            settings.DSIP_PASSWORD = os.getenv('DSIP_PASSWORD', settings.DSIP_PASSWORD)

        # if username valid, hash password and compare with stored password
        if form['username'] == settings.DSIP_USERNAME:
            if isinstance(settings.DSIP_PASSWORD, bytes):
                pwcheck = Credentials.hashCreds(form['password'], settings.DSIP_PASSWORD[Credentials.SALT_ENCODED_LEN:])
            else:
                pwcheck = form['password']

            if pwcheck == settings.DSIP_PASSWORD:
                session['logged_in'] = True
                session['username'] = form['username']
                return redirect(url_for('index'))

        # if we got here auth failed
        flash('Wrong Username or Password')
        return redirect(url_for('index'))

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/logout')
def logout():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        session.pop('logged_in', None)
        session.pop('username', None)
        return redirect(url_for('index'))

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/carriergroups')
@app.route('/carriergroups/<int:gwgroup>')
def displayCarrierGroups(gwgroup=None):
    """
    Display the carrier groups in the view
    :param gwgroup:
    """

    # TODO: track related dr_rules and update lists on delete

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        typeFilter = "%type:{}%".format(settings.FLT_CARRIER)

        # res must be a list()
        if gwgroup is not None and gwgroup != "":
            res = [db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                UAC.r_username, UAC.auth_password, UAC.r_domain, UAC.auth_username, UAC.auth_proxy).filter(
                GatewayGroups.id == gwgroup).first()]
        else:
            res = db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                UAC.r_username, UAC.auth_password, UAC.r_domain, UAC.auth_username, UAC.auth_proxy).filter(GatewayGroups.description.like(typeFilter))

        return render_template('carriergroups.html', rows=res)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/carriergroups', methods=['POST'])
def addUpdateCarrierGroups():
    """
    Add or Update a group of carriers
    """
    
    return addCarrierGroups()
    

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        gwgroup = form['gwgroup']
        name = form['name']
        new_name = form['new_name'] if 'new_name' in form else ''
        authtype = form['authtype'] if 'authtype' in form else ''
        r_username = form['r_username'] if 'r_username' in form else ''
        auth_username = form['auth_username'] if 'auth_username' in form else ''
        auth_password = form['auth_password'] if 'auth_password' in form else ''
        auth_domain = form['auth_domain'] if 'auth_domain' in form else settings.DEFAULT_AUTH_DOMAIN
        auth_proxy = form['auth_proxy'] if 'auth_proxy' in form else ''
        plugin_name = form['plugin_name'] if 'plugin_name' in form else ''
        plugin_account_sid = form['plugin_account_sid'] if 'plugin_account_sid' in form else ''
        plugin_account_token = form['plugin_account_token'] if 'plugin_account_token' in form else ''
        
        # format data
        if authtype == "userpwd":
            auth_domain = safeUriToHost(auth_domain)
            if auth_domain is None:
                raise http_exceptions.BadRequest("Auth domain hostname/address is malformed")
            if len(auth_proxy) == 0:
                auth_proxy = auth_domain
            auth_proxy = safeFormatSipUri(auth_proxy, default_user=r_username)
            if auth_proxy is None:
                raise http_exceptions.BadRequest('Auth domain or proxy is malformed')
            if len(auth_username) == 0:
                auth_username = r_username


        # Adding
        if len(gwgroup) <= 0:
            Gwgroup = GatewayGroups(name, type=settings.FLT_CARRIER)
            db.add(Gwgroup)
            db.flush()
            gwgroup = Gwgroup.id

            # Add auth_domain(aka registration server) to the gateway list
            if authtype == "userpwd":
                Uacreg = UAC(gwgroup, r_username, auth_password, realm=auth_domain, auth_username=auth_username, auth_proxy=auth_proxy,
                    local_domain=settings.EXTERNAL_IP_ADDR, remote_domain=auth_domain)
                Addr = Address(name + "-uac", auth_domain, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                db.add(Uacreg)
                db.add(Addr)
        

        # Updating
        else:
            # config form
            if len(new_name) > 0:
                Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                gwgroup_fields = strFieldsToDict(Gwgroup.description)
                old_name = gwgroup_fields['name']
                gwgroup_fields['name'] = new_name
                Gwgroup.description = dictToStrFields(gwgroup_fields)

                Addr = db.query(Address).filter(Address.tag.contains("name:{}-uac".format(old_name))).first()
                if Addr is not None:
                    addr_fields = strFieldsToDict(Addr.tag)
                    addr_fields['name'] = 'name:{}-uac'.format(new_name)
                    Addr.tag = dictToStrFields(addr_fields)

            # auth form
            else:
                if authtype == "userpwd":
                    # update uacreg if exists, otherwise create
                    if not db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                        {'l_username': r_username, 'r_username': r_username, 'auth_username': auth_username,
                         'auth_password': auth_password, 'r_domain': auth_domain, 'realm': auth_domain,
                         'auth_proxy': auth_proxy, 'flags': UAC.FLAGS.REG_ENABLED.value}, synchronize_session=False):
                        Uacreg = UAC(gwgroup, r_username, auth_password, realm=auth_domain, auth_username=auth_username,
                                     auth_proxy=auth_proxy, local_domain=settings.EXTERNAL_IP_ADDR, remote_domain=auth_domain)
                        db.add(Uacreg)

                    # update address if exists, otherwise create
                    if not db.query(Address).filter(Address.tag.contains("name:{}-uac".format(name))).update(
                        {'ip_addr': auth_domain}, synchronize_session=False):
                        Addr = Address(name + "-uac", auth_domain, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                        db.add(Addr)
                else:
                    # delete uacreg and address if they exist
                    db.query(UAC).filter(UAC.l_uuid == gwgroup).delete(synchronize_session=False)
                    db.query(Address).filter(Address.tag.contains("name:{}-uac".format(name))).delete(synchronize_session=False)

        db.commit()
        globals.reload_required = True
        return displayCarrierGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/carriergroupdelete', methods=['POST'])
def deleteCarrierGroups():
    """
    Delete a group of carriers
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        gwgroup = form['gwgroup']
        gwlist = form['gwlist'] if 'gwlist' in form else ''

        Addrs = db.query(Address).filter(Address.tag.contains("gwgroup:{}".format(gwgroup)))
        Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup)
        gwgroup_row = Gwgroup.first()
        if gwgroup_row is not None:
            Uac = db.query(UAC).filter(UAC.l_uuid == gwgroup_row.id)
            Uac.delete(synchronize_session=False)

        # validate this group has gateways assigned to it
        if len(gwlist) > 0:
            GWs = db.query(Gateways).filter(Gateways.gwid.in_(list(map(int, gwlist.split(",")))))
            GWs.delete(synchronize_session=False)

        Addrs.delete(synchronize_session=False)
        Gwgroup.delete(synchronize_session=False)

        db.commit()
        globals.reload_required = True
        return displayCarrierGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/carriers')
@app.route('/carriers/<int:gwid>')
@app.route('/carriers/group/<int:gwgroup>')
def displayCarriers(gwid=None, gwgroup=None, newgwid=None):
    """
    Display the carriers table
    :param gwid:
    :param gwgroup:
    :param newgwid:
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # carriers is a list of carriers matching query
        # carrier_routes is a list of associated rules for each carrier
        carriers = []
        carrier_rules = []

        # get carrier by id
        if gwid is not None:
            carriers = [db.query(Gateways).filter(Gateways.gwid == gwid).first()]
            rules = db.query(OutboundRoutes).filter(OutboundRoutes.groupid == settings.FLT_OUTBOUND).all()
            gateway_rules = {}
            for rule in rules:
                if str(gwid) in filter(None, rule.gwlist.split(',')):
                    gateway_rules[rule.ruleid] = strFieldsToDict(rule.description)['name']
            carrier_rules.append(json.dumps(gateway_rules, separators=(',', ':')))

        # get carriers by carrier group
        elif gwgroup is not None:
            Gatewaygroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
            # check if any endpoints in group b4 converting to list(int)
            if Gatewaygroup is not None and Gatewaygroup.gwlist != "":
                gwlist = [int(gw) for gw in filter(None, Gatewaygroup.gwlist.split(","))]
                carriers = db.query(Gateways).filter(Gateways.gwid.in_(gwlist)).all()
                rules = db.query(OutboundRoutes).filter(OutboundRoutes.groupid == settings.FLT_OUTBOUND).all()
                for gateway_id in filter(None, Gatewaygroup.gwlist.split(",")):
                    gateway_rules = {}
                    for rule in rules:
                        if gateway_id in filter(None, rule.gwlist.split(',')):
                            gateway_rules[rule.ruleid] = strFieldsToDict(rule.description)['name']
                    carrier_rules.append(json.dumps(gateway_rules, separators=(',', ':')))

        # get all carriers
        else:
            carriers = db.query(Gateways).filter(Gateways.type == settings.FLT_CARRIER).all()
            rules = db.query(OutboundRoutes).filter(OutboundRoutes.groupid == settings.FLT_OUTBOUND).all()
            for gateway in carriers:
                gateway_rules = {}
                for rule in rules:
                    if str(gateway.gwid) in filter(None, rule.gwlist.split(',')):
                        gateway_rules[rule.ruleid] = strFieldsToDict(rule.description)['name']
                carrier_rules.append(json.dumps(gateway_rules, separators=(',', ':')))

        return render_template('carriers.html', rows=carriers, routes=carrier_rules, gwgroup=gwgroup, new_gwid=newgwid,
            reload_required=globals.reload_required)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/carriers', methods=['POST'])
def addUpdateCarriers():
    """
    Add or Update a carrier
    """

    #carriergroups.addUpdateCarriers()

    db = DummySession()
    newgwid = None

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if len(form['gwgroup']) > 0 else ''
        name = form['name'] if len(form['name']) > 0 else ''
        hostname = form['ip_addr'] if len(form['ip_addr']) > 0 else ''
        strip = form['strip'] if len(form['strip']) > 0 else '0'
        prefix = form['prefix'] if len(form['prefix']) > 0 else ''

        if len(hostname) == 0:
            raise http_exceptions.BadRequest("Carrier hostname/address is required")

        sip_addr = safeUriToHost(hostname, default_port=5060)
        if sip_addr is None:
            raise http_exceptions.BadRequest("Endpoint hostname/address is malformed")
        host_addr = safeStripPort(sip_addr)

        # Adding
        if len(gwid) <= 0:
            if len(gwgroup) > 0:
                Addr = Address(name, host_addr, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                db.add(Addr)
                db.flush()

                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_CARRIER, gwgroup=gwgroup, addr_id=Addr.id)
                db.add(Gateway)
                db.flush()

                newgwid = Gateway.gwid
                gwid = str(newgwid)
                Gatewaygroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                gwlist = list(filter(None, Gatewaygroup.gwlist.split(",")))
                gwlist.append(gwid)
                Gatewaygroup.gwlist = ','.join(gwlist)

            else:
                Addr = Address(name, host_addr, 32, settings.FLT_CARRIER)
                db.add(Addr)
                db.flush()

                Gateway = Gateways(name, sip_addr, strip, prefix, settings.FLT_CARRIER, addr_id=Addr.id)
                db.add(Gateway)

        # Updating
        else:
            Gateway = db.query(Gateways).filter(Gateways.gwid == gwid).first()
            Gateway.address = sip_addr
            Gateway.strip = strip
            Gateway.pri_prefix = prefix

            gw_fields = strFieldsToDict(Gateway.description)
            gw_fields['name'] = name
            if len(gwgroup) <= 0:
                gw_fields['gwgroup'] = gwgroup

            # if address exists update
            address_exists = False
            if 'addr_id' in gw_fields and len(gw_fields['addr_id']) > 0:
                Addr = db.query(Address).filter(Address.id == gw_fields['addr_id']).first()

                # if entry is non existent handle in next block
                if Addr is not None:
                    address_exists = True

                    Addr.ip_addr = host_addr
                    addr_fields = strFieldsToDict(Addr.tag)
                    addr_fields['name'] = name

                    if len(gwgroup) > 0:
                        addr_fields['gwgroup'] = gwgroup
                    Addr.tag = dictToStrFields(addr_fields)

            # otherwise create the address
            if not address_exists:
                if len(gwgroup) > 0:
                    Addr = Address(name, host_addr, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                else:
                    Addr = Address(name, host_addr, 32, settings.FLT_CARRIER)

                db.add(Addr)
                db.flush()
                gw_fields['addr_id'] = str(Addr.id)

            # gw_fields may be updated above so set after
            Gateway.description = dictToStrFields(gw_fields)

        db.commit()
        globals.reload_required = True
        return displayCarriers(gwgroup=gwgroup, newgwid=newgwid)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/carrierdelete', methods=['POST'])
def deleteCarriers():
    """
    Delete a carrier
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if 'gwgroup' in form else ''
        related_rules = json.loads(form['related_rules']) if 'related_rules' in form else ''

        Gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
        Gateway_Row = Gateway.first()
        gw_fields = strFieldsToDict(Gateway_Row.description)

        # find associated gwgroup if not provided
        if len(gwgroup) <= 0:
            gwgroup = gw_fields['gwgroup'] if 'gwgroup' in gw_fields else ''

        # remove associated address if exists
        if 'addr_id' in gw_fields:
            Addr = db.query(Address).filter(Address.id == gw_fields['addr_id'])
            Addr.delete(synchronize_session=False)

        # grab any related carrier groups
        Gatewaygroups = db.execute('SELECT * FROM dr_gw_lists WHERE FIND_IN_SET({}, dr_gw_lists.gwlist)'.format(gwid))

        # remove gateway
        Gateway.delete(synchronize_session=False)

        # remove carrier from gwlist in carrier group
        for Gatewaygroup in Gatewaygroups:
            gwlist = list(filter(None, Gatewaygroup[1].split(",")))
            gwlist.remove(gwid)
            db.query(GatewayGroups).filter(GatewayGroups.id == str(Gatewaygroup[0])).update(
                {'gwlist': ','.join(gwlist)}, synchronize_session=False)

        # remove carrier from gwlist in carrier rules
        if len(related_rules) > 0:
            rule_ids = related_rules.keys()
            rules = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid.in_(rule_ids)).all()
            for rule in rules:
                gwlist = list(filter(None, rule.gwlist.split(",")))
                gwlist.remove(gwid)
                rule.gwlist = ','.join(gwlist)

        db.commit()
        globals.reload_required = True
        return displayCarriers(gwgroup=gwgroup)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/endpointgroups')
def displayEndpointGroups():
    """
    Display Endpoint Groups / Endpoints in the view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        return render_template('endpointgroups.html', dsiprouter_ip=settings.EXTERNAL_IP_ADDR,
                               DEFAULT_auth_domain=settings.DEFAULT_AUTH_DOMAIN)

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/numberenrichment')
def displayNumberEnrichment():
    """
    Display Endpoint Groups / Endpoints in the view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        return render_template('dnid_enrichment.html')

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/cdrs')
def displayCDRS():
    """
    Display Endpoint Groups / Endpoints in the view
    """
    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        return render_template('cdrs.html')

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

# TODO: why are we doing this weird api workaround, instead of making the gui and api separate??
@app.route('/endpointgroups', methods=['POST'])
def addUpdateEndpointGroups():
    """
    Add or Update a PBX / Endpoint
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        # form = stripDictVals(request.form.to_dict())
        #
        # TODO: change ip_addr field to hostname or domainname, we already support this
        # gwid = form['gwid']
        # gwgroupid = request.form.get("gwgroup", None)
        name = request.form.get("name", None)
        # ip_addr = request.form.get("ip_addr", None)
        # strip = form['strip'] if len(form['strip']) > 0 else "0"
        # prefix = form['prefix'] if len(form['prefix']) > 0 else ""
        # authtype = form['authtype']
        # fusionpbx_db_server = form['fusionpbx_db_server']
        # fusionpbx_db_username = form['fusionpbx_db_username']
        # fusionpbx_db_password = form['fusionpbx_db_password']
        # auth_username = form['auth_username']
        # auth_password = form['auth_password']
        # auth_domain = form['auth_domain'] if len(form['auth_domain']) > 0 else settings.DEFAULT_AUTH_DOMAIN
        # calllimit = form['calllimit'] if len(form['calllimit']) > 0 else ""
        #
        # multi_tenant_domain_enabled = False
        # multi_tenant_domain_type = dSIPMultiDomainMapping.FLAGS.TYPE_UNKNOWN.value
        # single_tenant_domain_enabled = False
        # single_tenant_domain_type = dSIPDomainMapping.FLAGS.TYPE_UNKNOWN.value

        if name is not None:
            Gwgroup = GatewayGroups(name, type=settings.FLT_PBX)
            db.add(Gwgroup)
            db.commit()

        globals.reload_required = True
        return displayEndpointGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

# TODO: is this route still in use?
@app.route('/pbxdelete', methods=['POST'])
def deletePBX():
    """
    Delete a PBX / Endpoint
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

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

        domainmultimapping = db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwid)
        res = domainmultimapping.options(load_only("domain_list", "attr_list")).first()
        if res is not None:
            # make sure mapping has domains
            if len(res.domain_list) > 0:
                domains = list(map(int, filter(None, res.domain_list.split(","))))
                domain = db.query(Domain).filter(Domain.id.in_(domains))
                domain.delete(synchronize_session=False)
            # make sure mapping has attributes
            if len(res.attr_list) > 0:
                attrs = list(map(int, filter(None, res.attr_list.split(","))))
                domainattrs = db.query(DomainAttrs).filter(DomainAttrs.id.in_(attrs))
                domainattrs.delete(synchronize_session=False)

            # delete the entry in the multi domain mapping table
            domainmultimapping.delete(synchronize_session=False)

        db.commit()
        globals.reload_required = True
        return displayEndpointGroups()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/inboundmapping')
def displayInboundMapping():
    """
    Displaying of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        endpoint_filter = "%type:{}%".format(settings.FLT_PBX)
        carrier_filter = "%type:{}%".format(settings.FLT_CARRIER)

        res = db.execute("""select * from (
    select r.ruleid, r.groupid, r.prefix, r.gwlist, r.description as rule_description, g.id as gwgroupid, g.description as gwgroup_description from dr_rules as r left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '') where r.groupid = {flt_inbound}
) as t1 left join (
    select hf.dr_ruleid as hf_ruleid, hf.dr_groupid as hf_groupid, hf.did as hf_fwddid, g.id as hf_gwgroupid from dsip_hardfwd as hf left join dr_rules as r on hf.dr_groupid = r.groupid left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '') where hf.dr_groupid <> {flt_outbound}
    union all
    select hf.dr_ruleid as hf_ruleid, hf.dr_groupid as hf_groupid, hf.did as hf_fwddid, NULL as hf_gwgroupid from dsip_hardfwd as hf left join dr_rules as r on hf.dr_ruleid = r.ruleid where hf.dr_groupid = {flt_outbound}
) as t2 on t1.ruleid = t2.hf_ruleid left join (
    select ff.dr_ruleid as ff_ruleid, ff.dr_groupid as ff_groupid, ff.did as ff_fwddid, g.id as ff_gwgroupid from dsip_failfwd as ff left join dr_rules as r on ff.dr_groupid = r.groupid left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '') where ff.dr_groupid <> {flt_outbound}
    union all
    select ff.dr_ruleid as ff_ruleid, ff.dr_groupid as ff_groupid, ff.did as ff_fwddid, NULL as ff_gwgroupid from dsip_failfwd as ff left join dr_rules as r on ff.dr_ruleid = r.ruleid where ff.dr_groupid = {flt_outbound}
) as t3 on t1.ruleid = t3.ff_ruleid""".format(flt_inbound=settings.FLT_INBOUND, flt_outbound=settings.FLT_OUTBOUND))

        epgroups = db.query(GatewayGroups).filter(GatewayGroups.description.like(endpoint_filter)).all()
        gwgroups = db.query(GatewayGroups).filter(
            (GatewayGroups.description.like(endpoint_filter)) | (GatewayGroups.description.like(carrier_filter))).all()

        # sort endpoint groups by name
        epgroups.sort(key=lambda x: strFieldsToDict(x.description)['name'].lower())
        # sort gateway groups by type then by name
        gwgroups.sort(key=lambda x: (strFieldsToDict(x.description)['type'], strFieldsToDict(x.description)['name'].lower()))

        dids = []
        if len(settings.FLOWROUTE_ACCESS_KEY) > 0 and len(settings.FLOWROUTE_SECRET_KEY) > 0:
            try:
                dids = numbers_api.getNumbers()
            except http_exceptions.HTTPException as ex:
                debugException(ex)
                return showError(type="http", code=ex.status_code, msg="Flowroute Credentials Not Valid")

        return render_template('inboundmapping.html', rows=res, gwgroups=gwgroups, epgroups=epgroups, imported_dids=dids)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/inboundmapping', methods=['POST'])
def addUpdateInboundMapping():
    """
    Adding and Updating of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        # get form data
        ruleid = form['ruleid'] if 'ruleid' in form else None
        gwgroupid = form['gwgroupid'] if 'gwgroupid' in form and form['gwgroupid'] != "0" else ''
        prefix = form['prefix'] if 'prefix' in form else ''
        description = 'name:{}'.format(form['rulename']) if 'rulename' in form else ''
        hardfwd_enabled = int(form['hardfwd_enabled'])
        hf_gwgroupid = form['hf_gwgroupid'] if 'hf_gwgroupid' in form and form['hf_gwgroupid'] != "0" else ''
        hf_groupid = form['hf_groupid'] if 'hf_groupid' in form else ''
        hf_fwddid = form['hf_fwddid'] if 'hf_fwddid' in form else ''
        failfwd_enabled = int(form['failfwd_enabled'])
        ff_gwgroupid = form['ff_gwgroupid'] if 'ff_gwgroupid' in form and form['ff_gwgroupid'] != "0" else ''
        ff_groupid = form['ff_groupid'] if 'ff_groupid' in form else ''
        ff_fwddid = form['ff_fwddid'] if 'ff_fwddid' in form else ''

        # we only support a single gwgroup at this time
        gwlist = '#{}'.format(gwgroupid) if len(gwgroupid) > 0 else ''
        fwdgroupid = None

        # TODO: seperate redundant code into functions
        # TODO  need to add support for updating and deleting a LB Rule

        # Adding
        if not ruleid:
            inserts = []

            # don't allow duplicate entries
            if db.query(InboundMapping).filter(InboundMapping.prefix == prefix).filter(InboundMapping.groupid == settings.FLT_INBOUND).scalar():
                raise http_exceptions.BadRequest("Duplicate DID's are not allowed")

            if "lb_" in gwgroupid:
                x = gwgroupid.split("_");
                gwgroupid = x[1]
                dispatcher_id = x[2].zfill(4)

                # Create a gateway

                Gateway = Gateways("drouting_to_dispatcher", "localhost",0, dispatcher_id, settings.FLT_PBX, gwgroup=gwgroupid)

                db.add(Gateway)
                db.flush()

                Addr = Address("myself", settings.INTERNAL_IP_ADDR, 32,1, gwgroup=gwgroupid)
                db.add(Addr)
                db.flush()

                # Define an Inbound Mapping that maps to the newly created gateway
                gwlist = Gateway.gwid
                IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
                db.add(IMap)
                db.flush()

                db.commit()
                return displayInboundMapping()

            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
            inserts.append(IMap)

            # find last rule in dr_rules
            ruleid = int(db.execute(
                """SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='{}' AND TABLE_NAME='dr_rules'""".format(
                    settings.KAM_DB_NAME)).first()[0])

            if hardfwd_enabled:
                # when gwgroup is set we need to create a dr_rule that maps to the gwlist of that gwgroup
                if len(hf_gwgroupid) > 0:
                    gwlist = '#{}'.format(hf_gwgroupid)

                    # find last forwarding rule
                    lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                        InboundMapping.groupid.desc()).first()

                    # Start forwarding routes with a groupid set in settings (default is 20000)
                    if lastfwd is None:
                        fwdgroupid = settings.FLT_FWD_MIN
                    else:
                        fwdgroupid = int(lastfwd.groupid) + 1

                    hfwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid))
                    inserts.append(hfwd)
                # if no gwgroup selected we dont need dr_rules we set dr_groupid to FLT_OUTBOUND and we create hardfwd/failfwd rules
                else:
                    fwdgroupid = settings.FLT_OUTBOUND

                hfwd_htable = dSIPHardFwd(ruleid, hf_fwddid, fwdgroupid)
                inserts.append(hfwd_htable)

            if failfwd_enabled:
                # when gwgroup is set we need to create a dr_rule that maps to the gwlist of that gwgroup
                if len(ff_gwgroupid) > 0:
                    gwlist = '#{}'.format(ff_gwgroupid)

                    # skip lookup if we just found the groupid
                    if fwdgroupid is not None:
                        fwdgroupid += 1
                    else:
                        # find last forwarding rule
                        lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                            InboundMapping.groupid.desc()).first()

                        # Start forwarding routes with a groupid set in settings (default is 20000)
                        if lastfwd is None:
                            fwdgroupid = settings.FLT_FWD_MIN
                        else:
                            fwdgroupid = int(lastfwd.groupid) + 1

                    ffwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid))
                    inserts.append(ffwd)
                # if no gwgroup selected we dont need dr_rules we set dr_groupid to FLT_OUTBOUND and we create hardfwd/failfwd rules
                else:
                    fwdgroupid = settings.FLT_OUTBOUND

                ffwd_htable = dSIPFailFwd(ruleid, ff_fwddid, fwdgroupid)
                inserts.append(ffwd_htable)

            db.add_all(inserts)

        # Updating
        else:
            inserts = []

            if "lb_" in gwgroupid:
                x = gwgroupid.split("_");
                gwgroupid = x[1]
                dispatcher_id = x[2].zfill(4)

                # Create a gateway
                Gateway = db.query(Gateways).filter(Gateways.description.like(gwgroupid) & Gateways.description.like("lb:{}".format(dispatcher_id))).first()
                if Gateway:
                    fields = strFieldsToDict(Gateway.description)
                    fields['lb'] = dispatcher_id
                    fields['gwgroup'] = gwgroupid
                    Gateway.update({'prefix':dispatcher_id,'description': dictToStrFields(fields)})
                else:

                    Gateway = Gateways("drouting_to_dispatcher", "localhost",0, dispatcher_id, settings.FLT_PBX, gwgroup=gwgroupid)

                    db.add(Gateway)

                db.flush()

                Addr = db.query(Address).filter(Address.ip_addr == settings.INTERNAL_IP_ADDR).first()
                if Addr is None:
                    Addr = Address("myself", settings.INTERNAL_IP_ADDR, 32, 1, gwgroup=gwgroupid)
                    db.add(Addr)
                    db.flush()

                # Assign Gateway id to the gateway list
                gwlist = Gateway.gwid

            db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).update(
                {'prefix': prefix, 'gwlist': gwlist, 'description': description}, synchronize_session=False)

            hardfwd_exists = True if db.query(dSIPHardFwd).filter(dSIPHardFwd.dr_ruleid == ruleid).scalar() else False
            db.flush()

            if hardfwd_enabled:

                # create fwd htable if it does not exist
                if not hardfwd_exists:
                    # only create rule if gwgroup has been selected
                    if len(hf_gwgroupid) > 0:
                        gwlist = '#{}'.format(hf_gwgroupid)

                        # find last forwarding rule
                        lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                            InboundMapping.groupid.desc()).first()

                        # Start forwarding routes with a groupid set in settings (default is 20000)
                        if lastfwd is None:
                            fwdgroupid = settings.FLT_FWD_MIN
                        else:
                            fwdgroupid = int(lastfwd.groupid) + 1

                        hfwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid))
                        inserts.append(hfwd)
                    # if no gwgroup selected we dont need dr_rules we set dr_groupid to FLT_OUTBOUND and we create htable
                    else:
                        fwdgroupid = settings.FLT_OUTBOUND

                    hfwd_htable = dSIPHardFwd(ruleid, hf_fwddid, fwdgroupid)
                    inserts.append(hfwd_htable)

                # update existing fwd htable
                else:
                    # intially set fwdgroupid to update (if we create new rule it will change)
                    fwdgroupid = int(hf_groupid) if len(hf_gwgroupid) > 0 else settings.FLT_OUTBOUND

                    # only update rule if one exists, which we know only happens if groupid != FLT_OUTBOUND
                    if hf_groupid != str(settings.FLT_OUTBOUND):
                        # if gwgroup is selected we update the rule, if not selected we delete the rule
                        if len(hf_gwgroupid) > 0:
                            gwlist = '#{}'.format(hf_gwgroupid)
                            db.query(InboundMapping).filter(InboundMapping.groupid == hf_groupid).update(
                                {'prefix': '', 'gwlist': gwlist, 'description': 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid)},
                                synchronize_session=False)
                        else:
                            hf_rule = db.query(InboundMapping).filter(
                                ((InboundMapping.groupid == hf_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                                ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
                            if hf_rule.scalar():
                                hf_rule.delete(synchronize_session=False)
                    else:
                        # if gwgroup is selected we create the rule
                        if len(hf_gwgroupid) > 0:
                            gwlist = '#{}'.format(hf_gwgroupid)

                            # find last forwarding rule
                            lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                                InboundMapping.groupid.desc()).first()

                            # Start forwarding routes with a groupid set in settings (default is 20000)
                            if lastfwd is None:
                                fwdgroupid = settings.FLT_FWD_MIN
                            else:
                                fwdgroupid = int(lastfwd.groupid) + 1

                            hfwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid))
                            inserts.append(hfwd)

                    db.query(dSIPHardFwd).filter(dSIPHardFwd.dr_ruleid == ruleid).update(
                        {'did': hf_fwddid, 'dr_groupid': fwdgroupid}, synchronize_session=False)

            else:
                # delete existing fwd htable and possibly fwd rule
                if hardfwd_exists:
                    hf_rule = db.query(InboundMapping).filter(
                        ((InboundMapping.groupid == hf_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                        ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
                    if hf_rule.scalar():
                        hf_rule.delete(synchronize_session=False)
                    hf_htable = db.query(dSIPHardFwd).filter(dSIPHardFwd.dr_ruleid == ruleid)
                    hf_htable.delete(synchronize_session=False)

            failfwd_exists = True if db.query(dSIPFailFwd).filter(dSIPFailFwd.dr_ruleid == ruleid).scalar() else False
            db.flush()

            if failfwd_enabled:

                # create fwd htable if it does not exist
                if not failfwd_exists:
                    # only create rule if gwgroup has been selected
                    if len(ff_gwgroupid) > 0:
                        gwlist = '#{}'.format(ff_gwgroupid)

                        # find last forwarding rule
                        lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                            InboundMapping.groupid.desc()).first()

                        # Start forwarding routes with a groupid set in settings (default is 20000)
                        if lastfwd is None:
                            fwdgroupid = settings.FLT_FWD_MIN
                        else:
                            fwdgroupid = int(lastfwd.groupid) + 1

                        ffwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid))
                        inserts.append(ffwd)
                    # if no gwgroup selected we dont need dr_rules we set dr_groupid to FLT_OUTBOUND and we create htable
                    else:
                        fwdgroupid = settings.FLT_OUTBOUND

                    ffwd_htable = dSIPFailFwd(ruleid, ff_fwddid, fwdgroupid)
                    inserts.append(ffwd_htable)

                # update existing fwd htable
                else:
                    # intially set fwdgroupid to update (if we create new rule it will change)
                    fwdgroupid = int(ff_groupid) if len(ff_gwgroupid) > 0 else settings.FLT_OUTBOUND

                    # only update rule if one exists, which we know only happens if groupid != FLT_OUTBOUND
                    if ff_groupid != str(settings.FLT_OUTBOUND):
                        # if gwgroup is selected we update the rule, if not selected we delete the rule
                        if len(ff_gwgroupid) > 0:
                            gwlist = '#{}'.format(ff_gwgroupid)
                            db.query(InboundMapping).filter(InboundMapping.groupid == ff_groupid).update(
                                {'prefix': '', 'gwlist': gwlist, 'description': 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid)},
                                synchronize_session=False)
                        else:
                            ff_rule = db.query(InboundMapping).filter(
                                ((InboundMapping.groupid == ff_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                                ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
                            if ff_rule.scalar():
                                ff_rule.delete(synchronize_session=False)
                    else:
                        # if gwgroup is selected we create the rule
                        if len(ff_gwgroupid) > 0:
                            gwlist = '#{}'.format(ff_gwgroupid)

                            # find last forwarding rule
                            lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(
                                InboundMapping.groupid.desc()).first()

                            # Start forwarding routes with a groupid set in settings (default is 20000)
                            if lastfwd is None:
                                fwdgroupid = settings.FLT_FWD_MIN
                            else:
                                fwdgroupid = int(lastfwd.groupid) + 1

                            ffwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid))
                            inserts.append(ffwd)

                    db.query(dSIPFailFwd).filter(dSIPFailFwd.dr_ruleid == ruleid).update(
                        {'did': ff_fwddid, 'dr_groupid': fwdgroupid}, synchronize_session=False)

            else:
                # delete existing fwd htable and possibly fwd rule
                if failfwd_exists:
                    ff_rule = db.query(InboundMapping).filter(
                        ((InboundMapping.groupid == ff_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                        ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
                    if ff_rule.scalar():
                        ff_rule.delete(synchronize_session=False)
                    ff_htable = db.query(dSIPFailFwd).filter(dSIPFailFwd.dr_ruleid == ruleid)
                    ff_htable.delete(synchronize_session=False)

            if len(inserts) > 0:
                db.add_all(inserts)

        db.commit()
        globals.reload_required = True
        return displayInboundMapping()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/inboundmappingdelete', methods=['POST'])
def deleteInboundMapping():
    """
    Deleting of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']
        hf_ruleid = form['hf_ruleid']
        hf_groupid = form['hf_groupid']
        ff_ruleid = form['ff_ruleid']
        ff_groupid = form['ff_groupid']

        im_rule = db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).first()
        # Delete the gateway if it's being used for Load Balancing
        if '#' not in im_rule.gwlist:
            dispatcher_gateway = db.query(Gateways).filter(Gateways.gwid == im_rule.gwlist)
            dispatcher_gateway.delete(synchronize_session=False)
        # Delete the rule now
        db.delete(im_rule)

        if len(hf_ruleid) > 0:
            # no dr_rules created for fwding without a gwgroup selected
            hf_rule = db.query(InboundMapping).filter(
                ((InboundMapping.groupid == hf_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
            if hf_rule.scalar():
                hf_rule.delete(synchronize_session=False)
            hf_htable = db.query(dSIPHardFwd).filter(dSIPHardFwd.dr_ruleid == ruleid)
            hf_htable.delete(synchronize_session=False)

        if len(ff_ruleid) > 0:
            # no dr_rules created for fwding without a gwgroup selected
            ff_rule = db.query(InboundMapping).filter(
                ((InboundMapping.groupid == ff_groupid) & (InboundMapping.groupid != settings.FLT_OUTBOUND)) |
                ((InboundMapping.ruleid == ruleid) & (InboundMapping.groupid == settings.FLT_OUTBOUND)))
            if ff_rule.scalar():
                ff_rule.delete(synchronize_session=False)
            ff_htable = db.query(dSIPFailFwd).filter(dSIPFailFwd.dr_ruleid == ruleid)
            ff_htable.delete(synchronize_session=False)

        db.commit()

        globals.reload_required = True
        return displayInboundMapping()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

def processInboundMappingImport(filename, override_gwgroupid, name, db):
    try:
        # Adding
        f = open(os.path.join(settings.UPLOAD_FOLDER, filename))
        csv_f = csv.reader(f)

        for row in csv_f:
            # skip header if present
            if row[0].startswith("#"):
                continue

            prefix = row[0]
            if len(row) > 0:
                if override_gwgroupid is not None:
                    gwgroupid = override_gwgroupid
                else:
                    gwgroupid = '#{}'.format(row[1]) if '#' not in row[1] else row[1]
            if len(row) > 1:
                description = 'name:{}'.format(row[2])
            else:
                description = 'name:{}'.format(name)

            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwgroupid, description)
            db.add(IMap)

        db.commit()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)

@app.route('/inboundmappingimport', methods=['POST'])
def importInboundMapping():
    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        # get form data
        gwgroupid = form['gwgroupid'] if 'gwgroupid' in form else None

        if 'file' not in request.files:
            flash('No file part')
            return redirect(url_for('displayInboundMapping'))
        file = request.files['file']
        # if user does not select file, browser also
        # submit a empty part without filename
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)
        if file and allowed_file(file.filename, ALLOWED_EXTENSIONS=set(['csv'])):
            filename = secure_filename(file.filename)
            file.save(os.path.join(settings.UPLOAD_FOLDER, filename))
            processInboundMappingImport(filename, gwgroupid, None, db)
            flash('X number of file were imported')
            globals.reload_required = True
            return redirect(url_for('displayInboundMapping', filename=filename))

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/teleblock')
def displayTeleBlock():
    """
    Display teleblock settings in view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        teleblock = {}
        teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
        teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
        teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
        teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
        teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT

        return render_template('teleblock.html', teleblock=teleblock)

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/teleblock', methods=['POST'])
def addUpdateTeleBlock():
    """
    Update teleblock config file settings
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # Update the teleblock settings
        teleblock = {}
        teleblock['TELEBLOCK_GW_ENABLED'] = form.get('gw_enabled', 0)
        teleblock['TELEBLOCK_GW_IP'] = form['gw_ip']
        teleblock['TELEBLOCK_GW_PORT'] = form['gw_port']
        teleblock['TELEBLOCK_MEDIA_IP'] = form['media_ip']
        teleblock['TELEBLOCK_MEDIA_PORT'] = form['media_port']

        updateConfig(settings, teleblock, hot_reload=True)

        globals.reload_required = True
        return displayTeleBlock()

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/transnexus')
def displayTransNexus():
    """
    Display TransNexus settings in view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        transnexus = {}
        transnexus["authservice_enabled"] = settings.TRANSNEXUS_AUTHSERVICE_ENABLED
        transnexus["authservice_host"] = settings.TRANSNEXUS_AUTHSERVICE_HOST

        return render_template('transnexus.html', transnexus=transnexus)

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/transnexus', methods=['POST'])
def addUpdateTransNexus():
    """
    Update TransNexus config file settings
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # Update the TransNexus settings
        transnexus = {}
        transnexus["TRANSNEXUS_AUTHSERVICE_ENABLED"] = form.get('authservice_enabled',0)
        transnexus["TRANSNEXUS_AUTHSERVICE_HOST"] = form.get('authservice_host', '')
       
        updateConfig(settings, transnexus, hot_reload=True)

        globals.reload_required = True
        return displayTransNexus()

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)

@app.route('/outboundroutes')
def displayOutboundRoutes():
    """
    Displaying of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        carrier_filter = "%type:{}%".format(settings.FLT_CARRIER)

        rows = db.query(OutboundRoutes).filter(
            (OutboundRoutes.groupid == settings.FLT_OUTBOUND) |
            ((OutboundRoutes.groupid >= settings.FLT_LCR_MIN) &
             (OutboundRoutes.groupid < settings.FLT_FWD_MIN))).outerjoin(
            dSIPLCR, dSIPLCR.dr_groupid == OutboundRoutes.groupid).outerjoin(
            GatewayGroups, func.REPLACE(OutboundRoutes.gwlist, '#', '') == GatewayGroups.id).add_columns(
            dSIPLCR.from_prefix, dSIPLCR.cost, dSIPLCR.dr_groupid, OutboundRoutes.ruleid,
            OutboundRoutes.prefix, OutboundRoutes.routeid, func.REPLACE(OutboundRoutes.gwlist, '#', '').label('gwgroupid'),
            OutboundRoutes.timerec, OutboundRoutes.priority, OutboundRoutes.description,
            GatewayGroups.description.label('gwgroup_description'), GatewayGroups.gwlist)

        cgroups = db.query(GatewayGroups).filter(GatewayGroups.description.like(carrier_filter)).all()

        # sort carrier groups by name
        cgroups.sort(key=lambda x: strFieldsToDict(x.description)['name'].lower())

        teleblock = {}
        teleblock["gw_enabled"] = settings.TELEBLOCK_GW_ENABLED
        teleblock["gw_ip"] = settings.TELEBLOCK_GW_IP
        teleblock["gw_port"] = settings.TELEBLOCK_GW_PORT
        teleblock["media_ip"] = settings.TELEBLOCK_MEDIA_IP
        teleblock["media_port"] = settings.TELEBLOCK_MEDIA_PORT

        return render_template('outboundroutes.html', rows=rows, cgroups=cgroups, teleblock=teleblock,
                               custom_routes=getCustomRoutes())

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/outboundroutes', methods=['POST'])
def addUpateOutboundRoutes():
    """
    Adding and Updating dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        # get form data
        ruleid = form['ruleid'] if 'ruleid' in form and len(form['ruleid']) > 0 else None
        groupid = form['groupid'] if 'groupid' in form and len(form['groupid']) > 0 \
                                     and form['groupid'] != "None" else settings.FLT_OUTBOUND
        from_prefix = form['from_prefix'] if 'from_prefix' in form and len(form['from_prefix']) > 0 else None
        prefix = form['prefix'] if 'prefix' in form else ''
        timerec = form['timerec'] if 'timerec' in form else ''
        priority = int(form['priority']) if 'priority' in form and len(form['priority']) > 0 else 0
        routeid = form['routeid'] if 'routeid' in form else ''
        gwgroupid = form['gwgroupid'] if 'gwgroupid' in form and form['gwgroupid'] != "0" else ''
        description = 'name:{}'.format(form['name']) if 'name' in form else ''

        pattern = None
        gwlist = '#{}'.format(gwgroupid) if len(gwgroupid) > 0 else ''

        # Adding
        if not ruleid:
            # if len(from_prefix) > 0 and len(prefix) == 0 :
            #    return displayOutboundRoutes()
            if from_prefix is not None:
                print("from_prefix: {}".format(from_prefix))

                # Grab the lastest groupid and increment
                mlcr = db.query(dSIPLCR).filter((dSIPLCR.dr_groupid >= settings.FLT_LCR_MIN) &
                                                (dSIPLCR.dr_groupid < settings.FLT_FWD_MIN)).order_by(dSIPLCR.dr_groupid.desc()).first()
                db.commit()

                # Start LCR routes with a groupid in settings (default is 10000)
                if mlcr is None:
                    groupid = settings.FLT_LCR_MIN
                else:
                    groupid = int(mlcr.dr_groupid) + 1

                pattern = from_prefix + "-" + prefix

            OMap = OutboundRoutes(groupid=groupid, prefix=prefix, timerec=timerec, priority=priority,
                routeid=routeid, gwlist=gwlist, description=description)
            db.add(OMap)

            # Add the lcr map
            if pattern != None:
                OLCRMap = dSIPLCR(pattern, from_prefix, groupid)
                db.add(OLCRMap)

        # Updating
        else:
            # no from_prefix we can update outbound route and remove any LCR entries
            if from_prefix is None and prefix is not None:
                oldgroupid = groupid
                if (groupid is None) or (groupid == "None"):
                    groupid = settings.FLT_OUTBOUND

                # Convert the dr_rule back to a default carrier rule
                db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                    'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                    'routeid': routeid, 'gwlist': gwlist, 'description': description
                }, synchronize_session=False)

                # Delete from LCR table using the old group id
                d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == oldgroupid)
                d1.delete(synchronize_session=False)

            # from_prefix given, we update outbound route and create/update LCR entry
            elif from_prefix is not None:

                # Setup pattern
                pattern = from_prefix + "-" + prefix

                # Check if pattern already exists
                exists = db.query(dSIPLCR).filter(dSIPLCR.pattern == pattern).scalar()
                if exists:
                    db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                        'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                        'routeid': routeid, 'gwlist': gwlist, 'description': description
                    }, synchronize_session=False)

                # Adding a From prefix to an existing To
                elif prefix is not None and groupid == settings.FLT_OUTBOUND:
                    # Create a new groupid
                    mlcr = db.query(dSIPLCR).filter((dSIPLCR.dr_groupid >= settings.FLT_LCR_MIN) &
                                                    (dSIPLCR.dr_groupid < settings.FLT_FWD_MIN)).order_by(dSIPLCR.dr_groupid.desc()).first()

                    # Start LCR routes with a groupid set in settings (default is 10000)
                    if mlcr is None:
                        groupid = settings.FLT_LCR_MIN
                    else:
                        groupid = int(mlcr.dr_groupid) + 1

                    # Setup new pattern
                    pattern = from_prefix + "-" + prefix

                    # Add the lcr map
                    if pattern != None:
                        OLCRMap = dSIPLCR(pattern, from_prefix, groupid)
                        db.add(OLCRMap)

                    db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                        'groupid': groupid, 'prefix': prefix, 'timerec': timerec, 'priority': priority,
                        'routeid': routeid, 'gwlist': gwlist, 'description': description
                    }, synchronize_session=False)

                # Update existing pattern
                elif (int(groupid) >= settings.FLT_LCR_MIN) and (int(groupid) < settings.FLT_FWD_MIN):
                    db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == groupid).update({
                        'pattern': pattern, 'from_prefix': from_prefix})

                    # Update the dr_rules table
                    db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                        'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                        'routeid': routeid, 'gwlist': gwlist, 'description': description
                    }, synchronize_session=False)

            # no to/from_prefix remove any LCR entries and update outbound route
            # TODO: not sure how to correlate stale LCR entries without old from-prefix (ideally we match by id)
            else:
                # Update the dr_rules table
                db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                    'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                    'routeid': routeid, 'gwlist': gwlist, 'description': description
                }, synchronize_session=False)

        db.commit()
        globals.reload_required = True
        return displayOutboundRoutes()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@app.route('/outboundroutesdelete', methods=['POST'])
def deleteOutboundRoute():
    """
    Deleting of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    db = DummySession()

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']

        OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
        if OMap:
            d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == OMap.groupid)
            d1.delete(synchronize_session=False)

        d = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid)
        d.delete(synchronize_session=False)

        db.commit()

        globals.reload_required = True
        return displayOutboundRoutes()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()


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
    if list is None:
        return ""
    if ":" in list:
        d = dict(item.split(":") for item in list.split(","))
        try:
            return d[field]
        except:
            return
    else:
        return list

def domainTypeFilter(list):
    if list is None:
        return "Unknown"
    if list == "0":
        return "Static"
    else:
        return "Dynamic"

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
def injectReloadRequired():
    return dict(reload_required=globals.reload_required, licensed=globals.licensed)

@app.context_processor
def injectSettings():
    return dict(settings=settings)

# TODO: deprecated, using bjoern for WSGI server
# class CustomServer(Server):
#     """ Customize the Flask server with our settings """
#
#     def __init__(self):
#         super().__init__(
#             host=settings.DSIP_HOST,
#             port=settings.DSIP_PORT
#         )
#
#         if len(settings.DSIP_SSL_CERT) > 0 and len(settings.DSIP_SSL_KEY) > 0:
#            self.ssl_crt = settings.DSIP_SSL_CERT
#            self.ssl_key = settings.DSIP_SSL_KEY
#
#         if settings.DEBUG == True:
#             self.use_debugger = True
#             self.use_reloader = True
#         else:
#             self.use_debugger = None
#             self.use_reloader = None
#             self.threaded = True
#             self.processes = 1

def syncSettings(new_fields={}, update_net=False):
    """
    Synchronize settings.py with shared mem / db

    :param new_fields:      fields to override when syncing
    :type new_fields:       dict
    :param update_net:      if the network settings should be updated
    :type update_net:       bool
    :return:                None
    :rtype:                 None
    """

    db = DummySession()

    try:
        db = SessionLoader()

        # update ip's dynamically
        # TODO: need to create external fqdn resolution funcs
        if update_net:
            net_dict = {
                'INTERNAL_IP_ADDR': getInternalIP(),
                'INTERNAL_IP_NET': "{}.*".format(getInternalIP().rsplit(".", 1)[0]),
                'EXTERNAL_IP_ADDR': getExternalIP(),
                'EXTERNAL_FQDN': settings.EXTERNAL_FQDN
            }
        else:
            net_dict = {}

        # sync settings from settings.py
        if settings.LOAD_SETTINGS_FROM == 'file' or settings.DSIP_ID is None:
            # need to grab any changes on disk b4 merging
            reload(settings)

            # format fields for DB
            fields = OrderedDict(
                [('DSIP_ID', settings.DSIP_ID), ('DSIP_CLUSTER_ID', settings.DSIP_CLUSTER_ID), ('DSIP_CLUSTER_SYNC', settings.DSIP_CLUSTER_SYNC),
                 ('DSIP_PROTO', settings.DSIP_PROTO), ('DSIP_PORT', settings.DSIP_PORT),
                 ('DSIP_USERNAME', settings.DSIP_USERNAME), ('DSIP_PASSWORD', settings.DSIP_PASSWORD),
                 ('DSIP_IPC_PASS', settings.DSIP_IPC_PASS), ('DSIP_API_PROTO', settings.DSIP_API_PROTO),
                 ('DSIP_API_PORT', settings.DSIP_API_PORT), ('DSIP_PRIV_KEY', settings.DSIP_PRIV_KEY), ('DSIP_PID_FILE', settings.DSIP_PID_FILE),
                 ('DSIP_IPC_SOCK', settings.DSIP_IPC_SOCK), ('DSIP_UNIX_SOCK', settings.DSIP_UNIX_SOCK), ('DSIP_API_TOKEN', settings.DSIP_API_TOKEN), ('DSIP_LOG_LEVEL', settings.DSIP_LOG_LEVEL),
                 ('DSIP_LOG_FACILITY', settings.DSIP_LOG_FACILITY), ('DSIP_SSL_KEY', settings.DSIP_SSL_KEY),
                 ('DSIP_SSL_CERT', settings.DSIP_SSL_CERT), ('DSIP_SSL_CA', settings.DSIP_SSL_CA),
                 ('DSIP_SSL_EMAIL', settings.DSIP_SSL_EMAIL), ('DSIP_CERTS_DIR', settings.DSIP_CERTS_DIR),
                 ('VERSION', settings.VERSION),
                 ('DEBUG', settings.DEBUG), ('ROLE', settings.ROLE), ('GUI_INACTIVE_TIMEOUT', settings.GUI_INACTIVE_TIMEOUT),
                 ('KAM_DB_HOST', settings.KAM_DB_HOST), ('KAM_DB_DRIVER', settings.KAM_DB_DRIVER), ('KAM_DB_TYPE', settings.KAM_DB_TYPE),
                 ('KAM_DB_PORT', settings.KAM_DB_PORT), ('KAM_DB_NAME', settings.KAM_DB_NAME), ('KAM_DB_USER', settings.KAM_DB_USER),
                 ('KAM_DB_PASS', settings.KAM_DB_PASS), ('KAM_KAMCMD_PATH', settings.KAM_KAMCMD_PATH), ('KAM_CFG_PATH', settings.KAM_CFG_PATH),
                 ('KAM_TLSCFG_PATH', settings.KAM_TLSCFG_PATH),
                 ('RTP_CFG_PATH', settings.RTP_CFG_PATH), ('SQLALCHEMY_TRACK_MODIFICATIONS', settings.SQLALCHEMY_TRACK_MODIFICATIONS),
                 ('SQLALCHEMY_SQL_DEBUG', settings.SQLALCHEMY_SQL_DEBUG), ('FLT_CARRIER', settings.FLT_CARRIER), ('FLT_PBX', settings.FLT_PBX),
                 ('FLT_MSTEAMS', settings.FLT_MSTEAMS),
                 ('FLT_OUTBOUND', settings.FLT_OUTBOUND), ('FLT_INBOUND', settings.FLT_INBOUND), ('FLT_LCR_MIN', settings.FLT_LCR_MIN),
                 ('FLT_FWD_MIN', settings.FLT_FWD_MIN), ('DEFAULT_AUTH_DOMAIN', settings.DEFAULT_AUTH_DOMAIN), ('TELEBLOCK_GW_ENABLED', settings.TELEBLOCK_GW_ENABLED),
                 ('TELEBLOCK_GW_IP', settings.TELEBLOCK_GW_IP), ('TELEBLOCK_GW_PORT', settings.TELEBLOCK_GW_PORT),
                 ('TELEBLOCK_MEDIA_IP', settings.TELEBLOCK_MEDIA_IP), ('TELEBLOCK_MEDIA_PORT', settings.TELEBLOCK_MEDIA_PORT),
                 ('FLOWROUTE_ACCESS_KEY', settings.FLOWROUTE_ACCESS_KEY), ('FLOWROUTE_SECRET_KEY', settings.FLOWROUTE_SECRET_KEY),
                 ('FLOWROUTE_API_ROOT_URL', settings.FLOWROUTE_API_ROOT_URL), ('INTERNAL_IP_ADDR', settings.INTERNAL_IP_ADDR),
                 ('INTERNAL_IP_NET', settings.INTERNAL_IP_NET), ('EXTERNAL_IP_ADDR', settings.EXTERNAL_IP_ADDR), ('EXTERNAL_FQDN', settings.EXTERNAL_FQDN),
                 ('UPLOAD_FOLDER', settings.UPLOAD_FOLDER), ('CLOUD_PLATFORM', settings.CLOUD_PLATFORM), ('MAIL_SERVER', settings.MAIL_SERVER),
                 ('MAIL_PORT', settings.MAIL_PORT), ('MAIL_USE_TLS', settings.MAIL_USE_TLS), ('MAIL_USERNAME', settings.MAIL_USERNAME),
                 ('MAIL_PASSWORD', settings.MAIL_PASSWORD), ('MAIL_ASCII_ATTACHMENTS', settings.MAIL_ASCII_ATTACHMENTS),
                 ('MAIL_DEFAULT_SENDER', settings.MAIL_DEFAULT_SENDER), ('MAIL_DEFAULT_SUBJECT', settings.MAIL_DEFAULT_SUBJECT)]
            )

            fields.update(new_fields)
            fields.update(net_dict)

            # convert db specific fields
            orig_kam_db_host = fields['KAM_DB_HOST']
            if isinstance(settings.KAM_DB_HOST, list):
                fields['KAM_DB_HOST'] = ','.join(settings.KAM_DB_HOST)

            db.execute('CALL update_dsip_settings({})'.format(','.join([':{}'.format(x) for x in fields.keys()])), fields)

            # revert db specific fields
            fields['KAM_DB_HOST'] = orig_kam_db_host

            if settings.DSIP_ID is None:
                lastrowid = db.execute('SELECT LAST_INSERT_ID()').first()[0]
                fields['DSIP_ID'] = lastrowid

        # sync settings from dsip_settings table
        elif settings.LOAD_SETTINGS_FROM == 'db':
            fields = dict(db.execute('SELECT * FROM dsip_settings WHERE DSIP_ID={}'.format(settings.DSIP_ID)).first().items())
            fields.update(new_fields)
            fields.update(net_dict)

            if ',' in fields['KAM_DB_HOST']:
                fields['KAM_DB_HOST'] = fields['KAM_DB_HOST'].split(',')

        # no other sync scenarios
        else:
            fields = {}

        # update and reload settings file
        if len(fields) > 0:
            updateConfig(settings, fields, hot_reload=True)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        IO.printerr('Could Not Update dsip_settings Database Table')
        db.rollback()
        db.flush()
    finally:
        db.close()

def sigHandler(signum=None, frame=None):
    """ Logic for trapped signals """
    # ignore SIGHUP
    if signum == signal.SIGHUP.value:
        IO.logwarn("Received SIGHUP.. ignoring signal")
    # sync settings from db or file
    elif signum == signal.SIGUSR1.value:
        syncSettings()
    # sync settings from shared memory
    elif signum == signal.SIGUSR2.value:
        shared_settings = dict(settings_manager.getSettings().items())
        syncSettings(shared_settings)

def replaceAppLoggers(log_handler):
    """ Handle configuration of web server loggers """

    # close current log handlers
    for handler in copy(logging.getLogger('werkzeug').handlers):
        logging.getLogger('werkzeug').removeHandler(handler)
        handler.close()
    for handler in copy(logging.getLogger('sqlalchemy').handlers):
        logging.getLogger('sqlalchemy').removeHandler(handler)
        handler.close()

    # replace vanilla werkzeug and sqlalchemy log handler
    logging.getLogger('werkzeug').addHandler(log_handler)
    logging.getLogger('werkzeug').setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger('sqlalchemy.engine').addHandler(log_handler)
    logging.getLogger('sqlalchemy.engine').setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger('sqlalchemy.dialects').addHandler(log_handler)
    logging.getLogger('sqlalchemy.dialects').setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger('sqlalchemy.pool').addHandler(log_handler)
    logging.getLogger('sqlalchemy.pool').setLevel(settings.DSIP_LOG_LEVEL)
    logging.getLogger('sqlalchemy.orm').addHandler(log_handler)
    logging.getLogger('sqlalchemy.orm').setLevel(settings.DSIP_LOG_LEVEL)

def initApp(flask_app):
    # Initialize Globals
    globals.initialize()

    # Setup the Flask session manager with a random secret key
    flask_app.secret_key = os.urandom(32)

    # Setup Flask timed url serializer
    flask_app.config['EMAIL_SALT'] = urandomChars()
    flask_app.config['TIMED_SERIALIZER'] = URLSafeTimedSerializer(flask_app.config["SECRET_KEY"])

    # Add jinja2 filters
    flask_app.jinja_env.filters["attrFilter"] = attrFilter
    flask_app.jinja_env.filters["yesOrNoFilter"] = yesOrNoFilter
    flask_app.jinja_env.filters["noneFilter"] = noneFilter
    flask_app.jinja_env.filters["imgFilter"] = imgFilter
    flask_app.jinja_env.filters["domainTypeFilter"] = domainTypeFilter

    # Add jinja2 functions
    flask_app.jinja_env.globals.update(zip=zip)
    flask_app.jinja_env.globals.update(jsonLoads=json.loads)

    # Dynamically update settings
    syncSettings(update_net=True)

    # Reload Kamailio with the settings from dSIPRouter settings config
    reloadKamailio()

    # configs depending on updated settings go here
    flask_app.env = "development" if settings.DEBUG else "production"
    flask_app.debug = settings.DEBUG

    # Set flask JSON encoder
    flask_app.json_encoder = CreateEncoder()

    # Set session / cookie options
    flask_app.config.update(
        SESSION_PROTECTION='strong',
        SESSION_COOKIE_SECURE=True,
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE='Lax',
        REMEMBER_COOKIE_SECURE=True,
        REMEMBER_COOKIE_HTTPONLY=True,
        REMEMBER_COOKIE_DURATION=datetime.timedelta(minutes=settings.GUI_INACTIVE_TIMEOUT),
        PERMANENT_SESSION_LIFETIME=datetime.timedelta(minutes=settings.GUI_INACTIVE_TIMEOUT),
    )

    # Setup ProxyFix middleware
    flask_app = ProxyFix(flask_app, 1, 1, 1, 1, 1)

    # trap signals we handle
    signal.signal(signal.SIGHUP, sigHandler)
    signal.signal(signal.SIGUSR1, sigHandler)
    signal.signal(signal.SIGUSR2, sigHandler)

    # change umask to 660 before creating sockets
    # this allows members of the dsiprouter group access
    os.umask(~0o660 & 0o777)

    # start the Shared Memory Management server
    if os.path.exists(settings.DSIP_IPC_SOCK):
        os.remove(settings.DSIP_IPC_SOCK)
    settings_manager.start()

    # start the Flask App server
    if os.path.exists(settings.DSIP_UNIX_SOCK):
        os.remove(settings.DSIP_UNIX_SOCK)
    with open(settings.DSIP_PID_FILE, 'w') as pidfd:
        pidfd.write(str(os.getpid()))
    bjoern.run(flask_app, 'unix:{}'.format(settings.DSIP_UNIX_SOCK), reuse_port=True)

def teardown():
    try:
        settings_manager.shutdown()
    except:
        pass
    try:
        SessionLoader.session_factory.close_all()
    except:
        pass
    try:
        db_engine.dispose()
    except:
        pass
    try:
        os.remove(settings.DSIP_PID_FILE)
    except:
        pass


if __name__ == "__main__":
    try:
        initApp(app)
    finally:
        teardown()
