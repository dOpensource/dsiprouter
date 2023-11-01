# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

# all of our standard and project file imports
import os, json, urllib.parse, glob, datetime, csv, logging, signal, bjoern, secrets, subprocess, time
from ansi2html import Ansi2HTMLConverter
from copy import copy
from importlib import reload
from flask import Flask, render_template, request, redirect, flash, session, url_for, send_from_directory, Blueprint, Response
from flask_wtf.csrf import CSRFProtect
from itsdangerous import URLSafeTimedSerializer
from pygtail import Pygtail
from sqlalchemy import func, exc as sql_exceptions
from sqlalchemy.orm import load_only
from sqlalchemy.sql import text
from sqlalchemy.orm.session import close_all_sessions
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import secure_filename
from werkzeug.middleware.proxy_fix import ProxyFix
from sysloginit import initSyslogLogger
from shared import updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields, allowed_file, showError, IO, objToDict, StatusCodes
from util.networking import safeUriToHost, safeFormatSipUri, safeStripPort
from database import DummySession, createSessionObjects, startSession, \
    DB_ENGINE_NAME, SESSION_LOADER_NAME, settingsToTableFormat, getDsipSettingsTableAsDict, \
    Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, dSIPLCR, UAC, GatewayGroups, \
    Domain, DomainAttrs, dSIPMultiDomainMapping, dSIPHardFwd, dSIPFailFwd, updateDsipSettingsTable
from modules import flowroute
from modules.domain.domain_routes import domains
from modules.api.api_routes import api
from modules.api.mediaserver.routes import mediaserver
from modules.api.carriergroups.routes import carriergroups, addCarrierGroups
from modules.api.kamailio.functions import reloadKamailio
from modules.api.licensemanager.functions import WoocommerceError, licenseToGlobalStateVariable
from modules.api.licensemanager.routes import license_manager
from modules.api.auth.routes import user
from util.security import Credentials, urandomChars, AES_CTR
from util.ipc import SETTINGS_SHMEM_NAME, STATE_SHMEM_NAME, createSharedMemoryDict, getSharedMemoryDict
from util.parse_json import CreateEncoder
from util.persistence import updatePersistentState, setPersistentState
from util.pyasync import process
from modules.upgrade import UpdateUtils
import settings

# TODO: unit testing per component
# TODO: many of these routes could use some updating...
#       possibly look into this as well when reworking the architecture for API
# TODO: do license checks on login and store in session variables
#       this alleviates the extra requests and can be updated easily
#       marked for implementation in v0.80
# TODO: move settings to read/write from shared memory instead of using module replacement
#       marked for implementation in v0.80
# TODO: go through templates/routes and replace redundant references to settings/globals
#       they are both injected on every request via the context processor
# TODO: remove references to "ipc.sock" / DSIP_IPC_SOCK
#       we moved to shared memory instead of domain sockets for sharing state across processes

# module constants
# TODO: create /var/log/dsiprouter/ and move there
UPGRADE_LOG = f'{settings.BACKUP_FOLDER}/upgrade.log'
UPGRADE_OFFSET = f'{UPGRADE_LOG}.offset'

# module variables
app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.register_blueprint(domains)
app.register_blueprint(api)
app.register_blueprint(mediaserver)
app.register_blueprint(carriergroups)
app.register_blueprint(user)
app.register_blueprint(license_manager)
app.register_blueprint(Blueprint('docs', 'docs', static_url_path='/docs', static_folder=settings.DSIP_DOCS_DIR))
csrf = CSRFProtect(app)
csrf.exempt(api)
csrf.exempt(mediaserver)
csrf.exempt(carriergroups)
csrf.exempt(user)
csrf.exempt(license_manager)
numbers_api = flowroute.Numbers()
ansi_converter = Ansi2HTMLConverter(inline=True)


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


# DEPRECATED: overridden by csrf.exempt(api), need to revist this, marked for review in v0.80
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
                pwcheck = Credentials.hashCreds(form['password'], settings.DSIP_PASSWORD[-(Credentials.SALT_LEN * 2):])
            else:
                pwcheck = form['password']

            if secrets.compare_digest(pwcheck, settings.DSIP_PASSWORD):
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

        db = startSession()

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

        db = startSession()

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
                    local_domain=settings.EXTERNAL_FQDN, remote_domain=auth_domain)
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
                            auth_proxy=auth_proxy, local_domain=settings.EXTERNAL_FQDN, remote_domain=auth_domain)
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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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
            kam_reload_required=getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'])

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

    # carriergroups.addUpdateCarriers()

    db = DummySession()
    newgwid = None

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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
        Gatewaygroups = db.execute(
            text('SELECT * FROM dr_gw_lists WHERE FIND_IN_SET(:gwid, dr_gw_lists.gwlist)'),
            {'gwid': gwid}
        )

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        # NOTE: not including IPv6 address here as we only need to connect over IPv4 to fusion DB
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


@app.route('/licensing')
def displayLicenseManager():
    """
    Display License Manager page
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        return render_template('license_manager.html')

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

        db = startSession()

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

        endpoint_filter = "%type:{}%".format(settings.FLT_PBX)
        carrier_filter = "%type:{}%".format(settings.FLT_CARRIER)

        res = db.execute(
            text("""
SELECT * FROM (
    SELECT r.ruleid, r.groupid, r.prefix, r.gwlist, r.description AS rule_description, g.id AS gwgroupid, g.description AS gwgroup_description FROM dr_rules AS r LEFT JOIN dr_gw_lists AS g ON g.id = REPLACE(r.gwlist, '#', '') WHERE r.groupid = :flt_inbound
) AS t1 LEFT JOIN (
    SELECT hf.dr_ruleid AS hf_ruleid, hf.dr_groupid AS hf_groupid, hf.did AS hf_fwddid, g.id AS hf_gwgroupid FROM dsip_hardfwd AS hf LEFT JOIN dr_rules AS r ON hf.dr_groupid = r.groupid LEFT JOIN dr_gw_lists AS g ON g.id = REPLACE(r.gwlist, '#', '') WHERE hf.dr_groupid <> :flt_outbound
    UNION ALL
    SELECT hf.dr_ruleid AS hf_ruleid, hf.dr_groupid AS hf_groupid, hf.did AS hf_fwddid, NULL AS hf_gwgroupid FROM dsip_hardfwd AS hf LEFT JOIN dr_rules AS r ON hf.dr_ruleid = r.ruleid WHERE hf.dr_groupid = :flt_outbound
) AS t2 ON t1.ruleid = t2.hf_ruleid LEFT JOIN (
    SELECT ff.dr_ruleid AS ff_ruleid, ff.dr_groupid AS ff_groupid, ff.did AS ff_fwddid, g.id AS ff_gwgroupid FROM dsip_failfwd AS ff LEFT JOIN dr_rules AS r ON ff.dr_groupid = r.groupid LEFT JOIN dr_gw_lists AS g ON g.id = REPLACE(r.gwlist, '#', '') WHERE ff.dr_groupid <> :flt_outbound
    UNION ALL
    SELECT ff.dr_ruleid AS ff_ruleid, ff.dr_groupid AS ff_groupid, ff.did AS ff_fwddid, NULL AS ff_gwgroupid FROM dsip_failfwd AS ff LEFT JOIN dr_rules AS r ON ff.dr_ruleid = r.ruleid WHERE ff.dr_groupid = :flt_outbound
) AS t3 ON t1.ruleid = t3.ff_ruleid"""), {"flt_inbound": settings.FLT_INBOUND, "flt_outbound": settings.FLT_OUTBOUND})

        epgroups = db.query(GatewayGroups).filter(GatewayGroups.description.like(endpoint_filter)).all()
        gwgroups = db.query(GatewayGroups).filter(
            (GatewayGroups.description.like(endpoint_filter)) | (GatewayGroups.description.like(carrier_filter))).all()

        gatewayList = db.query(Gateways).all()

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

        return render_template('inboundmapping.html', rows=res, gwgroups=gwgroups, epgroups=epgroups, imported_dids=dids, gatewayList=gatewayList)

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

        db = startSession()

        form = stripDictVals(request.form.to_dict())

        # get form data
        ruleid = form['ruleid'] if 'ruleid' in form else None
        gwgroupid = form['gwgroupid'] if 'gwgroupid' in form and form['gwgroupid'] != "0" else ''
        prefix = form['prefix'] if 'prefix' in form else ''
        desc_dict = {'name': form['rulename']} if 'rulename' in form else {}
        hardfwd_enabled = int(form['hardfwd_enabled'])
        hf_gwgroupid = form['hf_gwgroupid'] if 'hf_gwgroupid' in form and form['hf_gwgroupid'] != "0" else ''
        hf_groupid = form['hf_groupid'] if 'hf_groupid' in form else ''
        hf_fwddid = form['hf_fwddid'] if 'hf_fwddid' in form else ''
        failfwd_enabled = int(form['failfwd_enabled'])
        ff_gwgroupid = form['ff_gwgroupid'] if 'ff_gwgroupid' in form and form['ff_gwgroupid'] != "0" else ''
        ff_groupid = form['ff_groupid'] if 'ff_groupid' in form else ''
        ff_fwddid = form['ff_fwddid'] if 'ff_fwddid' in form else ''

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
                x = gwgroupid.split("_")
                gwgroupid = x[1]
                desc_dict['lb_enabled'] = '1'
            else:
                desc_dict['lb_enabled'] = '0'
            description = dictToStrFields(desc_dict)
            # we only support a single gwgroup at this time
            gwlist = '#{}'.format(gwgroupid) if len(gwgroupid) > 0 else ''
            #     dispatcher_id = x[2].zfill(4)
            #
            #     Gateway = db.query(Gateways).filter(Gateways.description.like("%drouting_to_dispatcher%"), Gateways.address == "localhost", Gateways.strip == 0, Gateways.pri_prefix == dispatcher_id, Gateways.type == settings.FLT_PBX).first()
            #
            #     if not Gateway:
            #         # Create a gateway
            #         Gateway = Gateways("drouting_to_dispatcher", "localhost", 0, dispatcher_id, settings.FLT_PBX, gwgroup=gwgroupid)
            #
            #         db.add(Gateway)
            #         db.flush()
            #
            #     addresses = [Address("myself", settings.INTERNAL_IP_ADDR, 32, 1, gwgroup=gwgroupid)]
            #     if settings.IPV6_ENABLED:
            #         addresses.append(Address("myself", settings.INTERNAL_IP6_ADDR, 32, 1, gwgroup=gwgroupid))
            #     db.add_all(addresses)
            #
            #     # Define an Inbound Mapping that maps to the newly created gateway
            #     gwlist = Gateway.gwid
            #     IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
            #     db.add(IMap)
            #
            #     db.commit()
            #     return displayInboundMapping()

            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
            inserts.append(IMap)

            # find last rule in dr_rules
            res = db.execute(
                text("SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=:db_name AND TABLE_NAME='dr_rules'"),
                {"db_name": settings.KAM_DB_NAME}
            ).first()
            ruleid = int(res[0])

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
                # logging.info("In the load balancing update logic")
                x = gwgroupid.split("_")
                gwgroupid = x[1]
                desc_dict['lb_enabled'] = '1'
            else:
                desc_dict['lb_enabled'] = '0'
            description = dictToStrFields(desc_dict)
            # we only support a single gwgroup at this time
            gwlist = '#{}'.format(gwgroupid) if len(gwgroupid) > 0 else ''
            # dispatcher_id = x[2].zfill(4)
            #
            # # logging.info("Searching for the gateway by description")
            # # Create a gateway
            # Gateway = db.query(Gateways).filter(Gateways.description.like(gwgroupid) & Gateways.description.like("lb:{}".format(dispatcher_id))).first()
            # if Gateway:
            #     logging.info("Gateway found")
            #     fields = strFieldsToDict(Gateway.description)
            #     fields['lb'] = dispatcher_id
            #     fields['gwgroup'] = gwgroupid
            #     Gateway.update({'prefix': dispatcher_id, 'description': dictToStrFields(fields)})
            # else:
            #     # logging.info("Gateway not found")
            #     Gateway = db.query(Gateways).filter(Gateways.description.like("%drouting_to_dispatcher%"), Gateways.address == "localhost", Gateways.strip == 0, Gateways.pri_prefix == dispatcher_id, Gateways.type == settings.FLT_PBX).first()
            #     if not Gateway:
            #         logging.info("Gateway not found, creating new gateway")
            #         # Create a gateway
            #         Gateway = Gateways("drouting_to_dispatcher", "localhost", 0, dispatcher_id, settings.FLT_PBX, gwgroup=gwgroupid)
            #         db.add(Gateway)
            #         db.flush()
            #
            #     # Gateway = Gateways("drouting_to_dispatcher", "localhost", 0, dispatcher_id, settings.FLT_PBX, gwgroup=gwgroupid)
            #     # db.add(Gateway)
            #
            # db.flush()
            # # Assign Gateway id to the gateway list
            # gwlist = Gateway.gwid
            #
            # try:
            #     if not db.query(Address).filter(Address.ip_addr == settings.INTERNAL_IP_ADDR).scalar():
            #         db.add(Address("myself", settings.INTERNAL_IP_ADDR, 32, 1, gwgroup=gwgroupid))
            #     if settings.IPV6_ENABLED:
            #         if not db.query(Address).filter(Address.ip_addr == settings.INTERNAL_IP6_ADDR).scalar():
            #             db.add(Address("myself", settings.INTERNAL_IP6_ADDR, 32, 1, gwgroup=gwgroupid))
            # except sql_exceptions.MultipleResultsFound as ex:
            #     logging.info("Multiple Address rows found")

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

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
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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
def displayTransNexus(msg=None):
    """
    Display TransNexus settings in view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        license_status = getSharedMemoryDict(STATE_SHMEM_NAME)['transnexus_license_status']
        if license_status == 0:
            return render_template('license_required.html', msg=None)

        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        if settings.TRANSNEXUS_AUTHSERVICE_ENABLED == 1:
            authservice_checked = 'checked'
            transnexusOptions_hidden = 'hidden'
        else:
            authservice_checked = ''
            transnexusOptions_hidden = ''

        return render_template(
            'transnexus.html',
            msg=msg,
            authservice_checked=authservice_checked,
            transnexusOptions_hidden=transnexusOptions_hidden
        )

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
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

        license_status = getSharedMemoryDict(STATE_SHMEM_NAME)['transnexus_license_status']
        if license_status == 0:
            return render_template('license_required.html', msg=None)

        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        form = stripDictVals(request.form.to_dict())

        # Update the TransNexus settings
        tn_settings = {}
        if 'authservice_enabled' in form:
            tn_settings['TRANSNEXUS_AUTHSERVICE_ENABLED'] = int(form['authservice_enabled'])
        else:
            # It was disabled so the form field was not sent over
            tn_settings['TRANSNEXUS_AUTHSERVICE_ENABLED'] = 0

        if 'authservice_host' in form:
            tn_settings["TRANSNEXUS_AUTHSERVICE_HOST"] = form['authservice_host']

        if len(tn_settings) != 0:
            updateConfig(settings, tn_settings, hot_reload=True)
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True

        return displayTransNexus()

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
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

        db = startSession()

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

        db = startSession()

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
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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

        db = startSession()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']

        OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
        if OMap:
            d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == OMap.groupid)
            d1.delete(synchronize_session=False)

        d = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid)
        d.delete(synchronize_session=False)

        db.commit()

        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
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


@app.route('/stirshaken')
def displayStirShaken(msg=None):
    """
    Display TransNexus settings in view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        license_status = getSharedMemoryDict(STATE_SHMEM_NAME)['stirshaken_license_status']
        if license_status == 0:
            return render_template('license_required.html', msg=None)

        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        if settings.STIR_SHAKEN_ENABLED == 1:
            toggle_checked = 'checked'
            options_hidden = 'hidden'
        else:
            toggle_checked = ''
            options_hidden = ''

        return render_template(
            'stirshaken.html',
            msg=msg,
            toggle_checked=toggle_checked,
            options_hidden=options_hidden
        )

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)


@app.route('/stirshaken', methods=['POST'])
def addUpdateStirShaken():
    """
    Update STIR/SHAKEN config file settings
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        license_status = getSharedMemoryDict(STATE_SHMEM_NAME)['stirshaken_license_status']
        if license_status == 0:
            return render_template('license_required.html', msg=None)

        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        form = stripDictVals(request.form.to_dict())

        # Update the STIR/SHAKEN settings
        ss_settings = {}
        if 'stir_shaken_enabled' in form:
            tmp = form.get('stir_shaken_enabled', 0)
            ss_settings["STIR_SHAKEN_ENABLED"] = 1 if tmp == "1" else 0
        else:
            ss_settings["STIR_SHAKEN_ENABLED"] = 0

        if 'stir_shaken_prefix_a' in form:
            ss_settings["STIR_SHAKEN_PREFIX_A"] = form.get('stir_shaken_prefix_a', '')
        if 'stir_shaken_prefix_b' in form:
            ss_settings["STIR_SHAKEN_PREFIX_B"] = form.get('stir_shaken_prefix_b', '')
        if 'stir_shaken_prefix_c' in form:
            ss_settings["STIR_SHAKEN_PREFIX_C"] = form.get('stir_shaken_prefix_c', '')
        if 'stir_shaken_prefix_invalid' in form:
            ss_settings["STIR_SHAKEN_PREFIX_INVALID"] = form.get('stir_shaken_prefix_invalid', '')
        if 'stir_shaken_block_invalid' in form:
            tmp = form.get('stir_shaken_block_invalid', 0)
            ss_settings["STIR_SHAKEN_BLOCK_INVALID"] = 1 if tmp == "on" else 0
        if 'stir_shaken_cert_url' in form:
            ss_settings["STIR_SHAKEN_CERT_URL"] = form.get('stir_shaken_cert_url', '')
        if 'stir_shaken_key_path' in form:
            ss_settings["STIR_SHAKEN_KEY_PATH"] = form.get('stir_shaken_key_path', '')

        if len(ss_settings) != 0:
            updateConfig(settings, ss_settings, hot_reload=True)
            getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True

        return displayStirShaken()

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)


@app.route('/upgrade')
def displayUpgrade(msg=None):
    """
    Display Upgrade settings in view
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        license_status = getSharedMemoryDict(STATE_SHMEM_NAME)['core_license_status']
        if license_status == 0:
            return render_template('license_required.html', msg=None)
        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')
        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        # make sure we remove offset file when navigating to top level page
        if os.path.exists(UPGRADE_OFFSET):
            os.remove(UPGRADE_OFFSET)

        latest = UpdateUtils.get_latest_version()

        upgrade_settings = {
            "current_version": settings.VERSION,
            "latest_version": latest['ver_num'],
            "upgrade_available": 1 if latest['ver_num'] > float(settings.VERSION) else 0
        }
        return render_template('upgrade.html', upgrade_settings=upgrade_settings, msg=msg)

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)


@process
def runUpgrade(cmd, env):
    try:
        getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_upgrade_ongoing'] = True

        with open(UPGRADE_LOG, 'wb', buffering=0) as f:
            run_info = subprocess.run(
                cmd,
                stdout=f,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                env=env,
                restore_signals=False,
                close_fds=True
            )
            run_info.check_returncode()

            # getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
            # kamailio will be reloaded when dsiprouter is reloaded
            getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_reload_required'] = True
    finally:
        getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_upgrade_ongoing'] = False

@app.route('/upgrade/start', methods=['POST'])
def startUpgrade():
    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        if getSharedMemoryDict(STATE_SHMEM_NAME)['core_license_status'] != 3:
            raise WoocommerceError('invalid license')

        IO.loginfo("starting upgrade")

        form = stripDictVals(request.form.to_dict())
        cmd = ['sudo', '-E', 'dsiprouter', 'upgrade', '-rel', f"{form['latest_version']}", '-url', settings.GIT_REPO_URL]
        env = os.environ.copy()
        env['RUN_FROM_GUI'] = '1'
        runUpgrade(cmd, env)

        IO.loginfo("upgrade started")

        return Response(), StatusCodes.HTTP_OK

    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
        error = "server"
        return showError(type=error)


# format a message as a server sent event
# idea from: https://maxhalford.github.io/blog/flask-sse-no-deps/
# TODO: separate into SSE specific file
def formatSSE(data: str, event: str = None) -> str:
    msg = f'data: {data}\n\n'
    if event is not None:
        msg = f'event: {event}\n{msg}'
    return msg


# inspired by: https://gist.github.com/kapb14/87255efffa173bb76cf5c1ed9db1d047
# TODO: move to file handling
def readLogChunk(log_file):
    while getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_upgrade_ongoing'] == True:
        time.sleep(2)
        for line in Pygtail(log_file, offset_file=f'{log_file}.offset'):
            yield formatSSE(ansi_converter.convert(line, full=False).rstrip() + '<br>')


def checkUpgradeStatus():
    while getSharedMemoryDict(STATE_SHMEM_NAME)['dsip_upgrade_ongoing'] == True:
        time.sleep(30)
        yield formatSSE('1')
    yield formatSSE('0')


@app.route('/upgrade/status')
def getUpgradeStatus():
    try:
        if not session.get('logged_in'):
            return 'Unauthorized', 401

        if (settings.DEBUG):
            debugEndpoint()

        return Response(
            checkUpgradeStatus(),
            mimetype="text/event-stream",
            headers={
                'X-Accel-Buffering': 'no',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive'
            },
        )

    except Exception as ex:
        debugException(ex)
        return 'Failed Checking Status', StatusCodes.HTTP_INTERNAL_SERVER_ERROR

@app.route('/upgrade/log')
def getUpgradeLog():
    try:
        if not session.get('logged_in'):
            return 'Unauthorized', 401

        if (settings.DEBUG):
            debugEndpoint()

        accept = request.headers.get('Accept', '').lower()
        if accept == 'text/event-stream':
            return Response(
                readLogChunk(UPGRADE_LOG),
                mimetype="text/event-stream",
                headers={
                    'X-Accel-Buffering': 'no',
                    'Cache-Control': 'no-cache',
                    'Connection': 'keep-alive'
                },
            )
        else:
            with open(UPGRADE_LOG, 'r') as f:
                return Response(
                    ansi_converter.convert(f.read(), full=False).replace('\n', '<br>'),
                    mimetype="text/html",
                )
    except FileNotFoundError:
        return 'File not found', 404
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        return showError(type=error)
    except Exception as ex:
        debugException(ex)
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
    elif list == "0":
        return "Static"
    elif list == "1":
        return "Dynamic"
    elif list == "2":
        return "Static using Dispatcher"
    elif list == "3":
        return "MSTeams"
    else:
        return "Other"


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
def injectGlobals():
    return {
        'settings': settings,
        'state': getSharedMemoryDict(STATE_SHMEM_NAME),
    }


# DEPRECATED: now done by dsiprouter.sh (CLI commands run by dsip-init.service), marked for removal in v0.80
# def getDynamicNetworkSettings():
#     """
#     Get the network settings depending on the state of NETWORK_MODE when called
#
#     :return:    network settings or empty dict
#     :rtype:     dict
#     """
#
#     if settings.NETWORK_MODE == 1:
#         return {}
#     elif settings.NETWORK_MODE == 2:
#         raise NotImplementedError()
#
#     int_ip = getInternalIP('4')
#     int_ip6 = getInternalIP('6')
#     int_net = getInternalCIDR('4')
#     int_net6 = getInternalCIDR('6')
#     int_fqdn = socket.getfqdn()
#     ext_ip = getExternalIP('4')
#     ext_ip6 = getExternalIP('6')
#     ext_fqdn = ipToHost(ext_ip)
#     if os.path.exists('/proc/net/if_inet6'):
#         try:
#             with socket.socket(socket.AF_INET6, socket.SOCK_DGRAM) as s:
#                 s.connect((int_ip6, 0))
#             ipv6_enabled = True
#         except:
#             ipv6_enabled = False
#     else:
#         ipv6_enabled = False
#
#     return {
#         'IPV6_ENABLED': ipv6_enabled,
#         'INTERNAL_IP_ADDR': int_ip if int_ip is not None else '',
#         'INTERNAL_IP_NET': int_net if int_net is not None else '',
#         'INTERNAL_IP6_ADDR': int_ip6 if int_ip6 is not None else '',
#         'INTERNAL_IP6_NET': int_net6 if int_net6 is not None else '',
#         'EXTERNAL_IP_ADDR': ext_ip if ext_ip is not None else int_ip if int_ip is not None else '',
#         'EXTERNAL_IP6_ADDR': ext_ip6 if ext_ip6 is not None else int_ip6 if int_ip6 is not None else '',
#         'EXTERNAL_FQDN': ext_fqdn if ext_fqdn is not None else int_fqdn if int_fqdn is not None else ''
#     }

# DEPRECATED: updating network settings portion of this function has moved to the CLI
#             marked for refactoring in v0.80 as shown below
#               def syncSettings(new_fields={}):
def syncSettings(new_fields={}, update_net=False):
    """
    Synchronize settings.py with shared mem / db

    :param new_fields:      fields to override when syncing
    :type new_fields:       dict
    :return:                None
    :rtype:                 None
    """

    try:
        # sync settings from settings.py
        if settings.LOAD_SETTINGS_FROM == 'file' or settings.DSIP_ID is None:
            # need to grab any changes on disk b4 merging
            reload(settings)

        # if DSIP_ID is not set, generate it
        if settings.DSIP_ID is None:
            with open('/etc/machine-id', 'r') as f:
                settings.DSIP_ID = Credentials.hashCreds(f.read().rstrip())

        # if HOMER_ID is not set, generate it
        if settings.HOMER_ID is None:
            with open('/etc/machine-id', 'r') as f:
                settings.HOMER_ID = int(Credentials.hashCreds(f.read().rstrip(), dklen=4)[0:8], 16)

        # sync settings from settings.py
        if settings.LOAD_SETTINGS_FROM == 'file':

            # format fields for DB
            fields = settingsToTableFormat(settings)
            fields.update(new_fields)

            # update the table
            updateDsipSettingsTable(fields)

            # revert db specific fields
            if ',' in fields['KAM_DB_HOST']:
                fields['KAM_DB_HOST'] = fields['KAM_DB_HOST'].split(',')

        # sync settings from dsip_settings table
        elif settings.LOAD_SETTINGS_FROM == 'db':
            fields = getDsipSettingsTableAsDict(settings.DSIP_ID)
            fields.update(new_fields)

            if ',' in fields['KAM_DB_HOST']:
                fields['KAM_DB_HOST'] = fields['KAM_DB_HOST'].split(',')

        # no configured storage device to sync settings to/from
        else:
            raise ValueError('invalid value for LOAD_SETTINGS_FROM, acceptable values: "file" or "db"')

        # update and reload settings file
        if len(fields) > 0:
            updateConfig(settings, fields, hot_reload=True)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        IO.printerr('Could Not Update dsip_settings Database Table')
        raise


def sigHandler(signum=None, frame=None):
    """ Logic for trapped signals """
    # ignore SIGHUP
    if signum == signal.SIGHUP.value:
        IO.printwarn("Received SIGHUP.. ignoring signal")
        IO.logwarn("Received SIGHUP.. ignoring signal")
    # sync settings from db or file
    elif signum == signal.SIGUSR1.value:
        IO.printdbg("Received SIGUSR1 syncing settings from {}".format(settings.LOAD_SETTINGS_FROM))
        IO.logdbg("Received SIGUSR1 syncing settings from {}".format(settings.LOAD_SETTINGS_FROM))
        syncSettings()
    # sync settings from shared memory
    elif signum == signal.SIGUSR2.value:
        IO.printdbg("Received SIGUSR2 syncing settings from shared memory")
        IO.logdbg("Received SIGUSR2 syncing settings from shared memory")
        shared_settings = dict(getSharedMemoryDict(SETTINGS_SHMEM_NAME).items())
        syncSettings(shared_settings)
    # run teardown logic before exiting
    elif signum == signal.SIGINT.value:
        IO.printdbg("Received SIGINT tearing down services")
        IO.logdbg("Received SIGINT tearing down services")
        teardown()
        sys.exit(0)
    # run teardown logic before exiting
    elif signum == signal.SIGTERM.value:
        IO.printdbg("Received SIGTERM tearing down services")
        IO.logdbg("Received SIGTERM tearing down services")
        teardown()
        sys.exit(0)


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


def intializeGlobalSettings():
    """
    Initialize global settings and make it accessible in shared memory

    :return:    None
    :rtype:     None
    """

    syncSettings()

    updated_settings = objToDict(settings)
    createSharedMemoryDict(updated_settings, name=SETTINGS_SHMEM_NAME)

    if settings.DEBUG:
        IO.printinfo(f'global settings initialized: {updated_settings}')


def intializeGlobalState():
    """
    Initialize global state and make it accessible in shared memory

    :return:    None
    :rtype:     None
    """

    # create/update the shared state file
    # if the state got corrupted throw it away and start fresh
    # NOTE: upgrade process does not daemonize, it is always gone on startup
    try:
        state = updatePersistentState({
            'dsip_reload_ongoing': False,
            'dsip_reload_required': False,
            'dsip_upgrade_ongoing': False,
        })
    except json.JSONDecodeError:
        state = {}

    # license checks are always performed on startup, not loaded from state file
    state['core_license_status'] = licenseToGlobalStateVariable(settings.DSIP_CORE_LICENSE)
    state['stirshaken_license_status'] = licenseToGlobalStateVariable(settings.DSIP_STIRSHAKEN_LICENSE)
    state['transnexus_license_status'] = licenseToGlobalStateVariable(settings.DSIP_TRANSNEXUS_LICENSE)
    state['msteams_license_status'] = licenseToGlobalStateVariable(settings.DSIP_MSTEAMS_LICENSE)
    state['kam_reload_required'] = state.get('kam_reload_required', False)
    state['dsip_reload_required'] = state.get('dsip_reload_required', False)
    state['dsip_reload_ongoing'] = state.get('dsip_reload_ongoing', False)
    state['dsip_upgrade_ongoing'] = state.get('dsip_upgrade_ongoing', False)

    createSharedMemoryDict(state, name=STATE_SHMEM_NAME)

    if settings.DEBUG:
        IO.printinfo(f'global state initialized: {state}')


def initApp(flask_app):
    # load the DB objects into memory
    global global_db_engine, global_session_loader
    global_db_engine, global_session_loader = createSessionObjects()
    # make sure we did not break the global naming contract with the database module
    assert DB_ENGINE_NAME in globals() and SESSION_LOADER_NAME in globals()

    # Setup the Flask session manager with a random secret key
    if settings.DSIP_SESSION_KEY is None:
        flask_app.secret_key = os.urandom(32)
    else:
        flask_app.secret_key = AES_CTR.decrypt(settings.DSIP_SESSION_KEY, decode=False)

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
    flask_app.jinja_env.globals.update(licenseValid=lambda x: x==3)

    # Dynamically update settings
    intializeGlobalSettings()

    # Reload Kamailio with the settings from dSIPRouter settings config
    reloadKamailio()

    # configs depending on updated settings go here
    # DEPRECATED: flask_app.env is deprecated and only flask_app.debug will be used in the future, marked for removal in v0.80
    flask_app.env = "development" if settings.DEBUG else "production"
    flask_app.debug = settings.DEBUG

    # DEPRECATED: class interface changed and will be removed in Flask 2.3, marked for review in v0.80
    #             customize 'app.json_provider_class' or 'app.json' instead
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
    signal.signal(signal.SIGINT, sigHandler)
    signal.signal(signal.SIGTERM, sigHandler)

    # change umask to 660 before creating sockets
    # this allows members of the dsiprouter group access
    os.umask(~0o660 & 0o777)

    # remove sockets / PID file from previous runs (only possible on SIGKILL or system halt)
    if os.path.exists(settings.DSIP_UNIX_SOCK):
        os.remove(settings.DSIP_UNIX_SOCK)

    # Initialize global variables based on persistent state
    intializeGlobalState()

    # write out the main proc's PID
    with open(settings.DSIP_PID_FILE, 'w') as pidfd:
        pidfd.write(str(os.getpid()))

    # start the Flask App server
    bjoern.run(flask_app, 'unix:{}'.format(settings.DSIP_UNIX_SOCK), reuse_port=True)


def teardown():
    global global_db_engine

    try:
        setPersistentState(objToDict(globals))
    except:
        pass
    try:
        getSharedMemoryDict(SETTINGS_SHMEM_NAME).unlink()
    except:
        pass
    try:
        getSharedMemoryDict(STATE_SHMEM_NAME).unlink()
    except:
        pass
    try:
        close_all_sessions()
    except:
        pass
    try:
        global_db_engine.dispose(close=True)
    except:
        pass
    try:
        os.remove(settings.DSIP_PID_FILE)
    except:
        pass
    # TODO: multiprocessing and bjoern modules try to handle this in the ExitException handlers
    #       marked for review...
    try:
        os.remove(settings.DSIP_UNIX_SOCK)
    except:
        pass


def main():
    try:
        # start the main proc here
        # from this point on shutdown is handled by signalling to the main proc
        initApp(app)
        # should not be reachable, we always exit with an exception or signal handler
        IO.printerr('a fatal logic error occurred, bypassing the signal handler')
        IO.logerr('a fatal logic error occurred, bypassing the signal handler')
        sys.exit(1)
    except SystemExit as ex:
        # normal exit, call underlying C-API with exit code
        if ex.code == 0:
            IO.printinfo('exited successfully')
            IO.loginfo('exited successfully')
            os._exit(0)
        # an exception bubbled up, allow caller to handler it
        raise


if __name__ == "__main__":
    main()
