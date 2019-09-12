#!/usr/bin/env python3

import os, re, json, subprocess, urllib.parse, glob,datetime, csv, logging, signal
from copy import copy
from flask import Flask, render_template, request, redirect, abort, flash, session, url_for, send_from_directory, g
from flask_script import Manager, Server
from importlib import reload
from sqlalchemy import case, func, exc as sql_exceptions
from sqlalchemy.orm import load_only
from werkzeug import exceptions as http_exceptions
from werkzeug.utils import secure_filename
from sysloginit import initSyslogLogger
from shared import getInternalIP, getExternalIP, updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields, allowed_file, showError, hostToIP, IO
from database import loadSession, Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, dSIPLCR, \
    UAC, GatewayGroups, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, \
    dSIPMaintModes, dSIPCallLimits, dSIPHardFwd, dSIPFailFwd
from modules import flowroute
from modules.domain.domain_routes import domains
import globals
from modules.api.api_routes import api
import settings

# global variables
app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.register_blueprint(domains)
app.register_blueprint(api)
db = loadSession()
numbers_api = flowroute.Numbers()


# TODO: unit testing per component

@app.before_first_request
def before_first_request():
    log_handler = initSyslogLogger()
    # replace werkzeug and sqlalchemy loggers
    replaceAppLoggers(log_handler)

@app.before_request
def before_request():
    session.permanent = True
    if not hasattr(settings,'GUI_INACTIVE_TIMEOUT'):
        settings.GUI_INACTIVE_TIMEOUT = 20 #20 minutes
    app.permanent_session_lifetime = datetime.timedelta(minutes=settings.GUI_INACTIVE_TIMEOUT)
    session.modified = True

@app.route('/')
def index():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            checkDatabase()
            return render_template('index.html', version=settings.VERSION)
        else:
            action = request.args.get('action')
            return render_template('dashboard.html', show_add_onload=action, version=settings.VERSION)


    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        db.close()
        return render_template('index.html', version=settings.VERSION)
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


        #Get Environment Variables if set
        settings.DSIP_USERNAME = os.getenv('DSIP_USER', settings.DSIP_USERNAME)
        settings.DSIP_PASSWORD = os.getenv('DSIP_PASS', settings.DSIP_PASSWORD)

        if form['password'] == settings.DSIP_PASSWORD and form['username'] == settings.DSIP_USERNAME:
            session['logged_in'] = True
            session['username'] = form['username']
        else:
            flash('wrong username or password!')
            return render_template('index.html', version=settings.VERSION), 403
        return redirect(url_for('index'))


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

        session.pop('logged_in', None)
        session.pop('username', None)
        return redirect(url_for('index'))

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

    # TODO: track related dr_rules and update lists on delete

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        typeFilter = "%type:{}%".format(settings.FLT_CARRIER)

        # res must be a list()
        if gwgroup is not None and gwgroup != "":
            res = [db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                UAC.auth_username, UAC.auth_password, UAC.realm).filter(
                GatewayGroups.id == gwgroup).first()]
        else:
            res = db.query(GatewayGroups).outerjoin(UAC, GatewayGroups.id == UAC.l_uuid).add_columns(
                GatewayGroups.id, GatewayGroups.gwlist, GatewayGroups.description,
                UAC.auth_username, UAC.auth_password, UAC.realm).filter(GatewayGroups.description.like(typeFilter))
        db.close()
        return render_template('carriergroups.html', rows=res, API_URL=request.url_root)

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
        db.close()


@app.route('/carriergroups', methods=['POST'])
def addUpdateCarrierGroups():
    """
    Add or Update a group of carriers
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

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

            Gwgroup = GatewayGroups(name,type=settings.FLT_CARRIER)
            db.add(Gwgroup)
            db.flush()
            gwgroup = Gwgroup.id

            if authtype == "userpwd":
                Uacreg = UAC(gwgroup, auth_username, auth_password, auth_domain, auth_proxy,
                             settings.EXTERNAL_IP_ADDR, auth_domain)
                #Add auth_domain(aka registration server) to the gateway list
                Addr = Address(name + "-uac", hostToIP(auth_domain), 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                db.add(Uacreg)
                db.add(Addr)

            else:
                Uacreg = UAC(gwgroup, username=gwgroup,local_domain=settings.EXTERNAL_IP_ADDR, flags=UAC.FLAGS.REG_DISABLED.value)
                db.add(Uacreg)

        # Updating
        else:
            # config form
            if len(new_name) > 0:
                Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                fields = strFieldsToDict(Gwgroup.description)
                fields['name'] = new_name
                Gwgroup.description = dictToStrFields(fields)
                db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).update({'description': Gwgroup.description},synchronize_session=False)

            # auth form
            else:
                if authtype == "userpwd":
                    db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                        {'l_username': auth_username, 'r_username': auth_username, 'auth_username': auth_username,
                         'auth_password': auth_password, 'r_domain': auth_domain, 'realm': auth_domain,
                         'auth_proxy': auth_proxy, 'flags': UAC.FLAGS.REG_ENABLED.value}, synchronize_session=False)
                    Addr = db.query(Address).filter(Address.tag.contains("name:{}-uac".format(name)))
                    Addr.delete(synchronize_session=False)
                    Addr = Address(name + "-uac", hostToIP(auth_domain), 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                    db.add(Addr)

                else:
                    db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                        {'l_username': '', 'r_username': '', 'auth_username': '', 'auth_password': '', 'r_domain': '',
                         'realm': '', 'auth_proxy': '', 'flags': UAC.FLAGS.REG_DISABLED.value},
                        synchronize_session=False)
                    Addr = db.query(Address).filter(Address.tag.contains("name:{}-uac".format(name)))
                    Addr.delete(synchronize_session=False)

        db.commit()
        globals.reload_required = True
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
        db.close()


@app.route('/carriergroupdelete', methods=['POST'])
def deleteCarrierGroups():
    """
    Delete a group of carriers
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

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
        globals.reload_required = True
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

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

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
                carrier_rules.append(json.dumps(gateway_rules, separators=(',',':')))

        return render_template('carriers.html', rows=carriers, routes=carrier_rules, gwgroup=gwgroup, new_gwid=newgwid)

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


@app.route('/carriers', methods=['POST'])
def addUpdateCarriers():
    """
    Add or Update a carrier
    """


    newgwid = None

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if len(form['gwgroup']) > 0 else ''
        name = form['name'] if len(form['name']) > 0 else ''
        ip_addr = form['ip_addr'] if len(form['ip_addr']) > 0 else ''
        strip = form['strip'] if len(form['strip']) > 0 else '0'
        prefix = form['prefix'] if len(form['prefix']) > 0 else ''

        # Adding
        if len(gwid) <= 0:
            if len(gwgroup) > 0:
                Addr = Address(name, ip_addr, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_CARRIER, gwgroup=gwgroup)

                db.add(Gateway)
                db.flush()

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
        globals.reload_required = True
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
        db.close()


@app.route('/carrierdelete', methods=['POST'])
def deleteCarriers():
    """
    Delete a carrier
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        gwid = form['gwid']
        gwgroup = form['gwgroup'] if 'gwgroup' in form else ''
        name = form['name']
        related_rules = json.loads(form['related_rules']) if 'related_rules' in form else ''

        Gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
        # make the extra query to find associated gwgroup if needed
        if len(gwgroup) <= 0:
            Gateway = db.query(Gateways).filter(Gateways.gwid == gwid)
            fields = strFieldsToDict(Gateway.first().description)
            gwgroup = fields['gwgroup']
        # grab associated address entry as well
        Addr = db.query(Address).filter(Address.tag.contains("gwgroup:{}".format(name)))
        # grab any related carrier groups
        Gatewaygroups = db.execute('SELECT * FROM dr_gw_lists WHERE FIND_IN_SET({}, dr_gw_lists.gwlist)'.format(gwid))

        # remove gateway and address
        Gateway.delete(synchronize_session=False)
        Addr.delete(synchronize_session=False)
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

        return render_template('endpointgroups.html', DEFAULT_AUTH_DOMAIN=settings.DOMAIN)

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

        return render_template('cdrs.html', DEFAULT_AUTH_DOMAIN=settings.DOMAIN)

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


@app.route('/endpointgroups', methods=['POST'])
def addUpdateEndpointGroups():
    """
    Add or Update a PBX / Endpoint
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # TODO: change ip_addr field to hostname or domainname, we already support this
        gwid = form['gwid']
        gwgroupid = request.form.get("gwgroup",None)
        name = request.form.get("name",None)
        ip_addr = request.form.get("ip_addr",None)
        strip = form['strip'] if len(form['strip']) > 0 else "0"
        prefix = form['prefix'] if len(form['prefix']) > 0 else ""
        authtype = form['authtype']
        fusionpbx_db_server = form['fusionpbx_db_server']
        fusionpbx_db_username = form['fusionpbx_db_username']
        fusionpbx_db_password = form['fusionpbx_db_password']
        auth_username = form['auth_username']
        auth_password = form['auth_password']
        auth_domain = form['auth_domain'] if len(form['auth_domain']) > 0 else settings.DOMAIN
        calllimit = form['calllimit'] if len(form['calllimit']) > 0 else ""

        multi_tenant_domain_enabled = False
        multi_tenant_domain_type = dSIPMultiDomainMapping.FLAGS.TYPE_UNKNOWN.value
        single_tenant_domain_enabled = False
        single_tenant_domain_type = dSIPDomainMapping.FLAGS.TYPE_UNKNOWN.value

        if name is not None:
            Gwgroup = GatewayGroups(name,type=settings.FLT_PBX)
            db.add(Gwgroup)
            db.flush()
            gwgroup = Gwgroup.id

        globals.reload_required = True
        return displayEndpointGroups()

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
        db.close()


@app.route('/pbxdelete', methods=['POST'])
def deletePBX():
    """
    Delete a PBX / Endpoint
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

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
        db.close()


@app.route('/inboundmapping')
def displayInboundMapping():
    """
    Displaying of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        endpoint_filter = "%type:{}%".format(settings.FLT_PBX)
        carrier_filter = "%type:{}%".format(settings.FLT_CARRIER)

        res = db.execute("""select * from (
select r.ruleid, r.groupid, r.prefix, r.gwlist, r.description as rule_description, g.id as gwgroupid, g.description as gwgroup_description from dr_rules as r left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '') where r.groupid = {}
) as t1 left join (
select r.ruleid as hf_ruleid, r.groupid as hf_groupid, hf.did as hf_fwddid, g.id as hf_gwgroupid, hf.prefix as hf_hardfwd_prefix from dsip_hardfwd as hf left join dr_rules as r on hf.dr_groupid = r.groupid left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '')
) as t2 on t1.prefix = t2.hf_hardfwd_prefix left join (
select r.ruleid as ff_ruleid, r.groupid as ff_groupid, ff.did as ff_fwddid, g.id as ff_gwgroupid, ff.prefix as ff_failfwd_prefix from dsip_failfwd as ff left join dr_rules as r on ff.dr_groupid = r.groupid left join dr_gw_lists as g on g.id = REPLACE(r.gwlist, '#', '')
) as t3 on t1.prefix = t3.ff_failfwd_prefix""".format(settings.FLT_INBOUND))

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
                debugException(ex, log_ex=False, print_ex=True, showstack=False)
                return showError(type="http", code=ex.status_code, msg="Flowroute Credentials Not Valid")

        return render_template('inboundmapping.html', rows=res, gwgroups=gwgroups, epgroups=epgroups, imported_dids=dids)

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
        db.close()



@app.route('/inboundmapping', methods=['POST'])
def addUpdateInboundMapping():
    """
    Adding and Updating of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # get form data
        ruleid = form['ruleid'] if 'ruleid' in form else None
        gwgroupid = form['gwgroupid'] if 'gwgroupid' in form else ''
        prefix = form['prefix'] if 'prefix' in form else ''
        description = 'name:{}'.format(form['rulename']) if 'rulename' in form else ''
        hardfwd_enabled = int(form['hardfwd_enabled'])
        hf_ruleid = form['hf_ruleid'] if 'hf_ruleid' in form else ''
        hf_gwgroupid = form['hf_gwgroupid'] if 'hf_gwgroupid' in form else ''
        hf_groupid = form['hf_groupid'] if 'hf_groupid' in form else ''
        hf_fwddid = form['hf_fwddid'] if 'hf_fwddid' in form else ''
        failfwd_enabled = int(form['failfwd_enabled'])
        ff_ruleid = form['ff_ruleid'] if 'ff_ruleid' in form else ''
        ff_gwgroupid = form['ff_gwgroupid'] if 'ff_gwgroupid' in form else ''
        ff_groupid = form['ff_groupid'] if 'ff_groupid' in form else ''
        ff_fwddid = form['ff_fwddid'] if 'ff_fwddid' in form else ''

        # we only support a single gwgroup at this time
        gwlist = '#{}'.format(gwgroupid) if len(gwgroupid) > 0 else ''
        fwdgroupid = None

        # Adding
        if not ruleid:
            inserts = []

            # don't allow duplicate entries
            if db.query(InboundMapping).filter(InboundMapping.prefix == prefix).filter(InboundMapping.groupid == settings.FLT_INBOUND).scalar():
                raise http_exceptions.BadRequest("Duplicate DID's are not allowed")

            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, description)
            inserts.append(IMap)

            if hardfwd_enabled:
                # find last forwarding rule
                lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(InboundMapping.groupid.desc()).first()
                db.commit()

                # Start forwarding routes with a groupid set in settings (default is 20000)
                if lastfwd is None:
                    fwdgroupid = settings.FLT_FWD_MIN
                else:
                    fwdgroupid = int(lastfwd.groupid) + 1

                gwlist = '#{}'.format(hf_gwgroupid) if len(hf_gwgroupid) > 0 else ''

                hfwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid))
                inserts.append(hfwd)

                hfwd_htable = dSIPHardFwd(prefix, hf_fwddid, fwdgroupid)
                inserts.append(hfwd_htable)

            if failfwd_enabled:
                # skip lookup if we just found the groupid
                if fwdgroupid is not None:
                    fwdgroupid += 1
                else:
                    # find last forwarding rule
                    lastfwd = db.query(InboundMapping).filter(InboundMapping.groupid >= settings.FLT_FWD_MIN).order_by(InboundMapping.groupid.desc()).first()
                    db.commit()

                    # Start forwarding routes with a groupid set in settings (default is 20000)
                    if lastfwd is None:
                        fwdgroupid = settings.FLT_FWD_MIN
                    else:
                        fwdgroupid = int(lastfwd.groupid) + 1

                    gwlist = '#{}'.format(ff_gwgroupid) if len(ff_gwgroupid) > 0 else ''

                ffwd = InboundMapping(fwdgroupid, '', gwlist, 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid))
                inserts.append(ffwd)

                ffwd_htable = dSIPFailFwd(prefix, ff_fwddid, fwdgroupid)
                inserts.append(ffwd_htable)

            db.add_all(inserts)

        # Updating
        else:
            db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).update(
                {'prefix': prefix, 'gwlist': gwlist, 'description': description}, synchronize_session=False)

            if hardfwd_enabled:
                db.query(InboundMapping).filter(InboundMapping.ruleid == hf_ruleid).update(
                    {'prefix': '', 'gwlist': '#{}'.format(hf_gwgroupid), 'description': 'name:Hard Forward from {} to DID {}'.format(prefix, hf_fwddid)}, synchronize_session=False)
                db.query(dSIPHardFwd).filter(dSIPHardFwd.prefix == prefix).update(
                    {'did': hf_fwddid, 'dr_groupid': hf_groupid}, synchronize_session=False)

            if failfwd_enabled:
                db.query(InboundMapping).filter(InboundMapping.ruleid == ff_ruleid).update(
                    {'prefix': '', 'gwlist': '#{}'.format(ff_gwgroupid), 'description': 'name:Failover Forward from {} to DID {}'.format(prefix, ff_fwddid)}, synchronize_session=False)
                db.query(dSIPFailFwd).filter(dSIPFailFwd.prefix == prefix).update(
                    {'did': ff_fwddid, 'dr_groupid': ff_groupid}, synchronize_session=False)

        db.commit()
        globals.reload_required = True
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
        db.close()


@app.route('/inboundmappingdelete', methods=['POST'])
def deleteInboundMapping():
    """
    Deleting of dr_rules table (inbound routes only)\n
    Partially Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']
        prefix = form['prefix']
        hf_ruleid = form['hf_ruleid']
        ff_ruleid = form['ff_ruleid']

        im_rule = db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid)
        im_rule.delete(synchronize_session=False)

        if len(hf_ruleid) > 0:
            hf_rule = db.query(InboundMapping).filter(InboundMapping.ruleid == hf_ruleid)
            hf_htable = db.query(dSIPHardFwd).filter(dSIPHardFwd.prefix == prefix)
            hf_rule.delete(synchronize_session=False)
            hf_htable.delete(synchronize_session=False)

        if len(ff_ruleid) > 0:
            ff_rule = db.query(InboundMapping).filter(InboundMapping.ruleid == ff_ruleid)
            ff_htable = db.query(dSIPFailFwd).filter(dSIPFailFwd.prefix == prefix)
            ff_rule.delete(synchronize_session=False)
            ff_htable.delete(synchronize_session=False)

        db.commit()

        globals.reload_required = True
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
        db.close()

def processInboundMappingImport(filename, groupid, pbxid, name, db):
    try:
        # Adding
        f = open(os.path.join(settings.UPLOAD_FOLDER, filename))
        csv_f = csv.reader(f)

        for row in csv_f:
            prefix = row[0]
            if len(row) > 1:
                pbxid = row[1]
            if len(row) > 2:
                description = 'name:{}'.format(row[2])
            else:
                description = 'name:{}'.format(name)
            IMap = InboundMapping(groupid, prefix, pbxid, description)
            db.add(IMap)

        db.commit()

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


@app.route('/inboundmappingimport',methods=['POST'])
def importInboundMapping():


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        # get form data
        gwid = form['gwid']
        name = form['name']

        if 'file' not in request.files:
            flash('No file part')
            return redirect(url_for('displayInboundMapping'))
        file = request.files['file']
        # if user does not select file, browser also
        # submit a empty part without filename
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)
        if file and allowed_file(file.filename,ALLOWED_EXTENSIONS=set(['csv'])):
            filename = secure_filename(file.filename)
            file.save(os.path.join(settings.UPLOAD_FOLDER, filename))
            processInboundMappingImport(filename,settings.FLT_INBOUND,gwid,name,db)
            flash('X number of file were imported')
            return redirect(url_for('displayInboundMapping',filename=filename))

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

        updateConfig(settings, teleblock)
        reload(settings)

        globals.reload_required = True
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
        db.close()


@app.route('/outboundroutes')
def displayOutboundRoutes():
    """
    Displaying of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        rows = db.query(OutboundRoutes).filter(
            (OutboundRoutes.groupid == settings.FLT_OUTBOUND) | (OutboundRoutes.groupid >= 10000)).outerjoin(
            dSIPLCR, dSIPLCR.dr_groupid == OutboundRoutes.groupid).add_columns(
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
    default_gwgroup = settings.FLT_OUTBOUND
    # id in dr_rules table
    ruleid = None
    from_prefix = None
    pattern = None

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        if form['ruleid']:
            ruleid = form['ruleid']

        groupid = form.get('groupid', default_gwgroup)
        if isinstance(groupid, str):
            if len(groupid) == 0 or (groupid == 'None'):
                groupid = settings.FLT_OUTBOUND

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

            # Add the lcr map
            if pattern != None:
                OLCRMap = dSIPLCR(pattern, from_prefix, groupid)
                db.add(OLCRMap)

        # Updating
        else:  # Handle the simple case of a To prefix being updated
            if (from_prefix is None) and (prefix is not None):
                oldgroupid = groupid
                if (groupid is None) or (groupid == "None"):
                    groupid = settings.FLT_OUTBOUND

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

                elif (prefix is not None) and (groupid == settings.FLT_OUTBOUND):  # Adding a From prefix to an existing To
                    # Create a new groupid
                    mlcr = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid >= settings.FLT_LCR_MIN).order_by(
                        dSIPLCR.dr_groupid.desc()).first()
                    db.commit()

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
                    })

                elif (int(groupid) >= 10000):  # Update existing pattern
                    db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == groupid).update({
                        'pattern': pattern, 'from_prefix': from_prefix})

                # Update the dr_rules table
                db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update({
                    'prefix': prefix, 'groupid': groupid, 'timerec': timerec, 'priority': priority,
                    'routeid': routeid, 'gwlist': gwlist, 'description': description
                })
                db.commit()

        db.commit()
        globals.reload_required = True
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
        db.close()


@app.route('/outboundroutesdelete', methods=['POST'])
def deleteOutboundRoute():
    """
    Deleting of dr_rules table (outbound routes only)\n
    Supports rule definitions for Kamailio Drouting module\n
    Documentation: `Drouting module <https://kamailio.org/docs/modules/4.4.x/modules/drouting.html>`_
    """


    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())

        ruleid = form['ruleid']

        OMap = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()

        d1 = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == OMap.groupid)
        d1.delete(synchronize_session=False)

        d = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid)
        d.delete(synchronize_session=False)

        db.commit()

        globals.reload_required = True
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
        db.close()


@app.route('/reloadkam')
def reloadkam():
    """
    Reload kamailio modules
    """

    prev_reload_val = globals.reload_required

    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        return_code = subprocess.call(['kamcmd', 'permissions.addressReload'])
        return_code += subprocess.call(['kamcmd', 'drouting.reload'])
        return_code += subprocess.call(['kamcmd', 'domain.reload'])
        return_code += subprocess.call(['kamcmd', 'htable.reload', 'tofromprefix'])
        return_code += subprocess.call(['kamcmd', 'htable.reload', 'maintmode'])
        return_code += subprocess.call(['kamcmd', 'htable.reload', 'calllimit'])
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
            globals.reload_required = False
        else:
            status_code = 0
            globals.reload_required = prev_reload_val
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
    return dict(reload_required=globals.reload_required,enterprise_enabled=globals.enterprise_enabled)


class CustomServer(Server):
    """ Customize the Flask server with our settings """

    def __init__(self):
        super().__init__(
            host=settings.DSIP_HOST,
            port=settings.DSIP_PORT
        )

        if len(settings.DSIP_SSL_CERT) > 0 and len(settings.DSIP_SSL_KEY) > 0:
            self.ssl_crt = settings.DSIP_SSL_CERT
            self.ssl_key = settings.DSIP_SSL_KEY

        #Enable debugging - check the environment variable first
        settings.DEBUG = os.getenv('DSIP_DEBUG',settings.DEBUG)
        if settings.DEBUG == True:
            self.use_debugger = True
            self.use_reloader = True
        else:
            self.use_debugger = None
            self.use_reloader = None
            self.threaded = True
            self.processes = 1

def sigHandler(signum=None, frame=None):
    """ Logic for trapped signals """
    # ignore SIGHUP
    if signum == 1:
        IO.logwarn("Received SIGHUP.. ignoring signal")

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

    #Initialize Globals
    globals.initialize()

    # Setup the Flask session manager with a random secret key
    flask_app.secret_key = os.urandom(12)

    # Add jinja2 filters
    flask_app.jinja_env.filters["attrFilter"] = attrFilter
    flask_app.jinja_env.filters["yesOrNoFilter"] = yesOrNoFilter
    flask_app.jinja_env.filters["noneFilter"] = noneFilter
    flask_app.jinja_env.filters["imgFilter"] = imgFilter
    flask_app.jinja_env.filters["domainTypeFilter"] = domainTypeFilter

    # Add jinja2 functions
    flask_app.jinja_env.globals.update(zip=zip)

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

    # Enable debugging - check the environment variable first
    settings.DEBUG = os.getenv('DSIP_DEBUG',settings.DEBUG)

    # configs depending on updated settings go here
    flask_app.env = "development" if settings.DEBUG else "production"
    flask_app.debug = settings.DEBUG

    # Flask App Manager configs
    manager = Manager(app)
    manager.add_command('runserver', CustomServer())

    # trap SIGHUP signals
    signal.signal(signal.SIGHUP, sigHandler)

    # start the server
    manager.run()

def checkDatabase():
   # Check database connection is still good
    try:
        db.execute('select 1')
        db.flush()
    except sql_exceptions.SQLAlchemyError as ex:
    # If not, close DB connection so that the SQL engine can get another one from the pool
        db.close()

if __name__ == "__main__":
    initApp(app)
