import { test as base, expect, type Locator, type Page } from '@playwright/test';

export async function watchErrors(page: Page): Promise<string[]> {
  const errors: string[] = [];
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(`console: ${m.text()} @ ${m.location().url}`);
  });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  await page.exposeFunction('__csp', (v: string) => errors.push(`csp: ${v}`));
  await page.addInitScript(() => {
    document.addEventListener('securitypolicyviolation', (e) => {
      (window as unknown as { __csp: (v: string) => void }).__csp(
        `${e.disposition} ${e.effectiveDirective} ${e.blockedURI}`,
      );
    });
  });
  return errors;
}

export const umamiScript = 'https://cloud.umami.is/**';
export const umamiGateway = 'https://gateway.umami.is/**';
export const web3formsApi = 'https://api.web3forms.com/**';

export interface Outbound {
  umamiGateway: string[];
  web3forms: string[];
}

export const test = base.extend<{
  allowedErrors: RegExp[];
  errors: string[];
  outbound: Outbound;
}>({
  outbound: [
    async ({ page }, use) => {
      const outbound: Outbound = { umamiGateway: [], web3forms: [] };
      page.on('request', (r) => {
        const host = new URL(r.url()).host;
        if (host === 'gateway.umami.is') outbound.umamiGateway.push(r.url());
        if (host === 'api.web3forms.com') outbound.web3forms.push(r.url());
      });
      await page.route(umamiScript, (route) =>
        route.fulfill({ contentType: 'text/javascript', body: '' }),
      );
      await page.route(umamiGateway, (route) => route.abort());
      await page.route(web3formsApi, (route) => route.abort());
      await use(outbound);
      expect(outbound.umamiGateway, 'requests to the Umami gateway').toEqual([]);
    },
    { auto: true },
  ],

  allowedErrors: [[], { option: true }],
  errors: [
    async ({ page, allowedErrors }, use) => {
      const errors = await watchErrors(page);
      await use(errors);
      const unexpected = errors.filter(
        (e) => !allowedErrors.some((r) => r.test(e)),
      );
      expect(unexpected, 'console errors, page errors or CSP violations').toEqual([]);
    },
    { auto: true },
  ],
});

export { expect };

export async function boot(page: Page, path: string): Promise<void> {
  const response = await page.goto(path);
  expect(response?.status()).toBe(200);
  await expect(page.locator('flutter-view')).toBeAttached({ timeout: 30_000 });
  await expect(page.locator('main.fallback')).toHaveCount(0, { timeout: 30_000 });
  await expect(page.locator('#splash')).toHaveCount(0);
}

export const nextFrames = (page: Page, count = 2) =>
  page.evaluate(
    (n) =>
      new Promise<void>((resolve) => {
        const step = (left: number) =>
          left === 0 ? resolve() : requestAnimationFrame(() => step(left - 1));
        step(n);
      }),
    count,
  );

export async function expectInsideViewport(page: Page, locator: Locator): Promise<void> {
  await expect(locator).toBeVisible();
  const box = await locator.boundingBox();
  const viewport = page.viewportSize()!;
  expect(box, 'bounding box').not.toBeNull();
  expect(box!.x).toBeGreaterThanOrEqual(0);
  expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width + 1);
}
