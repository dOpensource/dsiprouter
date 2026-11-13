import { test, expect } from '@playwright/test';
import { spawn, execFile } from 'child_process';
import { promisify } from 'util';
import { loginAdmin, guiApiRequest, SHELL_ENABLED, shell, dbQuery } from './helpers';
import {
  cdrTag, saveCdrSettings, resetCdrSettings, cdrSettingsAreDefault, getCdrSettings, runRetention, runWebhook,
  seedCall, cdrCallIds, accCallIds, clearCdrs, realRowsOlderThan,
} from './fixtures/cdrs';
import { startReceiver, receivedCdrs, basicAuth, WebhookReceiver } from './fixtures/webhook';

// the cron job also sends every minute, so the tests check what the receiver got and what is left in the DB,
// not how many CDRs one particular run sent
test.describe('CDR webhook', () => {
  let tag: string;
  let receiver: WebhookReceiver;

  test.beforeEach(async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed and inspect CDR rows');
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR settings are already configured on this install, not touching them');
    tag = cdrTag('wh');
    receiver = await startReceiver();
  });

  test.afterEach(async ({ page }) => {
    if (!SHELL_ENABLED) return;
    await resetCdrSettings(page);
    await receiver?.close();
    clearCdrs(tag);
  });

  async function enableWebhook(page: any, overrides: any = {}) {
    return saveCdrSettings(page, { CDR_WEBHOOK_ENABLED: true, CDR_WEBHOOK_URL: receiver.url, ...overrides });
  }

  test('sends new CDRs once, oldest first, as a JSON array', async ({ page }) => {
    await enableWebhook(page);
    seedCall(tag, 0, 'a');
    seedCall(tag, 0, 'b');

    const res = await runWebhook(page);
    expect(res.status, JSON.stringify(res.data)).toBe(200);
    expect(res.data.data[0].error).toBeNull();

    const cdrs = receivedCdrs(receiver, tag);
    expect(cdrs.map((c) => c.sip_call_id)).toEqual([`${tag}-a`, `${tag}-b`]);
    expect(cdrs[0].src_username).toBe('1001');
    expect(cdrs[0].duration).toBe(60);
    expect(cdrs[0].call_start_time).toMatch(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);
    expect(cdrs[0].cdr_id).toBeLessThan(cdrs[1].cdr_id);

    const request = receiver.requests.find((r) => r.headers['x-dsip-event'] === 'cdr')!;
    expect(request.method).toBe('POST');
    expect(request.headers['content-type']).toBe('application/json');
    expect(request.headers['authorization']).toBeUndefined();

    // a second run sends nothing again
    expect((await runWebhook(page)).status).toBe(200);
    expect(receivedCdrs(receiver, tag)).toHaveLength(2);

    // stored as usual, the position and the last run are recorded
    expect(cdrCallIds(tag)).toEqual([`${tag}-a`, `${tag}-b`]);
    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_WEBHOOK_LAST_CDR_ID).toBeGreaterThanOrEqual(cdrs[1].cdr_id);
    expect(cfg.CDR_WEBHOOK_LAST_RUN.result.error).toBeNull();
  });

  test('CDRs written before the webhook was enabled are not sent', async ({ page }) => {
    seedCall(tag, 0, 'before');
    await enableWebhook(page);
    seedCall(tag, 0, 'after');
    expect((await runWebhook(page)).status).toBe(200);
    expect(receivedCdrs(receiver, tag).map((c) => c.sip_call_id)).toEqual([`${tag}-after`]);
  });

  test('PUT with basic auth, a rejected request is retried with the same CDRs', async ({ page }) => {
    receiver.respond((req) => (req.headers['authorization'] === basicAuth('e2e-user', 'right-pass') ? 200 : 401));
    await enableWebhook(page, {
      CDR_WEBHOOK_METHOD: 'PUT', CDR_WEBHOOK_AUTH: 'basic', CDR_WEBHOOK_USERNAME: 'e2e-user',
      CDR_WEBHOOK_PASSWORD: 'wrong-pass',
    });
    const position = (await getCdrSettings(page)).CDR_WEBHOOK_LAST_CDR_ID;
    seedCall(tag, 0, 'auth');

    const failed = await runWebhook(page);
    expect(failed.status).toBe(502);
    expect(failed.data.msg).toContain('HTTP 401');
    const after = await getCdrSettings(page);
    expect(after.CDR_WEBHOOK_LAST_CDR_ID).toBe(position);
    expect(after.CDR_WEBHOOK_LAST_RUN.result.error).toContain('401');
    expect(receiver.requests.every((r) => r.method === 'PUT')).toBe(true);

    await saveCdrSettings(page, { CDR_WEBHOOK_PASSWORD: 'right-pass' });
    expect((await runWebhook(page)).status).toBe(200);
    const accepted = receiver.requests.filter((r) => r.headers['authorization'] === basicAuth('e2e-user', 'right-pass'));
    expect(accepted.flatMap((r) => r.body).map((c: any) => c.sip_call_id)).toContain(`${tag}-auth`);
    expect((await getCdrSettings(page)).CDR_WEBHOOK_LAST_RUN.result.error).toBeNull();
  });

  test('a failing or unreachable webhook keeps the CDRs for the next run', async ({ page }) => {
    test.setTimeout(60000);
    receiver.respond(500);
    await enableWebhook(page);
    seedCall(tag, 0, 'retry');

    const failed = await runWebhook(page);
    expect(failed.status).toBe(502);
    expect(failed.data.msg).toContain('HTTP 500');

    await saveCdrSettings(page, { CDR_WEBHOOK_URL: 'http://127.0.0.1:9/cdrs' });
    const unreachable = await runWebhook(page);
    expect(unreachable.status).toBe(502);
    expect(unreachable.data.msg).toContain('failed');

    receiver.respond(200);
    await saveCdrSettings(page, { CDR_WEBHOOK_URL: receiver.url });
    expect((await runWebhook(page)).status).toBe(200);
    const delivered = receiver.requests.filter((r) => r.headers['x-dsip-event'] === 'cdr');
    // the same CDR came in the failed request and again in the accepted one
    expect(delivered.filter((r) => r.body.some((c: any) => c.sip_call_id === `${tag}-retry`)).length).toBeGreaterThanOrEqual(2);
    expect(cdrCallIds(tag)).toEqual([`${tag}-retry`]);
  });

  test('CDR_STORE_CDR false deletes CDRs only after the webhook accepted them', async ({ page }) => {
    receiver.respond(503);
    await enableWebhook(page, { CDR_STORE_CDR: false });
    seedCall(tag, 0, 'x');
    seedCall(tag, 0, 'y');

    expect((await runWebhook(page)).status).toBe(502);
    expect(cdrCallIds(tag)).toEqual([`${tag}-x`, `${tag}-y`]);
    expect(accCallIds(tag)).toEqual([`${tag}-x`, `${tag}-y`]);

    receiver.respond(200);
    expect((await runWebhook(page)).status).toBe(200);
    expect(cdrCallIds(tag)).toEqual([]);
    expect(accCallIds(tag)).toEqual([]);
    const accepted = receiver.requests.filter((r) => r.headers['x-dsip-event'] === 'cdr' && r.body.length > 0).pop()!;
    expect(accepted.body.map((c: any) => c.sip_call_id)).toEqual(expect.arrayContaining([`${tag}-x`, `${tag}-y`]));
  });

  test('a disabled webhook sends nothing', async ({ page }) => {
    seedCall(tag, 0, 'off');
    const res = await runWebhook(page);
    expect(res.status).toBe(200);
    expect(res.data.msg).toContain('off');
    expect(res.data.data[0].enabled).toBe(false);
    expect(receiver.requests).toEqual([]);
  });

  test('skips the run while another node holds the lock', async ({ page }) => {
    await enableWebhook(page);
    seedCall(tag, 0, 'locked');

    const holder = spawn('sudo', ['mysql', '-N', '-e', "SELECT GET_LOCK('dsip_cdr_webhook', 5); SELECT SLEEP(6);"]);
    const exited = new Promise((resolve) => holder.on('exit', resolve));
    try {
      await expect.poll(() => shell(
        `sudo mysql -N -e "SELECT IS_USED_LOCK('dsip_cdr_webhook') IS NOT NULL"`
      ).trim(), { timeout: 10000 }).toBe('1');
      const res = await runWebhook(page);
      expect(res.status).toBe(200);
      expect(res.data.data[0].skipped_locked).toBe(true);
      expect(res.data.msg).toContain('already running');
    } finally {
      await exited;
    }
    expect((await runWebhook(page)).status).toBe(200);
    expect(receivedCdrs(receiver, tag).map((c) => c.sip_call_id)).toEqual([`${tag}-locked`]);
  });

  test('the cron command sends the same way', async ({ page }) => {
    expect(shell('sudo crontab -u dsiprouter -l')).toMatch(/^\*\/1 \* \* \* \* .*dsiprouter_cron\.py cdr webhook$/m);
    await enableWebhook(page);
    seedCall(tag, 0, 'cron');
    // async, the receiver lives in this process and has to answer while the command runs
    await promisify(execFile)('sudo', ['-u', 'dsiprouter', '/opt/dsiprouter/venv/bin/python',
      '/opt/dsiprouter/gui/dsiprouter_cron.py', 'cdr', 'webhook']);
    expect(receivedCdrs(receiver, tag).map((c) => c.sip_call_id)).toEqual([`${tag}-cron`]);
    expect((await getCdrSettings(page)).CDR_WEBHOOK_LAST_RUN.result.trigger).toBe('cron');
  });

  test('retention never deletes CDRs the webhook has not sent yet', async ({ page }) => {
    test.skip(realRowsOlderThan(1) > 0, 'this install has real CDRs older than a day, the job would delete them');
    receiver.respond(500);
    await enableWebhook(page);
    // an old CDR that only now reached the CDR table (its id is above the webhook position)
    seedCall(tag, 20, 'old');
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });

    expect((await runRetention(page)).status).toBe(200);
    expect(cdrCallIds(tag)).toEqual([`${tag}-old`]);

    receiver.respond(200);
    expect((await runWebhook(page)).status).toBe(200);
    expect(receivedCdrs(receiver, tag).map((c) => c.sip_call_id)).toContain(`${tag}-old`);
    expect((await runRetention(page)).status).toBe(200);
    expect(cdrCallIds(tag)).toEqual([]);
  });

  test('test webhook sends an empty array without saving anything', async ({ page }) => {
    const ok = await guiApiRequest(page, 'POST', '/settings/cdr/test-webhook', {
      CDR_WEBHOOK_URL: receiver.url, CDR_WEBHOOK_METHOD: 'PUT',
    });
    expect(ok.status, JSON.stringify(ok.data)).toBe(200);
    expect(ok.data.msg).toContain('HTTP 200');
    expect(receiver.requests).toHaveLength(1);
    expect(receiver.requests[0].method).toBe('PUT');
    expect(receiver.requests[0].headers['x-dsip-event']).toBe('test');
    expect(receiver.requests[0].body).toEqual([]);
    expect(await cdrSettingsAreDefault(page)).toBe(true);
    expect((await getCdrSettings(page)).CDR_WEBHOOK_URL).toBe('');

    receiver.respond(403);
    const rejected = await guiApiRequest(page, 'POST', '/settings/cdr/test-webhook', { CDR_WEBHOOK_URL: receiver.url });
    expect(rejected.status).toBe(400);
    expect(rejected.data.msg).toContain('Webhook error');
    expect(rejected.data.msg).toContain('HTTP 403');

    const missing = await guiApiRequest(page, 'POST', '/settings/cdr/test-webhook', {});
    expect(missing.status).toBe(400);
    expect(missing.data.msg).toContain('CDR_WEBHOOK_URL');
  });
});

test.describe('CDR webhook permissions', () => {
  test('the webhook password is stored encrypted', async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to read the DB');
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR settings are already configured on this install, not touching them');
    const password = `e2e-pass-${Date.now()}`;
    try {
      const saved = await saveCdrSettings(page, {
        CDR_WEBHOOK_ENABLED: true, CDR_WEBHOOK_URL: 'https://example.com/cdrs', CDR_WEBHOOK_AUTH: 'basic',
        CDR_WEBHOOK_USERNAME: 'e2e', CDR_WEBHOOK_PASSWORD: password,
      });
      expect(saved.CDR_WEBHOOK_PASSWORD_SET).toBe(true);
      expect(JSON.stringify(saved)).not.toContain(password);
      const stored = dbQuery('SELECT webhook_password FROM dsip_cdr_settings WHERE id = 1')[0][0];
      expect(stored).not.toBe('');
      expect(stored).not.toContain(password);
    } finally {
      await resetCdrSettings(page);
    }
  });
});
