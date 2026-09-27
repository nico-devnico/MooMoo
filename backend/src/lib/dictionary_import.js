// Dictionary import: format detection, parsing, field mapping and validation.
// Pure functions (no I/O) so they can be unit-tested; the route supplies the
// languages, categories and existing signs read from Supabase.
import { XMLParser } from 'fast-xml-parser';

export const MAX_ROWS = 2000;

/** Target fields of public.signs that an import may fill. */
export const TARGET_FIELDS = [
  'word', 'description', 'category', 'language', 'video_url',
  'thumbnail_url', 'tags', 'example_sentence', 'difficulty_level',
];

const SYNONYMS = {
  word: ['word', 'mot', 'sign', 'signe', 'name', 'nom', 'label', 'libelle', 'title', 'titre',
    'gloss', 'glose', 'term', 'terme', 'entry', 'entree', 'lemma', 'lemme'],
  description: ['description', 'desc', 'definition', 'meaning', 'sens', 'explication',
    'explanation', 'notes', 'note', 'details'],
  category: ['category', 'categorie', 'categories', 'theme', 'topic', 'groupe', 'group',
    'domain', 'domaine', 'rubrique', 'cat'],
  language: ['language', 'langue', 'lang', 'sign_language', 'langue_des_signes', 'code_langue',
    'language_code', 'locale'],
  video_url: ['video', 'video_url', 'videourl', 'url_video', 'lien_video', 'video_link',
    'media', 'media_url', 'mediaurl', 'url', 'lien', 'link', 'mp4', 'source', 'src', 'file'],
  thumbnail_url: ['thumbnail', 'thumbnail_url', 'thumb', 'image', 'image_url', 'img', 'picture',
    'poster', 'vignette', 'miniature', 'photo'],
  tags: ['tags', 'tag', 'keywords', 'mots_cles', 'motscles', 'labels', 'etiquettes'],
  example_sentence: ['example', 'exemple', 'example_sentence', 'phrase', 'phrase_exemple',
    'sentence', 'usage', 'contexte'],
  difficulty_level: ['difficulty', 'difficulty_level', 'difficulte', 'niveau', 'level'],
};

/** Lower-case, accent-free, non-alphanumerics collapsed to `_`. */
export function normalizeKey(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

export function normalizeText(value) {
  return normalizeKey(value).replace(/_/g, ' ');
}

export function slugify(value) {
  return normalizeKey(value).replace(/_/g, '-');
}

// ---------------------------------------------------------------------------
// Format detection and parsing
// ---------------------------------------------------------------------------
export function detectFormat(filename = '', content = '') {
  const ext = String(filename).toLowerCase().split('.').pop();
  if (['csv', 'tsv', 'json', 'xml', 'ndjson', 'jsonl'].includes(ext)) {
    return ext === 'jsonl' ? 'ndjson' : ext;
  }
  if (ext === 'txt') return 'csv';
  const head = content.trimStart().slice(0, 200);
  if (head.startsWith('<')) return 'xml';
  if (head.startsWith('[') || head.startsWith('{')) {
    const lines = content.trim().split(/\r?\n/);
    if (lines.length > 1 && lines.every((l) => !l.trim() || /^\s*\{.*\}\s*$/.test(l))) return 'ndjson';
    return 'json';
  }
  return 'csv';
}

function detectDelimiter(text) {
  const firstLine = text.split(/\r?\n/).find((l) => l.trim()) || '';
  const candidates = [',', ';', '\t', '|'];
  let best = ',';
  let bestCount = 0;
  for (const d of candidates) {
    let count = 0;
    let quoted = false;
    for (const ch of firstLine) {
      if (ch === '"') quoted = !quoted;
      else if (ch === d && !quoted) count++;
    }
    if (count > bestCount) { best = d; bestCount = count; }
  }
  return best;
}

/** RFC 4180 CSV (quoted fields, doubled quotes, embedded newlines). */
export function parseCsv(text, delimiter = detectDelimiter(text)) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  const src = text.replace(/^\uFEFF/, '');
  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    if (quoted) {
      if (ch === '"') {
        if (src[i + 1] === '"') { field += '"'; i++; } else quoted = false;
      } else field += ch;
    } else if (ch === '"' && field === '') {
      quoted = true;
    } else if (ch === delimiter) {
      row.push(field); field = '';
    } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && src[i + 1] === '\n') i++;
      row.push(field); field = '';
      if (row.some((v) => v.trim() !== '')) rows.push(row);
      row = [];
    } else field += ch;
  }
  row.push(field);
  if (row.some((v) => v.trim() !== '')) rows.push(row);
  if (!rows.length) return { fields: [], records: [], delimiter };

  const header = rows[0].map((h, i) => h.trim() || `colonne_${i + 1}`);
  const records = rows.slice(1).map((values) => {
    const record = {};
    header.forEach((h, i) => { record[h] = (values[i] ?? '').trim(); });
    return record;
  });
  return { fields: header, records, delimiter };
}

function flatten(value, prefix = '', out = {}) {
  if (value === null || value === undefined) return out;
  if (Array.isArray(value)) {
    if (value.every((v) => v === null || typeof v !== 'object')) {
      out[prefix] = value.filter((v) => v !== null && v !== '').map(String);
    } else if (value.length && typeof value[0] === 'object') {
      flatten(value[0], prefix, out);
    }
    return out;
  }
  if (typeof value === 'object') {
    for (const [k, v] of Object.entries(value)) {
      const key = k === '#text' ? prefix || 'text' : prefix ? `${prefix}.${k}` : k;
      flatten(v, key, out);
    }
    return out;
  }
  out[prefix || 'value'] = typeof value === 'string' ? value.trim() : value;
  return out;
}

const COLLECTION_HINTS = ['signs', 'signes', 'sign', 'signe', 'items', 'item', 'entries', 'entry',
  'records', 'record', 'data', 'words', 'mots', 'dictionary', 'dictionnaire', 'rows', 'row'];

/** Largest array of objects in the tree, preferring well-known collection names. */
function findCollection(node, depth = 0) {
  if (depth > 6 || node === null || typeof node !== 'object') return null;
  if (Array.isArray(node)) {
    return node.some((v) => v && typeof v === 'object' && !Array.isArray(v)) ? { items: node, score: node.length } : null;
  }
  let best = null;
  for (const [key, value] of Object.entries(node)) {
    let found = findCollection(value, depth + 1);
    if (!found && value && typeof value === 'object' && !Array.isArray(value)
        && COLLECTION_HINTS.includes(normalizeKey(key))) {
      found = { items: [value], score: 1 };
    }
    if (found) {
      const bonus = COLLECTION_HINTS.includes(normalizeKey(key)) ? 0.5 : 0;
      const score = found.score + bonus;
      if (!best || score > best.score) best = { items: found.items, score };
    }
  }
  return best;
}

function recordsFromTree(tree) {
  const collection = Array.isArray(tree) ? { items: tree } : findCollection(tree);
  if (!collection) return [];
  return collection.items
    .filter((v) => v && typeof v === 'object')
    .map((item) => flatten(item));
}

function fieldsOf(records) {
  const seen = new Set();
  for (const r of records.slice(0, 500)) for (const k of Object.keys(r)) seen.add(k);
  return [...seen];
}

/** Parses any supported format into flat records. Throws a 400 on malformed input. */
export function parseContent(filename, content) {
  const format = detectFormat(filename, content);
  let records;
  let fields;
  let delimiter;
  try {
    if (format === 'csv' || format === 'tsv') {
      const parsed = parseCsv(content, format === 'tsv' ? '\t' : undefined);
      ({ records, fields, delimiter } = parsed);
    } else if (format === 'json') {
      records = recordsFromTree(JSON.parse(content));
    } else if (format === 'ndjson') {
      records = content.split(/\r?\n/).filter((l) => l.trim()).map((l) => flatten(JSON.parse(l)));
    } else if (format === 'xml') {
      const parser = new XMLParser({
        ignoreAttributes: false,
        attributeNamePrefix: '',
        parseTagValue: false,
        trimValues: true,
      });
      records = recordsFromTree(parser.parse(content));
    }
  } catch (e) {
    // The parser's own message stays out of the user-facing text.
    const err = new Error(`Fichier ${format.toUpperCase()} illisible : vérifiez qu'il est bien formé.`);
    err.status = 400;
    err.code = 'parse_error';
    err.expose = true;
    err.details = e.message;
    throw err;
  }
  fields = fields || fieldsOf(records);
  return { format, delimiter, fields, records };
}

/** Suggests a source field for each target field; never maps one source twice. */
export function suggestMapping(fields) {
  const mapping = {};
  const used = new Set();
  const byNorm = fields.map((f) => ({ field: f, norm: normalizeKey(f), last: normalizeKey(String(f).split('.').pop()) }));
  for (const target of TARGET_FIELDS) {
    const synonyms = SYNONYMS[target];
    let match = null;
    for (const syn of synonyms) {
      match = byNorm.find((f) => !used.has(f.field) && (f.norm === syn || f.last === syn));
      if (match) break;
    }
    if (!match) {
      match = byNorm.find((f) => !used.has(f.field) && synonyms.some((s) => s.length > 3 && f.norm.includes(s)));
    }
    if (match) { mapping[target] = match.field; used.add(match.field); }
  }
  return mapping;
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------
function asString(value) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.join(', ').trim() || null;
  const s = String(value).trim();
  return s === '' ? null : s;
}

function isHttpUrl(value) {
  try {
    const u = new URL(value);
    return u.protocol === 'http:' || u.protocol === 'https:';
  } catch {
    return false;
  }
}

function parseTags(value) {
  if (value === null || value === undefined) return null;
  const list = Array.isArray(value) ? value : String(value).split(/[,;|]/);
  const tags = [...new Set(list.map((t) => String(t).trim()).filter(Boolean))];
  return tags.length ? tags : null;
}

/**
 * @param records flat records from parseContent
 * @param mapping { target: sourceField }
 * @param ctx { languages:[{id,code,name}], categories:[{id,name,slug,sign_language_id}],
 *              existing:[{id,word,sign_language_id}], defaultLanguageId?, createCategories? }
 */
export function validateRecords(records, mapping, ctx) {
  const languages = ctx.languages || [];
  const langById = new Map(languages.map((l) => [l.id, l]));
  const langIndex = new Map();
  for (const l of languages) {
    langIndex.set(normalizeText(l.code), l);
    langIndex.set(normalizeText(l.name), l);
  }
  const catIndex = new Map();
  for (const c of ctx.categories || []) {
    for (const key of [normalizeText(c.name), normalizeText(c.slug)]) {
      catIndex.set(`${c.sign_language_id}|${key}`, c);
    }
  }
  const existing = new Map();
  for (const s of ctx.existing || []) existing.set(`${s.sign_language_id}|${normalizeText(s.word)}`, s.id);

  const defaultLanguage = ctx.defaultLanguageId ? langById.get(Number(ctx.defaultLanguageId)) : null;
  const pick = (record, target) => (mapping[target] ? record[mapping[target]] : undefined);
  const seen = new Map();
  const newCategories = new Map();

  const rows = records.slice(0, MAX_ROWS).map((record, index) => {
    const errors = [];
    const warnings = [];

    const word = asString(pick(record, 'word'));
    if (!word) errors.push('Nom du signe manquant');
    else if (word.length > 120) errors.push('Nom du signe trop long (120 caractères max.)');

    let language = null;
    const rawLanguage = asString(pick(record, 'language'));
    if (rawLanguage) {
      language = langIndex.get(normalizeText(rawLanguage)) || null;
      if (!language) errors.push(`Langue inconnue : « ${rawLanguage} »`);
    } else if (defaultLanguage) {
      language = defaultLanguage;
    } else {
      errors.push('Langue manquante (aucune colonne langue ni langue par défaut choisie)');
    }

    let category = null;
    let categoryName = asString(pick(record, 'category'));
    if (categoryName && language) {
      const key = `${language.id}|${normalizeText(categoryName)}`;
      const found = catIndex.get(key);
      if (found) {
        category = { id: found.id, name: found.name, created: false };
      } else if (ctx.createCategories) {
        category = { id: null, name: categoryName, created: true };
        newCategories.set(key, { name: categoryName, sign_language_id: language.id });
        warnings.push(`Catégorie « ${categoryName} » à créer`);
      } else {
        warnings.push(`Catégorie « ${categoryName} » inconnue : signe importé sans catégorie`);
        categoryName = null;
      }
    }

    const media = {};
    for (const field of ['video_url', 'thumbnail_url']) {
      const value = asString(pick(record, field));
      if (!value) continue;
      if (isHttpUrl(value)) media[field] = value;
      else errors.push(`${field === 'video_url' ? 'URL vidéo' : 'URL vignette'} invalide : « ${value.slice(0, 80)} »`);
    }
    if (!media.video_url) warnings.push('Aucune vidéo : le signe sera sans média');

    let difficulty = null;
    const rawDifficulty = asString(pick(record, 'difficulty_level'));
    if (rawDifficulty) {
      const n = Number(rawDifficulty);
      if (Number.isInteger(n) && n >= 1 && n <= 3) difficulty = n;
      else errors.push(`Difficulté invalide : « ${rawDifficulty} » (entier de 1 à 3)`);
    }

    const description = asString(pick(record, 'description'));
    if (description && description.length > 2000) errors.push('Description trop longue (2000 caractères max.)');

    const data = {
      word,
      description,
      example_sentence: asString(pick(record, 'example_sentence')),
      tags: parseTags(pick(record, 'tags')),
      difficulty_level: difficulty,
      sign_language_id: language?.id ?? null,
      language_code: language?.code ?? null,
      category_id: category?.id ?? null,
      category_name: category?.name ?? null,
      category_created: category?.created ?? false,
      video_url: media.video_url ?? null,
      thumbnail_url: media.thumbnail_url ?? null,
    };

    let status = errors.length ? 'error' : 'valid';
    let existingId = null;
    if (word && language) {
      const key = `${language.id}|${normalizeText(word)}`;
      if (seen.has(key)) {
        errors.push(`Doublon dans le fichier (ligne ${seen.get(key) + 1})`);
        status = 'error';
      } else {
        seen.set(key, index);
        if (existing.has(key)) {
          existingId = existing.get(key);
          if (status === 'valid') status = 'duplicate';
        }
      }
    }
    return { index, status, errors, warnings, data, existing_id: existingId };
  });

  const summary = {
    total: records.length,
    analysed: rows.length,
    truncated: records.length > MAX_ROWS,
    valid: rows.filter((r) => r.status === 'valid').length,
    duplicates: rows.filter((r) => r.status === 'duplicate').length,
    errors: rows.filter((r) => r.status === 'error').length,
    categories_to_create: [...newCategories.values()],
  };
  return { rows, summary };
}

/**
 * Columns written for a row. On update, only non-empty values are sent so an
 * import never blanks out data already in the dictionary.
 */
export function signPayload(data, { publish, forUpdate }) {
  const payload = {
    word: data.word,
    description: data.description,
    example_sentence: data.example_sentence,
    tags: data.tags,
    difficulty_level: data.difficulty_level,
    sign_language_id: data.sign_language_id,
    category_id: data.category_id,
    video_url: data.video_url,
    thumbnail_url: data.thumbnail_url,
  };
  for (const [k, v] of Object.entries(payload)) if (v === null || v === undefined) delete payload[k];
  if (!forUpdate) payload.is_validated = Boolean(publish);
  else if (publish) payload.is_validated = true;
  return payload;
}
