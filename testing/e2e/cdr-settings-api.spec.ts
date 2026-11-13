import { test, expect } from '@playwright/test';
import {
  loginAdmin, loginGUI, guiApiRequest, createTestUser, deleteTestUser, freshContext, SHELL_ENABLED, dbQuery, shell,
} from './helpers';
import {
  CDR_DEFAULTS, getCdrSettings, putCdrSettings, saveCdrSettings, resetCdrSettings, cdrSettingsAreDefault,
} from './fixtures/cdrs';

test.describe('CDR settings API', () => {
  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR retention is already configured on this install, not touching it');
  });

  test.afterEach(async ({ page }) => {
    await resetCdrSettings(page);
  });

  test('GET returns typed values and never the secret', async ({ page }) => {
    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_RETENTION_DAYS).toBe(0);
    expect(cfg.CDR_ARCHIVE_ENABLED).toBe(false);
    expect(cfg.CDR_S3_PREFIX).toBe('cdrs/');
    expect(cfg.CDR_S3_SECRET_KEY_SET).toBe(false);
    expect(cfg).not.toHaveProperty('CDR_S3_SECRET_KEY');
    expect(cfg.CDR_WEBHOOK_ENABLED).toBe(false);
    expect(cfg.CDR_WEBHOOK_METHOD).toBe('POST');
    expect(cfg.CDR_WEBHOOK_AUTH).toBe('');
    expect(cfg.CDR_STORE_CDR).toBe(true);
    expect(cfg.CDR_WEBHOOK_PASSWORD_SET).toBe(false);
    expect(cfg).not.toHaveProperty('CDR_WEBHOOK_PASSWORD');
  });

  test('webhook settings round-trip and enabling starts at the newest CDR', async ({ page }) => {
    const saved = await saveCdrSettings(page, {
      CDR_WEBHOOK_ENABLED: 'true', CDR_WEBHOOK_URL: ' https://hooks.example.com/cdrs?x=1 ', CDR_WEBHOOK_METHOD: 'put',
      CDR_WEBHOOK_AUTH: 'basic', CDR_WEBHOOK_USERNAME: 'acme', CDR_WEBHOOK_PASSWORD: 'e2e-pass', CDR_STORE_CDR: 'false',
    });
    expect(saved.CDR_WEBHOOK_ENABLED).toBe(true);
    expect(saved.CDR_WEBHOOK_URL).toBe('https://hooks.example.com/cdrs?x=1');
    expect(saved.CDR_WEBHOOK_METHOD).toBe('PUT');
    expect(saved.CDR_WEBHOOK_AUTH).toBe('basic');
    expect(saved.CDR_WEBHOOK_USERNAME).toBe('acme');
    expect(saved.CDR_WEBHOOK_PASSWORD_SET).toBe(true);
    expect(saved.CDR_STORE_CDR).toBe(false);
    expect(typeof saved.CDR_WEBHOOK_LAST_CDR_ID).toBe('number');
    expect(JSON.stringify(saved)).not.toContain('e2e-pass');

    // "none" is the same as no auth, an omitted password is kept
    const none = await saveCdrSettings(page, { CDR_WEBHOOK_AUTH: 'none' });
    expect(none.CDR_WEBHOOK_AUTH).toBe('');
    expect(none.CDR_WEBHOOK_PASSWORD_SET).toBe(true);

    // turning the webhook off needs CDRs to be stored again
    const off = await putCdrSettings(page, { CDR_WEBHOOK_ENABLED: false });
    expect(off.status).toBe(400);
    expect(off.data.msg).toContain('CDR_STORE_CDR');
    await saveCdrSettings(page, { CDR_WEBHOOK_ENABLED: false, CDR_STORE_CDR: true, CDR_WEBHOOK_PASSWORD: null });
    expect((await getCdrSettings(page)).CDR_WEBHOOK_PASSWORD_SET).toBe(false);
  });

  test('PUT coerces and round-trips the values', async ({ page }) => {
    const saved = await saveCdrSettings(page, {
      CDR_RETENTION_DAYS: '30',
      CDR_ARCHIVE_ENABLED: 'false',
      CDR_S3_PREFIX: '/archive',
      CDR_S3_REGION: 'nyc3',
      CDR_S3_ENDPOINT: 'https://nyc3.digitaloceanspaces.com/',
    });
    expect(saved.CDR_RETENTION_DAYS).toBe(30);
    expect(saved.CDR_ARCHIVE_ENABLED).toBe(false);
    expect(saved.CDR_S3_PREFIX).toBe('archive/');
    expect(saved.CDR_S3_ENDPOINT).toBe('https://nyc3.digitaloceanspaces.com');

    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_RETENTION_DAYS).toBe(30);
    expect(cfg.CDR_S3_REGION).toBe('nyc3');

    // a partial PUT leaves the other values alone
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });
    const after = await getCdrSettings(page);
    expect(after.CDR_RETENTION_DAYS).toBe(7);
    expect(after.CDR_S3_PREFIX).toBe('archive/');
  });

  const invalid: [string, any, string][] = [
    ['negative days', { CDR_RETENTION_DAYS: -1 }, 'between 0 and'],
    ['fractional days', { CDR_RETENTION_DAYS: 1.5 }, 'whole number'],
    ['non numeric days', { CDR_RETENTION_DAYS: 'abc' }, 'whole number'],
    ['boolean days', { CDR_RETENTION_DAYS: true }, 'whole number'],
    ['too many days', { CDR_RETENTION_DAYS: 36501 }, 'between 0 and'],
    ['non boolean archive flag', { CDR_ARCHIVE_ENABLED: 'maybe' }, 'true or false'],
    ['bad bucket name', { CDR_S3_BUCKET: 'Bad_Bucket' }, 'bucket name'],
    ['bad endpoint', { CDR_S3_ENDPOINT: 'ftp://example.com' }, 'http(s) URL'],
    ['unknown key', { CDR_FOO: 1 }, 'unknown setting'],
    ['archive without credentials', { CDR_RETENTION_DAYS: 7, CDR_ARCHIVE_ENABLED: true }, 'S3 archiving needs'],
    ['archive without retention', {
      CDR_ARCHIVE_ENABLED: true, CDR_S3_BUCKET: 'b-1', CDR_S3_ACCESS_KEY: 'a', CDR_S3_SECRET_KEY: 's',
    }, 'CDR_RETENTION_DAYS above 0'],
    ['webhook URL that is not http(s)', { CDR_WEBHOOK_URL: 'ftp://example.com/cdrs' }, 'http(s) URL'],
    ['webhook URL with spaces', { CDR_WEBHOOK_URL: 'https://exa mple.com' }, 'http(s) URL'],
    ['webhook method GET', { CDR_WEBHOOK_METHOD: 'GET' }, 'POST or PUT'],
    ['webhook auth digest', { CDR_WEBHOOK_AUTH: 'digest' }, 'basic or empty'],
    ['webhook username with a colon', { CDR_WEBHOOK_USERNAME: 'a:b' }, 'colon'],
    ['non boolean webhook flag', { CDR_WEBHOOK_ENABLED: 'maybe' }, 'true or false'],
    ['webhook without a URL', { CDR_WEBHOOK_ENABLED: true }, 'needs CDR_WEBHOOK_URL'],
    ['basic auth without credentials', {
      CDR_WEBHOOK_ENABLED: true, CDR_WEBHOOK_URL: 'https://example.com/cdrs', CDR_WEBHOOK_AUTH: 'basic',
    }, 'basic auth needs CDR_WEBHOOK_USERNAME, CDR_WEBHOOK_PASSWORD'],
    ['not storing CDRs without the webhook', { CDR_STORE_CDR: false }, 'only be false while the webhook is enabled'],
  ];
  for (const [name, body, msg] of invalid) {
    test(`rejects ${name}`, async ({ page }) => {
      const res = await putCdrSettings(page, body);
      expect(res.status).toBe(400);
      expect(res.data.msg).toContain(msg);
      // nothing was saved
      expect(await cdrSettingsAreDefault(page)).toBe(true);
    });
  }

  test('the secret key is write-only, kept when omitted and cleared with null', async ({ page }) => {
    const secret = `e2e-secret-${Date.now()}`;
    const saved = await saveCdrSettings(page, {
      CDR_RETENTION_DAYS: 7, CDR_ARCHIVE_ENABLED: true, CDR_S3_BUCKET: 'e2e-bucket',
      CDR_S3_ACCESS_KEY: 'e2e-access', CDR_S3_SECRET_KEY: secret,
    });
    expect(saved.CDR_S3_SECRET_KEY_SET).toBe(true);
    expect(JSON.stringify(saved)).not.toContain(secret);

    // omitted or empty keeps it
    await saveCdrSettings(page, { CDR_S3_BUCKET: 'e2e-bucket-2' });
    expect((await getCdrSettings(page)).CDR_S3_SECRET_KEY_SET).toBe(true);
    await saveCdrSettings(page, { CDR_S3_SECRET_KEY: '' });
    expect((await getCdrSettings(page)).CDR_S3_SECRET_KEY_SET).toBe(true);

    if (SHELL_ENABLED) {
      const stored = dbQuery('SELECT s3_secret_key FROM dsip_cdr_settings WHERE id = 1')[0][0];
      expect(stored).not.toBe('');
      expect(stored).not.toContain(secret);
    }

    // archive has to be off before the secret can go
    await saveCdrSettings(page, { CDR_ARCHIVE_ENABLED: false, CDR_S3_SECRET_KEY: null });
    expect((await getCdrSettings(page)).CDR_S3_SECRET_KEY_SET).toBe(false);
  });

  test('CDR settings are not part of the generic settings list', async ({ page }) => {
    const res = await guiApiRequest(page, 'GET', '/settings');
    expect(res.status).toBe(200);
    const keys = Object.keys(res.data.data[0] || {});
    expect(keys.filter((k) => k.startsWith('CDR_'))).toEqual([]);
  });

  test('settings survive a dSIPRouter restart', async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to restart dsiprouter');
    test.setTimeout(120000);
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 45, CDR_S3_PREFIX: 'restart/' });
    shell('sudo systemctl restart dsiprouter');
    // the session normally survives the restart, log in again only when it did not
    await expect.poll(async () => {
      try {
        const res = await guiApiRequest(page, 'GET', '/settings/cdr');
        if (res.status === 401) {
          await loginAdmin(page);
          return null;
        }
        return res.status === 200 ? res.data.data[0].CDR_RETENTION_DAYS : null;
      } catch (e) {
        return null;
      }
    }, { timeout: 90000, intervals: [2000] }).toBe(45);
    expect((await getCdrSettings(page)).CDR_S3_PREFIX).toBe('restart/');
  });
});

test.describe('CDR settings permissions', () => {
  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR retention is already configured on this install, not touching it');
  });

  test('guest can not read, change or run', async ({ page, browser }) => {
    const user = `e2e_cdrguest_${Date.now()}`;
    await createTestUser(page, user, 'testpass123', 'dsip_guest');
    const { ctx, page: guest } = await freshContext(browser);
    try {
      await loginGUI(guest, user, 'testpass123');
      expect((await guiApiRequest(guest, 'GET', '/settings/cdr')).status).toBe(403);
      expect((await guiApiRequest(guest, 'PUT', '/settings/cdr', { CDR_RETENTION_DAYS: 1 })).status).toBe(403);
      expect((await guiApiRequest(guest, 'POST', '/settings/cdr/run')).status).toBe(403);
      expect((await guiApiRequest(guest, 'POST', '/settings/cdr/test-s3', {})).status).toBe(403);
      expect((await guiApiRequest(guest, 'POST', '/settings/cdr/test-webhook', {})).status).toBe(403);
      expect((await guiApiRequest(guest, 'POST', '/settings/cdr/run-webhook')).status).toBe(403);
      expect(await cdrSettingsAreDefault(page)).toBe(true);
    } finally {
      await ctx.close();
      await deleteTestUser(page, user);
    }
  });

  test('engineer can read and save but not run', async ({ page, browser }) => {
    const user = `e2e_cdreng_${Date.now()}`;
    await createTestUser(page, user, 'testpass123', 'dsip_engineer');
    const { ctx, page: eng } = await freshContext(browser);
    try {
      await loginGUI(eng, user, 'testpass123');
      expect((await guiApiRequest(eng, 'GET', '/settings/cdr')).status).toBe(200);
      expect((await guiApiRequest(eng, 'PUT', '/settings/cdr', { CDR_RETENTION_DAYS: 90 })).status).toBe(200);
      expect((await guiApiRequest(eng, 'POST', '/settings/cdr/run')).status).toBe(403);
      expect((await guiApiRequest(eng, 'POST', '/settings/cdr/run-webhook')).status).toBe(403);
    } finally {
      await ctx.close();
      await deleteTestUser(page, user);
      await resetCdrSettings(page);
    }
  });

  test('logged out requests are refused', async ({ browser }) => {
    const { ctx, page: anon } = await freshContext(browser);
    try {
      expect((await guiApiRequest(anon, 'GET', '/settings/cdr')).status).toBe(401);
      expect((await guiApiRequest(anon, 'PUT', '/settings/cdr', CDR_DEFAULTS)).status).toBe(401);
      expect((await guiApiRequest(anon, 'POST', '/settings/cdr/run')).status).toBe(401);
      expect((await guiApiRequest(anon, 'POST', '/settings/cdr/run-webhook')).status).toBe(401);
      expect((await guiApiRequest(anon, 'POST', '/settings/cdr/test-webhook', {})).status).toBe(401);
    } finally {
      await ctx.close();
    }
  });
});
