import type { Page, Request } from '@playwright/test';
import { boot, expect, test, umamiScript, web3formsApi } from '../fixtures';

const visitor = {
  name: 'Test Recruiter',
  email: 'recruiter@example.com',
  message: 'We are hiring a remote Flutter engineer and would like to talk.',
};

const cors = { 'access-control-allow-origin': '*' };

const form = (page: Page) => page.getByRole('group', { name: 'Contact form' });

async function typeInto(page: Page, label: string, text: string): Promise<void> {
  const field = form(page).getByRole('textbox', { name: label, exact: true });
  await field.scrollIntoViewIfNeeded();
  const box = (await field.boundingBox())!;
  const clip = { x: box.x, y: box.y, width: box.width, height: box.height };
  const idle = await page.screenshot({ clip });
  await field.click();
  await expect(field).toBeFocused();
  await expect.poll(async () => (await page.screenshot({ clip })).equals(idle)).toBe(false);
  await page.keyboard.insertText(text);
  await expect(field).toHaveValue(text);
}

async function fillForm(page: Page): Promise<void> {
  await typeInto(page, 'Name', visitor.name);
  await typeInto(page, 'Email', visitor.email);
  await typeInto(page, 'Message', visitor.message);
}

async function openContact(page: Page): Promise<void> {
  await boot(page, '/');
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
  await page.getByRole('button', { name: 'Email me' }).click();
  await expect(page.getByRole('textbox', { name: 'Message' })).toBeVisible();
}

test.describe('contact form', () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test('a successful send shows the sent state and posts the form fields', async ({
    page,
    outbound,
  }) => {
    const posted: Request[] = [];
    await page.route(web3formsApi, async (route) => {
      posted.push(route.request());
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        headers: cors,
        body: JSON.stringify({ success: true }),
      });
    });
    await openContact(page);
    await fillForm(page);
    await page.getByRole('button', { name: 'Send message' }).click();

    await expect(page.getByRole('heading', { name: 'Message sent.' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'Message' })).toHaveCount(0);

    expect(posted).toHaveLength(1);
    expect(posted[0].method()).toBe('POST');
    const body = posted[0].postDataJSON() as Record<string, unknown>;
    expect(Object.keys(body)).toEqual(
      expect.arrayContaining(['access_key', 'name', 'email', 'message']),
    );
    expect(typeof body.access_key).toBe('string');
    expect((body.access_key as string).length).toBeGreaterThan(0);
    expect(body.name).toBe(visitor.name);
    expect(body.email).toBe(visitor.email);
    expect(body.message).toBe(visitor.message);
    expect(outbound.web3forms).toHaveLength(1);
  });

  test('invalid input is rejected without any request', async ({ page, outbound }) => {
    await openContact(page);
    await page.getByRole('button', { name: 'Send message' }).click();

    await expect(form(page).getByText('Please enter your name.')).toBeVisible();
    expect(outbound.web3forms).toEqual([]);
  });
});

test.describe('contact form server error', () => {
  test.use({ viewport: { width: 1440, height: 900 }, allowedErrors: [/status of 500/] });

    test('a server error shows the fallback and keeps the typed message', async ({ page }) => {
      await page.route(web3formsApi, (route) =>
        route.fulfill({
          status: 500,
          contentType: 'application/json',
          headers: cors,
          body: JSON.stringify({ success: false }),
        }),
      );
      await openContact(page);
      await fillForm(page);
      await page.getByRole('button', { name: 'Send message' }).click();

      await expect(form(page).getByText(/Your message could not be sent/)).toBeVisible();
      const fallback = page.getByRole('link', { name: 'Email me directly' });
      await expect(fallback).toBeVisible();
      await expect(fallback).toHaveAttribute('href', /^mailto:lschmidt\.dev@gmail\.com/);
      await expect(page.getByRole('textbox', { name: 'Message' })).toHaveValue(visitor.message);
      await expect(page.getByRole('textbox', { name: 'Name' })).toHaveValue(visitor.name);
      await expect(page.getByRole('heading', { name: 'Message sent.' })).toHaveCount(0);
    });
});

test.describe('analytics script blocked', () => {
  test.use({ viewport: { width: 1440, height: 900 }, allowedErrors: [/ERR_FAILED/] });

  test('the page still works and the form still sends', async ({ page, errors }) => {
    await page.route(umamiScript, (route) => route.abort());
    await page.route(web3formsApi, (route) =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        headers: cors,
        body: JSON.stringify({ success: true }),
      }),
    );
    await openContact(page);
    await fillForm(page);
    await page.getByRole('button', { name: 'Send message' }).click();
    await expect(page.getByRole('heading', { name: 'Message sent.' })).toBeVisible();

    const unexpected = errors.filter((e) => !/ERR_FAILED/.test(e));
    expect(unexpected).toEqual([]);
  });
});
