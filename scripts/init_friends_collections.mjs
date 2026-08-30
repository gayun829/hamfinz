/**
 * 친구 기능 컬렉션 로컬 시드 — nicknames/emails/friendships 예시 1건씩 생성.
 *
 * quizQuestions와 달리 이 컬렉션들은 앱이 런타임에 실제 유저 uid로 채운다.
 * 이 스크립트는 로컬 개발/QA에서 검색·요청 UI를 빠르게 확인하기 위한 용도이며,
 * 아래 uid는 실제 Firebase Auth 계정 uid로 바꿔서 써야 로그인 후 테스트가 된다.
 *
 *   npm install firebase-admin
 *   firebase login
 *   node scripts/init_friends_collections.mjs
 */
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const projectId = 'hamfins-719b8';

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const db = getFirestore();

// 실제 테스트 계정 uid로 바꿔서 사용한다.
const uidA = 'uid_example_1';
const uidB = 'uid_example_2';
const nicknameA = '김기니니';

await db.collection('nicknames').doc(nicknameA).set(
  { uid: uidA, nickname: nicknameA },
  { merge: true },
);

await db.collection('emails').doc('gini@example.com').set(
  { uid: uidA, nickname: nicknameA },
  { merge: true },
);

const friendshipId = [uidA, uidB].sort().join('_');
await db.collection('friendships').doc(friendshipId).set(
  {
    uids: [uidA, uidB],
    requestedBy: uidA,
    requestedByNickname: nicknameA,
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  },
  { merge: true },
);

console.log(`OK: ${projectId} / nicknames, emails, friendships 예시 생성 (또는 갱신)`);
