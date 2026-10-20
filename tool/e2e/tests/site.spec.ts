import { boot, expect, test } from '../fixtures';

const viewports = [
  { name: 'phone', width: 390, height: 844 },
  { name: 'desktop', width: 1440, height: 900 },
];
const locales = [
  { path: '/', lang: 'en' },
  { path: '/pt', lang: 'pt-BR' },
];

for (const { name, width, height } of viewports) {
  for (const { path, lang } of locales) {
    test.describe(`${path} at ${name}`, () => {
      test.use({ viewport: { width, height } });

      test('boots on wasm with no console errors or CSP violations', async ({ page }) => {
        const paths: string[] = [];
        page.on('request', (r) => paths.push(new URL(r.url()).pathname));
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
        await page.locator('flt-semantics-placeholder').dispatchEvent('click');
        await expect(page.getByText('Lucas Schmidt').first()).toBeVisible();
        await expect(page.locator('html')).toHaveAttribute('lang', lang);
        await page.waitForTimeout(1_000);
        await expect(page.locator('html')).toHaveAttribute('lang', lang);
        await expect(page.getByText('Lucas Schmidt').first()).toBeVisible();
        expect(paths).toContain('/main.dart.wasm');
        expect(paths.some((p) => p.endsWith('/skwasm.wasm'))).toBe(true);
        expect(paths).not.toContain('/main.dart.js');
      });
    });
  }
}

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
