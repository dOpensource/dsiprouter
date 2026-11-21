import { test, expect } from '@playwright/test';
import { loginAdmin, guiApiRequest, tokenApiRequest, dbQuery, sqlQuote, SHELL_ENABLED, API_TOKEN } from './helpers';
import { createEndpointGroupFixture, deleteEndpointGroupFixture, EndpointGroupFixture } from './fixtures/endpoints';
import { uniqueDomain, createDomain, getDomain, deleteDomainQuietly, seedDomainRows, removeDomainRows } from './fixtures/domains';

const DOMAIN_SETID_OFFSET = 100000;

test.describe('Domains API', () => {
  let eg: EndpointGroupFixture;

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    eg = await createEndpointGroupFixture(page, 2);
  });

  test.afterEach(async ({ page }) => {
    await deleteEndpointGroupFixture(page, eg);
  });

  test.describe('passthru', () => {
    test('create, read and delete', async ({ page }) => {
      const name = uniqueDomain('pt');
      let id: number | undefined;
      try {
        const created = await guiApiRequest(page, 'POST', '/domains', {
          domain: name, type: 'passthru', pbxs: [eg.gwids[0]], notes: 'e2e notes',
        });
        expect(created.status).toBe(200);
        expect(created.data.kamreload).toBe(true);
        id = created.data.data[0].id;

        const { status, domain } = await getDomain(page, id!);
        expect(status).toBe(200);
        expect(domain).toMatchObject({
          id, domain: name, type: 'passthru', pbx_type: '0', pbxs: [eg.gwids[0]],
          notes: 'e2e notes', managed_by: null, editable: true, dispatcher_set_id: null,
        });

        if (SHELL_ENABLED) {
          const attrs = Object.fromEntries(dbQuery(`SELECT name, value FROM domain_attrs WHERE did='${name}'`));
          expect(attrs.domain_auth).toBe('passthru');
          expect(attrs.pbx_ip).toBe('127.0.0.10:5060');
          expect(attrs.pbx_list).toBe(String(eg.gwids[0]));
        }

        const deleted = await guiApiRequest(page, 'DELETE', `/domains/${id}`);
        expect(deleted.status).toBe(200);
        expect(deleted.data.kamreload).toBe(true);
        expect((await getDomain(page, id!)).status).toBe(404);
        id = undefined;
      } finally {
        await deleteDomainQuietly(page, id);
      }
    });

    test('requires exactly one existing endpoint', async ({ page }) => {
      const name = uniqueDomain('pt');
      for (const pbxs of [[], eg.gwids, [999999]]) {
        const result = await guiApiRequest(page, 'POST', '/domains', { domain: name, type: 'passthru', pbxs });
        expect(result.status, JSON.stringify(pbxs)).toBe(400);
      }
      const list = await guiApiRequest(page, 'GET', '/domains');
      expect(list.data.data.find((d: any) => d.domain === name)).toBeUndefined();
    });
  });

  for (const type of ['local', 'realtime']) {
    test.describe(type, () => {
      test('creates a dispatcher set in the domain range with the kamailio attr names', async ({ page }) => {
        const name = uniqueDomain(type);
        let id: number | undefined;
        try {
          id = await createDomain(page, { domain: name, type, pbxs: eg.gwids });
          const { domain } = await getDomain(page, id);
          expect(domain.type).toBe(type);
          expect(domain.pbxs).toEqual(eg.gwids);
          expect(domain.dispatcher_set_id).toBe(DOMAIN_SETID_OFFSET + id);
          expect(domain.dispatcher_alg).toBe(4);

          if (SHELL_ENABLED) {
            const attrs = Object.fromEntries(dbQuery(`SELECT name, value FROM domain_attrs WHERE did='${name}'`));
            expect(attrs.dispatcher_reg_alg).toBe('4');
            expect(attrs.dispatcher_alg).toBe('4');
            expect(attrs.dispatcher_alg_reg).toBeUndefined();
            expect(attrs.dispatcher_alg_in).toBeUndefined();
            const rows = dbQuery(`SELECT destination FROM dispatcher WHERE setid=${DOMAIN_SETID_OFFSET + id} ORDER BY id`);
            expect(rows.map((r) => r[0])).toEqual(['sip:127.0.0.10:5060', 'sip:127.0.0.11:5060']);
          }
        } finally {
          await deleteDomainQuietly(page, id);
        }
      });

      test('requires at least one endpoint', async ({ page }) => {
        const result = await guiApiRequest(page, 'POST', '/domains', { domain: uniqueDomain(type), type, pbxs: [] });
        expect(result.status).toBe(400);
      });
    });
  }

  test('bulk create is atomic', async ({ page }) => {
    const a = uniqueDomain('bulk');
    const b = uniqueDomain('bulk');
    const ids: number[] = [];
    try {
      const created = await guiApiRequest(page, 'POST', '/domains', { domain: [a, b], type: 'local', pbxs: eg.gwids });
      expect(created.status).toBe(200);
      ids.push(...created.data.data.map((d: any) => d.id));
      expect(created.data.data.map((d: any) => d.domain)).toEqual([a, b]);

      // one name already exists -> 409 and the new name is not created either
      const c = uniqueDomain('bulk');
      const dup = await guiApiRequest(page, 'POST', '/domains', { domain: [c, a], type: 'local', pbxs: eg.gwids });
      expect(dup.status).toBe(409);
      const list = await guiApiRequest(page, 'GET', '/domains');
      expect(list.data.data.find((d: any) => d.domain === c)).toBeUndefined();

      // a comma separated string works like a list
      const d = uniqueDomain('csv');
      const e = uniqueDomain('csv');
      const csv = await guiApiRequest(page, 'POST', '/domains', { domain: `${d}, ${e}`, type: 'passthru', pbxs: [eg.gwids[0]] });
      expect(csv.status).toBe(200);
      ids.push(...csv.data.data.map((x: any) => x.id));
    } finally {
      for (const id of ids) {
        await deleteDomainQuietly(page, id);
      }
    }
  });

  test('update keeps the id and rebuilds the dispatcher set', async ({ page }) => {
    const name = uniqueDomain('upd');
    let id: number | undefined;
    try {
      id = await createDomain(page, { domain: name, type: 'local', pbxs: eg.gwids, notes: 'before' });

      const notes = await guiApiRequest(page, 'PUT', `/domains/${id}`, { notes: 'after' });
      expect(notes.status).toBe(200);
      expect(notes.data.data[0]).toMatchObject({ id, notes: 'after', type: 'local', pbxs: eg.gwids });

      const pbxs = await guiApiRequest(page, 'PUT', `/domains/${id}`, { pbxs: [eg.gwids[1]] });
      expect(pbxs.status).toBe(200);
      expect(pbxs.data.data[0]).toMatchObject({ id, pbxs: [eg.gwids[1]], dispatcher_set_id: DOMAIN_SETID_OFFSET + id });
      if (SHELL_ENABLED) {
        expect(dbQuery(`SELECT destination FROM dispatcher WHERE setid=${DOMAIN_SETID_OFFSET + id}`))
          .toEqual([['sip:127.0.0.11:5060']]);
      }

      const toPassthru = await guiApiRequest(page, 'PUT', `/domains/${id}`, { type: 'passthru', pbxs: [eg.gwids[0]] });
      expect(toPassthru.status).toBe(200);
      expect(toPassthru.data.data[0]).toMatchObject({ id, type: 'passthru', dispatcher_set_id: null });
      if (SHELL_ENABLED) {
        expect(dbQuery(`SELECT id FROM dispatcher WHERE setid=${DOMAIN_SETID_OFFSET + id}`)).toEqual([]);
      }

      const renamed = uniqueDomain('renamed');
      const rename = await guiApiRequest(page, 'PUT', `/domains/${id}`, { domain: renamed });
      expect(rename.status).toBe(200);
      expect(rename.data.data[0]).toMatchObject({ id, domain: renamed, type: 'passthru' });
    } finally {
      await deleteDomainQuietly(page, id);
    }
  });

  test('validation errors', async ({ page }) => {
    const name = uniqueDomain('val');
    const cases: Array<[any, number]> = [
      [{ type: 'passthru', pbxs: [eg.gwids[0]] }, 400],                         // missing domain
      [{ domain: name, pbxs: [eg.gwids[0]] }, 400],                              // missing type
      [{ domain: name, type: 'nope', pbxs: [eg.gwids[0]] }, 400],                // unknown type
      [{ domain: 'bad_name!', type: 'passthru', pbxs: [eg.gwids[0]] }, 400],     // invalid hostname
      [{ domain: name, type: 'local', pbxs: ['abc'] }, 400],                     // non numeric endpoint id
      [{ domain: name, type: 'local', pbxs: [eg.gwids[0]], extra: 1 }, 400],     // unknown field
      [{ domain: name, type: 'local', pbxs: [eg.gwids[0]], dispatcher_alg: 99 }, 400],
      [{ domain: [name, name], type: 'local', pbxs: [eg.gwids[0]] }, 400],       // duplicate in list
    ];
    for (const [body, status] of cases) {
      const result = await guiApiRequest(page, 'POST', '/domains', body);
      expect(result.status, JSON.stringify(body)).toBe(status);
      expect(result.data.msg).toBeTruthy();
    }

    let id: number | undefined;
    try {
      id = await createDomain(page, { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] });
      expect((await guiApiRequest(page, 'POST', '/domains', { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] })).status).toBe(409);
      expect((await guiApiRequest(page, 'PUT', `/domains/${id}`, { domain: [name, uniqueDomain()] })).status).toBe(400);
    } finally {
      await deleteDomainQuietly(page, id);
    }

    expect((await guiApiRequest(page, 'GET', '/domains/999999999')).status).toBe(404);
    expect((await guiApiRequest(page, 'PUT', '/domains/999999999', { notes: 'x' })).status).toBe(404);
    expect((await guiApiRequest(page, 'DELETE', '/domains/999999999')).status).toBe(404);
    expect((await guiApiRequest(page, 'PUT', '/domains', { notes: 'x' })).status).toBe(400);
    expect((await guiApiRequest(page, 'DELETE', '/domains')).status).toBe(400);
    expect((await guiApiRequest(page, 'GET', '/domains?bogus=1')).status).toBe(400);
    expect((await guiApiRequest(page, 'GET', '/domains?type=nope')).status).toBe(400);
  });

  test('list filters by type', async ({ page }) => {
    const pt = uniqueDomain('pt');
    const local = uniqueDomain('local');
    const ids: number[] = [];
    try {
      ids.push(await createDomain(page, { domain: pt, type: 'passthru', pbxs: [eg.gwids[0]] }));
      ids.push(await createDomain(page, { domain: local, type: 'local', pbxs: eg.gwids }));
      const result = await guiApiRequest(page, 'GET', '/domains?type=local');
      expect(result.status).toBe(200);
      const names = result.data.data.map((d: any) => d.domain);
      expect(names).toContain(local);
      expect(names).not.toContain(pt);
      expect(result.data.data.every((d: any) => d.type === 'local')).toBe(true);
    } finally {
      for (const id of ids) {
        await deleteDomainQuietly(page, id);
      }
    }
  });

  test('msteams', async ({ page }) => {
    const name = uniqueDomain('teams');
    const created = await guiApiRequest(page, 'POST', '/domains', { domain: name, type: 'msteams' });
    if (created.status === 403) {
      // no DSIP_MSTEAMS license on this install: the API must refuse and create nothing
      expect(created.data.msg).toContain('DSIP_MSTEAMS');
      const list = await guiApiRequest(page, 'GET', '/domains');
      expect(list.data.data.find((d: any) => d.domain === name)).toBeUndefined();
      return;
    }

    expect(created.status).toBe(200);
    const id = created.data.data[0].id;
    try {
      const groupsNamed = async () => {
        const groups = await guiApiRequest(page, 'GET', '/endpointgroups');
        return groups.data.data.filter((g: any) => g.name === name);
      };
      expect(await groupsNamed()).toHaveLength(1);

      // updating twice must not create more endpoint groups
      expect((await guiApiRequest(page, 'PUT', `/domains/${id}`, { notes: 'one' })).status).toBe(200);
      expect((await guiApiRequest(page, 'PUT', `/domains/${id}`, { notes: 'two' })).status).toBe(200);
      expect(await groupsNamed()).toHaveLength(1);

      if (SHELL_ENABLED) {
        expect(dbQuery(`SELECT COUNT(*) FROM dispatcher WHERE setid=${DOMAIN_SETID_OFFSET + id}`)).toEqual([['3']]);
        expect(Number(dbQuery(`SELECT COUNT(*) FROM address WHERE tag LIKE '%msteams-sbc%'`)[0][0])).toBeGreaterThan(0);
      }

      expect((await guiApiRequest(page, 'DELETE', `/domains/${id}`)).status).toBe(200);
      expect(await groupsNamed()).toHaveLength(0);
    } finally {
      await deleteDomainQuietly(page, id);
    }
  });

  test('domains owned by an endpoint group are read-only', async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed a managed domain');
    const name = uniqueDomain('managed');
    try {
      seedDomainRows(name, {
        pbx_type: '1', created_by: String(eg.gwgroupid), domain_auth: 'passthru',
        pbx_list: String(eg.gwgroupid), description: 'notes:', pbx_ip: '127.0.0.10',
      });
      const list = await guiApiRequest(page, 'GET', '/domains');
      const managed = list.data.data.find((d: any) => d.domain === name);
      expect(managed).toMatchObject({ editable: false, managed_by: { gwgroupid: eg.gwgroupid } });

      expect((await guiApiRequest(page, 'PUT', `/domains/${managed.id}`, { notes: 'x' })).status).toBe(409);
      expect((await guiApiRequest(page, 'DELETE', `/domains/${managed.id}`)).status).toBe(409);
    } finally {
      removeDomainRows(name);
    }
  });

  test('legacy domains sharing a dispatcher set only remove their own rows', async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed a legacy domain');
    // the old form handler used setid = domain.id, which can equal an endpoint or carrier group's set.
    // Share the endpoint group's set: its rows describe the same gwid as 'name=...;gwid=N' and must survive.
    const name = uniqueDomain('legacy');
    const sharedSet = eg.gwgroupid;
    const legacyDest = 'sip:127.0.0.99:5060';
    const before = dbQuery(`SELECT id FROM dispatcher WHERE setid=${sharedSet} ORDER BY id`);
    expect(before.length).toBe(2);
    try {
      const id = seedDomainRows(name, {
        pbx_type: '0', created_by: '0', domain_auth: 'local', pbx_list: `['${eg.gwids[1]}']`,
        description: 'notes:', dispatcher_set_id: String(sharedSet), dispatcher_alg_reg: '8', dispatcher_alg_in: '4',
      });
      dbQuery(`INSERT INTO dispatcher (setid, destination, flags, priority, attrs, description) ` +
        `VALUES (${sharedSet}, ${sqlQuote(legacyDest)}, 0, 0, '', ${sqlQuote(`gwid=${eg.gwids[1]}`)})`);

      // the old python-repr pbx_list is understood
      expect((await getDomain(page, id)).domain.pbxs).toEqual([eg.gwids[1]]);

      expect((await guiApiRequest(page, 'DELETE', `/domains/${id}`)).status).toBe(200);
      expect(dbQuery(`SELECT id FROM dispatcher WHERE destination=${sqlQuote(legacyDest)}`)).toEqual([]);
      expect(dbQuery(`SELECT id FROM dispatcher WHERE setid=${sharedSet} ORDER BY id`)).toEqual(before);
    } finally {
      dbQuery(`DELETE FROM dispatcher WHERE destination=${sqlQuote(legacyDest)}`);
      removeDomainRows(name);
    }
  });

  test.describe('token auth', () => {
    test.skip(API_TOKEN === '', 'needs DSIP_TEST_API_TOKEN (DSIP_CORE license)');

    test('create, read and delete with a bearer token', async () => {
      const name = uniqueDomain('token');
      const created = await tokenApiRequest('POST', '/domains', { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] });
      expect(created.status).toBe(200);
      const id = created.data.data[0].id;
      expect((await tokenApiRequest('GET', `/domains/${id}`)).status).toBe(200);
      expect((await tokenApiRequest('DELETE', `/domains/${id}`)).status).toBe(200);
    });

    test('a bad token is rejected', async () => {
      expect((await tokenApiRequest('GET', '/domains', undefined, 'not-a-token')).status).toBe(401);
    });
  });
});
