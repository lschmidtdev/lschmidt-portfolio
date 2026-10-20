import { defineConfig, devices } from '@playwright/test';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '../..');
const external = process.env.E2E_BASE_URL;

export default defineConfig({
  testDir: 'tests',
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 2,
  timeout: 60_000,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: external ?? 'http://127.0.0.1:5000',
    trace: 'retain-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: external
    ? undefined
    : {
        command:
          `node "${here}/hosting-config.mjs" && ` +
          `"${here}/node_modules/.bin/firebase" emulators:start ` +
          '--only hosting --project demo-lschmidt --config firebase.e2e.json',
        cwd: repo,
        url: 'http://127.0.0.1:5000/build-info.json',
        timeout: 120_000,
        reuseExistingServer: false,
      },
});
