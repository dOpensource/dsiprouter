import { Page, expect } from '@playwright/test';
import { guiApiRequest, dbQuery, sqlQuote } from '../helpers';

/**
 * Insert a domain straight into the DB, the way the FusionPBX sync or the old domains form did.
 * Returns the new domain id. Needs DSIP_TEST_SHELL=1.
 */
export function seedDomainRows(name: string, attrs: Record<string, string>): number {
  dbQuery(`INSERT INTO domain (domain, did, last_modified) VALUES (${sqlQuote(name)}, ${sqlQuote(name)}, NOW())`);
  for (const [attr, value] of Object.entries(attrs)) {
    dbQuery(`INSERT INTO domain_attrs (did, name, type, value, last_modified) ` +
      `VALUES (${sqlQuote(name)}, ${sqlQuote(attr)}, 2, ${sqlQuote(value)}, NOW())`);
  }
  return Number(dbQuery(`SELECT id FROM domain WHERE did=${sqlQuote(name)}`)[0][0]);
}

export function removeDomainRows(name: string) {
  dbQuery(`DELETE FROM domain_attrs WHERE did=${sqlQuote(name)}`);
  dbQuery(`DELETE FROM domain WHERE did=${sqlQuote(name)}`);
}

let counter = 0;

/**
 * A unique domain name for this run, cleaned up by the global teardown if a test aborts.
 */
export function uniqueDomain(label: string = 'd'): string {
  counter += 1;
  return `e2e-${Date.now()}-${counter}-${label}.example.test`;
}

export async function createDomain(page: Page, body: any): Promise<number> {
  const result = await guiApiRequest(page, 'POST', '/domains', body);
  expect(result.status, JSON.stringify(result.data)).toBe(200);
  return result.data.data[0].id;
}

export async function getDomain(page: Page, id: number): Promise<{ status: number; domain: any }> {
  const result = await guiApiRequest(page, 'GET', `/domains/${id}`);
  return { status: result.status, domain: result.data.data ? result.data.data[0] : undefined };
}

export async function deleteDomainQuietly(page: Page, id: number | undefined) {
  if (id === undefined) {
    return;
  }
  await guiApiRequest(page, 'DELETE', `/domains/${id}`);
}
