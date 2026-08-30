/**
 * quizQuestions 시드 — q0001 1건 생성.
 *
 *   npm install firebase-admin
 *   firebase login
 *   node scripts/init_quiz_questions_collection.mjs
 */
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = 'hamfins-719b8';

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const db = getFirestore();

/** @type {import('firebase-admin/firestore').DocumentData} */
const q0001 = {
  categoryId: 'allowance',
  difficulty: 1,
  type: 'ox',
  question: '예산은 돈을 쓰기 전에 수입과 지출 계획을 세운 것을 뜻한다. (1번째 사례)',
  options: ['O', 'X'],
  correctIndex: 0,
  explanation: '예산은 돈을 쓰기 전에 수입과 지출 계획을 세운 것이다.',
  isActive: true,
};

await db.collection('quizQuestions').doc('q0001').set(q0001, { merge: true });
console.log(`OK: ${projectId} / quizQuestions/q0001 생성 (또는 갱신)`);
