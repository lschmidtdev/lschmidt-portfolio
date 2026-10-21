import type { Locator, Page } from '@playwright/test';
import { boot, expect, test } from '../fixtures';

const viewports = [
  { name: '360x740', width: 360, height: 740 },
  { name: '390x844', width: 390, height: 844 },
  { name: '1440x900', width: 1440, height: 900 },
];

const locales = [
  {
    path: '/',
    lang: 'en',
    role: 'Mobile Engineer — Flutter',
    email: 'Email me',
    summary: /^Building production Flutter apps since 2020/,
    themeToggle: 'Toggle light or dark theme',
  },
  {
    path: '/pt',
    lang: 'pt-BR',
    role: 'Engenheiro Mobile — Flutter',
    email: 'Fale comigo',
    summary: /^Construo apps Flutter em produção desde 2020/,
    themeToggle: 'Alternar tema claro ou escuro',
  },
];

const themes = ['dark', 'light'] as const;

const nextFrames = (page: Page, count = 2) =>
  page.evaluate(
    (n) =>
      new Promise<void>((resolve) => {
        const step = (left: number) =>
          left === 0 ? resolve() : requestAnimationFrame(() => step(left - 1));
        step(n);
      }),
    count,
  );

async function expectInsideViewport(page: Page, locator: Locator): Promise<void> {
  await expect(locator).toBeVisible();
  const box = await locator.boundingBox();
  const viewport = page.viewportSize()!;
  expect(box, 'bounding box').not.toBeNull();
  expect(box!.x).toBeGreaterThanOrEqual(0);
  expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width + 1);
}

for (const { name, width, height } of viewports) {
  for (const { path, lang, role, email, summary, themeToggle } of locales) {
    for (const theme of themes) {
      test.describe(`${path} at ${name} in ${theme}`, () => {
        test.use({ viewport: { width, height } });

        test('renders the hero with no console errors or CSP violations', async ({ page }) => {
          const requested: string[] = [];
          page.on('request', (r) => requested.push(new URL(r.url()).pathname));
          await page.addInitScript(() => {
            document.addEventListener('DOMContentLoaded', () => {
              (window as unknown as { shellLang: string }).shellLang =
                document.documentElement.lang;
            });
          });
          await boot(page, path);
          expect(
            await page.evaluate(() => (window as unknown as { shellLang: string }).shellLang),
          ).toBe(lang);

          if (theme === 'light') {
            await page.getByRole('button', { name: themeToggle }).click();
          }

          const heading = page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' });
          await expectInsideViewport(page, heading);
          await expectInsideViewport(page, page.getByText(role, { exact: true }));
          await expectInsideViewport(page, page.getByText(summary));
          await expectInsideViewport(page, page.getByRole('button', { name: email }));
          const headingBox = (await heading.boundingBox())!;
          expect(headingBox.y).toBeLessThan(height);

          await nextFrames(page, 10);
          await expect(page.locator('html')).toHaveAttribute('lang', lang);
          await expect(heading).toBeVisible();

          expect(requested).toContain('/main.dart.wasm');
          expect(requested.some((p) => p.endsWith('/skwasm.wasm'))).toBe(true);
          expect(requested).not.toContain('/main.dart.js');
        });

        test('shows no CV link or button and requests no CV file', async ({ page }) => {
          const cvRequests: string[] = [];
          page.on('request', (r) => {
            if (new URL(r.url()).pathname.startsWith('/cv/')) cvRequests.push(r.url());
          });
          await boot(page, path);
          await expect(
            page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' }),
          ).toBeVisible();

          await expect(page.getByRole('link', { name: /\bCV\b/ })).toHaveCount(0);
          await expect(page.getByRole('button', { name: /\bCV\b/ })).toHaveCount(0);
          await expect(page.locator('a[href*="/cv/"], a[href$=".pdf"]')).toHaveCount(0);
          await nextFrames(page, 10);
          expect(cvRequests).toEqual([]);
        });
      });
    }
  }
}

test.describe('theme toggle', () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test('repaints the page and keeps the hero in place', async ({ page }) => {
    await boot(page, '/');
    const heading = page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' });
    await expect(heading).toBeVisible();
    await nextFrames(page, 10);
    const dark = await page.screenshot();
    const before = await heading.boundingBox();

    await page.getByRole('button', { name: 'Toggle light or dark theme' }).click();
    await expect
      .poll(async () => (await page.screenshot()).equals(dark), { timeout: 10_000 })
      .toBe(false);
    expect(await heading.boundingBox()).toEqual(before);
  });
});

async function jumpToContact(page: Page): Promise<void> {
  await boot(page, '/');
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
  await page.getByRole('button', { name: 'Email me' }).click();
  const contact = page.getByRole('heading', { level: 2, name: 'Hiring a Flutter engineer?' });
  await expect
    .poll(async () => (await contact.boundingBox())!.y, { timeout: 10_000 })
    .toBeLessThan(844);
}

test.describe('reduced motion', () => {
  test.use({ viewport: { width: 390, height: 844 } });

  test('shows revealed content immediately with nothing animating', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await jumpToContact(page);

    const content = { x: 0, y: 0, width: 360, height: 844 };
    const first = await page.screenshot({ clip: content });
    await nextFrames(page, 45);
    const settled = await page.screenshot({ clip: content });
    expect(first.equals(settled), 'pixels changed after the jump: a reveal was animating').toBe(
      true,
    );
  });
});

test.describe('404', () => {
  test.use({ allowedErrors: [/status of 404/] });

  test('/does-not-exist returns the branded 404 page', async ({ page }) => {
    const response = await page.goto('/does-not-exist');
    expect(response?.status()).toBe(404);
    await expect(page).toHaveTitle('Page not found · Lucas Schmidt');
    await expect(page.getByRole('heading', { name: 'Page not found.' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Página não encontrada.' })).toBeVisible();
  });
});
