/**
 * Firestore quizQuestions 컬렉션 전체 삭제.
 *
 *   node scripts/delete_quiz_questions.mjs --dry-run
 *   node scripts/delete_quiz_questions.mjs
 */
import { execSync } from 'node:child_process';

const projectId = 'hamfins-719b8';
const collectionPath = 'quizQuestions';
const BATCH_SIZE = 400;

const dryRun = process.argv.includes('--dry-run');

function getAccessToken() {
  return execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
}

async function listAllDocNames(token) {
  const names = [];
  let pageToken = '';

  do {
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collectionPath}`,
    );
    url.searchParams.set('pageSize', '1000');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${token}`,
        'x-goog-user-project': projectId,
      },
    });

    if (!res.ok) {
      throw new Error(`list failed ${res.status}: ${(await res.text()).slice(0, 500)}`);
    }

    const data = await res.json();
    for (const doc of data.documents ?? []) {
      names.push(doc.name);
    }
    pageToken = data.nextPageToken ?? '';
  } while (pageToken);

  return names;
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
    throw new Error(`commit failed ${res.status}: ${(await res.text()).slice(0, 500)}`);
  }
}

async function deleteDocs(names, token) {
  let deleted = 0;

  for (let i = 0; i < names.length; i += BATCH_SIZE) {
    const chunk = names.slice(i, i + BATCH_SIZE);
    const writes = chunk.map((name) => ({
      delete: `${name}?currentDocument.exists=true`,
    }));

    await commitBatch(writes, token);
    deleted += chunk.length;
    console.log(`  deleted ${deleted}/${names.length}`);
  }
}

console.log(`quizQuestions delete — ${dryRun ? 'DRY RUN' : 'LIVE'}`);

const token = getAccessToken();
const names = await listAllDocNames(token);
console.log(`  found: ${names.length} documents`);

if (names.length === 0) {
  console.log('OK: nothing to delete');
  process.exit(0);
}

if (dryRun) {
  console.log('  sample ids:', names.slice(0, 5).map((n) => n.split('/').pop()));
  console.log('\nOK dry-run — no deletes');
  process.exit(0);
}

console.log('\nDeleting…');
await deleteDocs(names, token);
console.log(`\nOK: deleted ${names.length} documents from ${projectId}/quizQuestions`);
