import type { BrowserContext, Page } from '@playwright/test';
import { boot, expect, test } from '../fixtures';

const oldWorkerUrl = '/flutter_service_worker.js?v=1819639077';

const oldIndex =
  '<!DOCTYPE html><html><head><title>portfolio</title></head>' +
  '<body><p id="old-site">2024 site</p></body></html>';

const oldWorker = `
'use strict';
const CACHE_NAME = 'flutter-app-cache';
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      cache.put('/', new Response(${JSON.stringify(oldIndex)}, {
        headers: { 'Content-Type': 'text/html' },
      })),
    ),
  );
});
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) =>
      cache.match(event.request).then((cached) => cached || fetch(event.request)),
    ),
  );
});
`;

const registrations = (page: Page) =>
  page.evaluate(async () =>
    (await navigator.serviceWorker.getRegistrations()).map((r) => r.scope),
  );

const cacheNames = (page: Page) => page.evaluate(() => caches.keys());

async function spyOnRegister(page: Page): Promise<void> {
  await page.addInitScript(() => {
    const calls: string[] = [];
    (window as unknown as { registerCalls: string[] }).registerCalls = calls;
    const register = navigator.serviceWorker.register.bind(navigator.serviceWorker);
    navigator.serviceWorker.register = (url, options) => {
      calls.push(String(url));
      return register(url, options);
    };
  });
}

const registerCalls = (page: Page) =>
  page.evaluate(() => (window as unknown as { registerCalls: string[] }).registerCalls);

async function primeWithOldWorker(context: BrowserContext, page: Page): Promise<void> {
  await context.route('**/flutter_service_worker.js*', (route) =>
    route.fulfill({ contentType: 'text/javascript', body: oldWorker }),
  );
  await page.goto('/robots.txt');
  await page.evaluate(async (url) => {
    await navigator.serviceWorker.register(url, { scope: '/' });
    await navigator.serviceWorker.ready;
  }, oldWorkerUrl);
  await expect.poll(() => cacheNames(page)).toEqual(['flutter-app-cache']);
  await context.unroute('**/flutter_service_worker.js*');
  await page.goto('/');
  await expect(page.locator('#old-site')).toBeAttached();
}

test('a first visit registers no service worker', async ({ page }) => {
  await spyOnRegister(page);
  await boot(page, '/');
  await page.reload();
  await boot(page, '/');
  expect(await registerCalls(page)).toEqual([]);
  expect(await registrations(page)).toEqual([]);
});

test('the 2024 service worker retires itself and the new site loads', async ({
  context,
  page,
}) => {
  await primeWithOldWorker(context, page);
  await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.getRegistration();
    await registration?.update();
  });
  await expect.poll(() => registrations(page), { timeout: 20_000 }).toEqual([]);
  await page.reload();
  await boot(page, '/');
  await expect(page.locator('#old-site')).toHaveCount(0);
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
  expect(await registrations(page)).toEqual([]);
  expect(await cacheNames(page)).toEqual([]);
});

test('a page loaded through the 2024 worker ends with no worker and no caches', async ({
  context,
  page,
}) => {
  await primeWithOldWorker(context, page);
  await page.evaluate(async () => (await caches.open('flutter-app-cache')).delete('/'));
  await spyOnRegister(page);
  await page.reload();
  await boot(page, '/');
  expect(await registerCalls(page)).toEqual([]);
  expect(await page.evaluate(() => navigator.serviceWorker.controller)).toBeNull();
  expect(await registrations(page)).toEqual([]);
  expect(await cacheNames(page)).toEqual([]);
  await expect(page.getByRole('heading', { level: 1, name: 'Lucas Schmidt' })).toBeVisible();
});

test('the worker script is served uncached and unregisters itself', async ({ request }) => {
  const response = await request.get(oldWorkerUrl);
  expect(response.status()).toBe(200);
  expect(response.headers()['cache-control']).toBe('no-cache');
  const body = await response.text();
  expect(body).toContain('skipWaiting()');
  expect(body).toContain('registration.unregister()');
  expect(body).not.toContain("addEventListener('fetch'");
});
