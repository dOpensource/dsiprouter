import { request } from '@playwright/test';

/**
 * Remove data left behind by aborted test runs: domains named e2e-* and endpoint groups named e2e_*.
 * Uses the API as the admin user so it works without shell access.
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
  } catch (e) {
    console.warn(`global teardown cleanup failed: ${e}`);
  } finally {
    await ctx.dispose();
  }
}
