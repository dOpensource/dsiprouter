import { test, expect, Page } from '@playwright/test';
import { loginAdmin, loginGUI, createTestUser, deleteTestUser, freshContext } from './helpers';
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

  test('engineers do not get the run button', async ({ page, browser }) => {
    const user = `e2e_cdruieng_${Date.now()}`;
    await createTestUser(page, user, 'testpass123', 'dsip_engineer');
    const { ctx, page: eng } = await freshContext(browser);
    try {
      await loginGUI(eng, user, 'testpass123');
      await openCdrTab(eng);
      await expect(eng.locator('#cdr-save')).toBeVisible();
      await expect(eng.locator('#cdr-run')).toHaveCount(0);
    } finally {
      await ctx.close();
      await deleteTestUser(page, user);
    }
  });
});
