import { boot, expect, expectInsideViewport, nextFrames, test } from '../fixtures';

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
    themeToggle: 'Switch to light theme',
  },
  {
    path: '/pt',
    lang: 'pt-BR',
    role: 'Engenheiro Mobile — Flutter',
    email: 'Fale comigo',
    summary: /^Construo apps Flutter em produção desde 2020/,
    themeToggle: 'Mudar para o tema claro',
  },
];

const themes = ['dark', 'light'] as const;

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
            await nextFrames(page, 10);
            const dark = await page.screenshot();
            await page.getByRole('button', { name: themeToggle }).click();
            await expect
              .poll(async () => (await page.screenshot()).equals(dark), { timeout: 10_000 })
              .toBe(false);
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

    await page.getByRole('button', { name: 'Switch to light theme' }).click();
    await expect
      .poll(async () => (await page.screenshot()).equals(dark), { timeout: 10_000 })
      .toBe(false);
    expect(await heading.boundingBox()).toEqual(before);
  });
});

const scrollHost = 'flt-semantics';

test.describe('reduced motion', () => {
  test.use({ viewport: { width: 390, height: 844 } });

  test('jumps to the section and shows it fully revealed on the first frame', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await boot(page, '/');
    await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
    await nextFrames(page, 10);

    await page.evaluate((host) => {
      const el = [...document.querySelectorAll(host)].find(
        (n) => getComputedStyle(n).overflowY === 'scroll',
      )!;
      const samples: number[] = [];
      (window as unknown as { scrollSamples: number[] }).scrollSamples = samples;
      const sample = () => {
        samples.push(el.scrollTop);
        requestAnimationFrame(sample);
      };
      sample();
    }, scrollHost);

    await page.getByRole('button', { name: 'Email me' }).click();
    await page.waitForFunction(
      (host) =>
        [...document.querySelectorAll(host)].some(
          (n) => getComputedStyle(n).overflowY === 'scroll' && n.scrollTop > 0,
        ),
      scrollHost,
      { polling: 'raf' },
    );
    const viewport = page.viewportSize()!;
    const content = { x: 0, y: 0, width: viewport.width - 30, height: viewport.height };
    const caret = [page.getByRole('textbox', { name: 'Name', exact: true })];
    const first = await page.screenshot({ clip: content, mask: caret });
    await nextFrames(page, 45);
    const settled = await page.screenshot({ clip: content, mask: caret });

    const samples = await page.evaluate(
      () => (window as unknown as { scrollSamples: number[] }).scrollSamples,
    );
    const moving = samples.filter((v) => v > 0);
    expect(new Set(moving).size, 'scroll position kept changing: the jump was animated').toBe(1);
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
