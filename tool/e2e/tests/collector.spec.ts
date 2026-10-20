import { expect, test } from '@playwright/test';
import { watchErrors } from '../fixtures';

for (const [header, disposition] of [
  ['Content-Security-Policy-Report-Only', 'report'],
  ['Content-Security-Policy', 'enforce'],
] as const) {
  test(`the collector records ${disposition} CSP violations`, async ({ page }) => {
    const errors = await watchErrors(page);
    await page.route('**/csp-probe', (route) =>
      route.fulfill({
        contentType: 'text/html',
        headers: { [header]: "script-src 'none'" },
        body: '<!doctype html><title>probe</title><script>1</script>',
      }),
    );
    await page.goto('/csp-probe');
    await expect
      .poll(() => errors.join('\n'))
      .toContain(`csp: ${disposition} script-src-elem inline`);
  });
}
