import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, createTestUser, deleteTestUser } from './helpers';

test.describe('Password Visibility', () => {

  test.describe('as dsip_admin', () => {
    test('admin sees auth_password column in carrier groups', async ({ page }) => {
      await loginAdmin(page);
      await page.goto('/carriergroups');

      // The auth_password column cells exist in the DOM for the admin
      const emptyTable = await page.locator('td.auth_password').count();
      // Either the table is empty or the column exists; column header exists for admin
      await expect(page.locator('th.auth_password')).toHaveCount(1, { timeout: 10000 });
      void emptyTable;
    });

    test('admin sees password input in carrier group add modal', async ({ page }) => {
      await loginAdmin(page);
      await page.goto('/carriergroups');

      await page.click('#open-CarrierGroupAdd');
      await expect(page.locator('input.auth_password')).toBeVisible();
    });

    test('admin sees endpoint group password inputs', async ({ page }) => {
      await loginAdmin(page);
      await page.goto('/endpointgroups');

      // open the add modal / edit modal and verify inputs exist
      await page.click('#open-EndpointGroupAdd');
      await expect(page.locator('#auth_password2')).toBeVisible();
      await expect(page.locator('#auth_password')).not.toBeVisible();
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
        await expect(engPage.locator('input.auth_password')).toHaveCount(0);
        await engPage.locator('#add-gwgroup .btn-secondary').click();

        // Endpoint groups page
        await engPage.goto('/endpointgroups');
        await engPage.click('#open-EndpointGroupAdd');
        await expect(engPage.locator('#auth_password2')).toHaveCount(0);
        await expect(engPage.locator('#auth_password')).toHaveCount(0);
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
        await expect(guestPage.locator('input.auth_password')).toHaveCount(0);
      } finally {
        await guestCtx.close();
        await deleteTestUser(adminPage, guestUser);
        await adminCtx.close();
      }
    });
  });
});