import { Page, expect } from '@playwright/test';
import { guiApiRequest } from '../helpers';

export interface EndpointGroupFixture {
  gwgroupid: number;
  gwids: number[];
}

/**
 * Create an endpoint group with `count` endpoints (127.0.0.x hosts) for domains to point at.
 */
export async function createEndpointGroupFixture(page: Page, count: number = 2): Promise<EndpointGroupFixture> {
  const stamp = Date.now();
  const endpoints = [];
  for (let i = 0; i < count; i++) {
    endpoints.push({ host: `127.0.0.${10 + i}`, description: `e2e_pbx_${i}` });
  }
  const result = await guiApiRequest(page, 'POST', '/endpointgroups', {
    name: `e2e_${stamp}`,
    endpoints,
  });
  expect(result.status).toBe(200);
  const data = result.data.data[0];
  return { gwgroupid: data.gwgroupid, gwids: data.endpoints };
}

export async function deleteEndpointGroupFixture(page: Page, fixture: EndpointGroupFixture | undefined) {
  if (fixture === undefined) {
    return;
  }
  await guiApiRequest(page, 'DELETE', `/endpointgroups/${fixture.gwgroupid}`);
}
