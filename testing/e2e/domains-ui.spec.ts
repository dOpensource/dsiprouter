import { test, expect, Page } from '@playwright/test';
import { loginAdmin, guiApiRequest, SHELL_ENABLED } from './helpers';
import { createEndpointGroupFixture, deleteEndpointGroupFixture, EndpointGroupFixture } from './fixtures/endpoints';
import { uniqueDomain, createDomain, deleteDomainQuietly, seedDomainRows, removeDomainRows } from './fixtures/domains';

async function openDomainsPage(page: Page) {
  await page.goto('/domains');
  await expect(page.locator('h3:has-text("List of Domain(s)")')).toBeVisible();
  // wait for the ajax load to finish
  await expect(page.locator('#domains_processing')).toBeHidden();
}

async function filterTable(page: Page, query: string) {
  await page.fill('input[type="search"]', query);
}

function row(page: Page, name: string) {
  return page.locator('#domains tbody tr', { hasText: name });
}

async function findDomainId(page: Page, name: string): Promise<number | undefined> {
  const list = await guiApiRequest(page, 'GET', '/domains');
  const found = list.data.data.find((d: any) => d.domain === name);
  return found ? found.id : undefined;
}

test.describe('Domains page', () => {
  let eg: EndpointGroupFixture;

  test.beforeEach(async ({ page }) => {
    await loginAdmin(page);
    eg = await createEndpointGroupFixture(page, 2);
  });

  test.afterEach(async ({ page }) => {
    await deleteEndpointGroupFixture(page, eg);
  });

  test('table is loaded from the API', async ({ page }) => {
    const name = uniqueDomain('ui');
    let id: number | undefined;
    try {
      id = await createDomain(page, { domain: name, type: 'local', pbxs: eg.gwids, notes: 'from api' });
      await openDomainsPage(page);
      await filterTable(page, name);
      const r = row(page, name);
      await expect(r).toHaveCount(1);
      await expect(r.locator('td.domain_id')).toHaveText(String(id));
      await expect(r.locator('td.authtype')).toHaveText('local');
      await expect(r.locator('td.pbx_name')).toHaveText('Manually Created');
      await expect(r.locator('td.pbx_list')).toHaveText(eg.gwids.join(', '));
      await expect(r.locator('td.notes')).toHaveText('from api');
    } finally {
      await deleteDomainQuietly(page, id);
    }
  });

  for (const type of ['passthru', 'local', 'realtime']) {
    test(`add a ${type} domain through the modal`, async ({ page }) => {
      const name = uniqueDomain(`ui${type}`);
      try {
        await openDomainsPage(page);
        await page.click('#open-DomainAdd');
        const modal = page.locator('#add');
        await expect(modal).toBeVisible();
        await modal.locator('.domain_name').fill(name);
        await modal.locator('.authtype').selectOption(type);
        await modal.locator('.pbx_list').fill(type === 'passthru' ? String(eg.gwids[0]) : eg.gwids.join(','));
        await modal.locator('.notes').fill(`added ${type}`);
        await modal.locator('button[type="submit"]').click();

        await expect(modal).toBeHidden();
        await expect(page.locator('#message-bar')).toContainText('Domain added');
        await expect(page.locator('#top-nav')).toHaveClass(/reload-required/);
        await filterTable(page, name);
        await expect(row(page, name).locator('td.authtype')).toHaveText(type);
        await expect(row(page, name).locator('td.notes')).toHaveText(`added ${type}`);
      } finally {
        await deleteDomainQuietly(page, await findDomainId(page, name));
      }
    });
  }

  test('bulk add creates one row per domain', async ({ page }) => {
    const a = uniqueDomain('uibulk');
    const b = uniqueDomain('uibulk');
    try {
      await openDomainsPage(page);
      await page.click('#open-DomainAdd');
      const modal = page.locator('#add');
      await modal.locator('.domain_name').fill(`${a},${b}`);
      await modal.locator('.authtype').selectOption('passthru');
      await modal.locator('.pbx_list').fill(String(eg.gwids[0]));
      await modal.locator('button[type="submit"]').click();
      await expect(modal).toBeHidden();
      await filterTable(page, 'uibulk');
      await expect(row(page, a)).toHaveCount(1);
      await expect(row(page, b)).toHaveCount(1);
    } finally {
      await deleteDomainQuietly(page, await findDomainId(page, a));
      await deleteDomainQuietly(page, await findDomainId(page, b));
    }
  });

  test('edit keeps the id and updates the row', async ({ page }) => {
    const name = uniqueDomain('uiedit');
    let id: number | undefined;
    try {
      id = await createDomain(page, { domain: name, type: 'local', pbxs: eg.gwids, notes: 'before' });
      await openDomainsPage(page);
      await filterTable(page, name);
      await row(page, name).locator('.open-Update').click();

      const modal = page.locator('#edit');
      await expect(modal).toBeVisible();
      await expect(modal.locator('.domain_name')).toHaveValue(name);
      await expect(modal.locator('.authtype')).toHaveValue('local');
      await expect(modal.locator('.pbx_list')).toHaveValue(eg.gwids.join(','));
      await expect(modal.locator('.notes')).toHaveValue('before');

      await modal.locator('.pbx_list').fill(String(eg.gwids[1]));
      await modal.locator('.notes').fill('after');
      await modal.locator('button[type="submit"]').click();

      await expect(modal).toBeHidden();
      await expect(page.locator('#message-bar')).toContainText('Domain updated');
      await expect(row(page, name).locator('td.domain_id')).toHaveText(String(id));
      await expect(row(page, name).locator('td.notes')).toHaveText('after');
      await expect(row(page, name).locator('td.pbx_list')).toHaveText(String(eg.gwids[1]));
    } finally {
      await deleteDomainQuietly(page, id);
    }
  });

  test('delete removes the row', async ({ page }) => {
    const name = uniqueDomain('uidel');
    const id = await createDomain(page, { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] });
    try {
      await openDomainsPage(page);
      await filterTable(page, name);
      await row(page, name).locator('.open-Delete').click();
      const modal = page.locator('#delete');
      await expect(modal).toBeVisible();
      await expect(modal.locator('.domain_name')).toHaveText(name);
      await modal.locator('button[type="submit"]').click();
      await expect(modal).toBeHidden();
      await expect(page.locator('#message-bar')).toContainText('Domain deleted');
      await expect(row(page, name)).toHaveCount(0);
      expect(await findDomainId(page, name)).toBeUndefined();
    } finally {
      await deleteDomainQuietly(page, await findDomainId(page, name) ?? id);
    }
  });

  test('API errors keep the modal open and add nothing', async ({ page }) => {
    const name = uniqueDomain('uierr');
    try {
      await openDomainsPage(page);
      await page.click('#open-DomainAdd');
      const modal = page.locator('#add');
      await modal.locator('.domain_name').fill(name);
      await modal.locator('.authtype').selectOption('passthru');
      await modal.locator('.pbx_list').fill('999999');
      await modal.locator('button[type="submit"]').click();

      await expect(page.locator('#message-bar')).toContainText('endpoint id 999999 does not exist');
      await expect(modal).toBeVisible();
      expect(await findDomainId(page, name)).toBeUndefined();
    } finally {
      await deleteDomainQuietly(page, await findDomainId(page, name));
    }
  });

  test('client side validation flags an empty domain and a missing type', async ({ page }) => {
    await openDomainsPage(page);
    await page.click('#open-DomainAdd');
    const modal = page.locator('#add');

    await modal.locator('button[type="submit"]').click();
    await expect(modal.locator('.domain_name')).toHaveClass(/is-invalid/);
    await expect(modal).toBeVisible();

    await modal.locator('.domain_name').fill(uniqueDomain('uival'));
    await modal.locator('button[type="submit"]').click();
    await expect(modal.locator('.authtype')).toHaveClass(/is-invalid/);
    await expect(modal).toBeVisible();
  });

  test('picking a type in one modal does not disable the other modals (#834)', async ({ page }) => {
    const name = uniqueDomain('ui834');
    let id: number | undefined;
    try {
      id = await createDomain(page, { domain: name, type: 'passthru', pbxs: [eg.gwids[0]] });
      await openDomainsPage(page);

      await page.click('#open-DomainAdd');
      const add = page.locator('#add');
      const nosub = add.locator('.authtype option[value="msteams-nosub"]');
      // with or without a license, msteams disables the endpoint field of the add modal only
      await add.locator('.authtype').selectOption((await nosub.count()) > 0 ? 'msteams-nosub' : 'msteams');
      await expect(add.locator('.pbx_list')).toBeDisabled();
      await add.locator('.close').click();
      await expect(add).toBeHidden();

      await filterTable(page, name);
      await row(page, name).locator('.open-Update').click();
      const edit = page.locator('#edit');
      await expect(edit.locator('.domain_name')).toBeEnabled();
      await expect(edit.locator('.pbx_list')).toBeEnabled();
      await expect(edit.locator('button[type="submit"]')).toBeEnabled();
      await edit.locator('.close').click();
      await expect(edit).toBeHidden();

      await row(page, name).locator('.open-Delete').click();
      await expect(page.locator('#delete button[type="submit"]')).toBeEnabled();
    } finally {
      await deleteDomainQuietly(page, id);
    }
  });

  test('without a MSTeams license the msteams option disables the form', async ({ page }) => {
    await openDomainsPage(page);
    await page.click('#open-DomainAdd');
    const add = page.locator('#add');
    test.skip((await add.locator('.authtype option[value="msteams-nosub"]').count()) === 0,
      'this install has a DSIP_MSTEAMS license');
    await add.locator('.authtype').selectOption('msteams-nosub');
    await expect(add.locator('.domain_name')).toBeDisabled();
    await expect(add.locator('button[type="submit"]')).toBeDisabled();
  });

  test('domains owned by an endpoint group have no edit or delete buttons', async ({ page }) => {
    test.skip(!SHELL_ENABLED, 'needs DSIP_TEST_SHELL=1 to seed a managed domain');
    const name = uniqueDomain('uimanaged');
    try {
      seedDomainRows(name, {
        pbx_type: '1', created_by: String(eg.gwgroupid), domain_auth: 'passthru',
        pbx_list: String(eg.gwgroupid), description: 'notes:', pbx_ip: '127.0.0.10',
      });
      await openDomainsPage(page);
      await filterTable(page, name);
      const r = row(page, name);
      await expect(r).toHaveCount(1);
      await expect(r.locator('td.domain_type')).toHaveText('Dynamic');
      await expect(r.locator(`td.pbx_name a[href="/endpointgroups?id=${eg.gwgroupid}"]`)).toBeVisible();
      await expect(r.locator('.open-Update')).toHaveCount(0);
      await expect(r.locator('.open-Delete')).toHaveCount(0);
    } finally {
      removeDomainRows(name);
    }
  });
});
