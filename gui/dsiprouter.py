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
    UAC, GatewayGroups, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher
from modules import flowroute
from modules.domain.domain_routes import domains
import globals
import settings

# global variables
app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.register_blueprint(domains)
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

        if form['password'] == settings.PASSWORD and form['username'] == settings.USERNAME:
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

            Gwgroup = GatewayGroups(name)
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


@app.route('/pbx')
def displayPBX():
    """
    Display PBX / Endpoints in the view
    """
    try:
        if not session.get('logged_in'):
            return redirect(url_for('index'))

        if (settings.DEBUG):
            debugEndpoint()

        res = db.query(Gateways).outerjoin(
            dSIPMultiDomainMapping, Gateways.gwid == dSIPMultiDomainMapping.pbx_id).outerjoin(
            dSIPDomainMapping, Gateways.gwid == dSIPDomainMapping.pbx_id).outerjoin(
            Subscribers, Gateways.gwid == Subscribers.rpid).add_columns(
            Gateways.gwid, Gateways.description,
            Gateways.address, Gateways.strip,
            Gateways.pri_prefix,
            dSIPMultiDomainMapping.enabled.label('fusionpbx_enabled'),
            dSIPMultiDomainMapping.db_host,
            dSIPMultiDomainMapping.db_username,
            dSIPMultiDomainMapping.db_password,
            Subscribers.rpid, Subscribers.username,
            Subscribers.password, Subscribers.domain,
            dSIPDomainMapping.enabled.label('freepbx_enabled')
        ).filter(Gateways.type == settings.FLT_PBX).all()
        return render_template('pbxs.html', rows=res, DEFAULT_AUTH_DOMAIN=settings.DOMAIN)

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


@app.route('/pbx', methods=['POST'])
def addUpdatePBX():
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
        name = form['name']
        ip_addr = form["ip_addr"] if len(form['ip_addr']) > 0 else ""
        strip = form['strip'] if len(form['strip']) > 0 else "0"
        prefix = form['prefix'] if len(form['prefix']) > 0 else ""
        authtype = form['authtype']
        fusionpbx_db_server = form['fusionpbx_db_server']
        fusionpbx_db_username = form['fusionpbx_db_username']
        fusionpbx_db_password = form['fusionpbx_db_password']
        auth_username = form['auth_username']
        auth_password = form['auth_password']
        auth_domain = form['auth_domain'] if len(form['auth_domain']) > 0 else settings.DOMAIN

        multi_tenant_domain_enabled = False
        multi_tenant_domain_type = dSIPMultiDomainMapping.FLAGS.TYPE_UNKNOWN.value
        single_tenant_domain_enabled = False
        single_tenant_domain_type = dSIPDomainMapping.FLAGS.TYPE_UNKNOWN.value

        # add any other multi tenant pbx to this list as they are supported
        # ex) add or statements: if ... or .. or ... elif ... or ...
        if int(form['fusionpbx_db_enabled']):
            multi_tenant_domain_enabled = True
            multi_tenant_domain_type = dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value
        # add any other single tenant pbx to this list as they are supported
        else:
            single_tenant_domain_enabled = True
        #elif int(form['freepbx_enabled']):
        #    single_tenant_domain_enabled = True
        #    single_tenant_domain_type = dSIPDomainMapping.FLAGS.TYPE_FREEPBX.value

        # Adding
        if len(gwid) <= 0:
            Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)
            db.add(Gateway)
            db.flush()

            if authtype == "ip":
                Addr = Address(name, ip_addr, 32, settings.FLT_PBX)
                db.add(Addr)
            else:
                # verify we won't break (username,domain) unique key constraint
                if db.query(Subscribers).filter(Subscribers.username == auth_username,
                                                Subscribers.domain == auth_domain).scalar():
                    db.rollback()
                    db.flush()
                    return showError(type="db", code=400,
                                     msg="Entry for {}@{} already exists".format(auth_username, auth_domain))
                Subscriber = Subscribers(auth_username, auth_password, auth_domain, Gateway.gwid)
                db.add(Subscriber)

            # enable domain routing for all pbx in multi tenant db
            if multi_tenant_domain_enabled:
                pass
                # put required VALUES for all multi tenant use cases here
            # disable domain routing for all pbx in multi tenant db
            else:
                pass
                # put required DEFAULTS for all multi tenant use cases here

            # specific use cases go here
            if multi_tenant_domain_type == dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value:
                PBXMultiMapping = dSIPMultiDomainMapping(Gateway.gwid, fusionpbx_db_server, fusionpbx_db_username,
                                                         fusionpbx_db_password, type=multi_tenant_domain_type)

                # Add another Gateway that represents the External interface, which is 5080 by default
                name = name + " external"
                # Test ip address to see if it contains a port number
                index = ip_addr.find(":")
                if index > 0:
                    ip_addr = ip_addr[:index - 1]
                    ip_addr = ip_addr + ":5080"
                else:
                    ip_addr = ip_addr + ":5080"

                Gateway2 = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)
                db.add(Gateway2)
            # create an entry for fusion pbx that is disabled
            else:
                PBXMultiMapping = dSIPMultiDomainMapping(Gateway.gwid, fusionpbx_db_server, fusionpbx_db_username,
                                                         fusionpbx_db_password, type=multi_tenant_domain_type,
                                                         enabled=dSIPMultiDomainMapping.FLAGS.DOMAIN_DISABLED.value)

            # required entries guranteed to be created
            db.add(PBXMultiMapping)

            # enable domain routing for this pbx
            #if single_tenant_domain_enabled:
            #    # put required VALUES for all single tenant use cases here
            #    PBXDomain = Domain(ip_addr)
            #    PBXDomainAttr = DomainAttrs(ip_addr)
            #    db.add(PBXDomain)
            #    db.add(PBXDomainAttr)
            #    db.flush()

            #    PBXMapping = dSIPDomainMapping(Gateway.gwid, '', '',type=single_tenant_domain_type)
            # create an entry for this pbx that is disabled (must not match any domain)
            #else:
            #    # put required DEFAULTS for all single tenant use cases here
            #    PBXDomain = Domain(domain="", did="")
            #    PBXDomainAttr = DomainAttrs(did="", value="")
            #    db.add(PBXDomain)
            #    db.add(PBXDomainAttr)
            #    db.flush()

            #   PBXMapping = dSIPDomainMapping(Gateway.gwid, PBXDomain.id, [PBXDomainAttr.id],
           #                                    enabled=dSIPDomainMapping.FLAGS.DOMAIN_DISABLED.value)

                # specific use cases go here

            # required entries guranteed to be created
            #db.add(PBXMapping)

        # Updating
        else:
            # Update the Gateway table
            db.query(Gateways).filter(Gateways.gwid == gwid).update(
                {'description': "name:" + name, 'address': ip_addr, 'strip': strip, 'pri_prefix': prefix},
                synchronize_session=False)

            # enable domain routing for all pbx in multi tenant db
            if multi_tenant_domain_enabled:
                pass
                # put required VALUES for all multi tenant use cases here
            # disable domain routing for all pbx in multi tenant db
            else:
                pass
                # put required DEFAULTS for multi single tenant use cases here

            # specific use cases go here
            if multi_tenant_domain_type == dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value:
                db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwid).update(
                    {'pbx_id': gwid, 'db_host': fusionpbx_db_server, 'db_username': fusionpbx_db_username,
                     'db_password': fusionpbx_db_password, 'enabled': dSIPMultiDomainMapping.FLAGS.DOMAIN_ENABLED.value},
                    synchronize_session=False)
            # disable fusion pbx db
            else:
                db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == gwid).update(
                    {'enabled': dSIPMultiDomainMapping.FLAGS.DOMAIN_DISABLED.value}, synchronize_session=False)

            # enable domain routing for this pbx
            #if single_tenant_domain_enabled:
            #
                # put required VALUES for all single tenant use cases here
            #    PBXMapping = db.query(dSIPDomainMapping).filter(dSIPDomainMapping.pbx_id == gwid).first()
            #    PBXMapping.enabled = dSIPDomainMapping.FLAGS.DOMAIN_ENABLED.value

            #    # TODO: support adding / editing multiple domain attributes
            #    db.query(Domain).filter(Domain.id == PBXMapping.domain_id).update(
            #        {'domain': ip_addr, 'did': ip_addr, 'last_modified': datetime.utcnow()}, synchronize_session=False)
                # make sure domain has attributes
            #    if len(PBXMapping.attr_list) > 0:
            #        attr_list = list(map(int, filter(None, PBXMapping.attr_list.split(","))))
            #    db.query(DomainAttrs).filter(DomainAttrs.id.in_(attr_list)).update(
            #        {'did': ip_addr, 'value': '', 'last_modified': datetime.utcnow()},
            #        synchronize_session=False)
            # disable domain routing for this pbx
            #else:
            #    # put required DEFAULTS for all single tenant use cases here
            #    PBXMapping = db.query(dSIPDomainMapping).filter(dSIPDomainMapping.pbx_id == gwid).first()
            #    PBXMapping.enabled = dSIPDomainMapping.FLAGS.DOMAIN_DISABLED.value

            #    db.query(Domain).filter(Domain.id == PBXMapping.domain_id).update(
            #        {'did': '', 'value': '', 'last_modified': datetime.utcnow()}, synchronize_session=False)
                # make sure domain has attributes
            #    if len(PBXMapping.attr_list) > 0:
            #        attr_list = list(map(int, filter(None, PBXMapping.attr_list.split(","))))
            #    db.query(DomainAttrs).filter(DomainAttrs.id.in_(attr_list)).update(
            #        {'did': '', 'value': '', 'last_modified': datetime.utcnow()}, synchronize_session=False)

            # specific use cases go here
            # if single_tenant_domain_type == dSIPDomainMapping.FLAGS.TYPE_FREEPBX.value:

            # Update Subscribers table if auth credentials are being used
            if authtype == "userpwd":
                # Remove ip address from address table
                Addr = db.query(Address).filter(Address.tag.contains("name:{}".format(name)))
                Addr.delete(synchronize_session=False)

                # Add the username and password that will be used for authentication
                # Check if the entry in the subscriber table already exists
                exists = db.query(Subscribers).filter(Subscribers.rpid == gwid).scalar()
                if exists:
                    db.query(Subscribers).filter(Subscribers.rpid == gwid).update(
                        {'username': auth_username, 'password': auth_password, 'domain': auth_domain, 'rpid': gwid},
                        synchronize_session=False)
                else:
                    # verify we won't break (username,domain) unique key constraint
                    if db.query(Subscribers).filter(Subscribers.username == auth_username,
                                                    Subscribers.domain == auth_domain).scalar():
                        db.rollback()
                        db.flush()
                        return showError(type="db", code=400,
                                         msg="Entry for {}@{} already exists".format(auth_username, auth_domain))
                    else:
                        Subscriber = Subscribers(auth_username, auth_password, auth_domain, gwid)
                        db.add(Subscriber)
            # Update the Address table with the new ip address
            else:
                # remove pbx from subscriber table
                Subscriber = db.query(Subscribers).filter(Subscribers.rpid == gwid)
                if Subscriber:
                    Subscriber.delete(synchronize_session=False)

                db.query(Address).filter(Address.tag.contains("name:{}".format(name))).update(
                    {'ip_addr': ip_addr}, synchronize_session=False)

        db.commit()
        globals.reload_required = True
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

        res = db.execute(
            'select r.ruleid,r.groupid,r.prefix,r.gwlist,r.description as notes, g.gwid, g.description from dr_rules r,dr_gateways g where r.gwlist = g.gwid and r.groupid = {}'.format(settings.FLT_INBOUND))
        gateways = db.query(Gateways).filter(Gateways.type == settings.FLT_PBX).all()
        # sort gateways by name
        gateways.sort(key=lambda x: strFieldsToDict(x.description)['name'])

        dids = []
        if len(settings.FLOWROUTE_ACCESS_KEY) > 0 and len(settings.FLOWROUTE_SECRET_KEY) > 0:
            try:
                dids = numbers_api.getNumbers()
            except http_exceptions.HTTPException as ex:
                debugException(ex, log_ex=False, print_ex=True, showstack=False)
                return showError(type="http", code=ex.status_code, msg="Flowroute Credentials Not Valid")

        return render_template('inboundmapping.html', rows=res, gwlist=gateways, imported_dids=dids)

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

        # id in dr_rules table
        ruleid = None
        if form['ruleid']:
            ruleid = form['ruleid']

        # get form data
        gwid = form['gwid'] if 'gwid' in form else ''
        alt_gwid = form['alt_gwid'] if 'alt_gwid' in form else ''
        prefix = form['prefix'] if 'prefix' in form else ''
        notes = form['notes'] if 'notes' in form else ''

        # we only support 2 pbx's so format gwlist accordingly
        gateways = []
        for gw in gwid, alt_gwid:
            if len(gw) > 0:
                gateways.append(gw)
        gwlist = ','.join(gateways)


        # Adding
        if not ruleid:
            IMap = InboundMapping(settings.FLT_INBOUND, prefix, gwlist, notes)
            db.add(IMap)

        # Updating
        else:
            db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid).update(
                {'prefix': prefix, 'gwlist': gwlist, 'description': notes}, synchronize_session=False)

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
        d = db.query(InboundMapping).filter(InboundMapping.ruleid == ruleid)
        d.delete(synchronize_session=False)
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

def processInboundMappingImport(filename,groupid,pbxid,notes,db):
    try:

        # Adding
        f = open(os.path.join(settings.UPLOAD_FOLDER, filename))
        csv_f = csv.reader(f)

        for row in csv_f:
            if len(row) > 1:
                pbxid=row[1]
            if len(row) > 2:
                notes=row[2]
            IMap = InboundMapping(groupid, row[0], pbxid, notes)
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
        notes = form['notes']

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
            processInboundMappingImport(filename,settings.FLT_INBOUND,gwid,notes,db)
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
    return dict(reload_required=globals.reload_required)


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
