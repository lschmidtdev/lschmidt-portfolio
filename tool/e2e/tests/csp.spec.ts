import { boot, expect, test, umamiGateway } from '../fixtures';

const umamiSend = 'https://gateway.umami.is/api/send';

test.describe('enforced CSP with analytics on', () => {
  test.use({ umamiGatewayAllowed: true });

  test('the tracker can post to the Umami gateway', async ({ page, outbound }) => {
    await page.route(umamiGateway, (route) =>
      route.fulfill({
        contentType: 'application/json',
        headers: { 'access-control-allow-origin': '*', 'access-control-allow-headers': '*' },
        body: '{}',
      }),
    );
    await boot(page, '/');
    const status = await page.evaluate(
      async (url) =>
        (
          await fetch(url, {
            keepalive: true,
            method: 'POST',
            body: JSON.stringify({ type: 'event', payload: {} }),
            headers: { 'Content-Type': 'application/json' },
            credentials: 'omit',
          })
        ).status,
      umamiSend,
    );
    expect(status).toBe(200);
    expect(outbound.umamiGateway).toContain(umamiSend);
  });
});

test('the CanvasKit build boots under the enforced CSP', async ({ page }) => {
  await page.route('**/flutter_bootstrap.js', async (route) => {
    const response = await route.fetch();
    const body = (await response.text()).replaceAll(
      '_flutter.loader.load()',
      "_flutter.loader.load({ config: { renderer: 'canvaskit' } })",
    );
    await route.fulfill({ response, body });
  });
  const requested: string[] = [];
  page.on('request', (r) => requested.push(r.url()));
  await boot(page, '/');
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
  expect(requested.filter((u) => u.endsWith('/main.dart.js'))).toHaveLength(1);
  expect(requested.filter((u) => u.endsWith('/main.dart.wasm'))).toEqual([]);
  expect(
    requested.filter((u) =>
      /^https:\/\/www\.gstatic\.com\/flutter-canvaskit\/.*canvaskit\.wasm$/.test(u),
    ),
  ).toHaveLength(1);
});
