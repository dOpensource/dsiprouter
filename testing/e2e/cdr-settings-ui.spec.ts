import { test, expect, Page } from '@playwright/test';
import { loginAdmin, loginGUI, createTestUser, deleteTestUser, freshContext } from './helpers';
import { startReceiver } from './fixtures/webhook';
import {
  DEAD_S3_ENDPOINT, getCdrSettings, saveCdrSettings, resetCdrSettings, cdrSettingsAreDefault,
} from './fixtures/cdrs';

async function openCdrTab(page: Page) {
  await page.goto('/settings');
  await page.click('a[href="#cdr-settings"]');
  const form = page.locator('#cdrSettingsForm');
  await expect(form).toBeVisible();
  // the form is filled once the settings GET returns
  await expect(page.locator('#cdr-last-run')).not.toBeEmpty();
  return form;
}

test.describe('CDR settings page', () => {
  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR retention is already configured on this install, not touching it');
  });

  test.afterEach(async ({ page }) => {
    await resetCdrSettings(page);
  });

  test('the CDR tab sits next to the generic settings table', async ({ page }) => {
    await page.goto('/settings');
    await expect(page.locator('#settings-table')).toBeVisible();
    await expect(page.locator('#cdrSettingsForm')).toBeHidden();
    const form = await openCdrTab(page);
    await expect(form.locator('#CDR_RETENTION_DAYS')).toHaveValue('0');
    await expect(form.locator('#CDR_ARCHIVE_ENABLED')).not.toBeChecked();
    await expect(page.locator('#cdr-s3-fields')).toBeHidden();
    await expect(page.locator('#cdr-run')).toBeVisible();
  });

  test('saving the retention period persists it', async ({ page }) => {
    const form = await openCdrTab(page);
    await form.locator('#CDR_RETENTION_DAYS').fill('30');
    await page.click('#cdr-save');
    await expect(page.locator('#message-bar')).toContainText('CDR settings saved');
    expect((await getCdrSettings(page)).CDR_RETENTION_DAYS).toBe(30);

    await openCdrTab(page);
    await expect(page.locator('#CDR_RETENTION_DAYS')).toHaveValue('30');
  });

  test('invalid days are flagged without saving', async ({ page }) => {
    const form = await openCdrTab(page);
    await form.locator('#CDR_RETENTION_DAYS').fill('-5');
    await page.click('#cdr-save');
    await expect(form.locator('#CDR_RETENTION_DAYS')).toHaveClass(/is-invalid/);
    expect((await getCdrSettings(page)).CDR_RETENTION_DAYS).toBe(0);
  });

  test('the archive switch shows the S3 fields and requires them', async ({ page }) => {
    const form = await openCdrTab(page);
    await form.locator('#CDR_RETENTION_DAYS').fill('7');
    await form.locator('#CDR_ARCHIVE_ENABLED').check();
    await expect(page.locator('#cdr-s3-fields')).toBeVisible();

    await page.click('#cdr-save');
    for (const id of ['CDR_S3_BUCKET', 'CDR_S3_ACCESS_KEY', 'CDR_S3_SECRET_KEY']) {
      await expect(form.locator(`#${id}`)).toHaveClass(/is-invalid/);
    }
    expect((await getCdrSettings(page)).CDR_ARCHIVE_ENABLED).toBe(false);

    await form.locator('#CDR_ARCHIVE_ENABLED').uncheck();
    await expect(page.locator('#cdr-s3-fields')).toBeHidden();
  });

  test('the secret is write-only and stays saved when left empty', async ({ page }) => {
    const form = await openCdrTab(page);
    await form.locator('#CDR_RETENTION_DAYS').fill('7');
    await form.locator('#CDR_ARCHIVE_ENABLED').check();
    await form.locator('#CDR_S3_BUCKET').fill('e2e-ui-bucket');
    await form.locator('#CDR_S3_ACCESS_KEY').fill('e2e-access');
    await form.locator('#CDR_S3_SECRET_KEY').fill('e2e-ui-secret');
    await page.click('#cdr-save');
    await expect(page.locator('#message-bar')).toContainText('CDR settings saved');

    await openCdrTab(page);
    await expect(page.locator('#CDR_S3_SECRET_KEY')).toHaveValue('');
    await expect(page.locator('#CDR_S3_SECRET_KEY')).toHaveAttribute('placeholder', /Saved/);
    await expect(page.locator('#CDR_S3_BUCKET')).toHaveValue('e2e-ui-bucket');

    // saving again without typing the secret keeps it
    await page.locator('#CDR_S3_PREFIX').fill('ui/');
    await page.click('#cdr-save');
    await expect(page.locator('#message-bar')).toContainText('CDR settings saved');
    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_S3_SECRET_KEY_SET).toBe(true);
    expect(cfg.CDR_S3_PREFIX).toBe('ui/');
    await saveCdrSettings(page, { CDR_ARCHIVE_ENABLED: false, CDR_S3_SECRET_KEY: null });
  });

  test('test connection reports an unreachable endpoint', async ({ page }) => {
    test.setTimeout(60000);
    const form = await openCdrTab(page);
    await form.locator('#CDR_ARCHIVE_ENABLED').check();
    await form.locator('#CDR_S3_BUCKET').fill('e2e-ui-bucket');
    await form.locator('#CDR_S3_ENDPOINT').fill(DEAD_S3_ENDPOINT);
    await form.locator('#CDR_S3_ACCESS_KEY').fill('e2e');
    await form.locator('#CDR_S3_SECRET_KEY').fill('e2e');
    await page.click('#cdr-test-s3');
    await expect(page.locator('#message-bar')).toContainText('S3 error', { timeout: 30000 });
    // testing does not save anything
    expect((await getCdrSettings(page)).CDR_ARCHIVE_ENABLED).toBe(false);
  });

  test('run now reports that retention is off', async ({ page }) => {
    await openCdrTab(page);
    page.once('dialog', (dialog) => dialog.accept());
    await page.click('#cdr-run');
    await expect(page.locator('#message-bar')).toContainText('retention is off');
  });

  test('the webhook switch shows its fields and requires a URL', async ({ page }) => {
    const form = await openCdrTab(page);
    await expect(page.locator('#cdr-webhook-fields')).toBeHidden();
    await expect(form.locator('#CDR_STORE_CDR')).toBeChecked();
    await expect(form.locator('#CDR_STORE_CDR')).toBeDisabled();

    await form.locator('#CDR_WEBHOOK_ENABLED').check();
    await expect(page.locator('#cdr-webhook-fields')).toBeVisible();
    await expect(form.locator('#CDR_STORE_CDR')).toBeEnabled();
    await expect(page.locator('#cdr-webhook-auth-fields')).toBeHidden();

    await page.click('#cdr-save');
    await expect(form.locator('#CDR_WEBHOOK_URL')).toHaveClass(/is-invalid/);
    expect((await getCdrSettings(page)).CDR_WEBHOOK_ENABLED).toBe(false);

    // basic auth needs a username and password
    await form.locator('#CDR_WEBHOOK_URL').fill('https://hooks.example.com/cdrs');
    await form.locator('#CDR_WEBHOOK_AUTH').selectOption('basic');
    await expect(page.locator('#cdr-webhook-auth-fields')).toBeVisible();
    await page.click('#cdr-save');
    await expect(form.locator('#CDR_WEBHOOK_USERNAME')).toHaveClass(/is-invalid/);
    await expect(form.locator('#CDR_WEBHOOK_PASSWORD')).toHaveClass(/is-invalid/);
    expect((await getCdrSettings(page)).CDR_WEBHOOK_ENABLED).toBe(false);

    // turning the webhook off stores CDRs again
    await form.locator('#CDR_STORE_CDR').uncheck();
    await form.locator('#CDR_WEBHOOK_ENABLED').uncheck();
    await expect(form.locator('#CDR_STORE_CDR')).toBeChecked();
  });

  test('saving the webhook persists it and keeps the password write-only', async ({ page }) => {
    const form = await openCdrTab(page);
    await form.locator('#CDR_WEBHOOK_ENABLED').check();
    await form.locator('#CDR_WEBHOOK_URL').fill('https://hooks.example.com/cdrs');
    await form.locator('#CDR_WEBHOOK_METHOD').selectOption('PUT');
    await form.locator('#CDR_WEBHOOK_AUTH').selectOption('basic');
    await form.locator('#CDR_WEBHOOK_USERNAME').fill('acme');
    await form.locator('#CDR_WEBHOOK_PASSWORD').fill('e2e-ui-pass');
    await form.locator('#CDR_STORE_CDR').uncheck();
    await page.click('#cdr-save');
    await expect(page.locator('#message-bar')).toContainText('CDR settings saved');

    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_WEBHOOK_ENABLED).toBe(true);
    expect(cfg.CDR_WEBHOOK_METHOD).toBe('PUT');
    expect(cfg.CDR_WEBHOOK_USERNAME).toBe('acme');
    expect(cfg.CDR_WEBHOOK_PASSWORD_SET).toBe(true);
    expect(cfg.CDR_STORE_CDR).toBe(false);

    await openCdrTab(page);
    await expect(page.locator('#CDR_WEBHOOK_URL')).toHaveValue('https://hooks.example.com/cdrs');
    await expect(page.locator('#CDR_WEBHOOK_METHOD')).toHaveValue('PUT');
    await expect(page.locator('#CDR_WEBHOOK_PASSWORD')).toHaveValue('');
    await expect(page.locator('#CDR_WEBHOOK_PASSWORD')).toHaveAttribute('placeholder', /Saved/);
    await expect(page.locator('#CDR_STORE_CDR')).not.toBeChecked();
    // the status line shows either the last delivery (kept from earlier runs) or that nothing was sent yet
    await expect(page.locator('#cdr-webhook-last-run')).toContainText(/Last webhook run|not sent anything/);

    // saving again without typing the password keeps it
    await page.click('#cdr-save');
    await expect(page.locator('#message-bar')).toContainText('CDR settings saved');
    expect((await getCdrSettings(page)).CDR_WEBHOOK_PASSWORD_SET).toBe(true);
  });

  test('test webhook reaches the receiver', async ({ page }) => {
    const receiver = await startReceiver();
    try {
      const form = await openCdrTab(page);
      await form.locator('#CDR_WEBHOOK_ENABLED').check();
      await form.locator('#CDR_WEBHOOK_URL').fill(receiver.url);
      await page.click('#cdr-test-webhook');
      await expect(page.locator('#message-bar')).toContainText('answered HTTP 200');
      expect(receiver.requests.map((r) => r.headers['x-dsip-event'])).toEqual(['test']);

      receiver.respond(500);
      await page.click('#cdr-test-webhook');
      await expect(page.locator('#message-bar')).toContainText('HTTP 500');
      // testing does not save anything
      expect((await getCdrSettings(page)).CDR_WEBHOOK_ENABLED).toBe(false);
    } finally {
      await receiver.close();
    }
  });

  test('send now reports that the webhook is off', async ({ page }) => {
    await openCdrTab(page);
    await page.click('#cdr-run-webhook');
    await expect(page.locator('#message-bar')).toContainText('webhook is off');
  });

  test('engineers do not get the run button', async ({ page, browser }) => {
    const user = `e2e_cdruieng_${Date.now()}`;
    await createTestUser(page, user, 'testpass123', 'dsip_engineer');
    const { ctx, page: eng } = await freshContext(browser);
    try {
      await loginGUI(eng, user, 'testpass123');
      await openCdrTab(eng);
      await expect(eng.locator('#cdr-save')).toBeVisible();
      await expect(eng.locator('#cdr-run')).toHaveCount(0);
      await expect(eng.locator('#cdr-run-webhook')).toHaveCount(0);
      await expect(eng.locator('#cdr-test-webhook')).toBeVisible();
    } finally {
      await ctx.close();
      await deleteTestUser(page, user);
    }
  });
});
