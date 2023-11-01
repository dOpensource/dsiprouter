from flask import request
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
import settings
from shared import debugException, debugEndpoint, stripDictVals, strFieldsToDict, dictToStrFields, showError
from database import startSession, DummySession, Gateways, Address, UAC, GatewayGroups
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
from util.networking import safeUriToHost, safeFormatSipUri, safeStripPort

def addUpdateCarrierGroups(data=None):
    """
    Add or Update a group of carriers
    """

    global displayCarrierGroups

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = startSession()

        if data is not None:
            # Set the form variables to data parameter
            form = data
        else:
            form = stripDictVals(request.form.to_dict())

        gwgroup = form['gwgroup']
        name = form['name']
        new_name = form['new_name'] if 'new_name' in form else ''
        plugin_name = form['plugin_name'] if 'plugin_name' in form else ''
        authtype = form['authtype'] if 'authtype' in form else ''
        r_username = form['r_username'] if 'r_username' in form else ''
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
            if authtype == "userpwd" and (plugin_name is None or plugin_name == ''):
                Uacreg = UAC(gwgroup, r_username, auth_password, realm=auth_realm, auth_username=auth_username, auth_proxy=auth_proxy,
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

                Addr = db.query(Address).filter(Address.tag.contains("name:{}-uac".format(old_name))).first()
                if Addr is not None:
                    addr_fields = strFieldsToDict(Addr.tag)
                    addr_fields['name'] = 'name:{}-uac'.format(new_name)
                    Addr.tag = dictToStrFields(addr_fields)

            # auth form
            if authtype == "userpwd" and (plugin_name is None or plugin_name == ''):
                # update uacreg if exists, otherwise create
                if not db.query(UAC).filter(UAC.l_uuid == gwgroup).update(
                    {'l_username': r_username, 'r_username': r_username, 'auth_username': auth_username,
                        'auth_password': auth_password, 'r_domain': auth_domain, 'realm': auth_realm,
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

        if data is not None:
            # Set the form variables to data parameter
            form = data
            # Convert gwgroup to a string
            gwgroup = form['gwgroup'] if 'gwgroup' in form else ''
            if gwgroup is not None:
                form['gwgroup'] = str(gwgroup)
        else:
            form = stripDictVals(request.form.to_dict())



        gwid = form['gwid'] if 'gwid' in form else ''
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
        if data is None:
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
