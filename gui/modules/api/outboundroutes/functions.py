# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from werkzeug import exceptions as http_exceptions
from database import OutboundRoutes, dSIPLCR
from shared import strFieldsToDict
import settings


VALID_REQUEST_DATA_ARGS = {'name', 'from_prefix', 'prefix', 'timerec',
                           'priority', 'routeid', 'gwgroupid'}


def validateOutboundRouteBody(data, require_gwgroupid):
    """Validate an outbound-routes request body. Raises werkzeug.BadRequest on failure.

    Rules mirror gui/dsiprouter.py:1732-1744 and gui/static/js/outboundroutes.js:19-28.
    """
    for arg in data:
        if arg not in VALID_REQUEST_DATA_ARGS:
            raise http_exceptions.BadRequest('Request data argument not recognized')
    if require_gwgroupid:
        gwg = data.get('gwgroupid')
        # GUI treats "0" as no carrier group (gui/dsiprouter.py:1740) - reject both empty and "0"
        if not gwg or str(gwg) == '0':
            raise http_exceptions.BadRequest('gwgroupid is required (and cannot be "0")')
    for fld in ('prefix', 'from_prefix'):
        v = data.get(fld)
        if v:
            for c in v:
                if c not in settings.DID_PREFIX_ALLOWED_CHARS:
                    raise http_exceptions.BadRequest(
                        '{} improperly formatted. Allowed chars: {}'.format(
                            fld, ','.join(sorted(settings.DID_PREFIX_ALLOWED_CHARS))))
    if data.get('from_prefix') and not data.get('prefix'):
        # mirrors GUI JS validator at gui/static/js/outboundroutes.js:19-28
        raise http_exceptions.BadRequest(
            'To Prefix is required when From Prefix is provided')
    return data


def nextLcrGroupid(db):
    """Allocate the next available dr_groupid in [FLT_LCR_MIN, FLT_FWD_MIN).
    Replicates gui/dsiprouter.py:1754-1762 / 1811-1818."""
    mlcr = db.query(dSIPLCR).filter(
        (dSIPLCR.dr_groupid >= settings.FLT_LCR_MIN) &
        (dSIPLCR.dr_groupid <  settings.FLT_FWD_MIN)
    ).order_by(dSIPLCR.dr_groupid.desc()).first()
    return settings.FLT_LCR_MIN if mlcr is None else int(mlcr.dr_groupid) + 1


def serializeOutboundRoute(db, row):
    """Build the canonical API representation for one OutboundRoutes row."""
    desc   = strFieldsToDict(row.description) if row.description else {}
    gwlist = row.gwlist or ''
    gwgrp  = gwlist[1:] if gwlist.startswith('#') else gwlist
    lcr = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == row.groupid).first()
    return {
        'ruleid':      row.ruleid,
        'groupid':     str(row.groupid),
        'name':        desc.get('name', ''),
        'from_prefix': lcr.from_prefix if lcr else None,
        'prefix':      row.prefix,
        'timerec':     row.timerec,
        'priority':    row.priority,
        'routeid':     row.routeid,
        'gwgroupid':   gwgrp,
    }


def createOutboundRoute(db, data):
    """Insert a row matching gui/dsiprouter.py:1746-1773. Caller must commit().
    Returns the new ruleid."""
    from_prefix = data.get('from_prefix') or None
    prefix      = data.get('prefix', '')
    timerec     = data.get('timerec', '')
    priority    = int(data.get('priority') or 0)
    routeid     = data.get('routeid', '')
    gwgroupid   = data.get('gwgroupid') or ''
    name        = data.get('name', '')
    gwlist      = '#{}'.format(gwgroupid) if (gwgroupid and str(gwgroupid) != '0') else ''
    description = 'name:{}'.format(name) if name else ''

    groupid = nextLcrGroupid(db) if from_prefix is not None else settings.FLT_OUTBOUND

    OMap = OutboundRoutes(groupid=groupid, prefix=prefix, timerec=timerec,
                          priority=priority, routeid=routeid,
                          gwlist=gwlist, description=description)
    db.add(OMap)
    db.flush()  # flush so OMap.ruleid is populated

    if from_prefix is not None:
        db.add(dSIPLCR(pattern='{}-{}'.format(from_prefix, prefix),
                       from_prefix=from_prefix, dr_groupid=groupid))
    return OMap.ruleid


def updateOutboundRoute(db, ruleid, data):
    """Replicates the 4 branches in gui/dsiprouter.py:1775-1851.
    Caller must commit(). Returns False if no row matched."""
    row = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
    if row is None:
        return False
    cur_groupid = int(row.groupid)
    is_lcr      = settings.FLT_LCR_MIN <= cur_groupid < settings.FLT_FWD_MIN

    # merge incoming over current for any field not supplied
    desc      = strFieldsToDict(row.description) if row.description else {}
    name      = data.get('name', desc.get('name', ''))
    prefix    = data.get('prefix', row.prefix)
    timerec   = data.get('timerec', row.timerec)
    priority  = int(data.get('priority', row.priority) or 0)
    routeid   = data.get('routeid', row.routeid)
    gwgroupid = data.get('gwgroupid',
                         row.gwlist[1:] if (row.gwlist or '').startswith('#') else '')
    gwlist    = '#{}'.format(gwgroupid) if (gwgroupid and str(gwgroupid) != '0') else ''
    description = 'name:{}'.format(name) if name else ''

    # target from_prefix: explicit empty string == clear; absent == leave current
    if 'from_prefix' in data:
        new_from = data['from_prefix'] or None
    else:
        cur_lcr  = db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == cur_groupid).first()
        new_from = cur_lcr.from_prefix if cur_lcr else None

    base = {'prefix': prefix, 'timerec': timerec, 'priority': priority,
            'routeid': routeid, 'gwlist': gwlist, 'description': description}

    if new_from is None and is_lcr:
        # demote LCR -> simple
        db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == cur_groupid).delete(
            synchronize_session=False)
        base['groupid'] = settings.FLT_OUTBOUND
        db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update(
            base, synchronize_session=False)
    elif new_from is not None and not is_lcr:
        # promote simple -> LCR
        new_groupid = nextLcrGroupid(db)
        db.add(dSIPLCR(pattern='{}-{}'.format(new_from, prefix),
                       from_prefix=new_from, dr_groupid=new_groupid))
        base['groupid'] = new_groupid
        db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update(
            base, synchronize_session=False)
    elif new_from is not None and is_lcr:
        # update LCR in place
        db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == cur_groupid).update(
            {'pattern': '{}-{}'.format(new_from, prefix), 'from_prefix': new_from},
            synchronize_session=False)
        db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update(
            base, synchronize_session=False)
    else:
        # plain field update (still simple)
        db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).update(
            base, synchronize_session=False)
    return True


def deleteOutboundRoute(db, ruleid):
    """Replicates gui/dsiprouter.py:1899-1907. Caller must commit().
    Returns False if no row matched."""
    row = db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).first()
    if row is None:
        return False
    db.query(dSIPLCR).filter(dSIPLCR.dr_groupid == row.groupid).delete(
        synchronize_session=False)
    db.query(OutboundRoutes).filter(OutboundRoutes.ruleid == ruleid).delete(
        synchronize_session=False)
    return True
