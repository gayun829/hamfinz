/**
 * 보험·세금·신용&대출의 계산 문제를 끄고 개념 문제 1,800개(카테고리마다 단계당 60)를 넣는다.
 * 2026-10-13 Firestore에 이미 반영했다. 다시 돌려도 같은 값이 들어간다.
 *
 * 계산 문제는 지우지 않고 isActive=false, inactiveReason='calculation-2026-10-13'만 붙인다.
 * 꺼진 문제 id는 backups/calculation_quiz_ids_2026-10-13.json에 있다.
 *
 *   node scripts/replace_calculation_quiz_questions.mjs --dry-run   # 개수만 출력
 *   node scripts/replace_calculation_quiz_questions.mjs             # 반영
 *   node scripts/replace_calculation_quiz_questions.mjs --restore   # 계산 문제를 다시 켜고 개념 문제를 끔
 *
 * 토큰은 firebase CLI 로그인(`firebase login`)에서 가져온다.
 */
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const projectId = 'hamfins-719b8';
const reason = 'calculation-2026-10-13';
const dryRun = process.argv.includes('--dry-run');
const restore = process.argv.includes('--restore');

const read = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url), 'utf8'));
const concepts = read('./data/concept_quiz_questions_2026-10-13.json');
const calcIds = read('./backups/calculation_quiz_ids_2026-10-13.json');

const docPath = `projects/${projectId}/databases/(default)/documents`;
const name = (id) => `${docPath}/quizQuestions/${id}`;
const str = (v) => ({ stringValue: v });
const int = (v) => ({ integerValue: String(v) });
const bool = (v) => ({ booleanValue: v });

const toggle = (id, active) => ({
  update: {
    name: name(id),
    fields: active ? { isActive: bool(true) } : { isActive: bool(false), inactiveReason: str(reason) },
  },
  updateMask: { fieldPaths: ['isActive', 'inactiveReason'] },
  currentDocument: { exists: true },
});

const writes = restore
  ? [...calcIds.map((id) => toggle(id, true)), ...concepts.map((q) => toggle(q.id, false))]
  : [
      ...calcIds.map((id) => toggle(id, false)),
      ...concepts.map((q) => ({
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
            isActive: bool(true),
          },
        },
      })),
    ];

console.log(`${restore ? '복원' : '반영'}: 계산 문제 ${calcIds.length}개, 개념 문제 ${concepts.length}개`);
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
