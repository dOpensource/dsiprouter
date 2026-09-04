import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, guiApiRequest, createTestUser, deleteTestUser } from './helpers';

test.describe('Role-Based Access Control', () => {

  test.describe('dsip_admin role', () => {
    test('admin can access all pages', async ({ page }) => {
      await loginAdmin(page);

      // Dashboard
      await page.goto('/');
      await expect(page.locator('.dashboard-container')).toBeVisible();

      // Settings
      await page.goto('/settings');
      await expect(page.locator('h3:has-text("Settings")')).toBeVisible();

      // Users
      await page.goto('/users');
      await expect(page.locator('h3:has-text("Users")')).toBeVisible();
    });

    test('admin API access to /api/v1/users returns 200', async ({ page }) => {
      await loginAdmin(page);
      const result = await guiApiRequest(page, 'GET', '/users');
      expect(result.status).toBe(200);
    });
  });

  test.describe('dsip_engineer role', () => {

    // non-admin pages must use a FRESH browser context so the admin session
    // cookie does not carry over (page.context() would share it)
    const freshContext = async (browser: any) => {
      const ctx = await browser.newContext();
      return { ctx, page: await ctx.newPage() };
    };

    test('engineer can access dashboard and settings', async ({ page, browser }) => {
      const engineerUser = `e2e_eng_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, engineerUser, 'testpass123', 'dsip_engineer');

      const { ctx, page: engPage } = await freshContext(browser);
      try {
        await loginGUI(engPage, engineerUser, 'testpass123');
        await expect(engPage.locator('.dashboard-container')).toBeVisible();

        await engPage.goto('/settings');
        await expect(engPage.locator('h3:has-text("Settings")')).toBeVisible();
      } finally {
        await ctx.close();
        await deleteTestUser(page, engineerUser);
      }
    });

    test('engineer cannot access users page', async ({ page, browser }) => {
      const engineerUser = `e2e_eng_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, engineerUser, 'testpass123', 'dsip_engineer');

      const { ctx, page: engPage } = await freshContext(browser);
      try {
        await loginGUI(engPage, engineerUser, 'testpass123');
        await engPage.goto('/users');

        // Should be redirected away from /users
        await expect(engPage).not.toHaveURL(/.*\/users/);
      } finally {
        await ctx.close();
        await deleteTestUser(page, engineerUser);
      }
    });

    test('engineer API call to /api/v1/users returns 403', async ({ page, browser }) => {
      const engineerUser = `e2e_eng_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, engineerUser, 'testpass123', 'dsip_engineer');

      const { ctx, page: engPage } = await freshContext(browser);
      try {
        await loginGUI(engPage, engineerUser, 'testpass123');
        const result = await guiApiRequest(engPage, 'GET', '/users');
        expect(result.status).toBe(403);
      } finally {
        await ctx.close();
        await deleteTestUser(page, engineerUser);
      }
    });
  });

  test.describe('dsip_guest role', () => {

    const freshContext = async (browser: any) => {
      const ctx = await browser.newContext();
      return { ctx, page: await ctx.newPage() };
    };

    test('guest can access dashboard', async ({ page, browser }) => {
      const guestUser = `e2e_guest_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, guestUser, 'testpass123', 'dsip_guest');

      const { ctx, page: guestPage } = await freshContext(browser);
      try {
        await loginGUI(guestPage, guestUser, 'testpass123');
        await expect(guestPage.locator('.dashboard-container')).toBeVisible();
      } finally {
        await ctx.close();
        await deleteTestUser(page, guestUser);
      }
    });

    test('guest cannot access users page', async ({ page, browser }) => {
      const guestUser = `e2e_guest_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, guestUser, 'testpass123', 'dsip_guest');

      const { ctx, page: guestPage } = await freshContext(browser);
      try {
        await loginGUI(guestPage, guestUser, 'testpass123');
        await guestPage.goto('/users');
        await expect(guestPage).not.toHaveURL(/.*\/users/);
      } finally {
        await ctx.close();
        await deleteTestUser(page, guestUser);
      }
    });

    test('guest cannot access settings page', async ({ page, browser }) => {
      const guestUser = `e2e_guest_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, guestUser, 'testpass123', 'dsip_guest');

      const { ctx, page: guestPage } = await freshContext(browser);
      try {
        await loginGUI(guestPage, guestUser, 'testpass123');
        await guestPage.goto('/settings');

        // Should be redirected away from /settings
        await expect(guestPage).not.toHaveURL(/.*\/settings/);
      } finally {
        await ctx.close();
        await deleteTestUser(page, guestUser);
      }
    });

    test('guest API call to /api/v1/users returns 403', async ({ page, browser }) => {
      const guestUser = `e2e_guest_${Date.now()}`;
      await loginAdmin(page);
      await createTestUser(page, guestUser, 'testpass123', 'dsip_guest');

      const { ctx, page: guestPage } = await freshContext(browser);
      try {
        await loginGUI(guestPage, guestUser, 'testpass123');
        const result = await guiApiRequest(guestPage, 'GET', '/users');
        expect(result.status).toBe(403);
      } finally {
        await ctx.close();
        await deleteTestUser(page, guestUser);
      }
    });
  });
});