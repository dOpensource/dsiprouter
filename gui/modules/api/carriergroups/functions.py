import json, sys
from flask import request, session, redirect, url_for, render_template
from sqlalchemy import exc as sql_exceptions, text, cast, Integer, func
from werkzeug import exceptions as http_exceptions
# make sure the generated source files are imported instead of the template ones
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')
import settings
from shared import debugException, debugEndpoint, stripDictVals, strFieldsToDict, dictToStrFields, showError
from database import startSession, DummySession, Gateways, Address, UAC, GatewayGroups, Dispatcher, DsipGwgroup2LB, \
    OutboundRoutes
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from util.networking import safeUriToHost, safeFormatSipUri, safeStripPort, encodeSipUser


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

        query = db.query(
            GatewayGroups.id,
            GatewayGroups.description,
            GatewayGroups.gwlist,
            UAC.r_username,
            UAC.auth_password,
            UAC.r_domain,
            UAC.auth_username,
            UAC.auth_proxy,
            cast(DsipGwgroup2LB.enabled, Integer).label('lb_enabled')
        ).outerjoin(
            UAC, GatewayGroups.id == UAC.l_uuid
        ).outerjoin(
            DsipGwgroup2LB, GatewayGroups.id == DsipGwgroup2LB.gwgroupid
        ).filter(
            GatewayGroups.description.regexp_match(GatewayGroups.FILTER.CARRIER.value)
        )

        # res must be a list()
        if gwgroup is not None and gwgroup != "":
            res = [
                query.filter(
                    GatewayGroups.id == gwgroup
                ).first()
            ]
        else:
            res = query.all()

        return render_template('carriergroups.html', rows=res)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

def addUpdateCarrierGroups(data=None):
    """
    Add or Update a group of carriers
    """

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        if data is None:
            # called from flask url router, make sure user is logged in
            # TODO: toss this in a decorator func with error handling and use for gui auth checks
            if not session.get('logged_in'):
                return redirect(url_for('index'))

            # grab data from gui form
            form = stripDictVals(request.form.to_dict())
        else:
            # Set the form variables to data parameter
            form = data

        gwgroup = form['gwgroupid']
        name = form['name']
        lb_enabled = int(form['lb_enabled']) if 'lb_enabled' in form else 0
        new_name = form['new_name'] if 'new_name' in form else ''
        plugin_name = form['plugin_name'] if 'plugin_name' in form else ''
        authtype = form['authtype'] if 'authtype' in form else ''
        username = form['r_username'] if 'r_username' in form else ''
        auth_username = form['auth_username'] if 'auth_username' in form else ''
        auth_password = form['auth_password'] if 'auth_password' in form else ''
        auth_domain = form['auth_domain'] if 'auth_domain' in form else settings.DEFAULT_AUTH_DOMAIN
        auth_proxy = form['auth_proxy'] if 'auth_proxy' in form else ''

        # Workaround: for Twilio Elastic SIP and Programmable SIP
        # Set the Realm to sip.twilio.com if the domain contains a pstn.twilio.com or sip.twilio.com domain.
        # Otherwise, set it to the name of the auth domain
        auth_realm = "sip.twilio.com" if "twilio.com" in auth_domain else auth_domain

        # format data
        if authtype == "userpwd" and (plugin_name is None or plugin_name == ''):
            auth_domain = safeUriToHost(auth_domain)
            if auth_domain is None:
                raise http_exceptions.BadRequest("Auth domain hostname/address is malformed")
            if len(auth_proxy) == 0:
                auth_proxy = auth_domain
            auth_proxy = safeFormatSipUri(auth_proxy)
            if auth_proxy is None:
                raise http_exceptions.BadRequest('Auth domain or proxy is malformed')
            if len(auth_username) == 0:
                auth_username = username
            auth_username = encodeSipUser(auth_username)

        # Adding
        if len(gwgroup) <= 0:
            Gwgroup = GatewayGroups(name, type=settings.FLT_CARRIER)
            db.add(Gwgroup)
            db.flush()
            gwgroup = Gwgroup.id

            # Add auth_domain(aka registration server) to the gateway list
            if authtype == "userpwd" and (plugin_name is None or plugin_name == ''):
                Uacreg = UAC(gwgroup, username, auth_password, realm=auth_realm, auth_username=auth_username, auth_proxy=auth_proxy,
                    local_domain=settings.EXTERNAL_FQDN, remote_domain=auth_domain)
                Addr = Address(name + "-uac", auth_domain, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                db.add(Uacreg)
                db.add(Addr)

        # Updating
        else:
            # config form
            if len(name) > 0:
                Gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == gwgroup).first()
                gwgroup_fields = strFieldsToDict(Gwgroup.description)
                old_name = gwgroup_fields['name']
                gwgroup_fields['name'] = name
                Gwgroup.description = dictToStrFields(gwgroup_fields)

                Addr = db.query(Address).filter(
                    Address.tag.regexp_match(f'name:{old_name}-uac(,|$)')
                ).first()
                if Addr is not None:
                    addr_fields = strFieldsToDict(Addr.tag)
                    addr_fields['name'] = 'name:{}-uac'.format(new_name)
                    Addr.tag = dictToStrFields(addr_fields)

            # auth form
            if authtype == "userpwd" and (plugin_name is None or plugin_name == ''):
                # update uacreg if exists, otherwise create
                if not db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                    {
                        'l_username': username, 'r_username': username, 'auth_username': auth_username,
                        'auth_password': auth_password, 'r_domain': auth_domain, 'realm': auth_realm,
                        'auth_proxy': auth_proxy, 'flags': UAC.FLAGS.REG_ENABLED.value
                    },
                    synchronize_session=False
                ):
                    Uacreg = UAC(gwgroup, username, auth_password, realm=auth_domain, auth_username=auth_username,
                                    auth_proxy=auth_proxy, local_domain=settings.EXTERNAL_FQDN, remote_domain=auth_domain)
                    db.add(Uacreg)

                # update address if exists, otherwise create
                if not db.query(Address).filter(
                    Address.tag.contains("name:{}-uac".format(name))
                ).update({'ip_addr': auth_domain}, synchronize_session=False):
                    Addr = Address(name + "-uac", auth_domain, 32, settings.FLT_CARRIER, gwgroup=gwgroup)
                    db.add(Addr)
            else:
                # delete uacreg and address if they exist
                db.query(UAC).filter(UAC.l_uuid == gwgroup).delete(synchronize_session=False)
                db.query(Address).filter(
                    Address.tag.regexp_match(f'name:{name}-uac(,|$)')
                ).delete(synchronize_session=False)

        # toggle load balancing based on user input
        # TODO: this WILL be changed in the future when we refactor load balancing
        fields = strFieldsToDict(Gwgroup.description)
        fields['lb'] = gwgroup
        Gwgroup.description = dictToStrFields(fields)
        db.flush()
        db.execute(
            text("UPDATE dsip_gwgroup2lb SET enabled = :enabled WHERE gwgroupid = :gwgroupid"),
            {'enabled': lb_enabled, 'gwgroupid': gwgroup}
        )

        db.commit()
        getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'] = True
        if data is None:
            return displayCarrierGroups()
        else:
            return gwgroup

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
            carriers = [
                db.query(
                    Gateways.gwid, Gateways.description, Gateways.address, Gateways.strip, Gateways.pri_prefix,
                    Dispatcher.attrs.label("dispatcher_attrs")
                ).filter(
                    Gateways.gwid == gwid
                ).outerjoin(
                    Dispatcher,
                    Dispatcher.description.regexp_match(f'gwid={gwid}(;|$)')
                ).first()
            ]
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
                carriers = db.query(
                    Gateways.gwid, Gateways.description, Gateways.address, Gateways.strip, Gateways.pri_prefix,
                    Dispatcher.attrs.label("dispatcher_attrs")
                ).filter(
                    Gateways.gwid.in_(gwlist)
                ).outerjoin(
                    Dispatcher,
                    Dispatcher.description.regexp_match(func.CONCAT('gwid=', Gateways.gwid, '(;|$)'))
                ).all()
                rules = db.query(OutboundRoutes).filter(OutboundRoutes.groupid == settings.FLT_OUTBOUND).all()
                for gateway_id in filter(None, Gatewaygroup.gwlist.split(",")):
                    gateway_rules = {}
                    for rule in rules:
                        if gateway_id in filter(None, rule.gwlist.split(',')):
                            gateway_rules[rule.ruleid] = strFieldsToDict(rule.description)['name']
                    carrier_rules.append(json.dumps(gateway_rules, separators=(',', ':')))

        # get all carriers
        else:
            carriers = db.query(
                Gateways.gwid, Gateways.description, Gateways.address, Gateways.strip, Gateways.pri_prefix,
                Dispatcher.attrs.label("dispatcher_attrs")
            ).filter(
                Gateways.type == settings.FLT_CARRIER
            ).outerjoin(
                Dispatcher,
                Dispatcher.description.regexp_match(func.CONCAT('gwid=', Gateways.gwid, '(;|$)'))
            ).all()
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
        db.rollback()
        db.flush()
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

def addUpdateCarriers(data=None):
    """
    Add or Update a carrier
    """

    db = DummySession()
    newgwid = None

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        if data is None:
            # called from flask url router, make sure user is logged in
            # TODO: toss this in a decorator func with error handling and use for gui auth checks
            if not session.get('logged_in'):
                return redirect(url_for('index'))
            # grab data from gui form
            form = stripDictVals(request.form.to_dict())
        else:
            # Set the form variables to data parameter
            form = data

        
        # match what the API would send us
        if 'gwgroupid' in form:
            form['gwgroupid'] = str(form['gwgroupid'])

        # match what the UI would send us
        if 'gwgroup' in form:
            form['gwgroupid'] = str(form['gwgroup'])
        if 'ip_addr' in form:
            form['hostname'] = str(form['ip_addr'])


        gwid = form['gwid'] if 'gwid' in form else ''
        gwgroup = form['gwgroupid'] if len(form['gwgroupid']) > 0 else ''
        name = form['name'] if len(form['name']) > 0 else ''
        hostname = form['hostname'] if len(form['hostname']) > 0 else ''
        strip = form['strip'] if len(form['strip']) > 0 else '0'
        prefix = form['prefix'] if len(form['prefix']) > 0 else ''
        rweight = int(form['rweight']) if form.get('rweight', '') != '' else 1

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

                # Create dispatcher group with the set id being the gateway group id
                dispatcher = Dispatcher(setid=gwgroup, destination=sip_addr, rweight=rweight, name=name, gwid=gwid)
                db.add(dispatcher)
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

            # update dispatcher entry
            if db.query(Dispatcher).filter(
                Dispatcher.description.regexp_match(f'gwid={gwid}(;|$)')
            ).update({
                "attrs": Dispatcher.buildAttrs(rweight=rweight)
            }, synchronize_session=False):
                pass
            # add new dispatcher entry if it did not exist (gwgroup must also exist)
            elif len(gwgroup) > 0:
                dispatcher = Dispatcher(setid=gwgroup, destination=sip_addr, rweight=rweight, name=name, gwid=gwid)
                db.add(dispatcher)

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

        if data is None:
            return displayCarriers(gwgroup=gwgroup, newgwid=newgwid)
        return gwid

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        db.rollback()
        db.flush()
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()
