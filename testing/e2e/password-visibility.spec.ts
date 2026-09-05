import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, createTestUser, deleteTestUser } from './helpers';

test.describe('Password Visibility', () => {

  test.describe('as dsip_admin', () => {
    test('admin sees password input in carrier group add modal', async ({ page }) => {
      await loginAdmin(page);
      await page.goto('/carriergroups');

      await page.click('#open-CarrierGroupAdd');
      await expect(page.locator('#add-group')).toBeVisible();
      // toggle the add-modal auth type radio to reveal the password field;
      // carriergroups.js rewrites radio `value` attrs on open, so key off the
      // stable `data-toggle` selector instead
      await page.locator('#add-group input[data-toggle="userpwd_enabled"]').check();
      await expect(page.locator('#add-group input.auth_password')).toBeVisible();
    });

    test('admin sees endpoint group password inputs', async ({ page }) => {
      await loginAdmin(page);
      await page.goto('/endpointgroups');

      await page.click('#open-EndpointGroupsAdd');
      await expect(page.locator('#add')).toBeVisible();
      // add-modal control ids are unsuffixed: #userpwd / #auth_password
      // (the *2 suffixed ids belong to the update modal)
      await page.locator('#add #userpwd').check();
      await expect(page.locator('#add #auth_password')).toBeVisible();
      await expect(page.locator('#add #auth_password2')).toHaveCount(0);
    });
  });

  test.describe('as non-admin (dsip_engineer)', () => {
    const engineerUser = `e2e_pwd_eng_${Date.now()}`;

    test('non-admin does not see auth_password column or inputs', async ({ browser }) => {
      // Create the engineer user via a temporary admin context
      const adminCtx = await browser.newContext();
      const adminPage = await adminCtx.newPage();
      await loginAdmin(adminPage);
      await createTestUser(adminPage, engineerUser, 'testpass123', 'dsip_engineer');

      const engCtx = await browser.newContext();
      const engPage = await engCtx.newPage();
      try {
        await loginGUI(engPage, engineerUser, 'testpass123');

        // Carrier groups page
        await engPage.goto('/carriergroups');
        await expect(engPage.locator('td.auth_password')).toHaveCount(0, { timeout: 10000 });
        await engPage.click('#open-CarrierGroupAdd');
        await expect(engPage.locator('#add-group')).toBeVisible();
        await expect(engPage.locator('input.auth_password')).toHaveCount(0);

        // Endpoint groups page (both modals are in the DOM, none may carry inputs)
        await engPage.goto('/endpointgroups');
        await expect(engPage.locator('input.auth_password')).toHaveCount(0);
        await expect(engPage.locator('#auth_password2')).toHaveCount(0);
      } finally {
        await engCtx.close();
        await deleteTestUser(adminPage, engineerUser);
        await adminCtx.close();
      }
    });
  });

  test.describe('as dsip_guest', () => {
    const guestUser = `e2e_pwd_guest_${Date.now()}`;

    test('guest does not see auth_password column or inputs', async ({ browser }) => {
      const adminCtx = await browser.newContext();
      const adminPage = await adminCtx.newPage();
      await loginAdmin(adminPage);
      await createTestUser(adminPage, guestUser, 'testpass123', 'dsip_guest');

      const guestCtx = await browser.newContext();
      const guestPage = await guestCtx.newPage();
      try {
        await loginGUI(guestPage, guestUser, 'testpass123');

        await guestPage.goto('/carriergroups');
        await expect(guestPage.locator('td.auth_password')).toHaveCount(0, { timeout: 10000 });
        await guestPage.click('#open-CarrierGroupAdd');
        await expect(guestPage.locator('#add-group')).toBeVisible();
        await expect(guestPage.locator('input.auth_password')).toHaveCount(0);
      } finally {
        await guestCtx.close();
        await deleteTestUser(adminPage, guestUser);
        await adminCtx.close();
      }
    });
  });
});