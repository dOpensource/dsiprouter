import { Page, expect } from '@playwright/test';
import { guiApiRequest, dbQuery, sqlQuote, SHELL_ENABLED, shell } from '../helpers';

export const CDR_DEFAULTS = {
  CDR_RETENTION_DAYS: 0,
  CDR_ARCHIVE_ENABLED: false,
  CDR_S3_BUCKET: '',
  CDR_S3_PREFIX: 'cdrs/',
  CDR_S3_REGION: '',
  CDR_S3_ENDPOINT: '',
  CDR_S3_ACCESS_KEY: '',
  CDR_S3_SECRET_KEY: null,
};

// a local port nothing listens on, uploads to it always fail
export const DEAD_S3_ENDPOINT = 'http://127.0.0.1:9';

// S3 compatible service for the archive happy path, the S3 tests skip without it
export const S3 = {
  endpoint: process.env.DSIP_TEST_S3_ENDPOINT || '',
  bucket: process.env.DSIP_TEST_S3_BUCKET || '',
  region: process.env.DSIP_TEST_S3_REGION || 'us-east-1',
  accessKey: process.env.DSIP_TEST_S3_ACCESS_KEY || '',
  secretKey: process.env.DSIP_TEST_S3_SECRET_KEY || '',
};
export const S3_ENABLED = S3.bucket !== '' && S3.accessKey !== '' && S3.secretKey !== '';

/**
 * A run-unique call-id prefix, every seeded row carries it so cleanup never touches real CDRs.
 */
export function cdrTag(label = 'cdr'): string {
  return `e2e-${label}-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
}

export async function getCdrSettings(page: Page): Promise<any> {
  const res = await guiApiRequest(page, 'GET', '/settings/cdr');
  expect(res.status, JSON.stringify(res.data)).toBe(200);
  return res.data.data[0];
}

export async function putCdrSettings(page: Page, body: any) {
  return guiApiRequest(page, 'PUT', '/settings/cdr', body);
}

export async function saveCdrSettings(page: Page, body: any): Promise<any> {
  const res = await putCdrSettings(page, body);
  expect(res.status, JSON.stringify(res.data)).toBe(200);
  return res.data.data[0];
}

export async function resetCdrSettings(page: Page) {
  await saveCdrSettings(page, CDR_DEFAULTS);
}

/**
 * The CDR tests change cluster wide settings, only do that on an install that still has the defaults
 * (so resetting them afterwards loses nothing).
 */
export async function cdrSettingsAreDefault(page: Page): Promise<boolean> {
  const cfg = await getCdrSettings(page);
  return cfg.CDR_RETENTION_DAYS === 0 && cfg.CDR_ARCHIVE_ENABLED === false && cfg.CDR_S3_SECRET_KEY_SET === false;
}

export async function runRetention(page: Page) {
  return guiApiRequest(page, 'POST', '/settings/cdr/run');
}

/**
 * Insert a completed call (cdrs row + its acc INVITE) started daysAgo days ago.
 */
export function seedCall(tag: string, daysAgo: number, suffix: string | number = daysAgo) {
  const callid = sqlQuote(`${tag}-${suffix}`);
  dbQuery(
    `INSERT INTO cdrs (call_start_time, sip_call_id, src_username, dst_username, duration) ` +
    `VALUES (NOW() - INTERVAL ${daysAgo} DAY, ${callid}, '1001', '2002', 60); ` +
    `INSERT INTO acc (method, callid, time, sip_code, sip_reason, cdr_id) ` +
    `VALUES ('INVITE', ${callid}, NOW() - INTERVAL ${daysAgo} DAY, '200', 'OK', LAST_INSERT_ID())`
  );
}

/**
 * Insert an unanswered INVITE that never became a CDR.
 */
export function seedOrphanInvite(tag: string, daysAgo: number) {
  dbQuery(
    `INSERT INTO acc (method, callid, time, sip_code, sip_reason) ` +
    `VALUES ('INVITE', ${sqlQuote(`${tag}-orphan-${daysAgo}`)}, NOW() - INTERVAL ${daysAgo} DAY, '487', 'Request Terminated')`
  );
}

export function seedMissedCall(tag: string, daysAgo: number) {
  dbQuery(
    `INSERT INTO missed_calls (method, callid, time, sip_code, sip_reason) ` +
    `VALUES ('INVITE', ${sqlQuote(`${tag}-missed-${daysAgo}`)}, NOW() - INTERVAL ${daysAgo} DAY, '486', 'Busy Here')`
  );
}

/**
 * Bulk insert count completed calls daysAgo days ago (cdrs rows only), using MariaDB's sequence engine.
 */
export function seedManyCdrs(tag: string, count: number, daysAgo: number) {
  dbQuery(
    `INSERT INTO cdrs (call_start_time, sip_call_id) ` +
    `SELECT NOW() - INTERVAL ${daysAgo} DAY, CONCAT(${sqlQuote(`${tag}-bulk-`)}, seq) FROM seq_1_to_${count}`
  );
}

export function cdrCallIds(tag: string): string[] {
  return dbQuery(`SELECT sip_call_id FROM cdrs WHERE sip_call_id LIKE ${sqlQuote(`${tag}-%`)} ORDER BY sip_call_id`)
    .map((row) => row[0]);
}

export function accCallIds(tag: string): string[] {
  return dbQuery(`SELECT callid FROM acc WHERE callid LIKE ${sqlQuote(`${tag}-%`)} ORDER BY callid`)
    .map((row) => row[0]);
}

export function missedCallIds(tag: string): string[] {
  return dbQuery(`SELECT callid FROM missed_calls WHERE callid LIKE ${sqlQuote(`${tag}-%`)} ORDER BY callid`)
    .map((row) => row[0]);
}

export function countCdrs(tag: string): number {
  return Number(dbQuery(`SELECT COUNT(*) FROM cdrs WHERE sip_call_id LIKE ${sqlQuote(`${tag}-%`)}`)[0][0]);
}

export function clearCdrs(tag: string) {
  if (!SHELL_ENABLED) return;
  const like = sqlQuote(`${tag}-%`);
  dbQuery(
    `DELETE FROM cdrs WHERE sip_call_id LIKE ${like}; DELETE FROM acc WHERE callid LIKE ${like}; ` +
    `DELETE FROM missed_calls WHERE callid LIKE ${like}`
  );
}

/**
 * Number of CDR rows NOT created by the tests that a retention run with this many days would delete.
 * The retention tests skip when it is above 0 so they never delete real CDRs.
 */
export function realRowsOlderThan(days: number): number {
  const cutoff = `DATE_SUB(CURDATE(), INTERVAL ${days} DAY)`;
  const rows = dbQuery(
    `SELECT (SELECT COUNT(*) FROM cdrs WHERE call_start_time < ${cutoff} AND sip_call_id NOT LIKE 'e2e-%') + ` +
    `(SELECT COUNT(*) FROM acc WHERE time < ${cutoff} AND callid NOT LIKE 'e2e-%') + ` +
    `(SELECT COUNT(*) FROM missed_calls WHERE time < ${cutoff} AND callid NOT LIKE 'e2e-%')`
  );
  return Number(rows[0][0]);
}

/**
 * List the objects under a prefix of the test bucket, with each object's gunzipped CSV text.
 * Uses boto3 from the dSIPRouter venv so the suite needs no S3 client of its own.
 */
export function listS3Objects(prefix: string): { key: string; csv: string }[] {
  const script = [
    'import boto3, gzip, json, sys',
    'a = json.loads(sys.argv[1])',
    "c = boto3.client('s3', endpoint_url=a['endpoint'] or None, region_name=a['region'], " +
    "aws_access_key_id=a['accessKey'], aws_secret_access_key=a['secretKey'])",
    'out = []',
    "for page in c.get_paginator('list_objects_v2').paginate(Bucket=a['bucket'], Prefix=a['prefix']):",
    "    for o in page.get('Contents', []):",
    "        body = c.get_object(Bucket=a['bucket'], Key=o['Key'])['Body'].read()",
    "        out.append({'key': o['Key'], 'csv': gzip.decompress(body).decode('utf-8')})",
    'print(json.dumps(out))',
  ].join('\n');
  const args = JSON.stringify({ ...S3, prefix });
  const out = shell(`/opt/dsiprouter/venv/bin/python -I -c ${shellQuote(script)} ${shellQuote(args)}`);
  return JSON.parse(out);
}

export function deleteS3Prefix(prefix: string) {
  if (!S3_ENABLED || !SHELL_ENABLED || prefix === '') return;
  const script = [
    'import boto3, json, sys',
    'a = json.loads(sys.argv[1])',
    "c = boto3.client('s3', endpoint_url=a['endpoint'] or None, region_name=a['region'], " +
    "aws_access_key_id=a['accessKey'], aws_secret_access_key=a['secretKey'])",
    "for page in c.get_paginator('list_objects_v2').paginate(Bucket=a['bucket'], Prefix=a['prefix']):",
    "    for o in page.get('Contents', []):",
    "        c.delete_object(Bucket=a['bucket'], Key=o['Key'])",
  ].join('\n');
  shell(`/opt/dsiprouter/venv/bin/python -I -c ${shellQuote(script)} ${shellQuote(JSON.stringify({ ...S3, prefix }))}`);
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

/**
 * Parse the CSV written by the archive job (no embedded newlines in test data).
 */
export function parseCsv(text: string): { header: string[]; rows: Record<string, string>[] } {
  const lines = text.split(/\r?\n/).filter((line) => line !== '');
  const split = (line: string) => line.split(',').map((v) => v.replace(/^"|"$/g, ''));
  const header = split(lines[0]);
  const rows = lines.slice(1).map((line) => {
    const values = split(line);
    return Object.fromEntries(header.map((h, i) => [h, values[i]]));
  });
  return { header, rows };
}
