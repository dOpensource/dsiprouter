import { Page, expect } from '@playwright/test';

// Node's fetch (used by loginAPI) rejects self-signed test-instance certs;
// relax TLS trust only for API probes. Browser contexts keep their own
// ignoreHTTPSErrors handling via playwright.config.ts.
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const BASE_URL = process.env.DSIP_BASE_URL || 'https://localhost:5000';
const API_BASE = `${BASE_URL}/api/v1`;
const ADMIN_USER = process.env.DSIP_TEST_ADMIN_USER || 'admin';
const ADMIN_PASS = process.env.DSIP_TEST_ADMIN_PASS || 'admin';

/**
 * Login via the GUI form. Establishes the session cookie used by all
 * subsequent requests in the same browser context.
 */
export async function loginGUI(page: Page, username: string, password: string) {
  await page.goto('/');
  await page.fill('#login-username', username);
  await page.fill('#login-password', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('**/');
}

/**
 * Login the defaults-based admin via the GUI form.
 */
export async function loginAdmin(page: Page) {
  await loginGUI(page, ADMIN_USER, ADMIN_PASS);
  await expectDashboard(page);
}

/**
 * Perform an API request carrying the current browser-context session cookie.
 *
 * This is the session-based path (what the GUI itself uses), so it works on
 * installs without a DSIP_CORE license. The /api/v1/auth/user routes are
 * CSRF-exempt, so no token is required beyond the session.
 */
export async function guiApiRequest(
  page: Page,
  method: string,
  path: string,
  body?: any
): Promise<{ status: number; data: any }> {
  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  const response = await page.request.fetch(`${API_BASE}${path}`, {
    method,
    headers,
    data: body !== undefined ? JSON.stringify(body) : undefined,
  });

  let data: any = {};
  try {
    data = await response.json();
  } catch (e) {
    // non-JSON response body; keep empty object
  }
  return { status: response.status(), data };
}

/**
 * Validate a username/password pair through the login API.
 * Returns (status, token) of the login attempt.
 */
export async function loginAPI(username: string, password: string): Promise<{ status: number; token?: string }> {
  const response = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify({ username, password }),
  });
  let data: any = {};
  try {
    data = await response.json();
  } catch (e) {
    // ignore parse errors
  }
  return { status: response.status, token: data.token };
}

/**
 * Create a test user (as the currently logged-in admin session) via the
 * existing /api/v1/auth/user API.
 */
export async function createTestUser(
  page: Page,
  username: string,
  password: string,
  role: string = 'dsip_guest'
): Promise<{ status: number; data: any }> {
  return guiApiRequest(page, 'POST', '/auth/user', {
    firstname: 'Test',
    lastname: 'User',
    username,
    password,
    roles: [role],
    domains: [],
  });
}

/**
 * Look up a user's row id from the existing /api/v1/auth/user list.
 */
export async function findUserId(page: Page, username: string): Promise<number | null> {
  const result = await guiApiRequest(page, 'GET', '/auth/user');
  if (result.status !== 200 || !Array.isArray(result.data)) {
    return null;
  }
  const found = result.data.find((u: any) => u.username === username);
  return found ? found.id : null;
}

/**
 * Delete a test user by id (as the currently logged-in admin session).
 */
export async function deleteTestUser(
  page: Page,
  username: string
): Promise<{ status: number; data: any }> {
  const id = await findUserId(page, username);
  if (id === null) {
    return { status: 404, data: {} };
  }
  return guiApiRequest(page, 'DELETE', `/auth/user/${id}`);
}

/**
 * Assert that the page shows the login form.
 */
export async function expectLoginPage(page: Page) {
  await expect(page.locator('#loginform')).toBeVisible();
}

/**
 * Assert that the page shows the dashboard.
 */
export async function expectDashboard(page: Page) {
  await expect(page.locator('.dashboard-container')).toBeVisible();
}

/**
 * Filter the users DataTable to a specific username so its single row is on
 * the visible page (the table is client-side paginated at 25 rows/page).
 * DataTables 2 renders the search box as the sole input[type=search].
 */
export async function filterUsersTable(page: Page, query: string) {
  await page.fill('input[type="search"]', query);
  await page.waitForTimeout(400);
}

export { ADMIN_USER, ADMIN_PASS };