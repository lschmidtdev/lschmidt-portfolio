import { test as base, expect, type Page } from '@playwright/test';

export async function watchErrors(page: Page): Promise<string[]> {
  const errors: string[] = [];
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(`console: ${m.text()}`);
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

export const test = base.extend<{ allowedErrors: RegExp[]; errors: string[] }>({
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
