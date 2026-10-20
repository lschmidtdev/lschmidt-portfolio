import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const name = process.env.E2E_TARGET ?? 'site';
const { hosting } = JSON.parse(readFileSync(resolve(repo, 'firebase.json'), 'utf8'));
const site = hosting.find((t) => t.target === name);
if (!site) throw new Error(`firebase.json has no hosting target "${name}"`);
const { target: _target, ...config } = site;
writeFileSync(resolve(repo, 'firebase.e2e.json'), JSON.stringify({ hosting: config }, null, 2));
