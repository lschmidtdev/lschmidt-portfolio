import type { Page } from '@playwright/test';
import { boot, expect, test } from '../fixtures';

const headerControls: [string, RegExp][] = [
  ['brand', /^LS\s*Lucas Schmidt$/],
  ['Work', /^Work$/],
  ['Experience', /^Experience$/],
  ['Skills', /^Skills$/],
  ['Contact', /^Contact$/],
  ['English', /^English$/],
  ['Português', /^Português$/],
  ['theme', /^Toggle light or dark theme$/],
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
});
