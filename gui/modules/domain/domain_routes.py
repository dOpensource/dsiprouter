from flask import Blueprint, session
from sqlalchemy import case, func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from database import SessionLoader, DummySession, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, Gateways, Address
from modules.api.api_routes import addEndpointGroups
from shared import *
import settings
import globals


domains = Blueprint('domains', __name__)


# Gateway to IP - A gateway can be a carrier or PBX
def gatewayIdToIP(pbx_id, db):
    gw = db.query(Gateways).filter(Gateways.gwid == pbx_id).first()
    if gw is not None:
        return gw.address

def addDomain(domain, authtype, pbxs, notes, db):
    # Create the domain because we need the domain id
    PBXDomain = Domain(domain=domain, did=domain)
    db.add(PBXDomain)
    db.flush()

    # Check if list of PBX's
    if pbxs:
        pbx_list = re.split(' |,',pbxs)
    else:
        pbx_list = []

    # If list is found
    if len(pbx_list) > 1 and authtype == "passthru":
        pbx_id=pbx_list[0]
    else:
        #Else Single value was submitted
        pbx_id = pbxs

    # Implement Passthru authentication to the first PBX on the list.
    # because Passthru Registration only works against one PBX
    if authtype == "passthru":
        PBXDomainAttr1 = DomainAttrs(did=domain, name='pbx_list', value=pbx_id)
        PBXDomainAttr2 = DomainAttrs(did=domain, name='pbx_type', value="0")
        PBXDomainAttr3 = DomainAttrs(did=domain, name='created_by', value="0")
        PBXDomainAttr4 = DomainAttrs(did=domain, name='domain_auth', value=authtype)
        PBXDomainAttr5 = DomainAttrs(did=domain, name='description', value="notes:{}".format(notes))
        PBXDomainAttr6 = DomainAttrs(did=domain, name='pbx_ip', value=gatewayIdToIP(pbx_id, db))

        db.add(PBXDomainAttr1)
        db.add(PBXDomainAttr2)
        db.add(PBXDomainAttr3)
        db.add(PBXDomainAttr4)
        db.add(PBXDomainAttr5)
        db.add(PBXDomainAttr6)

    # MSTeams Support
    elif authtype == "msteams":
        # Set of MS Teams Proxies
        msteams_dns_endpoints=settings.MSTEAMS_DNS_ENDPOINTS
        msteams_ip_endpoints=settings.MSTEAMS_IP_ENDPOINTS

        # Attributes to specify that the domain was created manually
        PBXDomainAttr1 = DomainAttrs(did=domain, name='pbx_list', value="{}".format(",".join(msteams_dns_endpoints)))
        PBXDomainAttr2 = DomainAttrs(did=domain, name='pbx_type', value="0")
        PBXDomainAttr3 = DomainAttrs(did=domain, name='created_by', value="0")
        PBXDomainAttr4 = DomainAttrs(did=domain, name='domain_auth', value=authtype)
        PBXDomainAttr5 = DomainAttrs(did=domain, name='description', value="notes:{}".format(notes))
        # Serial folking will be used to forward registration info to multiple PBX's
        PBXDomainAttr6 = DomainAttrs(did=domain, name='dispatcher_alg_reg', value="4")
        PBXDomainAttr7 = DomainAttrs(did=domain, name='dispatcher_alg_in', value="4")
        # Create entry in dispatcher and set dispatcher_set_id in domain_attrs
        PBXDomainAttr8 = DomainAttrs(did=domain, name='dispatcher_set_id', value=PBXDomain.id)

        # Use the default MS Teams SIP Proxy List if one isn't defined
        print("pbx list {}".format(pbx_list))
        if len(pbx_list) == 0 or pbx_list[0] == '':
            for endpoint in msteams_dns_endpoints:
                # Logic to handle when dSIPRouter is behind NAT (aka servernat is enabled)
                if settings.EXTERNAL_IP_ADDR != settings.INTERNAL_IP_ADDR:
                    socket_addr = settings.INTERNAL_IP_ADDR
                else:
                    socket_addr = settings.EXTERNAL_IP_ADDR

                dispatcher = Dispatcher(setid=PBXDomain.id, destination=endpoint, attrs="socket=tls:{}:5061;ping_from=sip:{}".format(socket_addr,domain),description='msteam_endpoint:{}'.format(endpoint))
                db.add(dispatcher)

        db.add(PBXDomainAttr1)
        db.add(PBXDomainAttr2)
        db.add(PBXDomainAttr3)
        db.add(PBXDomainAttr4)
        db.add(PBXDomainAttr5)
        db.add(PBXDomainAttr6)
        db.add(PBXDomainAttr7)
        db.add(PBXDomainAttr8)


        # Check if the MSTeams IP(s) that send us OPTION messages is in the the address table
        for endpoint_ip in msteams_ip_endpoints:
            address_query = db.query(Address).filter(Address.ip_addr == endpoint_ip).first()
            if address_query is None:
                Addr = Address("msteams-sbc", endpoint_ip, 32, settings.FLT_MSTEAMS)
                db.add(Addr)


        # Add Endpoint group to enable Inbound Mapping
        endpointGroup = {"name":domain,"endpoints":None}
        endpoints = []
        for hostname in msteams_dns_endpoints:
            endpoints.append({"hostname":hostname,"description":"msteams_endpoint","maintmode":False});

        endpointGroup['endpoints'] = endpoints
        addEndpointGroups(endpointGroup,"msteams",domain)

    # Implement external authentiction to either Realtime DB or Local Subscriber table
    else:
        # Attributes to specify that the domain was created manually
        PBXDomainAttr1 = DomainAttrs(did=domain, name='pbx_list', value=str(pbx_list))
        PBXDomainAttr2 = DomainAttrs(did=domain, name='pbx_type', value="0")
        PBXDomainAttr3 = DomainAttrs(did=domain, name='created_by', value="0")
        PBXDomainAttr4 = DomainAttrs(did=domain, name='domain_auth', value=authtype)
        PBXDomainAttr5 = DomainAttrs(did=domain, name='description', value="notes:{}".format(notes))
        # Serial folking will be used to forward registration info to multiple PBX's
        PBXDomainAttr6 = DomainAttrs(did=domain, name='dispatcher_alg_reg', value="8")
        PBXDomainAttr7 = DomainAttrs(did=domain, name='dispatcher_alg_in', value="4")
        # Create entry in dispatcher and set dispatcher_set_id in domain_attrs
        PBXDomainAttr8 = DomainAttrs(did=domain, name='dispatcher_set_id', value=PBXDomain.id)
        for pbx_id in pbx_list:
            dispatcher = Dispatcher(setid=PBXDomain.id, destination=gatewayIdToIP(pbx_id, db), description='pbx_id:{}'.format(pbx_id))
            db.add(dispatcher)

        db.add(PBXDomainAttr1)
        db.add(PBXDomainAttr2)
        db.add(PBXDomainAttr3)
        db.add(PBXDomainAttr4)
        db.add(PBXDomainAttr5)
        db.add(PBXDomainAttr6)
        db.add(PBXDomainAttr7)
        db.add(PBXDomainAttr8)

@domains.route("/domains/msteams/<int:id>", methods=['GET'])
def configureMSTeams(id):

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        if not session.get('logged_in'):
            return render_template('index.html')

        domain_query = db.query(Domain).filter(Domain.id == id)
        domain = domain_query.first()


        return render_template('msteams.html', domainid=id, domain=domain)

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
        debugException(ex, log_ex=True, print_ex=True, showstack=True)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@domains.route("/domains", methods=['GET'])
def displayDomains():

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        # sql1 = "select domain.id,domain.domain,dsip_domain_mapping.type,dsip_domain_mapping.pbx_id,dr_gateways.description from domain left join dsip_domain_mapping on domain.id = dsip_domain_mapping.domain_id left join dr_gateways on dsip_domain_mapping.pbx_id = dr_gateways.gwid;"
        sql1 = "select distinct domain.did as domain, domain.id, value as type from domain_attrs join domain on domain.did = domain_attrs.did where name='pbx_type';"
        res = db.execute(sql1)

        sql2 = """select distinct domain_attrs.did, pbx_list, domain_auth, creator, description from domain_attrs join
            ( select did,value as pbx_list from domain_attrs where name='pbx_list' ) t1
            on t1.did=domain_attrs.did join
            ( select did,value as description from domain_attrs where name='description' ) t2
            on t2.did=domain_attrs.did join
            ( select did,value as domain_auth from domain_attrs where name='domain_auth' ) t3
            on t3.did=domain_attrs.did join
            ( select did,description as creator from domain_attrs left join dr_gw_lists on domain_attrs.value = dr_gw_lists.id where name='created_by') t4
            on t4.did=domain_attrs.did;"""

        res2 = db.execute(sql2)
        pbx_lookup = {}
        for row in res2:
            notes = strFieldsToDict(row['description'])['notes'] or ''
            if row['creator'] is not None:
                name = strFieldsToDict(row['creator'])['name'] or ''
            else:
                name = "Manually Created"

            pbx_lookup[row['did']] = {
                'pbx_list': str(row['pbx_list']).strip('[]').replace("'","").replace(",",", "),
                'domain_auth': row['domain_auth'],
                'name': name,
                'notes': notes
            }


        return render_template('domains.html', rows=res, pbxlookup=pbx_lookup, hc=healthCheck())

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
        debugException(ex, log_ex=True, print_ex=True, showstack=True)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@domains.route("/domains", methods=['POST'])
def addUpdateDomain():

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        if not session.get('logged_in'):
            return render_template('index.html')

        form = stripDictVals(request.form.to_dict())

        domain_id = form['domain_id'] if len(form['domain_id']) > 0 else ''
        domainlist = form['domainlist'] if len(form['domainlist']) > 0 else ''
        authtype = form['authtype'] if len(form['authtype']) > 0 else ''
        pbxs = request.form['pbx_list'] if len(form['pbx_list']) > 0 else ''
        notes = request.form['notes'] if len(form['notes']) > 0 else ''

        # Adding
        if len(domain_id) <= 0:
            domainlist = domainlist.split(",")

            for domain in domainlist:
                addDomain(domain.strip(), authtype, pbxs, notes, db)
        # Updating
        else:
            # remove old entries and add new ones
            domain_query = db.query(Domain).filter(Domain.id == domain_id)
            domain = domain_query.first()
            if domain is not None:
                db.query(DomainAttrs).filter(DomainAttrs.did == domain.did).delete(
                    synchronize_session=False
                )
                db.query(Dispatcher).filter(Dispatcher.setid == domain.id).delete(
                    synchronize_session=False
                )
                domain_query.delete(synchronize_session=False)
                db.flush()

            addDomain(domainlist.split(",")[0].strip(), authtype, pbxs, notes, db)

        db.commit()
        globals.reload_required = True
        return displayDomains()

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=True, print_ex=True, showstack=False)
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
        debugException(ex, log_ex=True, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()

@domains.route("/domainsdelete", methods=['POST'])
def deleteDomain():

    db = DummySession()

    try:
        if (settings.DEBUG):
            debugEndpoint()

        db = SessionLoader()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        form = stripDictVals(request.form.to_dict())

        domainid = form['domain_id'] if 'domain_id' in form else ''
        domainname = form['domain_name'] if 'domain_name' in form else ''

        dispatcherEntry = db.query(Dispatcher).filter(Dispatcher.setid == domainid)
        domainAttrs = db.query(DomainAttrs).filter(DomainAttrs.did == domainname)
        domainEntry = db.query(Domain).filter(Domain.did == domainname)

        dispatcherEntry.delete(synchronize_session=False)
        domainAttrs.delete(synchronize_session=False)
        domainEntry.delete(synchronize_session=False)

        db.commit()
        globals.reload_required = True
        return displayDomains()

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
