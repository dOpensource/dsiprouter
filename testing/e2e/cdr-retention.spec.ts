import { test, expect } from '@playwright/test';
import { spawn } from 'child_process';
import { loginAdmin, SHELL_ENABLED, shell } from './helpers';
import {
  DEAD_S3_ENDPOINT, cdrTag, saveCdrSettings, resetCdrSettings, cdrSettingsAreDefault, runRetention, getCdrSettings,
  seedCall, seedOrphanInvite, seedMissedCall, seedManyCdrs, cdrCallIds, accCallIds, missedCallIds, countCdrs,
  clearCdrs, realRowsOlderThan,
} from './fixtures/cdrs';

// the job deletes every CDR older than the cutoff, so these tests only run where that is test data alone
test.describe('CDR retention job', () => {
  let tag: string;

  test.beforeEach(async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed and inspect CDR rows');
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR retention is already configured on this install, not touching it');
    test.skip(realRowsOlderThan(1) > 0, 'this install has real CDRs older than a day, the job would delete them');
    tag = cdrTag('ret');
  });

  test.afterEach(async ({ page }) => {
    if (!SHELL_ENABLED) return;
    clearCdrs(tag);
    await resetCdrSettings(page);
  });

  test('deletes whole days older than the retention period from cdrs, acc and missed_calls', async ({ page }) => {
    for (const days of [1, 6, 8, 40, 400]) {
      seedCall(tag, days);
    }
    seedOrphanInvite(tag, 10);
    seedOrphanInvite(tag, 2);
    seedMissedCall(tag, 9);
    seedMissedCall(tag, 3);

    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });
    const res = await runRetention(page);
    expect(res.status, JSON.stringify(res.data)).toBe(200);
    const result = res.data.data[0];
    expect(result.skipped_locked).toBe(false);
    expect(result.retention_days).toBe(7);
    expect(result.error).toBeNull();
    expect(result.deleted.cdrs).toBe(3);
    expect(result.deleted.acc).toBe(4);
    expect(result.deleted.missed_calls).toBe(1);

    expect(cdrCallIds(tag)).toEqual([`${tag}-1`, `${tag}-6`]);
    expect(accCallIds(tag)).toEqual([`${tag}-1`, `${tag}-6`, `${tag}-orphan-2`]);
    expect(missedCallIds(tag)).toEqual([`${tag}-missed-3`]);

    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_LAST_RUN.result.trigger).toBe('api');
    expect(cfg.CDR_LAST_RUN.result.deleted.cdrs).toBe(3);
  });

  test('0 days keeps everything', async ({ page }) => {
    seedCall(tag, 400);
    const res = await runRetention(page);
    expect(res.status).toBe(200);
    expect(res.data.msg).toContain('retention is off');
    expect(res.data.data[0].deleted).toEqual({});
    expect(cdrCallIds(tag)).toEqual([`${tag}-400`]);
  });

  test('deletes large backlogs in batches', async ({ page }) => {
    test.setTimeout(120000);
    seedManyCdrs(tag, 25000, 30);
    seedCall(tag, 1);
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });
    const res = await runRetention(page);
    expect(res.status).toBe(200);
    const result = res.data.data[0];
    expect(result.deleted.cdrs).toBe(25000);
    // 10k rows per batch: 3 batches for cdrs plus one each for acc and missed_calls
    expect(result.batches).toBeGreaterThanOrEqual(5);
    expect(countCdrs(tag)).toBe(1);
  });

  test('skips the run while another node holds the lock', async ({ page }) => {
    seedCall(tag, 30);
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });

    // a second DB session holds the job's lock for a few seconds
    const holder = spawn('sudo', ['mysql', '-N', '-e', "SELECT GET_LOCK('dsip_cdr_retention', 0); SELECT SLEEP(6);"]);
    const exited = new Promise((resolve) => holder.on('exit', resolve));
    try {
      await expect.poll(() => shell(
        `sudo mysql -N -e "SELECT IS_USED_LOCK('dsip_cdr_retention') IS NOT NULL"`
      ).trim(), { timeout: 5000 }).toBe('1');

      const res = await runRetention(page);
      expect(res.status).toBe(200);
      expect(res.data.data[0].skipped_locked).toBe(true);
      expect(res.data.msg).toContain('already running');
      expect(cdrCallIds(tag)).toEqual([`${tag}-30`]);
    } finally {
      await exited;
    }

    const res = await runRetention(page);
    expect(res.data.data[0].skipped_locked).toBe(false);
    expect(cdrCallIds(tag)).toEqual([]);
  });

  test('the cron command runs the same job', async ({ page }) => {
    expect(shell('sudo crontab -u dsiprouter -l')).toMatch(/^30 2 \* \* \* .*dsiprouter_cron\.py cdr purge$/m);

    seedCall(tag, 1);
    seedCall(tag, 20);
    await saveCdrSettings(page, { CDR_RETENTION_DAYS: 7 });
    shell('sudo -u dsiprouter /opt/dsiprouter/venv/bin/python /opt/dsiprouter/gui/dsiprouter_cron.py cdr purge');
    expect(cdrCallIds(tag)).toEqual([`${tag}-1`]);
    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_LAST_RUN.result.trigger).toBe('cron');
    expect(cfg.CDR_LAST_RUN.result.deleted.cdrs).toBe(1);
  });

  test('a failed S3 upload keeps every row', async ({ page }) => {
    test.setTimeout(60000);
    seedCall(tag, 20);
    seedCall(tag, 21);
    await saveCdrSettings(page, {
      CDR_RETENTION_DAYS: 7, CDR_ARCHIVE_ENABLED: true, CDR_S3_BUCKET: 'e2e-dead-bucket',
      CDR_S3_ENDPOINT: DEAD_S3_ENDPOINT, CDR_S3_ACCESS_KEY: 'e2e', CDR_S3_SECRET_KEY: 'e2e',
    });
    const res = await runRetention(page);
    expect(res.status).toBe(502);
    expect(res.data.msg).toContain('the remaining CDRs were kept');
    expect(res.data.data[0].archived_files).toEqual([]);
    expect(res.data.data[0].deleted).toEqual({});
    expect(cdrCallIds(tag)).toEqual([`${tag}-20`, `${tag}-21`]);
    expect(accCallIds(tag)).toEqual([`${tag}-20`, `${tag}-21`]);

    const cfg = await getCdrSettings(page);
    expect(cfg.CDR_LAST_RUN.result.error).toContain('uploading');
  });

  test('installmodules keeps existing CDRs', async ({ page }) => {
    test.skip(process.env.DSIP_TEST_INSTALLMODULES !== '1',
      'set DSIP_TEST_INSTALLMODULES=1, it reinstalls every module and restarts kamailio and dsiprouter');
    test.setTimeout(600000);
    seedCall(tag, 3);
    seedOrphanInvite(tag, 3);
    shell('sudo dsiprouter installmodules');
    expect(cdrCallIds(tag)).toEqual([`${tag}-3`]);
    expect(accCallIds(tag)).toEqual([`${tag}-3`, `${tag}-orphan-3`]);
    expect(shell(`sudo mysql -N kamailio -e "SHOW INDEX FROM cdrs WHERE Key_name = 'cdrs_call_start_time'"`)).not.toBe('');
    expect(shell(`sudo mysql -N kamailio -e "SHOW INDEX FROM acc WHERE Key_name = 'acc_time'"`)).not.toBe('');
    await expect.poll(async () => {
      try {
        await loginAdmin(page);
        return true;
      } catch (e) {
        return false;
      }
    }, { timeout: 90000, intervals: [2000] }).toBe(true);
  });
});
