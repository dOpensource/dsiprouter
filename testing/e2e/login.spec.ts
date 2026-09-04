import { test, expect } from '@playwright/test';
import { loginGUI, loginAdmin, expectLoginPage, expectDashboard, createTestUser, deleteTestUser, ADMIN_USER, ADMIN_PASS } from './helpers';

test.describe('Login Flow', () => {

  test('settings-based admin login succeeds', async ({ page }) => {
    await loginAdmin(page);
    await expectDashboard(page);
  });

  test('table-based user login succeeds', async ({ page, browser }) => {
    // Admin creates a test user first
    await loginAdmin(page);
    const testUser = `e2e_login_test_${Date.now()}`;

    try {
      const created = await createTestUser(page, testUser, 'testpass123', 'dsip_engineer');
      expect(created.status).toBe(200);

      // Login as the table-based user from a fresh context so the admin
      // session cookie does not carry over
      const ctx = await browser.newContext();
      const loginPage = await ctx.newPage();
      await loginGUI(loginPage, testUser, 'testpass123');
      await expectDashboard(loginPage);
      await ctx.close();
    } finally {
      await deleteTestUser(page, testUser);
    }
  });

  test('invalid credentials shows error', async ({ page }) => {
    await page.goto('/');
    await page.fill('#login-username', 'nonexistent_user');
    await page.fill('#login-password', 'wrongpassword');
    await page.click('button[type="submit"]');

    // Should stay on login page and show flash message
    await expect(page.locator('ul.alert-danger')).toBeVisible();
  });

  test('empty credentials shows error', async ({ page }) => {
    await page.goto('/');
    await page.click('button[type="submit"]');

    // Should NOT reach the dashboard
    await expect(page.locator('.dashboard-container')).not.toBeVisible();
  });

  test('logout clears session and redirects to login', async ({ page }) => {
    await loginAdmin(page);
    await expectDashboard(page);

    await page.goto('/logout');
    await expectLoginPage(page);
  });
});