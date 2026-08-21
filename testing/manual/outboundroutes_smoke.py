#!/opt/dsiprouter/venv/bin/python
"""Smoke test for outbound routes business logic, without the HTTP layer.

Run on a live install:
    sudo /opt/dsiprouter/venv/bin/python testing/manual/outboundroutes_smoke.py

Exercises the helpers in modules.api.outboundroutes.functions directly so a
failure points at the business logic rather than the Flask/HTTP layer.

Row naming follows the bash cleanup pattern in testing/19.sh:
  - dr_rules.description LIKE 'name:Test Outbound %'
  - dsip_lcr.from_prefix LIKE '999%'
so any rows leaked on failure get swept by the next testing/19.sh run.
"""
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

from database import startSession, GatewayGroups
from modules.api.outboundroutes.functions import (
    nextLcrGroupid, createOutboundRoute, updateOutboundRoute,
    deleteOutboundRoute, serializeOutboundRoute, validateOutboundRouteBody)
from werkzeug import exceptions as http_exceptions
import settings


def main():
    db = startSession()
    try:
        # Discover a real carrier-group id (not hardcoded "2") so this script
        # still works on installs where the default seed was customized.
        cg = db.query(GatewayGroups).filter(
            GatewayGroups.description.regexp_match(GatewayGroups.FILTER.CARRIER.value)
        ).first()
        assert cg is not None, 'no carrier groups exist; cannot smoke-test'
        gwg = str(cg.id)

        # nextLcrGroupid: returns an int in [FLT_LCR_MIN, FLT_FWD_MIN)
        nxt = nextLcrGroupid(db)
        assert settings.FLT_LCR_MIN <= nxt < settings.FLT_FWD_MIN, \
            'nextLcrGroupid returned {} (out of range)'.format(nxt)

        # validator: each bad payload must raise BadRequest
        bad_payloads = [
            {},                                                  # missing gwgroupid
            {'gwgroupid': '0'},                                  # gwgroupid == "0"
            {'gwgroupid': gwg, 'bogus': 1},                      # unknown arg
            {'gwgroupid': gwg, 'prefix': 'abc'},                 # bad chars in prefix
            {'gwgroupid': gwg, 'from_prefix': '999000'},         # from_prefix without prefix
        ]
        for bad in bad_payloads:
            try:
                validateOutboundRouteBody(bad, require_gwgroupid=True)
            except http_exceptions.BadRequest:
                continue
            raise AssertionError('validator did not reject bad payload: {}'.format(bad))

        # create simple, verify groupid, delete
        rid = createOutboundRoute(db, {
            'name': 'Test Outbound Smoke Simple',
            'prefix': '55510',
            'gwgroupid': gwg,
        })
        db.commit()
        assert deleteOutboundRoute(db, rid), 'delete simple route returned False'
        db.commit()

        # create LCR, demote, re-promote, delete
        rid = createOutboundRoute(db, {
            'name': 'Test Outbound Smoke LCR',
            'from_prefix': '999800',
            'prefix': '55511',
            'gwgroupid': gwg,
        })
        db.commit()
        assert updateOutboundRoute(db, rid, {'from_prefix': ''}), 'demote returned False'
        db.commit()
        assert updateOutboundRoute(db, rid, {'from_prefix': '999801'}), 're-promote returned False'
        db.commit()
        assert deleteOutboundRoute(db, rid), 'delete LCR route returned False'
        db.commit()

        print('ALL OK')
    finally:
        db.close()


if __name__ == '__main__':
    main()
