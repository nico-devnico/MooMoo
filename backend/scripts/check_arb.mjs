/**
 * Fails on duplicate keys or invalid JSON in the ARB files (JSON.parse keeps
 * the last duplicate silently, which overwrites an existing translation).
 * Usage: cd backend && node scripts/check_arb.mjs
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
let failed = false;

const sets = {};
for (const name of ['app_fr.arb', 'app_en.arb']) {
  const text = readFileSync(resolve(root, 'lib', 'l10n', name), 'utf8');
  JSON.parse(text);
  const keys = [...text.matchAll(/^ {2}"([^"]+)"\s*:/gm)].map((m) => m[1]);
  const seen = new Set();
  const dups = keys.filter((k) => (seen.has(k) ? true : (seen.add(k), false)));
  sets[name] = new Set(keys.filter((k) => !k.startsWith('@')));
  console.log(`${name}: ${sets[name].size} messages, duplicates: ${dups.join(', ') || 'none'}`);
  if (dups.length) failed = true;
}

const missing = [...sets['app_fr.arb']].filter((k) => !sets['app_en.arb'].has(k));
const extra = [...sets['app_en.arb']].filter((k) => !sets['app_fr.arb'].has(k));
console.log(`missing in en: ${missing.join(', ') || 'none'}`);
console.log(`missing in fr: ${extra.join(', ') || 'none'}`);
if (missing.length || extra.length) failed = true;

process.exit(failed ? 1 : 0);
