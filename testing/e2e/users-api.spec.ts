import { test, expect } from '@playwright/test';
import { loginAdmin, loginGUI, loginAPI, guiApiRequest, ADMIN_USER, ADMIN_PASS } from './helpers';

test.describe('Users API', () => {

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
  });

  test('GET /api/v1/users as admin returns user list', async ({ page }) => {
    const result = await guiApiRequest(page, 'GET', '/users');
    expect(result.status).toBe(200);
    expect(Array.isArray(result.data.data)).toBe(true);
    expect(result.data.data.length).toBeGreaterThan(0);
  });

  test('GET /api/v1/users?username=xxxx filters by username', async ({ page }) => {
    const result = await guiApiRequest(page, 'GET', `/users?username=${encodeURIComponent(ADMIN_USER)}`);
    expect(result.status).toBe(200);
    expect(result.data.data.length).toBe(1);
    expect(result.data.data[0].username).toBe(ADMIN_USER);
  });

  test('GET /api/v1/users?group=dsip_admin filters by group', async ({ page }) => {
    const result = await guiApiRequest(page, 'GET', '/users?group=dsip_admin');
    expect(result.status).toBe(200);
    expect(result.data.data.length).toBeGreaterThan(0);
    for (const user of result.data.data) {
      expect(user.groups).toContain('dsip_admin');
    }
  });

  test('POST /api/v1/users creates a user and returns api_token', async ({ page }) => {
    const testUser = `e2e_api_create_${Date.now()}`;
    try {
      const result = await guiApiRequest(page, 'POST', '/users', {
        username: testUser,
        password: 'testpass123',
        group: 'dsip_engineer',
      });
      expect(result.status).toBe(200);
      expect(result.data.data.username).toBe(testUser);
      expect(result.data.data.groups).toContain('dsip_engineer');
      expect(result.data.data.auth_type).toBe('local');
      expect(result.data.data.api_token).toBeTruthy();
    } finally {
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('PUT /api/v1/users?username=xxxx updates a user group', async ({ page }) => {
    const testUser = `e2e_api_update_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/users', {
        username: testUser,
        password: 'testpass123',
        group: 'dsip_guest',
      });
      expect(created.status).toBe(200);

      const result = await guiApiRequest(page, 'PUT', `/users?username=${encodeURIComponent(testUser)}`, {
        group: 'dsip_engineer',
      });
      expect(result.status).toBe(200);
      expect(result.data.data.groups).toContain('dsip_engineer');
    } finally {
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('DELETE /api/v1/users?username=xxxx deletes a user', async ({ page }) => {
    const testUser = `e2e_api_delete_${Date.now()}`;
    const created = await guiApiRequest(page, 'POST', '/users', {
      username: testUser,
      password: 'testpass123',
      group: 'dsip_guest',
    });
    expect(created.status).toBe(200);

    const result = await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    expect(result.status).toBe(200);

    const listResult = await guiApiRequest(page, 'GET', `/users?username=${encodeURIComponent(testUser)}`);
    expect(listResult.status).toBe(200);
    expect(listResult.data.data.length).toBe(0);
  });

  test('GET /api/v1/users/<username>/token returns the stored token', async ({ page }) => {
    const testUser = `e2e_api_token_${Date.now()}`;
    try {
      const createResult = await guiApiRequest(page, 'POST', '/users', {
        username: testUser,
        password: 'testpass123',
        group: 'dsip_guest',
      });
      const expectedToken = createResult.data.data.api_token;

      const result = await guiApiRequest(page, 'GET', `/users/${encodeURIComponent(testUser)}/token`);
      expect(result.status).toBe(200);
      expect(result.data.data.api_token).toBe(expectedToken);
    } finally {
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('POST /api/v1/users/<username>/token regenerates token', async ({ page }) => {
    const testUser = `e2e_api_regen_${Date.now()}`;
    try {
      const createResult = await guiApiRequest(page, 'POST', '/users', {
        username: testUser,
        password: 'testpass123',
        group: 'dsip_guest',
      });
      const oldToken = createResult.data.data.api_token;

      const result = await guiApiRequest(page, 'POST', `/users/${encodeURIComponent(testUser)}/token`);
      expect(result.status).toBe(200);
      expect(result.data.data.api_token).toBeTruthy();
      expect(result.data.data.api_token).not.toBe(oldToken);
    } finally {
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('non-admin API call returns 403', async ({ page }) => {
    const testUser = `e2e_api_403_${Date.now()}`;
    const created = await guiApiRequest(page, 'POST', '/users', {
      username: testUser,
      password: 'testpass123',
      group: 'dsip_guest',
    });
    expect(created.status).toBe(200);

    // Login as the guest via GUI in a fresh page (own session)
    const guestPage = await page.context().newPage();
    try {
      await loginGUI(guestPage, testUser, 'testpass123');

      const result = await guiApiRequest(guestPage, 'GET', '/users');
      expect(result.status).toBe(403);
    } finally {
      await guestPage.close();
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('invalid group returns 400', async ({ page }) => {
    const result = await guiApiRequest(page, 'POST', '/users', {
      username: 'test_invalid_group',
      password: 'testpass123',
      group: 'invalid_group',
    });
    expect(result.status).toBe(400);
  });

  test('missing required args returns 400', async ({ page }) => {
    const result = await guiApiRequest(page, 'POST', '/users', {
      username: 'test_missing_args',
    });
    expect(result.status).toBe(400);
  });

  test('local user missing password returns 400', async ({ page }) => {
    const result = await guiApiRequest(page, 'POST', '/users', {
      username: 'test_no_password',
      group: 'dsip_guest',
    });
    expect(result.status).toBe(400);
  });

  test('login API validates settings admin and returns token', async () => {
    const result = await loginAPI(ADMIN_USER, ADMIN_PASS);
    expect(result.status).toBe(200);
    expect(result.token).toBeTruthy();
  });

  test('login API validates table-based user and returns token', async ({ page }) => {
    const testUser = `e2e_api_login_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/users', {
        username: testUser,
        password: 'testpass123',
        group: 'dsip_guest',
      });
      expect(created.status).toBe(200);
      const storedToken = created.data.data.api_token;

      const result = await loginAPI(testUser, 'testpass123');
      expect(result.status).toBe(200);
      expect(result.token).toBe(storedToken);
    } finally {
      await guiApiRequest(page, 'DELETE', `/users?username=${encodeURIComponent(testUser)}`);
    }
  });

  test('login API rejects invalid credentials', async () => {
    const result = await loginAPI('nonexistent_user', 'wrongpassword');
    expect(result.status).toBe(401);
  });
});