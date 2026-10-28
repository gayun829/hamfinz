/**
 * 보험·세금·신용&대출을 카테고리당 2,000문제(난이도별 200, 모두 활성)로 맞춘다.
 * 2026-10-13 Firestore에 이미 반영했다. 다시 돌려도 같은 값이 들어간다.
 *
 * - {cat}_0001~2000 문서를 data 파일 내용으로 통째로 덮어쓴다 (계산 문제·중복 문제 자리를 개념 문제로 채움).
 * - 앞서 따로 넣었던 {cat}_concept_0001~0600 문서는 지운다.
 * 반영 직전 상태는 로컬 백업 backups/quizQuestions-2026-10-13-before-2000.json 에 있다.
 *
 *   node scripts/sync_quiz_questions_2000.mjs --dry-run   # 개수만 출력
 *   node scripts/sync_quiz_questions_2000.mjs             # 반영
 *
 * 토큰은 firebase CLI 로그인(`firebase login`)에서 가져온다.
 */
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const projectId = 'hamfins-719b8';
const dryRun = process.argv.includes('--dry-run');

const questions = JSON.parse(
  readFileSync(new URL('./data/quiz_questions_insurance_tax_credit_2026-10-13.json', import.meta.url), 'utf8'),
);

const docPath = `projects/${projectId}/databases/(default)/documents`;
const name = (id) => `${docPath}/quizQuestions/${id}`;
const str = (v) => ({ stringValue: v });
const int = (v) => ({ integerValue: String(v) });

const conceptIds = ['insurance', 'tax', 'credit'].flatMap((cat) =>
  Array.from({ length: 600 }, (_, i) => `${cat}_concept_${String(i + 1).padStart(4, '0')}`),
);

const writes = [
  ...questions.map((q) => ({
    update: {
      name: name(q.id),
      fields: {
        categoryId: str(q.categoryId),
        difficulty: int(q.difficulty),
        type: str(q.type),
        question: str(q.question),
        options: { arrayValue: { values: q.options.map(str) } },
        correctIndex: int(q.correctIndex),
        explanation: str(q.explanation),
        isActive: { booleanValue: true },
      },
    },
  })),
  ...conceptIds.map((id) => ({ delete: name(id) })),
];

console.log(`덮어쓰기 ${questions.length}개, 삭제 ${conceptIds.length}개`);
if (dryRun) process.exit(0);

const config = JSON.parse(readFileSync(join(homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
const token = config.tokens?.access_token;
if (!token) throw new Error('firebase login 먼저 (firebase projects:list 한 번 돌리면 토큰이 갱신된다)');

// commit 한 번에 500개까지라 나눠 보낸다.
for (let i = 0; i < writes.length; i += 400) {
  const res = await fetch(`https://firestore.googleapis.com/v1/${docPath}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes: writes.slice(i, i + 400) }),
  });
  if (!res.ok) throw new Error(`commit failed ${res.status}: ${(await res.text()).slice(0, 500)}`);
}
console.log('OK');
