// Unit tests of the dictionary import engine (no network, no database).
import assert from 'node:assert/strict';
import {
  parseContent, suggestMapping, validateRecords, signPayload, detectFormat,
} from '../src/lib/dictionary_import.js';
import { isPrivateAddress } from '../src/lib/media_fetch.js';

const ctx = {
  languages: [{ id: 1, code: 'LSF', name: 'Langue des Signes Française' }, { id: 2, code: 'ASL', name: 'American Sign Language' }],
  categories: [{ id: 10, name: 'Salutations', slug: 'salutations-lsf', sign_language_id: 1 }],
  existing: [{ id: 'e1', word: 'Merci', sign_language_id: 1 }],
};

let passed = 0;
function test(name, fn) {
  fn();
  passed++;
  console.log(`OK   ${name}`);
}

test('détection du format', () => {
  assert.equal(detectFormat('a.csv', ''), 'csv');
  assert.equal(detectFormat('x', '<root/>'), 'xml');
  assert.equal(detectFormat('x', '[{"a":1}]'), 'json');
  assert.equal(detectFormat('x', '{"a":1}\n{"a":2}'), 'ndjson');
});

test('CSV point-virgule, guillemets et accents', () => {
  const csv = 'Mot;Catégorie;Définition;Langue;Vidéo\n"Bonjour";Salutations;"Se dit ""le matin""";LSF;https://x.org/b.mp4\nMerci;;;lsf;\n';
  const p = parseContent('d.csv', csv);
  assert.equal(p.delimiter, ';');
  assert.equal(p.records.length, 2);
  assert.equal(p.records[0]['Définition'], 'Se dit "le matin"');
  const m = suggestMapping(p.fields);
  assert.deepEqual(m, { word: 'Mot', description: 'Définition', category: 'Catégorie', language: 'Langue', video_url: 'Vidéo' });
  const v = validateRecords(p.records, m, ctx);
  assert.equal(v.rows[0].status, 'valid');
  assert.equal(v.rows[0].data.category_id, 10);
  assert.equal(v.rows[1].status, 'duplicate');
  assert.equal(v.rows[1].existing_id, 'e1');
});

test('JSON imbriqué, tags et médias', () => {
  const json = JSON.stringify({ meta: { v: 1 }, signs: [
    { name: 'Hello', language: 'ASL', media: { video: 'https://x.org/h.mp4', image: 'https://x.org/h.jpg' }, tags: ['greeting', 'basic'] },
    { name: 'Bad', language: 'XYZ', media: { video: 'not a url' } },
  ] });
  const p = parseContent('d.json', json);
  assert.equal(p.records.length, 2);
  const m = suggestMapping(p.fields);
  assert.equal(m.word, 'name');
  assert.equal(m.video_url, 'media.video');
  assert.equal(m.thumbnail_url, 'media.image');
  const v = validateRecords(p.records, m, ctx);
  assert.equal(v.rows[0].status, 'valid');
  assert.deepEqual(v.rows[0].data.tags, ['greeting', 'basic']);
  assert.equal(v.rows[1].status, 'error');
  assert.ok(v.rows[1].errors.some((e) => e.includes('Langue inconnue')));
  assert.ok(v.rows[1].errors.some((e) => e.includes('URL vidéo invalide')));
});

test('XML avec attributs', () => {
  const xml = `<?xml version="1.0"?><dictionnaire><signe langue="LSF"><mot>Au revoir</mot><categorie>Salutations</categorie></signe><signe langue="LSF"><mot>Maison</mot><categorie>Lieux</categorie></signe></dictionnaire>`;
  const p = parseContent('d.xml', xml);
  assert.equal(p.records.length, 2);
  const m = suggestMapping(p.fields);
  assert.equal(m.word, 'mot');
  assert.equal(m.language, 'langue');
  const v1 = validateRecords(p.records, m, ctx);
  assert.equal(v1.rows[1].data.category_id, null);
  assert.ok(v1.rows[1].warnings.some((w) => w.includes('inconnue')));
  const v2 = validateRecords(p.records, m, { ...ctx, createCategories: true });
  assert.equal(v2.summary.categories_to_create.length, 1);
  assert.equal(v2.rows[1].data.category_created, true);
});

test('langue par défaut explicite, doublon interne, difficulté', () => {
  const p = parseContent('d.csv', 'word,difficulty\nA,2\na,1\nB,9\n');
  const m = suggestMapping(p.fields);
  const noLang = validateRecords(p.records, m, ctx);
  assert.ok(noLang.rows.every((r) => r.status === 'error'));
  const v = validateRecords(p.records, m, { ...ctx, defaultLanguageId: 2 });
  assert.equal(v.rows[0].status, 'valid');
  assert.equal(v.rows[0].data.difficulty_level, 2);
  assert.ok(v.rows[1].errors[0].startsWith('Doublon dans le fichier'));
  assert.ok(v.rows[2].errors[0].startsWith('Difficulté invalide'));
});

test('payload : jamais de valeur inventée ni d\'effacement', () => {
  const data = { word: 'X', description: null, tags: null, sign_language_id: 1, video_url: null, difficulty_level: null };
  assert.deepEqual(signPayload(data, { publish: false, forUpdate: false }), { word: 'X', sign_language_id: 1, is_validated: false });
  assert.deepEqual(signPayload(data, { publish: false, forUpdate: true }), { word: 'X', sign_language_id: 1 });
});

test('protection SSRF', () => {
  for (const ip of ['127.0.0.1', '10.1.2.3', '192.168.0.1', '172.20.0.1', '169.254.169.254', '::1', 'fd00::1', '::ffff:127.0.0.1']) {
    assert.equal(isPrivateAddress(ip), true, ip);
  }
  assert.equal(isPrivateAddress('93.184.216.34'), false);
});

console.log(`passed=${passed}`);
