import { Router } from 'express';
import { randomUUID } from 'node:crypto';
import { dbForUser } from '../supabase.js';
import { requireRole } from '../lib/roles.js';
import {
  parseContent, suggestMapping, validateRecords, signPayload, slugify, TARGET_FIELDS, MAX_ROWS,
} from '../lib/dictionary_import.js';
import { fetchMedia } from '../lib/media_fetch.js';

export const dictionaryRouter = Router();

const MAX_CONTENT = 10 * 1024 * 1024;
const PAGE = 1000;

function badRequest(message, code = 'bad_request') {
  return Object.assign(new Error(message), { status: 400, code });
}

function readBody(body) {
  const filename = String(body?.filename || '').slice(0, 200);
  const content = typeof body?.content === 'string' ? body.content : '';
  if (!content.trim()) throw badRequest('Fichier vide', 'empty_file');
  if (content.length > MAX_CONTENT) throw badRequest('Fichier trop volumineux (10 Mo max.)', 'too_large');
  const mapping = {};
  if (body?.mapping && typeof body.mapping === 'object') {
    for (const target of TARGET_FIELDS) {
      const source = body.mapping[target];
      if (typeof source === 'string' && source) mapping[target] = source;
    }
  }
  const o = body?.options || {};
  const options = {
    defaultLanguageId: Number.isInteger(Number(o.defaultLanguageId)) && Number(o.defaultLanguageId) > 0
      ? Number(o.defaultLanguageId) : null,
    createCategories: o.createCategories === true,
    publish: o.publish === true,
    fetchMedia: o.fetchMedia === true,
    duplicates: o.duplicates === 'update' ? 'update' : 'skip',
  };
  return { filename, content, mapping: body?.mapping ? mapping : null, options };
}

async function selectAll(query) {
  const rows = [];
  for (let from = 0; ; from += PAGE) {
    const { data, error } = await query().range(from, from + PAGE - 1);
    if (error) throw Object.assign(new Error(error.message), { status: 502 });
    rows.push(...data);
    if (data.length < PAGE) return rows;
  }
}

async function loadContext(db) {
  const [languages, categories, existing] = await Promise.all([
    selectAll(() => db.from('sign_languages').select('id,code,name').order('id')),
    selectAll(() => db.from('sign_categories').select('id,name,slug,sign_language_id').order('id')),
    selectAll(() => db.from('signs').select('id,word,sign_language_id').order('id')),
  ]);
  return { languages, categories, existing };
}

async function analyse(req) {
  const { filename, content, mapping, options } = readBody(req.body);
  const parsed = parseContent(filename, content);
  if (!parsed.records.length) {
    throw badRequest('Aucun enregistrement détecté dans le fichier', 'no_records');
  }
  const usedMapping = mapping || suggestMapping(parsed.fields);
  const db = dbForUser(req.accessToken);
  const ctx = await loadContext(db);
  const result = validateRecords(parsed.records, usedMapping, { ...ctx, ...options });
  return { db, ctx, parsed, mapping: usedMapping, options, ...result };
}

dictionaryRouter.post('/import/preview', requireRole(), async (req, res, next) => {
  try {
    const a = await analyse(req);
    res.json({
      ok: true,
      format: a.parsed.format,
      delimiter: a.parsed.delimiter || null,
      fields: a.parsed.fields,
      suggested_mapping: suggestMapping(a.parsed.fields),
      mapping: a.mapping,
      target_fields: TARGET_FIELDS,
      max_rows: MAX_ROWS,
      sample: a.parsed.records.slice(0, 5),
      summary: a.summary,
      rows: a.rows,
    });
  } catch (e) {
    next(e);
  }
});

async function ensureCategories(db, rows, ctx) {
  const created = [];
  const bySlug = new Map(ctx.categories.map((c) => [c.slug, c]));
  const byKey = new Map();
  for (const row of rows) {
    const d = row.data;
    if (!d.category_created || d.category_id) continue;
    const key = `${d.sign_language_id}|${d.category_name.toLowerCase()}`;
    if (!byKey.has(key)) {
      const lang = ctx.languages.find((l) => l.id === d.sign_language_id);
      let slug = `${slugify(d.category_name)}-${slugify(lang?.code || d.sign_language_id)}`;
      for (let n = 2; bySlug.has(slug); n++) slug = `${slugify(d.category_name)}-${slugify(lang?.code)}-${n}`;
      const { data, error } = await db.from('sign_categories')
        .insert({ name: d.category_name, slug, sign_language_id: d.sign_language_id })
        .select('id,name,slug,sign_language_id').single();
      if (error) {
        byKey.set(key, { error: error.message });
      } else {
        bySlug.set(slug, data);
        byKey.set(key, data);
        created.push(data);
      }
    }
    const cat = byKey.get(key);
    if (cat.id) d.category_id = cat.id;
    else row.warnings.push(`Catégorie non créée (${cat.error}) : signe importé sans catégorie`);
  }
  return created;
}

async function importMedia(db, row, report) {
  const targets = [['video_url', 'video', 'sign-videos'], ['thumbnail_url', 'image', 'sign-thumbnails']];
  for (const [field, kind, bucket] of targets) {
    const url = row.data[field];
    if (!url) continue;
    try {
      const media = await fetchMedia(url, kind);
      const path = `imports/${new Date().toISOString().slice(0, 10)}/${randomUUID()}.${media.extension}`;
      const { error } = await db.storage.from(bucket).upload(path, media.buffer, {
        contentType: media.contentType, upsert: false,
      });
      if (error) throw new Error(`stockage : ${error.message}`);
      row.data[field] = db.storage.from(bucket).getPublicUrl(path).data.publicUrl;
      report.media_fetched++;
    } catch (e) {
      report.media_failed++;
      row.warnings.push(`${kind === 'video' ? 'Vidéo' : 'Vignette'} non rapatriée (${e.message}) : URL d'origine conservée`);
    }
  }
}

async function runPool(items, size, worker) {
  let next = 0;
  const lanes = Array.from({ length: Math.min(size, items.length) }, async () => {
    while (next < items.length) {
      const item = items[next++];
      await worker(item);
    }
  });
  await Promise.all(lanes);
}

dictionaryRouter.post('/import/commit', requireRole(), async (req, res, next) => {
  try {
    const a = await analyse(req);
    const { db, options } = a;
    const report = {
      imported: 0, updated: 0, skipped: 0, rejected: 0,
      media_fetched: 0, media_failed: 0, categories_created: [], rows: [],
    };
    const result = new Map();
    const toInsert = a.rows.filter((r) => r.status === 'valid');
    const toUpdate = options.duplicates === 'update' ? a.rows.filter((r) => r.status === 'duplicate') : [];

    for (const r of a.rows) {
      if (r.status === 'error') {
        report.rejected++;
        result.set(r.index, { result: 'rejected', message: r.errors.join(' ; ') });
      } else if (r.status === 'duplicate' && options.duplicates !== 'update') {
        report.skipped++;
        result.set(r.index, { result: 'skipped', message: 'Déjà présent dans le dictionnaire' });
      }
    }

    const active = [...toInsert, ...toUpdate];
    if (options.createCategories) {
      report.categories_created = await ensureCategories(db, active, a.ctx);
    }
    if (options.fetchMedia) {
      await runPool(active, 3, (row) => importMedia(db, row, report));
    }

    for (let i = 0; i < toInsert.length; i += 100) {
      const batch = toInsert.slice(i, i + 100);
      const payloads = batch.map((r) => signPayload(r.data, { publish: options.publish, forUpdate: false }));
      const { error } = await db.from('signs').insert(payloads);
      if (!error) {
        for (const r of batch) {
          report.imported++;
          result.set(r.index, { result: 'imported' });
        }
        continue;
      }
      // A failing batch is retried row by row so one bad line does not reject the others.
      for (const [j, r] of batch.entries()) {
        const { error: rowError } = await db.from('signs').insert(payloads[j]);
        if (rowError) {
          report.rejected++;
          result.set(r.index, { result: 'rejected', message: rowError.message });
        } else {
          report.imported++;
          result.set(r.index, { result: 'imported' });
        }
      }
    }

    for (const r of toUpdate) {
      const payload = signPayload(r.data, { publish: options.publish, forUpdate: true });
      delete payload.word;
      delete payload.sign_language_id;
      payload.updated_at = new Date().toISOString();
      const { data, error } = await db.from('signs').update(payload).eq('id', r.existing_id).select('id');
      if (error || !data?.length) {
        report.rejected++;
        result.set(r.index, { result: 'rejected', message: error?.message || 'Mise à jour refusée' });
      } else {
        report.updated++;
        result.set(r.index, { result: 'updated' });
      }
    }

    report.rows = a.rows.map((r) => ({
      index: r.index,
      word: r.data.word,
      language_code: r.data.language_code,
      ...result.get(r.index),
      warnings: r.warnings,
    }));
    report.total = a.summary.total;
    report.truncated = a.summary.truncated;
    res.json({ ok: true, report });
  } catch (e) {
    next(e);
  }
});
