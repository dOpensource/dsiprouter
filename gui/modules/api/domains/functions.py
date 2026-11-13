# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import re
from werkzeug import exceptions as http_exceptions
from database import Domain, DomainAttrs, Dispatcher, Gateways, GatewayGroups, Address, dSIPCallSettings
from shared import strFieldsToDict
from util.networking import isValidIP, safeUriToHost
import settings


DOMAIN_TYPES = ('passthru', 'msteams', 'local', 'realtime')
DISPATCHER_TYPES = ('msteams', 'local', 'realtime')

VALID_REQUEST_DATA_ARGS = {'domain', 'type', 'pbxs', 'notes', 'dispatcher_alg'}

# pbx_type attr values (see domainTypeFilter in gui/dsiprouter.py)
PBX_TYPE_STATIC = '0'
PBX_TYPE_MSTEAMS = '3'

# created_by == '0' marks a manually created domain, anything else is the
# gwgroupid of the endpoint group (FusionPBX sync) that owns the domain
CREATED_BY_MANUAL = '0'

# Dispatcher set ids for domains live in their own range. Endpoint / carrier groups use setid = gwgroupid and
# FusionPBX external interfaces use gwgroupid + 1000, so the old setid = domain.id collided with them.
DOMAIN_SETID_OFFSET = 100000

# domain table column is varchar(64)
DOMAIN_MAX_LEN = 64
HOSTNAME_REGEX = re.compile(
    r'^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))*$'
)


class DomainConflict(http_exceptions.Conflict):
    pass


def isValidDomainName(name):
    if not isinstance(name, str) or len(name) == 0 or len(name) > DOMAIN_MAX_LEN:
        return False
    return HOSTNAME_REGEX.match(name) is not None or isValidIP(name)


def parsePbxList(value):
    """
    Parse a pbx_list attr or request value into a list of gwid strings.
    Accepts a list, a comma/space separated string, or the python list repr
    the old domains form wrote, e.g. "['1', '2']".
    """
    if value is None:
        return []
    if isinstance(value, (list, tuple)):
        items = value
    else:
        items = re.split(r'[\s,]+', str(value).strip('[]').replace("'", '').replace('"', ''))
    return [str(item).strip() for item in items if str(item).strip() != '']


def validateDomainBody(data, require_all):
    """
    Validate a domains request body. Raises werkzeug.BadRequest on failure.

    :param data:            request payload
    :param require_all:     True on POST (domain and type are required)
    :return:                normalized payload
    """
    for arg in data:
        if arg not in VALID_REQUEST_DATA_ARGS:
            raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(arg))

    clean = {}

    if 'domain' in data:
        domains = data['domain']
        if isinstance(domains, str):
            domains = [d.strip() for d in domains.split(',')]
        if not isinstance(domains, list) or len(domains) == 0:
            raise http_exceptions.BadRequest('domain must be a string or a list of strings')
        for name in domains:
            if not isValidDomainName(name):
                raise http_exceptions.BadRequest("domain '{}' is not a valid hostname or IP address".format(name))
        if len(set(d.lower() for d in domains)) != len(domains):
            raise http_exceptions.BadRequest('domain list contains duplicates')
        clean['domain'] = domains
    elif require_all:
        raise http_exceptions.BadRequest('domain is required')

    if 'type' in data:
        if data['type'] not in DOMAIN_TYPES:
            raise http_exceptions.BadRequest('type must be one of: {}'.format(', '.join(DOMAIN_TYPES)))
        clean['type'] = data['type']
    elif require_all:
        raise http_exceptions.BadRequest('type is required')

    if 'pbxs' in data:
        try:
            clean['pbxs'] = [str(int(gwid)) for gwid in parsePbxList(data['pbxs'])]
        except (TypeError, ValueError):
            raise http_exceptions.BadRequest('pbxs must be a list of endpoint ids')

    if 'notes' in data:
        clean['notes'] = '' if data['notes'] is None else str(data['notes'])

    if 'dispatcher_alg' in data:
        try:
            alg = int(data['dispatcher_alg'])
        except (TypeError, ValueError):
            raise http_exceptions.BadRequest('dispatcher_alg must be an integer')
        if alg not in Dispatcher.DST_ALG.values():
            raise http_exceptions.BadRequest('dispatcher_alg must be one of: {}'.format(
                ', '.join(str(v) for v in sorted(Dispatcher.DST_ALG.values()))))
        clean['dispatcher_alg'] = str(alg)

    return clean


def getDomainAttrs(db, did):
    return {attr.name: attr.value for attr in db.query(DomainAttrs).filter(DomainAttrs.did == did).all()}


def serializeDomain(db, domain, attrs=None):
    """Build the canonical API representation for one domain row."""
    if attrs is None:
        attrs = getDomainAttrs(db, domain.did)

    created_by = attrs.get('created_by', CREATED_BY_MANUAL)
    managed_by = None
    if created_by != CREATED_BY_MANUAL:
        gwgroup = db.query(GatewayGroups).filter(GatewayGroups.id == created_by).first()
        managed_by = {
            'gwgroupid': int(created_by) if created_by.isdigit() else created_by,
            'name': strFieldsToDict(gwgroup.description).get('name', '') if gwgroup is not None else '',
        }

    description = attrs.get('description', '')
    notes = strFieldsToDict(description).get('notes', '') if description else ''

    pbxs = parsePbxList(attrs.get('pbx_list'))
    if attrs.get('domain_auth') == 'msteams' or managed_by is not None:
        # msteams pbx_list holds the teams proxy uris, managed domains hold a gwgroupid
        pbxs = []

    alg = attrs.get('dispatcher_alg')
    return {
        'id': domain.id,
        'domain': domain.domain,
        'type': attrs.get('domain_auth', ''),
        'pbx_type': attrs.get('pbx_type', ''),
        'pbxs': [int(p) if p.isdigit() else p for p in pbxs],
        'notes': notes or '',
        'dispatcher_set_id': int(attrs['dispatcher_set_id']) if attrs.get('dispatcher_set_id', '').isdigit() else None,
        'dispatcher_alg': int(alg) if alg is not None and alg.isdigit() else None,
        'managed_by': managed_by,
        'editable': managed_by is None,
    }


def listDomains(db, domain_type=None):
    domains = db.query(Domain).order_by(Domain.id).all()
    if len(domains) == 0:
        return []

    attrs_by_did = {}
    for attr in db.query(DomainAttrs).filter(DomainAttrs.did.in_([d.did for d in domains])).all():
        attrs_by_did.setdefault(attr.did, {})[attr.name] = attr.value

    results = []
    for domain in domains:
        attrs = attrs_by_did.get(domain.did, {})
        if domain_type is not None and attrs.get('domain_auth') != domain_type:
            continue
        results.append(serializeDomain(db, domain, attrs))
    return results


def lookupGateways(db, gwids):
    """Map gwids to dr_gateways rows, raising BadRequest for any that don't exist."""
    gateways = {}
    for gwid in gwids:
        gw = db.query(Gateways).filter(Gateways.gwid == gwid).first()
        if gw is None:
            raise http_exceptions.BadRequest('endpoint id {} does not exist'.format(gwid))
        gateways[gwid] = gw
    return gateways


def validatePbxsForType(domain_type, pbxs):
    if domain_type == 'passthru':
        if len(pbxs) != 1:
            raise http_exceptions.BadRequest('passthru domains require exactly one endpoint id in pbxs')
    elif domain_type in ('local', 'realtime'):
        if len(pbxs) == 0:
            raise http_exceptions.BadRequest('{} domains require at least one endpoint id in pbxs'.format(domain_type))


def addAttr(db, did, name, value):
    db.add(DomainAttrs(did=did, name=name, value=str(value)))


def createMSTeamsEndpointGroup(db, domain_name):
    """
    Create the endpoint group that enables inbound mapping for a MSTeams domain.
    Mirrors addEndpointGroups(..., "msteams", domain) in gui/modules/api/api_routes.py but runs in the caller's
    transaction, so a failure rolls the whole domain back.

    :return:    the new gwgroupid
    """
    gwgroup = GatewayGroups(domain_name, type=settings.FLT_PBX)
    db.add(gwgroup)
    db.flush()
    gwgroupid = gwgroup.id
    db.add(dSIPCallSettings(gwgroupid))

    gwlist = []
    for hostname in settings.MSTEAMS_DNS_ENDPOINTS:
        sip_addr = safeUriToHost('{}:5061;transport=tls'.format(hostname), default_port=5060)
        gateway = Gateways('msteams_endpoint', sip_addr, 0, '', settings.FLT_PBX, gwgroup=gwgroupid,
            msteams_domain=domain_name, signalling='sips_tls', media='rtp_savp')
        db.add(gateway)
        db.flush()
        gwlist.append(gateway.gwid)

    gwgroup.gwlist = ','.join(str(gw) for gw in gwlist)
    return gwgroupid


def findMSTeamsEndpointGroupId(db, domain_name, attrs):
    """Find the endpoint group created for a MSTeams domain (older domains don't store the link)."""
    if attrs.get('msteams_gwgroupid', '').isdigit():
        return int(attrs['msteams_gwgroupid'])
    for gwgroup in db.query(GatewayGroups).filter(GatewayGroups.description.regexp_match(GatewayGroups.FILTER.ENDPOINT.value)).all():
        if strFieldsToDict(gwgroup.description).get('name') != domain_name:
            continue
        gateways = db.query(Gateways).filter(Gateways.description.regexp_match('gwgroup:{}(,|$)'.format(gwgroup.id))).all()
        if len(gateways) > 0 and all(gw.attrsToDict()['msteams_domain'] == domain_name for gw in gateways):
            return gwgroup.id
    return None


def deleteMSTeamsEndpointGroup(db, gwgroupid):
    db.query(Gateways).filter(Gateways.description.regexp_match('gwgroup:{}(,|$)'.format(gwgroupid))).delete(
        synchronize_session=False)
    db.query(dSIPCallSettings).filter(dSIPCallSettings.gwgroupid == gwgroupid).delete(synchronize_session=False)
    db.query(GatewayGroups).filter(GatewayGroups.id == gwgroupid).delete(synchronize_session=False)


def ensureMSTeamsAddresses(db):
    """Make sure the MSTeams SBCs that send us OPTIONS are in the address table."""
    for endpoint in list(settings.MSTEAMS_IP_ENDPOINTS) + list(settings.MSTEAMS_DNS_ENDPOINTS):
        if db.query(Address).filter(Address.ip_addr == endpoint).first() is None:
            db.add(Address('msteams-sbc', endpoint, 32, settings.FLT_MSTEAMS, gwgroup=0))


def writeDomainConfig(db, domain, domain_type, pbxs, notes, dispatcher_alg, msteams_gwgroupid=None):
    """
    Write the domain_attrs and dispatcher rows for a domain of the given type.
    Any existing attrs / dispatcher set for the domain must already be removed.
    """
    did = domain.did

    addAttr(db, did, 'pbx_type', PBX_TYPE_MSTEAMS if domain_type == 'msteams' else PBX_TYPE_STATIC)
    addAttr(db, did, 'created_by', CREATED_BY_MANUAL)
    addAttr(db, did, 'domain_auth', domain_type)
    addAttr(db, did, 'description', 'notes:{}'.format(notes))

    if domain_type == 'passthru':
        gateway = lookupGateways(db, pbxs)[pbxs[0]]
        addAttr(db, did, 'pbx_list', pbxs[0])
        addAttr(db, did, 'pbx_ip', gateway.address)
        return

    setid = domainSetId(domain)
    # the attr names below are the ones kamailio reads (domain_dispatcher_reg_alg / domain_dispatcher_alg)
    addAttr(db, did, 'dispatcher_set_id', setid)
    addAttr(db, did, 'dispatcher_reg_alg', dispatcher_alg)
    addAttr(db, did, 'dispatcher_alg', dispatcher_alg)

    if domain_type == 'msteams':
        msteams_uris = ['{}:5061;transport=tls'.format(endpoint) for endpoint in settings.MSTEAMS_DNS_ENDPOINTS]
        addAttr(db, did, 'pbx_list', ','.join(msteams_uris))
        for hostname, sipuri in zip(settings.MSTEAMS_DNS_ENDPOINTS, msteams_uris):
            db.add(Dispatcher(
                setid=setid,
                destination=sipuri,
                attrs='ping_from=sip:{}'.format(domain.domain),
                flags=Dispatcher.FLAGS['KEEP_ALIVE'],
                name=hostname
            ))
        ensureMSTeamsAddresses(db)
        if msteams_gwgroupid is None:
            msteams_gwgroupid = createMSTeamsEndpointGroup(db, domain.domain)
        addAttr(db, did, 'msteams_gwgroupid', msteams_gwgroupid)
        return

    # local / realtime
    gateways = lookupGateways(db, pbxs)
    addAttr(db, did, 'pbx_list', ','.join(pbxs))
    for gwid in pbxs:
        db.add(Dispatcher(setid=setid, destination=gateways[gwid].address, gwid=gwid))


def domainSetId(domain):
    return DOMAIN_SETID_OFFSET + domain.id


def clearDomainConfig(db, domain, attrs):
    """
    Remove the domain_attrs and the dispatcher entries owned by a domain.
    Domains created before DOMAIN_SETID_OFFSET used setid = domain.id, which can be shared with an endpoint or
    carrier group, so for those only the rows the domain created are removed.
    """
    setid = attrs.get('dispatcher_set_id', '')
    if setid.isdigit():
        setid = int(setid)
        if setid >= DOMAIN_SETID_OFFSET:
            db.query(Dispatcher).filter(Dispatcher.setid == setid).delete(synchronize_session=False)
        elif attrs.get('domain_auth') == 'msteams':
            db.query(Dispatcher).filter(
                (Dispatcher.setid == setid) & (Dispatcher.attrs == 'ping_from=sip:{}'.format(domain.domain))
            ).delete(synchronize_session=False)
        else:
            # the old form handler wrote description 'gwid=<id>' with no name, endpoint / carrier group rows
            # for the same gateway are 'name=...;gwid=<id>' and must be kept
            gwids = [gwid for gwid in parsePbxList(attrs.get('pbx_list')) if gwid.isdigit()]
            if len(gwids) > 0:
                db.query(Dispatcher).filter(
                    (Dispatcher.setid == setid) &
                    Dispatcher.description.in_(['gwid={}'.format(gwid) for gwid in gwids])
                ).delete(synchronize_session=False)
    db.query(DomainAttrs).filter(DomainAttrs.did == domain.did).delete(synchronize_session=False)


def createDomains(db, data):
    """
    Create one domain per name in data['domain']. Caller must commit().

    :return:    list of {id, domain}
    """
    domain_type = data['type']
    pbxs = data.get('pbxs', [])
    notes = data.get('notes', '')
    dispatcher_alg = data.get('dispatcher_alg', str(Dispatcher.DST_ALG['ROUND_ROBIN']))

    if domain_type != 'msteams':
        validatePbxsForType(domain_type, pbxs)

    created = []
    for name in data['domain']:
        if db.query(Domain).filter((Domain.domain == name) | (Domain.did == name)).first() is not None:
            raise DomainConflict("domain '{}' already exists".format(name))
        domain = Domain(domain=name, did=name)
        db.add(domain)
        db.flush()
        writeDomainConfig(db, domain, domain_type, pbxs, notes, dispatcher_alg)
        created.append({'id': domain.id, 'domain': domain.domain})
    return created


def getManualDomain(db, domain_id):
    """Return (domain, attrs) for an editable domain, None if not found, raise Conflict if managed."""
    domain = db.query(Domain).filter(Domain.id == domain_id).first()
    if domain is None:
        return None, None
    attrs = getDomainAttrs(db, domain.did)
    if attrs.get('created_by', CREATED_BY_MANUAL) != CREATED_BY_MANUAL:
        raise DomainConflict('domain is managed by endpoint group {} and can not be changed here'.format(
            attrs['created_by']))
    return domain, attrs


def updateDomain(db, domain_id, data):
    """
    Update a domain in place, keeping its id (and dispatcher set id). Caller must commit().
    Fields not supplied keep their current values.

    :return:    False if no domain matched
    """
    domain, attrs = getManualDomain(db, domain_id)
    if domain is None:
        return False

    if 'domain' in data and len(data['domain']) != 1:
        raise http_exceptions.BadRequest('only one domain can be given when updating')

    cur_type = attrs.get('domain_auth', '')
    new_type = data.get('type', cur_type)
    if new_type not in DOMAIN_TYPES:
        raise http_exceptions.BadRequest('type is required, the current domain has no valid type')

    if 'pbxs' in data:
        pbxs = data['pbxs']
    elif cur_type == new_type and new_type != 'msteams':
        pbxs = parsePbxList(attrs.get('pbx_list'))
    else:
        pbxs = []
    if new_type != 'msteams':
        validatePbxsForType(new_type, pbxs)

    description = attrs.get('description', '')
    notes = data.get('notes', strFieldsToDict(description).get('notes', '') if description else '')
    dispatcher_alg = data.get('dispatcher_alg',
        attrs.get('dispatcher_alg', str(Dispatcher.DST_ALG['ROUND_ROBIN'])))

    new_name = data['domain'][0] if 'domain' in data else domain.domain
    if new_name != domain.domain:
        if db.query(Domain).filter(((Domain.domain == new_name) | (Domain.did == new_name)) & (Domain.id != domain.id)).first() is not None:
            raise DomainConflict("domain '{}' already exists".format(new_name))

    msteams_gwgroupid = findMSTeamsEndpointGroupId(db, domain.domain, attrs) if cur_type == 'msteams' else None
    keep_gwgroupid = None
    if msteams_gwgroupid is not None:
        if new_type == 'msteams' and new_name == domain.domain:
            keep_gwgroupid = msteams_gwgroupid
        else:
            deleteMSTeamsEndpointGroup(db, msteams_gwgroupid)

    clearDomainConfig(db, domain, attrs)
    if new_name != domain.domain:
        domain.domain = new_name
        domain.did = new_name
    db.flush()

    writeDomainConfig(db, domain, new_type, pbxs, notes, dispatcher_alg, msteams_gwgroupid=keep_gwgroupid)
    return True


def deleteDomain(db, domain_id):
    """
    Delete a domain with its attrs, dispatcher set and (MSTeams) endpoint group. Caller must commit().

    :return:    False if no domain matched
    """
    domain, attrs = getManualDomain(db, domain_id)
    if domain is None:
        return False

    if attrs.get('domain_auth') == 'msteams':
        msteams_gwgroupid = findMSTeamsEndpointGroupId(db, domain.domain, attrs)
        if msteams_gwgroupid is not None:
            deleteMSTeamsEndpointGroup(db, msteams_gwgroupid)

    clearDomainConfig(db, domain, attrs)
    db.query(Domain).filter(Domain.id == domain.id).delete(synchronize_session=False)
    return True
