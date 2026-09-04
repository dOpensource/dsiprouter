import { test, expect } from '@playwright/test';
import { loginAdmin, loginAPI, guiApiRequest, findUserId } from './helpers';

test.describe('Users API', () => {

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
  });

  test('GET /api/v1/auth/user as admin returns user list', async ({ page }) => {
    const result = await guiApiRequest(page, 'GET', '/auth/user');
    expect(result.status).toBe(200);
    expect(Array.isArray(result.data)).toBe(true);
  });

  test('POST /api/v1/auth/user creates a user and appears in the list', async ({ page }) => {
    const testUser = `e2e_api_create_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/auth/user', {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        password: 'testpass123',
        roles: ['dsip_engineer'],
        domains: [],
      });
      expect(created.status).toBe(200);
      expect(created.data.data.message).toBe('User Created Successfully');

      const list = await guiApiRequest(page, 'GET', '/auth/user');
      const row = list.data.find((u: any) => u.username === testUser);
      expect(row).toBeTruthy();
      expect(row.roles).toContain('dsip_engineer');
    } finally {
      await deleteTestUserByName(page, testUser);
    }
  });

  test('POST duplicate username returns 409', async ({ page }) => {
    const testUser = `e2e_api_dup_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/auth/user', {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        password: 'testpass123',
        roles: ['dsip_guest'],
        domains: [],
      });
      expect(created.status).toBe(200);

      const dup = await guiApiRequest(page, 'POST', '/auth/user', {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        password: 'testpass123',
        roles: ['dsip_guest'],
        domains: [],
      });
      expect(dup.status).toBe(409);
    } finally {
      await deleteTestUserByName(page, testUser);
    }
  });

  test('PUT /api/v1/auth/user/<id> updates role and keeps password', async ({ page }) => {
    const testUser = `e2e_api_update_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/auth/user', {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        password: 'testpass123',
        roles: ['dsip_guest'],
        domains: [],
      });
      expect(created.status).toBe(200);

      const id = await findUserId(page, testUser);
      expect(id).not.toBeNull();

      // Role-only edit: no password field sent, password must be preserved
      const updated = await guiApiRequest(page, 'PUT', `/auth/user/${id}`, {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        roles: ['dsip_engineer'],
        domains: [],
      });
      expect(updated.status).toBe(200);
      expect(updated.data.data.roles).toContain('dsip_engineer');

      // password was preserved, login still works
      const login = await loginAPI(testUser, 'testpass123');
      expect(login.status).toBe(200);
    } finally {
      await deleteTestUserByName(page, testUser);
    }
  });

  test('DELETE /api/v1/auth/user/<id> deletes a user', async ({ page }) => {
    const testUser = `e2e_api_delete_${Date.now()}`;
    const created = await guiApiRequest(page, 'POST', '/auth/user', {
      firstname: 'Test',
      lastname: 'User',
      username: testUser,
      password: 'testpass123',
      roles: ['dsip_guest'],
      domains: [],
    });
    expect(created.status).toBe(200);

    const id = await findUserId(page, testUser);
    expect(id).not.toBeNull();

    const result = await guiApiRequest(page, 'DELETE', `/auth/user/${id}`);
    expect(result.status).toBe(200);

    const list = await guiApiRequest(page, 'GET', '/auth/user');
    expect(list.data.find((u: any) => u.username === testUser)).toBeUndefined();
  });

  test('login API validates table-based user and returns token', async ({ page }) => {
    const testUser = `e2e_api_login_${Date.now()}`;
    try {
      const created = await guiApiRequest(page, 'POST', '/auth/user', {
        firstname: 'Test',
        lastname: 'User',
        username: testUser,
        password: 'testpass123',
        roles: ['dsip_guest'],
        domains: [],
      });
      expect(created.status).toBe(200);

      const result = await loginAPI(testUser, 'testpass123');
      expect(result.status).toBe(200);
      expect(result.token).toBeTruthy();
    } finally {
      await deleteTestUserByName(page, testUser);
    }
  });

  test('login API rejects invalid credentials', async () => {
    const result = await loginAPI('nonexistent_user', 'wrongpassword');
    expect(result.status).toBe(401);
  });
});

async function deleteTestUserByName(page: any, username: string) {
  const id = await findUserId(page, username);
  if (id !== null) {
    await guiApiRequest(page, 'DELETE', `/auth/user/${id}`);
  }
}