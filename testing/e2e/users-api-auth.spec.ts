import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, guiApiRequest, createTestUser, deleteTestUser, findUserId } from './helpers';

// every /api/v1/auth/user route, the login route is the only auth route open without credentials
const USER_ROUTES = (id: number): [string, string, any?][] => [
  ['GET', '/auth/user'],
  ['POST', '/auth/user', {
    firstname: 'E2E', lastname: 'Intruder', username: `e2e_intruder_${Date.now()}`, password: 'x',
    roles: ['dsip_admin'], domains: [],
  }],
  ['GET', `/auth/user/${id}`],
  ['PUT', `/auth/user/${id}`, { password: 'hijacked', roles: ['dsip_admin'], domains: [] }],
  ['DELETE', `/auth/user/${id}`],
];

const freshContext = async (browser: any) => {
  const ctx = await browser.newContext();
  return { ctx, page: await ctx.newPage() };
};

test.describe('User API authentication', () => {
  let target: string;
  let targetId: number;

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    target = `e2e_target_${Date.now()}`;
    expect((await createTestUser(page, target, 'targetpass1', 'dsip_guest')).status).toBe(200);
    targetId = (await findUserId(page, target))!;
    expect(targetId).not.toBeNull();
  });

  test.afterEach(async ({ page }) => {
    await deleteTestUser(page, target);
  });

  async function expectTargetUnchanged(page: any, browser: any) {
    const res = await guiApiRequest(page, 'GET', `/auth/user/${targetId}`);
    expect(res.status).toBe(200);
    expect(res.data.username).toBe(target);
    expect(res.data.roles).toEqual(['dsip_guest']);
    // the password was not changed either
    const { ctx, page: check } = await freshContext(browser);
    try {
      await loginGUI(check, target, 'targetpass1');
      await expect(check.locator('.dashboard-container')).toBeVisible();
    } finally {
      await ctx.close();
    }
  }

  test('logged out requests are refused on every user route', async ({ page, browser }) => {
    const { ctx, page: anon } = await freshContext(browser);
    try {
      for (const [method, path, body] of USER_ROUTES(targetId)) {
        const res = await guiApiRequest(anon, method, path, body);
        expect(res.status, `${method} ${path}`).toBe(401);
        expect(JSON.stringify(res.data)).not.toContain(target);
      }
    } finally {
      await ctx.close();
    }
    await expectTargetUnchanged(page, browser);
    expect(await findUserId(page, 'e2e_intruder_')).toBeNull();
  });

  for (const role of ['dsip_engineer', 'dsip_guest']) {
    test(`${role} can not list, create, change or delete users`, async ({ page, browser }) => {
      const caller = `e2e_caller_${Date.now()}`;
      await createTestUser(page, caller, 'callerpass1', role);
      const { ctx, page: other } = await freshContext(browser);
      try {
        await loginGUI(other, caller, 'callerpass1');
        for (const [method, path, body] of USER_ROUTES(targetId)) {
          const res = await guiApiRequest(other, method, path, body);
          expect(res.status, `${method} ${path}`).toBe(403);
        }
        // nor promote itself
        const callerId = (await findUserId(page, caller))!;
        const promote = await guiApiRequest(other, 'PUT', `/auth/user/${callerId}`, { roles: ['dsip_admin'], domains: [] });
        expect(promote.status).toBe(403);
        expect((await guiApiRequest(page, 'GET', `/auth/user/${callerId}`)).data.roles).toEqual([role]);
      } finally {
        await ctx.close();
        await deleteTestUser(page, caller);
      }
      await expectTargetUnchanged(page, browser);
    });
  }

  test('admin still manages users', async ({ page }) => {
    const list = await guiApiRequest(page, 'GET', '/auth/user');
    expect(list.status).toBe(200);
    expect(list.data.map((u: any) => u.username)).toContain(target);
    const update = await guiApiRequest(page, 'PUT', `/auth/user/${targetId}`, {
      firstname: 'Changed', roles: ['dsip_guest'], domains: [],
    });
    expect(update.status).toBe(200);
    expect((await guiApiRequest(page, 'GET', `/auth/user/${targetId}`)).data.firstname).toBe('Changed');
  });
});
