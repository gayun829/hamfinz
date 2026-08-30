/**
 * Quiz session — submitAnswer · completeSession (서버 채점 · 기록)
 *
 * deploy: firebase deploy --only functions
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

const db = getFirestore();

const ENERGY_PER_QUESTION = 5;
const XP_CORRECT = 10;
const XP_WRONG = 2;
const SEEDS_PER_CORRECT = 5;
const MAX_ENERGY = 100;
const XP_PER_LEVEL = 100;
const MAX_LEVEL = 10;

const CATEGORY_LABELS = {
  allowance: '용돈 관리',
  saving: '저축',
  stock: '주식 기초',
  insurance: '보험',
  tax: '세금',
  credit: '신용',
};

function todayKey() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

function yesterdayKey() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(d);
}

function levelFromXp(xp) {
  return Math.min(MAX_LEVEL, Math.floor(xp / XP_PER_LEVEL) + 1);
}

function computeUnlocks(userData, streak, xp) {
  const unlocked = new Set(userData.unlockedHamsterIds || ['hamster_basic']);
  const newly = [];

  function unlock(id) {
    if (!unlocked.has(id)) {
      unlocked.add(id);
      newly.push(id);
    }
  }

  const history = userData.learningHistory || [];
  if (history.length > 0) unlock('hamster_study');
  if (streak >= 3) unlock('hamster_streak');
  const level = levelFromXp(xp);
  if (level >= 3) unlock('hamster_level3');
  if (level >= 5) unlock('hamster_level5');
  if (level >= 10) unlock('hamster_master');

  return { all: [...unlocked], newly };
}

exports.submitAnswer = onCall({ region: 'asia-northeast3' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  }

  const { sessionId, questionId, selectedIndex } = request.data ?? {};
  if (!sessionId || !questionId || selectedIndex === undefined) {
    throw new HttpsError('invalid-argument', 'sessionId, questionId, selectedIndex가 필요해요.');
  }

  const selected = Number(selectedIndex);
  if (!Number.isInteger(selected) || selected < 0) {
    throw new HttpsError('invalid-argument', 'selectedIndex가 올바르지 않아요.');
  }

  const userRef = db.collection('users').doc(uid);
  const sessionRef = userRef.collection('sessions').doc(sessionId);
  const answerRef = sessionRef.collection('answers').doc(questionId);
  const questionRef = db.collection('quizQuestions').doc(questionId);

  return db.runTransaction(async (tx) => {
    const [userSnap, sessionSnap, answerSnap, questionSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(sessionRef),
      tx.get(answerRef),
      tx.get(questionRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError('not-found', '유저 프로필을 찾을 수 없어요.');
    }
    if (!sessionSnap.exists) {
      throw new HttpsError('not-found', '세션을 찾을 수 없어요.');
    }
    if (!questionSnap.exists) {
      throw new HttpsError('not-found', '문제를 찾을 수 없어요.');
    }

    const session = sessionSnap.data();
    if (session.status !== 'inProgress') {
      throw new HttpsError('failed-precondition', '이미 종료된 세션이에요.');
    }

    const questionIds = session.questionIds || [];
    if (!questionIds.includes(questionId)) {
      throw new HttpsError('invalid-argument', '이 세션의 문제가 아니에요.');
    }

    if (answerSnap.exists) {
      throw new HttpsError('already-exists', '이미 제출한 문제예요.');
    }

    const user = userSnap.data();
    let energy = user.energy ?? MAX_ENERGY;
    if (energy < ENERGY_PER_QUESTION) {
      throw new HttpsError('failed-precondition', '에너지가 부족해요.');
    }

    const q = questionSnap.data();
    if (q.isActive !== true) {
      throw new HttpsError('failed-precondition', '출제되지 않은 문제예요.');
    }

    const options = q.options || [];
    if (selected >= options.length) {
      throw new HttpsError('invalid-argument', '보기 번호가 올바르지 않아요.');
    }

    const correctIndex = Number(q.correctIndex ?? 0);
    const isCorrect = selected === correctIndex;
    energy = Math.max(0, energy - ENERGY_PER_QUESTION);

    tx.update(userRef, { energy });

    tx.set(answerRef, {
      selectedIndex: selected,
      isCorrect,
      categoryId: q.categoryId || 'allowance',
      energySpent: ENERGY_PER_QUESTION,
      answeredAt: FieldValue.serverTimestamp(),
    });

    if (isCorrect) {
      tx.set(
        userRef.collection('mastered').doc(questionId),
        { answeredAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }

    const sessionUpdate = {
      energySpent: (session.energySpent ?? 0) + ENERGY_PER_QUESTION,
    };
    if (isCorrect) {
      sessionUpdate.correctCount = (session.correctCount ?? 0) + 1;
    }
    tx.update(sessionRef, sessionUpdate);

    return { isCorrect, correctIndex, energyRemaining: energy };
  });
});

exports.completeSession = onCall({ region: 'asia-northeast3' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  }

  const { sessionId } = request.data ?? {};
  if (!sessionId) {
    throw new HttpsError('invalid-argument', 'sessionId가 필요해요.');
  }

  const userRef = db.collection('users').doc(uid);
  const sessionRef = userRef.collection('sessions').doc(sessionId);

  return db.runTransaction(async (tx) => {
    const sessionSnap = await tx.get(sessionRef);
    if (!sessionSnap.exists) {
      throw new HttpsError('not-found', '세션을 찾을 수 없어요.');
    }

    const session = sessionSnap.data();
    if (session.status !== 'inProgress') {
      throw new HttpsError('failed-precondition', '이미 완료된 세션이에요.');
    }

    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError('not-found', '유저 프로필을 찾을 수 없어요.');
    }

    const answersSnap = await tx.get(sessionRef.collection('answers'));
    const answers = answersSnap.docs.map((d) => ({
      questionId: d.id,
      ...d.data(),
    }));

    const expectedCount = session.questionCount ?? (session.questionIds || []).length;
    if (answers.length < expectedCount) {
      throw new HttpsError(
        'failed-precondition',
        `아직 풀지 않은 문제가 있어요. (${answers.length}/${expectedCount})`,
      );
    }

    const user = userSnap.data();
    const previousXp = user.xp ?? 0;
    const previousLevel = levelFromXp(previousXp);

    let xpEarned = 0;
    let correctCount = 0;
    const categoryStats = { ...(user.categoryStats || {}) };

    const answerResults = answers.map((a) => {
      const isCorrect = a.isCorrect === true;
      if (isCorrect) correctCount += 1;
      xpEarned += isCorrect ? XP_CORRECT : XP_WRONG;

      const label = CATEGORY_LABELS[a.categoryId] || a.categoryId;
      if (!categoryStats[label]) {
        categoryStats[label] = { correct: 0, total: 0 };
      }
      categoryStats[label].total += 1;
      if (isCorrect) categoryStats[label].correct += 1;

      return {
        questionId: a.questionId,
        selectedIndex: a.selectedIndex,
        isCorrect,
      };
    });

    const seedsEarned = correctCount * SEEDS_PER_CORRECT;
    const newXp = previousXp + xpEarned;
    const newLevel = levelFromXp(newXp);

    let streak = user.streak ?? 0;
    let lastQuizCompletedDate = user.lastQuizCompletedDate ?? null;
    let todayQuizCompleted = user.todayQuizCompleted ?? false;
    const today = todayKey();

    if (!todayQuizCompleted) {
      todayQuizCompleted = true;
      if (!lastQuizCompletedDate) {
        streak = 1;
      } else if (lastQuizCompletedDate === yesterdayKey()) {
        streak += 1;
      } else if (lastQuizCompletedDate !== today) {
        streak = 1;
      }
      lastQuizCompletedDate = today;
    }

    const history = [...(user.learningHistory || [])];
    history.unshift({
      date: today,
      correctCount,
      totalCount: answers.length,
      xpEarned,
    });

    const unlocks = computeUnlocks(user, streak, newXp);

    tx.update(userRef, {
      xp: newXp,
      seeds: (user.seeds ?? 0) + seedsEarned,
      streak,
      lastQuizCompletedDate,
      todayQuizCompleted,
      categoryStats,
      learningHistory: history.slice(0, 50),
      unlockedHamsterIds: unlocks.all,
    });

    tx.update(sessionRef, {
      status: 'completed',
      correctCount,
      xpEarned,
      energySpent: session.energySpent ?? answers.length * ENERGY_PER_QUESTION,
      completedAt: FieldValue.serverTimestamp(),
    });

    return {
      answers: answerResults,
      xpEarned,
      seedsEarned,
      correctCount,
      totalCount: answers.length,
      leveledUp: newLevel > previousLevel,
      newLevel,
      previousLevel,
      unlockedItems: unlocks.newly,
      newStreak: streak,
      energyRemaining: user.energy ?? 0,
    };
  });
});
