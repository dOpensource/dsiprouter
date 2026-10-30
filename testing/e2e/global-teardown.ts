import { request } from '@playwright/test';
import { SHELL_ENABLED, dbQuery } from './helpers';

/**
 * Remove data left behind by aborted test runs: domains named e2e-* and endpoint groups named e2e_*
 * through the API as the admin user, and (with shell access) CDR rows whose call-id starts with e2e-.
 */
export default async function globalTeardown() {
  const baseURL = process.env.DSIP_BASE_URL || 'https://localhost:5000';
  const ctx = await request.newContext({ baseURL, ignoreHTTPSErrors: true });

  try {
    const home = await (await ctx.get('/')).text();
    const csrf = (home.match(/name="csrf_token" value="([^"]+)"/) || [])[1] || '';
    await ctx.post('/login', {
      form: {
        csrf_token: csrf,
        username: process.env.DSIP_TEST_ADMIN_USER || 'admin',
        password: process.env.DSIP_TEST_ADMIN_PASS || 'admin',
      },
      headers: { Referer: `${baseURL}/` },
    });

    const headers = { Accept: 'application/json' };
    const domains = await (await ctx.get('/api/v1/domains', { headers })).json();
    for (const domain of domains.data || []) {
      if (domain.editable && /^e2e-/.test(domain.domain)) {
        await ctx.delete(`/api/v1/domains/${domain.id}`, { headers });
      }
    }

    const groups = await (await ctx.get('/api/v1/endpointgroups', { headers })).json();
    for (const group of groups.data || []) {
      if (/^e2e_/.test(group.name)) {
        await ctx.delete(`/api/v1/endpointgroups/${group.gwgroupid}`, { headers });
      }
    }

    if (SHELL_ENABLED) {
      dbQuery(
        "DELETE FROM cdrs WHERE sip_call_id LIKE 'e2e-%'; DELETE FROM acc WHERE callid LIKE 'e2e-%'; " +
        "DELETE FROM missed_calls WHERE callid LIKE 'e2e-%'"
      );
    }
  } catch (e) {
    console.warn(`global teardown cleanup failed: ${e}`);
  } finally {
    await ctx.dispose();
  }
}
