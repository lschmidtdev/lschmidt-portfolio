import { readFileSync } from 'node:fs';
import { expect, test } from '../fixtures';

type Header = { key: string; value: string };
type Target = { target: string; headers: { headers: Header[] }[] };

const firebase = JSON.parse(
  readFileSync(new URL('../../../firebase.json', import.meta.url), 'utf8'),
) as { hosting: Target[] };
const site = firebase.hosting.find((t) => t.target === (process.env.E2E_TARGET ?? 'site'))!;
const headers = site.headers.flatMap((r) => r.headers);
const csp = headers.find((h) => h.key === 'Content-Security-Policy')!;

for (const path of ['/', '/pt', '/does-not-exist']) {
  test(`${path} carries the firebase.json headers`, async ({ request }) => {
    const served = (await request.get(path)).headers();
    expect(served['content-security-policy']).toBe(csp.value);
    expect(served).not.toHaveProperty('content-security-policy-report-only');
    expect(served['x-content-type-options']).toBe('nosniff');
    for (const name of ['Cache-Control', 'Referrer-Policy']) {
      const expected = headers.find((h) => h.key === name)!;
      expect(served[name.toLowerCase()]).toBe(expected.value);
    }
  });
}
