import { test, expect } from '@playwright/test';
import { loginAdmin, createTestUser, deleteTestUser, filterUsersTable } from './helpers';

test.describe('User CRUD - Admin', () => {

  test('admin can access /users page', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/users');
    await expect(page.locator('h3:has-text("Users")')).toBeVisible();
    await expect(page.locator('#users-table')).toBeVisible();
  });

  test('create user via GUI', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/users');

    const testUser = `e2e_crud_${Date.now()}`;
    try {
      await page.click('#open-UserAdd');
      await expect(page.locator('#add')).toBeVisible();
      await page.fill('#add-firstname', 'Test');
      await page.fill('#add-lastname', 'User');
      await page.fill('#add-username', testUser);
      await page.fill('#add-password', 'testpass123');
      await page.selectOption('#add-roles', 'dsip_engineer');
      await page.click('#submitAddUser');

      // the submit handler reloads the page on success; let the navigation land
      // before filtering or the reload wipes the search input mid-assertion
      await page.waitForLoadState('load').catch(() => {});
      await filterUsersTable(page, testUser);
      await expect(page.locator(`tr[data-username="${testUser}"]`)).toBeVisible({ timeout: 10000 });
    } finally {
      await page.reload();
      await deleteTestUser(page, testUser);
    }
  });

  test('create dsip_guest user', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/users');

    const testUser = `e2e_guest_${Date.now()}`;
    try {
      await page.click('#open-UserAdd');
      await expect(page.locator('#add')).toBeVisible();
      await page.fill('#add-firstname', 'Test');
      await page.fill('#add-lastname', 'User');
      await page.fill('#add-username', testUser);
      await page.fill('#add-password', 'testpass123');
      await page.selectOption('#add-roles', 'dsip_guest');
      await page.click('#submitAddUser');

      await page.waitForLoadState('load').catch(() => {});
      await filterUsersTable(page, testUser);
      await expect(page.locator(`tr[data-username="${testUser}"]`)).toBeVisible({ timeout: 10000 });
    } finally {
      await page.reload();
      await deleteTestUser(page, testUser);
    }
  });

  test('edit user role via GUI', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/users');

    const testUser = `e2e_edit_${Date.now()}`;
    try {
      // Create user via API then reload
      const created = await createTestUser(page, testUser, 'testpass123', 'dsip_guest');
      expect(created.status).toBe(200);
      await page.reload();
      await filterUsersTable(page, testUser);

      // Click edit button
      await page.click(`tr[data-username="${testUser}"] .open-Edit`);
      await expect(page.locator('#edit')).toBeVisible();
      const rolesSelect = page.locator('#edit-roles');
      await rolesSelect.selectOption('dsip_engineer');
      await page.click('#submitEditUser');

      // Verify role changed after reload
      const row = page.locator(`tr[data-username="${testUser}"]`);
      await expect(row.locator('.roles')).toContainText('dsip_engineer', { timeout: 10000 });
    } finally {
      await page.reload();
      await deleteTestUser(page, testUser);
    }
  });

  test('delete user via GUI', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/users');

    const testUser = `e2e_delete_${Date.now()}`;
    const created = await createTestUser(page, testUser, 'testpass123', 'dsip_guest');
    expect(created.status).toBe(200);
    await page.reload();
    await filterUsersTable(page, testUser);

    // Click delete button
    await page.click(`tr[data-username="${testUser}"] .open-Delete`);
    await expect(page.locator('#delete')).toBeVisible();
    await expect(page.locator('#delete-username-display')).toHaveText(testUser);
    await page.click('#submitDeleteUser');

    await expect(page.locator(`tr[data-username="${testUser}"]`)).not.toBeVisible({ timeout: 10000 });
  });

  test('duplicate username shows error', async ({ page }) => {
    await loginAdmin(page);
    const testUser = `e2e_dup_${Date.now()}`;

    try {
      const created = await createTestUser(page, testUser, 'testpass123', 'dsip_guest');
      expect(created.status).toBe(200);

      await page.goto('/users');
      await filterUsersTable(page, testUser);
      await page.click('#open-UserAdd');
      await expect(page.locator('#add')).toBeVisible();
      await page.fill('#add-firstname', 'Test');
      await page.fill('#add-lastname', 'User');
      await page.fill('#add-username', testUser);
      await page.fill('#add-password', 'testpass123');
      await page.selectOption('#add-roles', 'dsip_guest');

      // Accept the error alert and confirm no duplicate row appears
      page.on('dialog', dialog => dialog.accept());
      await page.click('#submitAddUser');
      await page.waitForTimeout(1000);

      await filterUsersTable(page, testUser);
      await expect(page.locator(`tr[data-username="${testUser}"]`)).toHaveCount(1);
    } finally {
      await page.reload();
      await deleteTestUser(page, testUser);
    }
  });
});