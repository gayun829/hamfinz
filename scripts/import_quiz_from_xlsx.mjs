/**
 * .local/quiz_data/*.xlsx → Firestore quizQuestions 일괄 업로드
 *
 *   npm install xlsx
 *   gcloud auth login   (또는 ADC)
 *
 *   node scripts/import_quiz_from_xlsx.mjs --dry-run
 *   node scripts/import_quiz_from_xlsx.mjs
 *   node scripts/import_quiz_from_xlsx.mjs --file allowance_expense_quiz_2000.xlsx
 *   node scripts/import_quiz_from_xlsx.mjs --limit 10
 *
 * xlsx isActive가 전부 false여도 기본값은 true (--respect-xlsx 로 xlsx 값 유지).
 * insurance/stock/tax의 q0001 충돌 id는 {categoryId}_0001 형식으로 정규화.
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { execSync } from 'node:child_process';
import XLSX from 'xlsx';

const projectId = 'hamfins-719b8';
const quizDataDir = resolve('.local/quiz_data');
const BATCH_SIZE = 400;

const FILE_CATEGORY = {
  'allowance_expense_quiz_2000.xlsx': 'allowance',
  'saving_deposit_quiz_2000.xlsx': 'saving',
  'stock_quiz_2000.xlsx': 'stock',
  'insurance_quiz_2000.xlsx': 'insurance',
  'tax_quiz_2000.xlsx': 'tax',
  'credit_loan_quiz_2000.xlsx': 'credit',
};

const VALID_CATEGORIES = new Set(Object.values(FILE_CATEGORY));
const VALID_TYPES = new Set(['ox', 'multipleChoice']);

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const respectXlsx = args.includes('--respect-xlsx');
const fileArg = args.find((a, i) => args[i - 1] === '--file');
const limitArg = args.find((a, i) => args[i - 1] === '--limit');
const limit = limitArg ? Number(limitArg) : Infinity;

function getAccessToken() {
  return execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
}

function normalizeQuestionId(row, categoryId, index) {
  const raw = String(row.questionId ?? '').trim();
  const prefix = `${categoryId}_`;
  if (raw.startsWith(prefix)) return raw;
  return `${prefix}${String(index + 1).padStart(4, '0')}`;
}

function parseOptions(value, type) {
  if (Array.isArray(value)) return value.map(String);
  const text = String(value ?? '').trim();
  if (!text) throw new Error('options empty');

  if (text.startsWith('[')) {
    const parsed = JSON.parse(text);
    if (!Array.isArray(parsed)) throw new Error('options JSON must be array');
    return parsed.map(String);
  }

  if (text.includes('|')) return text.split('|').map((s) => s.trim()).filter(Boolean);

  if (type === 'ox') return ['O', 'X'];
  throw new Error(`cannot parse options: ${text.slice(0, 80)}`);
}

function parseBool(value, defaultValue) {
  if (value === '' || value === undefined || value === null) return defaultValue;
  if (typeof value === 'boolean') return value;
  const s = String(value).trim().toLowerCase();
  if (s === 'true' || s === '1') return true;
  if (s === 'false' || s === '0') return false;
  return defaultValue;
}

function toFirestoreFields(doc) {
  return {
    categoryId: { stringValue: doc.categoryId },
    difficulty: { integerValue: String(doc.difficulty) },
    type: { stringValue: doc.type },
    question: { stringValue: doc.question },
    options: {
      arrayValue: {
        values: doc.options.map((o) => ({ stringValue: o })),
      },
    },
    correctIndex: { integerValue: String(doc.correctIndex) },
    explanation: { stringValue: doc.explanation },
    isActive: { booleanValue: doc.isActive },
  };
}

function validateRow(doc, sourceFile, rowNum) {
  const ctx = `${sourceFile} row ${rowNum} (${doc.questionId})`;
  if (!VALID_CATEGORIES.has(doc.categoryId)) throw new Error(`${ctx}: invalid categoryId`);
  if (!VALID_TYPES.has(doc.type)) throw new Error(`${ctx}: invalid type`);
  if (!Number.isInteger(doc.difficulty) || doc.difficulty < 1 || doc.difficulty > 10) {
    throw new Error(`${ctx}: difficulty must be 1-10`);
  }
  if (!doc.question) throw new Error(`${ctx}: question empty`);
  if (!doc.explanation) throw new Error(`${ctx}: explanation empty`);
  if (doc.type === 'ox' && doc.options.length !== 2) {
    throw new Error(`${ctx}: ox must have 2 options`);
  }
  if (doc.type === 'multipleChoice' && doc.options.length !== 4) {
    throw new Error(`${ctx}: multipleChoice must have 4 options`);
  }
  if (!Number.isInteger(doc.correctIndex) || doc.correctIndex < 0 || doc.correctIndex >= doc.options.length) {
    throw new Error(`${ctx}: correctIndex out of range`);
  }
}

function loadQuestions() {
  if (!existsSync(quizDataDir)) throw new Error(`missing directory: ${quizDataDir}`);

  const files = fileArg
    ? [fileArg]
    : readdirSync(quizDataDir).filter((f) => f.endsWith('.xlsx')).sort();

  const docs = [];

  for (const file of files) {
    const categoryId = FILE_CATEGORY[file];
    if (!categoryId) throw new Error(`unknown xlsx file: ${file} (add to FILE_CATEGORY)`);

    const path = join(quizDataDir, file);
    const wb = XLSX.readFile(path);
    const sheetName = wb.SheetNames[0];
    const rows = XLSX.utils.sheet_to_json(wb.Sheets[sheetName], { defval: '' });

    rows.forEach((row, index) => {
      const questionId = normalizeQuestionId(row, categoryId, index);
      const type = String(row.type ?? '').trim();
      const options = parseOptions(row.options, type);
      const doc = {
        questionId,
        categoryId: String(row.categoryId ?? categoryId).trim(),
        difficulty: Number(row.difficulty),
        type,
        question: String(row.question ?? '').trim(),
        options,
        correctIndex: Number(row.correctIndex),
        explanation: String(row.explanation ?? '').trim(),
        isActive: respectXlsx ? parseBool(row.isActive, false) : true,
      };
      validateRow(doc, file, index + 2);
      docs.push(doc);
    });

    console.log(`  ${file}: ${rows.length} rows → category ${categoryId}`);
  }

  const ids = new Set();
  for (const d of docs) {
    if (ids.has(d.questionId)) throw new Error(`duplicate questionId: ${d.questionId}`);
    ids.add(d.questionId);
  }

  return docs.slice(0, limit);
}

async function commitBatch(writes, token) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'x-goog-user-project': projectId,
      },
      body: JSON.stringify({ writes }),
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`commit failed ${res.status}: ${body.slice(0, 500)}`);
  }
}

async function uploadQuestions(docs) {
  const token = getAccessToken();
  let uploaded = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const writes = chunk.map((doc) => ({
      update: {
        name: `projects/${projectId}/databases/(default)/documents/quizQuestions/${doc.questionId}`,
        fields: toFirestoreFields(doc),
      },
    }));

    await commitBatch(writes, token);
    uploaded += chunk.length;
    console.log(`  uploaded ${uploaded}/${docs.length}`);
  }
}

console.log(`quizQuestions import — ${dryRun ? 'DRY RUN' : 'LIVE'}`);
console.log(`  source: ${quizDataDir}`);
console.log(`  isActive: ${respectXlsx ? 'from xlsx' : 'true (default)'}`);

const docs = loadQuestions();
console.log(`  total: ${docs.length} questions`);

const byCategory = Object.fromEntries([...VALID_CATEGORIES].map((c) => [c, 0]));
for (const d of docs) byCategory[d.categoryId]++;
console.log('  by category:', byCategory);

if (dryRun) {
  console.log('\nSample (first 2):');
  console.log(JSON.stringify(docs.slice(0, 2), null, 2));
  console.log('\nOK dry-run — no writes');
  process.exit(0);
}

console.log('\nUploading…');
await uploadQuestions(docs);
console.log(`\nOK: ${docs.length} documents → ${projectId}/quizQuestions`);
