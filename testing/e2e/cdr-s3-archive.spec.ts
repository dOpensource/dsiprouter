import { test, expect } from '@playwright/test';
import { loginAdmin, guiApiRequest, SHELL_ENABLED } from './helpers';
import {
  S3, S3_ENABLED, cdrTag, saveCdrSettings, resetCdrSettings, cdrSettingsAreDefault, runRetention, seedCall,
  seedOrphanInvite, cdrCallIds, accCallIds, clearCdrs, realRowsOlderThan, listS3Objects, deleteS3Prefix, parseCsv,
} from './fixtures/cdrs';

function dayString(daysAgo: number): string {
  // the job buckets rows by the DB's date, the test box runs the DB in the same timezone as node
  const d = new Date(Date.now() - daysAgo * 86400000);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

test.describe('CDR S3 archive', () => {
  let tag: string;
  let prefix: string;

  test.beforeEach(async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed and inspect CDR rows');
    test.skip(!S3_ENABLED, 'set DSIP_TEST_S3_ENDPOINT, _BUCKET, _ACCESS_KEY and _SECRET_KEY to test against an S3 service');
    await loginAdmin(page);
    test.skip(!(await cdrSettingsAreDefault(page)), 'CDR retention is already configured on this install, not touching it');
    test.skip(realRowsOlderThan(1) > 0, 'this install has real CDRs older than a day, the job would delete them');
    tag = cdrTag('s3');
    // every test archives under its own prefix so object listings only see its files
    prefix = `e2e/${tag}/`;
  });

  test.afterEach(async ({ page }) => {
    if (!SHELL_ENABLED || !S3_ENABLED) return;
    clearCdrs(tag);
    deleteS3Prefix(prefix);
    await resetCdrSettings(page);
  });

  async function enableArchive(page: any, overrides: any = {}) {
    await saveCdrSettings(page, {
      CDR_RETENTION_DAYS: 7, CDR_ARCHIVE_ENABLED: true, CDR_S3_BUCKET: S3.bucket, CDR_S3_PREFIX: prefix,
      CDR_S3_REGION: S3.region, CDR_S3_ENDPOINT: S3.endpoint, CDR_S3_ACCESS_KEY: S3.accessKey,
      CDR_S3_SECRET_KEY: S3.secretKey, ...overrides,
    });
  }

  test('test connection succeeds with valid credentials and fails with a wrong secret', async ({ page }) => {
    await enableArchive(page);
    const ok = await guiApiRequest(page, 'POST', '/settings/cdr/test-s3', {});
    expect(ok.status, JSON.stringify(ok.data)).toBe(200);
    expect(ok.data.msg).toContain(S3.bucket);

    // unsaved values in the body are tested without being saved
    const bad = await guiApiRequest(page, 'POST', '/settings/cdr/test-s3', { CDR_S3_SECRET_KEY: 'wrong-secret' });
    expect(bad.status).toBe(400);
    expect(bad.data.msg).toContain('S3 error');
    expect((await guiApiRequest(page, 'POST', '/settings/cdr/test-s3', {})).status).toBe(200);
    // the test object was removed again
    expect(listS3Objects(prefix)).toEqual([]);
  });

  test('archives each expired day as gzipped CSV, then deletes the rows', async ({ page }) => {
    seedCall(tag, 1);
    seedCall(tag, 10, 'a');
    seedCall(tag, 10, 'b');
    seedCall(tag, 12);
    seedOrphanInvite(tag, 12);
    await enableArchive(page);

    const res = await runRetention(page);
    expect(res.status, JSON.stringify(res.data)).toBe(200);
    const result = res.data.data[0];
    expect(result.error).toBeNull();

    const day10 = dayString(10);
    const day12 = dayString(12);
    const month = (day: string) => day.slice(0, 7).replace('-', '/');
    const expected = [
      `${prefix}${month(day10)}/acc-${day10}.csv.gz`,
      `${prefix}${month(day10)}/cdrs-${day10}.csv.gz`,
      `${prefix}${month(day12)}/acc-${day12}.csv.gz`,
      `${prefix}${month(day12)}/cdrs-${day12}.csv.gz`,
    ].sort();
    expect([...result.archived_files].sort()).toEqual(expected);

    const objects = listS3Objects(prefix);
    expect(objects.map((o) => o.key).sort()).toEqual(expected);

    const cdrs10 = parseCsv(objects.find((o) => o.key.endsWith(`cdrs-${day10}.csv.gz`))!.csv);
    expect(cdrs10.header).toEqual(expect.arrayContaining(['cdr_id', 'call_start_time', 'sip_call_id', 'duration']));
    expect(cdrs10.rows.map((r) => r.sip_call_id).sort()).toEqual([`${tag}-a`, `${tag}-b`]);
    expect(cdrs10.rows[0].src_username).toBe('1001');

    const acc12 = parseCsv(objects.find((o) => o.key.endsWith(`acc-${day12}.csv.gz`))!.csv);
    expect(acc12.rows.map((r) => r.callid).sort()).toEqual([`${tag}-12`, `${tag}-orphan-12`]);

    // rows are gone only after the upload
    expect(cdrCallIds(tag)).toEqual([`${tag}-1`]);
    expect(accCallIds(tag)).toEqual([`${tag}-1`]);
    expect(result.deleted.cdrs).toBe(3);
    expect(result.deleted.acc).toBe(4);

    // nothing expired is left, a second run uploads and deletes nothing
    const again = await runRetention(page);
    expect(again.status).toBe(200);
    expect(again.data.data[0].archived_files).toEqual([]);
    expect(listS3Objects(prefix)).toHaveLength(4);
  });

  test('a later run for the same day never overwrites the earlier file', async ({ page }) => {
    seedCall(tag, 15, 'first');
    await enableArchive(page);
    expect((await runRetention(page)).status).toBe(200);

    // a call of the same day that turned up after the first run
    seedCall(tag, 15, 'late');
    const res = await runRetention(page);
    expect(res.status).toBe(200);
    const day = dayString(15);
    const objects = listS3Objects(prefix).filter((o) => o.key.includes(`cdrs-${day}`));
    expect(objects.map((o) => o.key.split('/').pop()).sort()).toEqual([`cdrs-${day}.2.csv.gz`, `cdrs-${day}.csv.gz`]);
    const ids = objects.flatMap((o) => parseCsv(o.csv).rows.map((r) => r.sip_call_id)).sort();
    expect(ids).toEqual([`${tag}-first`, `${tag}-late`]);
  });

  test('a wrong secret stops the run and keeps the rows, fixing it archives them', async ({ page }) => {
    seedCall(tag, 9);
    await enableArchive(page, { CDR_S3_SECRET_KEY: 'wrong-secret' });
    const failed = await runRetention(page);
    expect(failed.status).toBe(502);
    expect(cdrCallIds(tag)).toEqual([`${tag}-9`]);
    expect(listS3Objects(prefix)).toEqual([]);

    await saveCdrSettings(page, { CDR_S3_SECRET_KEY: S3.secretKey });
    const fixed = await runRetention(page);
    expect(fixed.status).toBe(200);
    expect(cdrCallIds(tag)).toEqual([]);
    expect(listS3Objects(prefix).map((o) => o.key)).toContain(`${prefix}${dayString(9).slice(0, 7).replace('-', '/')}/cdrs-${dayString(9)}.csv.gz`);
  });
});
