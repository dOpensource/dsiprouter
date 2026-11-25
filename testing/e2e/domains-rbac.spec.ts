import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, guiApiRequest, createTestUser, deleteTestUser, freshContext } from './helpers';
import { createEndpointGroupFixture, deleteEndpointGroupFixture, EndpointGroupFixture } from './fixtures/endpoints';
import { uniqueDomain, createDomain, deleteDomainQuietly } from './fixtures/domains';

test.describe('Domains permissions', () => {
  let eg: EndpointGroupFixture;

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    eg = await createEndpointGroupFixture(page, 1);
  });

  test.afterEach(async ({ page }) => {
    await deleteEndpointGroupFixture(page, eg);
  });

  test('guest can read domains but not change them', async ({ page, browser }) => {
    const guestUser = `e2e_guest_${Date.now()}`;
    const name = uniqueDomain('rbac');
    let id: number | undefined;
    await createTestUser(page, guestUser, 'testpass123', 'dsip_guest');
    const { ctx, page: guestPage } = await freshContext(browser);
    try {
      id = await createDomain(page, { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] });
      await loginGUI(guestPage, guestUser, 'testpass123');

      expect((await guiApiRequest(guestPage, 'GET', '/domains')).status).toBe(200);
      expect((await guiApiRequest(guestPage, 'GET', `/domains/${id}`)).status).toBe(200);
      const post = await guiApiRequest(guestPage, 'POST', '/domains',
        { domain: uniqueDomain('rbac'), type: 'passthru', pbxs: [eg.gwids[0]] });
      expect(post.status).toBe(403);
      expect((await guiApiRequest(guestPage, 'PUT', `/domains/${id}`, { notes: 'x' })).status).toBe(403);
      expect((await guiApiRequest(guestPage, 'DELETE', `/domains/${id}`)).status).toBe(403);

      await guestPage.goto('/domains');
      await guestPage.fill('input[type="search"]', name);
      await expect(guestPage.locator('#domains tbody tr', { hasText: name })).toHaveCount(1);
      await expect(guestPage.locator('#open-DomainAdd')).toHaveCount(0);
      await expect(guestPage.locator('#domains .open-Update')).toHaveCount(0);
      await expect(guestPage.locator('#domains .open-Delete')).toHaveCount(0);
    } finally {
      await ctx.close();
      await deleteDomainQuietly(page, id);
      await deleteTestUser(page, guestUser);
    }
  });

  test('engineer can create, update and delete domains', async ({ page, browser }) => {
    const engineerUser = `e2e_eng_${Date.now()}`;
    await createTestUser(page, engineerUser, 'testpass123', 'dsip_engineer');
    const { ctx, page: engPage } = await freshContext(browser);
    let id: number | undefined;
    try {
      await loginGUI(engPage, engineerUser, 'testpass123');
      id = await createDomain(engPage, { domain: uniqueDomain('eng'), type: 'passthru', pbxs: [eg.gwids[0]] });
      expect((await guiApiRequest(engPage, 'PUT', `/domains/${id}`, { notes: 'eng' })).status).toBe(200);
      expect((await guiApiRequest(engPage, 'DELETE', `/domains/${id}`)).status).toBe(200);
      id = undefined;

      await engPage.goto('/domains');
      await expect(engPage.locator('#open-DomainAdd')).toBeVisible();
    } finally {
      await ctx.close();
      await deleteDomainQuietly(page, id);
      await deleteTestUser(page, engineerUser);
    }
  });

  test('logged out requests are refused', async ({ browser }) => {
    const { ctx, page: anonPage } = await freshContext(browser);
    try {
      expect((await guiApiRequest(anonPage, 'GET', '/domains')).status).toBe(401);
      expect((await guiApiRequest(anonPage, 'POST', '/domains', { domain: uniqueDomain(), type: 'passthru', pbxs: [1] })).status).toBe(401);
      await anonPage.goto('/domains');
      await expect(anonPage.locator('#loginform')).toBeVisible();
    } finally {
      await ctx.close();
    }
  });
});
