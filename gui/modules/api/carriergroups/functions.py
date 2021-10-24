from shared import getInternalIP, getExternalIP, updateConfig, getCustomRoutes, debugException, debugEndpoint, \
    stripDictVals, strFieldsToDict, dictToStrFields, allowed_file, showError, hostToIP, IO, objToDict, StatusCodes, \
    safeUriToHost, safeFormatSipUri, safeStripPort
from database import db_engine, SessionLoader, DummySession, Gateways, Address, InboundMapping, OutboundRoutes, Subscribers, \
    dSIPLCR, UAC, GatewayGroups, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, dSIPMaintModes, \
    dSIPCallLimits, dSIPHardFwd, dSIPFailFwd
from sqlalchemy import func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
import settings, globals

def addUpdateCarrierGroups(data=None):
    """
    Add or Update a group of carriers
    """

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        if data is not None:
            # Set the data parameter to form variable
            form = data
        else:
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
        if data is None:
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
