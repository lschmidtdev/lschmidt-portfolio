import type { Page } from '@playwright/test';
import { boot, expect, nextFrames, test } from '../fixtures';

const headerControls: [string, RegExp][] = [
  ['brand', /^LS\s*Lucas Schmidt$/],
  ['Work', /^Work$/],
  ['Experience', /^Experience$/],
  ['Skills', /^Skills$/],
  ['Contact', /^Contact$/],
  ['English', /^English$/],
  ['Português', /^Português$/],
  ['theme', /^Switch to light theme$/],
];

const focusedName = (page: Page) =>
  page.evaluate(() => {
    const el = document.activeElement;
    if (!el || !el.closest('flt-semantics-host')) return '';
    return (el.getAttribute('aria-label') ?? el.textContent ?? '').trim();
  });

async function open(page: Page): Promise<void> {
  await boot(page, '/');
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
}

async function tabTo(page: Page, name: string, pattern: RegExp): Promise<void> {
  await page.keyboard.press('Tab');
  await expect.poll(() => focusedName(page), { message: `Tab should reach ${name}` }).toMatch(
    pattern,
  );
}

test.describe('keyboard', () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test('Tab walks through every header control in order', async ({ page }) => {
    await open(page);
    for (const [name, pattern] of headerControls) {
      await tabTo(page, name, pattern);
    }
  });

  test('Enter on Contact moves the focus into the form', async ({ page }) => {
    await open(page);
    for (const [name, pattern] of headerControls.slice(0, 5)) {
      await tabTo(page, name, pattern);
    }

    await page.keyboard.press('Enter');
    await page.keyboard.press('Tab');

    const form = page.getByRole('group', { name: 'Contact form' });
    const focused = form.locator(':focus');
    await expect(focused).toHaveCount(1);
    const box = (await focused.boundingBox())!;
    const viewport = page.viewportSize()!;
    expect(box.y).toBeGreaterThanOrEqual(0);
    expect(box.y + box.height).toBeLessThanOrEqual(viewport.height);
  });
});

const brandName = /^LS\s*Lucas Schmidt$/;

const headerLinks = [
  {
    path: '/',
    links: { Work: 'work', Experience: 'experience', Skills: 'skills', Contact: 'contact' },
  },
  {
    path: '/pt',
    links: { Trabalho: 'work', Experiência: 'experience', Habilidades: 'skills', Contato: 'contact' },
  },
];

const pageScroll = (page: Page) =>
  page.evaluate(() =>
    Math.max(
      0,
      ...[...document.querySelectorAll('flt-semantics')]
        .filter((n) => getComputedStyle(n).overflowY === 'scroll')
        .map((n) => n.scrollTop),
    ),
  );

test.describe('header links', () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  for (const { path, links } of headerLinks) {
    test(`on ${path} the brand and the nav links have real urls`, async ({ page }) => {
      await boot(page, path);
      await expect(page.getByRole('link', { name: brandName })).toHaveAttribute('href', path);
      for (const [name, fragment] of Object.entries(links)) {
        await expect(page.getByRole('link', { name, exact: true })).toHaveAttribute(
          'href',
          `${path}#${fragment}`,
        );
      }
    });
  }

  test('nav clicks scroll in page and leave the url and history alone', async ({ page }) => {
    await page.goto('/robots.txt');
    await open(page);
    const before = await page.evaluate(() => {
      (window as unknown as { sameDocument: boolean }).sameDocument = true;
      return { url: location.href, length: history.length };
    });
    expect(await pageScroll(page)).toBe(0);

    await page.getByRole('link', { name: 'Experience', exact: true }).click();
    await expect.poll(() => pageScroll(page)).toBeGreaterThan(0);
    await expect(page.getByRole('heading', { name: 'Experience', exact: true })).toBeInViewport();
    for (const name of ['Work', 'Skills', 'Contact']) {
      await page.mouse.move(700, 450);
      await page.mouse.wheel(0, -100_000);
      await expect.poll(() => pageScroll(page)).toBe(0);
      await page.getByRole('link', { name, exact: true }).click();
      await expect.poll(() => pageScroll(page)).toBeGreaterThan(0);
    }
    await page.mouse.wheel(0, -100_000);
    await expect.poll(() => pageScroll(page)).toBe(0);
    await page.getByRole('link', { name: brandName }).click();
    await nextFrames(page, 10);

    const after = await page.evaluate(() => ({
      url: location.href,
      length: history.length,
      sameDocument: (window as unknown as { sameDocument?: boolean }).sameDocument,
    }));
    expect(after).toEqual({ ...before, sameDocument: true });

    await page.goBack();
    await expect(page).toHaveURL(/\/robots\.txt$/);
  });

  test('a ctrl-click on a nav link opens its url in a new tab', async ({ context, page }) => {
    await open(page);
    const url = page.url();
    const [opened] = await Promise.all([
      context.waitForEvent('page'),
      page.getByRole('link', { name: 'Skills', exact: true }).click({ modifiers: ['ControlOrMeta'] }),
    ]);
    await expect.poll(() => opened.url()).toMatch(/\/#skills$/);
    expect(page.url()).toBe(url);
  });
});
