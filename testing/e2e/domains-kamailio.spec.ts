import { test, expect } from '@playwright/test';
import { loginAdmin, kamcmd, reloadKamailio, SHELL_ENABLED } from './helpers';
import { createEndpointGroupFixture, deleteEndpointGroupFixture, EndpointGroupFixture } from './fixtures/endpoints';
import { uniqueDomain, createDomain, deleteDomainQuietly } from './fixtures/domains';

const DOMAIN_SETID_OFFSET = 100000;

test.describe('Domains reach kamailio', () => {
  test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to run kamcmd on the host');

  let eg: EndpointGroupFixture;

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    eg = await createEndpointGroupFixture(page, 2);
  });

  test.afterEach(async ({ page }) => {
    await deleteEndpointGroupFixture(page, eg);
    await reloadKamailio(page);
  });

  test('domains and dispatcher sets are loaded after a reload and gone after delete', async ({ page }) => {
    const passthru = uniqueDomain('kpt');
    const local = uniqueDomain('klocal');
    const realtime = uniqueDomain('krt');
    const ids: number[] = [];
    try {
      ids.push(await createDomain(page, { domain: passthru, type: 'passthru', pbxs: [eg.gwids[0]] }));
      ids.push(await createDomain(page, { domain: local, type: 'local', pbxs: eg.gwids }));
      ids.push(await createDomain(page, { domain: realtime, type: 'realtime', pbxs: [eg.gwids[1]] }));
      await reloadKamailio(page);

      const domains = kamcmd('domain.dump');
      for (const name of [passthru, local, realtime]) {
        expect(domains).toContain(`domain: ${name}`);
      }

      const sets = kamcmd('dispatcher.list');
      expect(sets).toContain(`ID: ${DOMAIN_SETID_OFFSET + ids[1]}`);
      expect(sets).toContain(`ID: ${DOMAIN_SETID_OFFSET + ids[2]}`);
      // passthru domains route straight to pbx_ip, no dispatcher set
      expect(sets).not.toContain(`ID: ${DOMAIN_SETID_OFFSET + ids[0]}`);

      for (const id of ids.splice(0)) {
        await deleteDomainQuietly(page, id);
      }
      await reloadKamailio(page);

      const after = kamcmd('domain.dump');
      for (const name of [passthru, local, realtime]) {
        expect(after).not.toContain(`domain: ${name}`);
      }
    } finally {
      for (const id of ids) {
        await deleteDomainQuietly(page, id);
      }
    }
  });
});
