const { learningDatesFromUser } = require('./learning_dates');
const {
  abandonRefund,
  completionEnergyReward,
  kstDateKey,
  sessionDateKey,
} = require('./quiz_energy');
const {
  hasIncorrectQuestionCounts,
  planSessionIncorrectQuestions,
  readIncorrectQuestionCounts,
  reconcileCategoryIncorrectQuestions,
} = require('./incorrect_questions');
/**
 * Quiz session — submitAnswer · completeSession (서버 채점 · 기록)
 *   reconcileIncorrectQuestions (복습할 수 없는 오답 정리)
 * Shop — purchaseShopItem (씨앗 차감 상점 구매)
 * News — fetchNewsFeed (웹 빌드용 구글뉴스 RSS 프록시)
 *
 * deploy: firebase deploy --only functions
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

const db = getFirestore();

const ENERGY_PER_QUESTION = 5;
const SEEDS_PER_CORRECT = 5;
const MAX_ENERGY = 100;
const MAX_STUDY_GUARD = 4;
// 세션 완료 보상 에너지 — Dart `QuizData.sessionCompleteEnergyReward`와 같아야 한다.
const ENERGY_SESSION_COMPLETE_REWARD = 20;
const ENERGY_PACK_AMOUNT = 20;

// Dart `ShopData.items`와 값을 맞춰야 한다 (lib/data/shop_data.dart).
// 앱에 포함된 상품은 이 가격을 사용하고, 추가 상품은 Firestore에서 읽는다.
const SHOP_CATALOG = {
  skin_black: { price: 579, kind: 'cosmetic' },
  skin_dinosaur: { price: 579, kind: 'cosmetic' },
  skin_ninja: { price: 579, kind: 'cosmetic' },
  skin_pirate: { price: 579, kind: 'cosmetic' },
  skin_genie_blue: { price: 579, kind: 'cosmetic' },
  skin_genie_tail: { price: 579, kind: 'cosmetic' },
  skin_crewcut: { price: 579, kind: 'cosmetic' },
  skin_grandma: { price: 579, kind: 'cosmetic' },
  skin_kindergarten: { price: 579, kind: 'cosmetic' },
  skin_perm: { price: 579, kind: 'cosmetic' },
  skin_genie: { price: 579, kind: 'cosmetic' },
  skin_business: { price: 579, kind: 'cosmetic' },
  skin_bee: { price: 579, kind: 'cosmetic' },
  skin_bee_duckbill: { price: 579, kind: 'cosmetic' },
  skin_default: { price: 0, kind: 'cosmetic' },
  skin_bearded_cream: { price: 579, kind: 'cosmetic' },
  skin_bearded_gray: { price: 579, kind: 'cosmetic' },
  skin_caveman: { price: 579, kind: 'cosmetic' },
  skin_caveman_bearded: { price: 579, kind: 'cosmetic' },
  accessory_perm: { price: 579, kind: 'cosmetic' },
  accessory_kindergarten_hair: { price: 579, kind: 'cosmetic' },
  accessory_kindergarten: { price: 579, kind: 'cosmetic' },
  accessory_propeller_hat: { price: 579, kind: 'cosmetic' },
  accessory_genie_set: { price: 579, kind: 'cosmetic' },
  accessory_grandma: { price: 579, kind: 'cosmetic' },
  accessory_painter_set: { price: 579, kind: 'cosmetic' },

  headband: { price: 579, kind: 'cosmetic' },
  cap: { price: 579, kind: 'cosmetic' },
  hoodie: { price: 579, kind: 'cosmetic' },
  glasses: { price: 579, kind: 'cosmetic' },
  bow: { price: 579, kind: 'cosmetic' },
  coconut: { price: 579, kind: 'cosmetic' },
  study_guard: { price: 123, kind: 'studyGuard' },
  energy_pack: { price: 123, kind: 'energyPack', amount: ENERGY_PACK_AMOUNT },
};

const CATEGORY_LABELS = {
  allowance: '용돈 관리',
  saving: '저축',
  stock: '주식 기초',
  insurance: '보험',
  tax: '세금',
  credit: '신용',
};

function todayKey() {
  return kstDateKey(new Date());
}

function yesterdayKey() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return kstDateKey(d);
}


// 날짜가 바뀌면 에너지를 최대로 회복한다 (Dart `AuthService._profileFromJson`과
// 동일한 규칙). 서버가 항상 이 값을 기준으로 계산해야 클라이언트가 화면에만
// 보여주고 저장은 안 하는 상황(리셋 유실)이 안 생긴다.
function resolveEnergy(user, today) {
  let energy = user.energy ?? MAX_ENERGY;
  let lastEnergyResetDate = user.lastEnergyResetDate ?? null;
  if (lastEnergyResetDate !== today) {
    energy = MAX_ENERGY;
    lastEnergyResetDate = today;
  }
  return { energy, lastEnergyResetDate };
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
    const today = todayKey();
    let { energy, lastEnergyResetDate } = resolveEnergy(user, today);
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

    tx.update(userRef, { energy, lastEnergyResetDate });

    // 정답(mastered)·오답(incorrectQuestions)은 여기서 쓰지 않는다. 세션을 끝까지
    // 풀어야 completeSession이 반영한다 — 중간에 나가면 안 푼 문제로 남는다.
    tx.set(answerRef, {
      selectedIndex: selected,
      isCorrect,
      categoryId: q.categoryId || 'allowance',
      difficulty: Number(q.difficulty ?? 1),
      energySpent: ENERGY_PER_QUESTION,
      answeredAt: FieldValue.serverTimestamp(),
    });

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

/**
 * 한 카테고리의 오답을 실제 출제 가능한 문제와 맞춘다.
 * 삭제·비활성화되었거나 카테고리가 바뀐 문제는 복습에 나올 수 없으므로 오답 수를
 * 복습할 수 있는 문서 수로 다시 센다. 그러지 않으면 복습 홈에서 나갈 수 없다.
 * 오답 문서는 문제가 삭제된 경우에만 지운다.
 */
exports.reconcileIncorrectQuestions = onCall({ region: 'asia-northeast3' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  }

  const { categoryId } = request.data ?? {};
  if (typeof categoryId !== 'string' || !CATEGORY_LABELS[categoryId]) {
    throw new HttpsError('invalid-argument', 'categoryId가 올바르지 않아요.');
  }

  const userRef = db.collection('users').doc(uid);
  const incorrectCol = userRef.collection('incorrectQuestions');
  // categoryId가 없는 예전 문서는 allowance로 보므로 그 카테고리만 전체를 읽는다.
  const incorrectQuery =
    categoryId === 'allowance'
      ? incorrectCol
      : incorrectCol.where('categoryId', '==', categoryId);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError('not-found', '유저 프로필을 찾을 수 없어요.');
    }

    const incorrectSnap = await tx.get(incorrectQuery);
    const incorrectDocs = incorrectSnap.docs.map((doc) => ({
      id: doc.id,
      data: doc.data(),
    }));
    const questionSnaps = incorrectDocs.length
      ? await tx.getAll(
        ...incorrectDocs.map((doc) => db.collection('quizQuestions').doc(doc.id)),
      )
      : [];
    const questionsById = {};
    for (const snap of questionSnaps) {
      questionsById[snap.id] = snap.exists ? snap.data() : null;
    }

    const user = userSnap.data();
    const plan = reconcileCategoryIncorrectQuestions({
      counts: readIncorrectQuestionCounts(user),
      categoryId,
      incorrectDocs,
      questionsById,
    });
    for (const id of plan.removeIds) tx.delete(incorrectCol.doc(id));
    // 맵이 없는 예전 계정은 문서만 지운다. 맵은 다음 제출의 백필이 남은 문서로 센다.
    if (plan.changed && hasIncorrectQuestionCounts(user)) {
      tx.update(userRef, {
        incorrectQuestionCounts: plan.counts,
        incorrectQuestionCount: plan.total,
      });
    }
    return { removed: plan.removeIds.length, available: plan.available };
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

    // 끝까지 푼 세션의 답만 정답·오답 목록에 반영한다.
    const incorrectCol = userRef.collection('incorrectQuestions');
    const trackedSnaps = answers.length
      ? await tx.getAll(...answers.map((a) => incorrectCol.doc(a.questionId)))
      : [];
    const trackedById = {};
    for (const snap of trackedSnaps) {
      if (snap.exists) trackedById[snap.id] = snap.data();
    }
    // 카테고리별 맵이 없는 예전 계정만 같은 트랜잭션에서 오답 문서를 센다.
    const incorrectDocs = hasIncorrectQuestionCounts(user)
      ? null
      : (await tx.get(incorrectCol)).docs.map((doc) => doc.data());
    const incorrectPlan = planSessionIncorrectQuestions({
      user,
      incorrectDocs,
      answers,
      trackedById,
    });

    let correctCount = 0;
    const categoryStats = { ...(user.categoryStats || {}) };

    const answerResults = answers.map((a) => {
      const isCorrect = a.isCorrect === true;
      if (isCorrect) correctCount += 1;

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

    const sessionSource = session.source || 'energySession';
    if (sessionSource !== 'reviewSession' && answers.length > 0) {
      const firstCategoryId = answers[0].categoryId || 'allowance';
      const sessionLabel = CATEGORY_LABELS[firstCategoryId] || firstCategoryId;
      if (!categoryStats[sessionLabel]) {
        categoryStats[sessionLabel] = { correct: 0, total: 0, completedSessions: 0 };
      }
      categoryStats[sessionLabel].completedSessions =
        (categoryStats[sessionLabel].completedSessions || 0) + 1;
    }

    const seedsEarned = correctCount * SEEDS_PER_CORRECT;

    let streak = user.streak ?? 0;
    let lastQuizCompletedDate = user.lastQuizCompletedDate ?? null;
    let todayQuizCompleted = lastQuizCompletedDate === todayKey();
    let studyGuardCount = user.studyGuardCount ?? 0;
    const today = todayKey();

    if (!todayQuizCompleted) {
      todayQuizCompleted = true;
      if (!lastQuizCompletedDate) {
        streak = 1;
      } else if (lastQuizCompletedDate === yesterdayKey()) {
        streak += 1;
      } else if (lastQuizCompletedDate !== today) {
        const last = new Date(`${lastQuizCompletedDate}T00:00:00+09:00`);
        const current = new Date(`${today}T00:00:00+09:00`);
        const missedDays = Math.max(1, Math.round((current - last) / 86400000) - 1);
        // 방어권은 결석일수를 "전부" 못 덮으면 쓰지 않는다 — 일부만 막고
        // streak을 어차피 리셋하면 유저 입장에서 방어권만 날리고 얻는 게 없다.
        if (missedDays <= studyGuardCount) {
          studyGuardCount -= missedDays;
          streak += 1;
        } else {
          streak = 1;
        }
      }
      lastQuizCompletedDate = today;
    }

    const learningDates = learningDatesFromUser(user, today, true);

    // 짧은 복습 세션이 에너지 생성 수단이 되지 않도록 실제 소모량까지만
    // 돌려준다. 날짜가 바뀐 경우 submitAnswer와 같은 회복 규칙을 적용한다.
    const energySpent =
      session.energySpent ?? answers.length * ENERGY_PER_QUESTION;
    const rewardCap = completionEnergyReward(
      energySpent,
      ENERGY_SESSION_COMPLETE_REWARD,
    );
    const {
      energy: energyBefore,
      lastEnergyResetDate,
    } = resolveEnergy(user, today);
    const energyRemaining = Math.min(
      MAX_ENERGY,
      energyBefore + rewardCap,
    );
    const energyEarned = energyRemaining - energyBefore;

    const userUpdate = {
      energy: energyRemaining,
      lastEnergyResetDate,
      seeds: (user.seeds ?? 0) + seedsEarned,
      streak,
      lastQuizCompletedDate,
      todayQuizCompleted,
      studyGuardCount,
      categoryStats,
      learningDates,
    };
    if (incorrectPlan.writeCounts) {
      userUpdate.incorrectQuestionCounts = incorrectPlan.counts;
      userUpdate.incorrectQuestionCount = incorrectPlan.total;
    }
    if (sessionSource === 'reviewSession' && session.categoryId) {
      const reviewLabel = CATEGORY_LABELS[session.categoryId] || session.categoryId;
      userUpdate[`reviewArrivals.${session.categoryId}`] =
        categoryStats[reviewLabel]?.completedSessions ?? 0;
    }
    tx.update(userRef, userUpdate);

    for (const questionId of incorrectPlan.masteredIds) {
      tx.set(
        userRef.collection('mastered').doc(questionId),
        { answeredAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    for (const questionId of incorrectPlan.removeIds) {
      tx.delete(incorrectCol.doc(questionId));
    }
    for (const { answer, categoryId, isNew, previousWrongCount } of incorrectPlan.wrong) {
      const incorrectUpdate = {
        questionId: answer.questionId,
        categoryId,
        difficulty: Number(answer.difficulty ?? 1),
        wrongCount: previousWrongCount + 1,
        lastSelectedIndex: answer.selectedIndex,
        lastSessionId: sessionId,
        lastWrongAt: FieldValue.serverTimestamp(),
      };
      if (isNew) incorrectUpdate.firstWrongAt = FieldValue.serverTimestamp();
      tx.set(incorrectCol.doc(answer.questionId), incorrectUpdate, { merge: true });
    }

    tx.update(sessionRef, {
      status: 'completed',
      correctCount,
      energySpent,
      energyEarned,
      completedAt: FieldValue.serverTimestamp(),
    });

    return {
      answers: answerResults,
      seedsEarned,
      correctCount,
      totalCount: answers.length,
      newStreak: streak,
      energyRemaining,
      energyEarned,
    };
  });
});

/**
 * 끝까지 풀지 않고 나간 세션을 닫는다. 그 세션에서 푼 문제는 정답·오답 목록에
 * 반영되지 않은 채(안 푼 문제) 남고, 오늘 시작한 세션이면 쓴 에너지를 돌려준다.
 * 이미 닫힌 세션이면 아무것도 하지 않는다.
 */
exports.abandonSession = onCall({ region: 'asia-northeast3' }, async (request) => {
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
    const [sessionSnap, userSnap] = await Promise.all([
      tx.get(sessionRef),
      tx.get(userRef),
    ]);
    if (!sessionSnap.exists || !userSnap.exists) {
      return { energyRefunded: 0, energyRemaining: null };
    }
    const session = sessionSnap.data();
    const today = todayKey();
    const { energy, lastEnergyResetDate } = resolveEnergy(userSnap.data(), today);
    if (session.status !== 'inProgress') {
      return { energyRefunded: 0, energyRemaining: energy };
    }

    const { energyRemaining, energyRefunded } = abandonRefund({
      energy,
      spent: Number(session.energySpent ?? 0),
      sessionDate: sessionDateKey(session),
      today,
      maxEnergy: MAX_ENERGY,
    });

    tx.update(userRef, { energy: energyRemaining, lastEnergyResetDate });
    tx.update(sessionRef, {
      status: 'abandoned',
      energyRefunded,
      abandonedAt: FieldValue.serverTimestamp(),
    });
    return { energyRefunded, energyRemaining };
  });
});

/**
 * 상점 구매 — 씨앗 차감·소유/방어권/에너지 갱신을 서버 트랜잭션으로 처리한다.
 * 클라이언트가 화면에 들고 있는 프로필로 seeds를 직접 덮어쓰지 않으므로,
 * 오래된 값 때문에 서버 값이 롤백되거나(동시 편집) 두 번 소모되는 문제가 없다.
 */
exports.purchaseShopItem = onCall({ region: 'asia-northeast3' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  }

  const { itemId } = request.data ?? {};
  if (!itemId || typeof itemId !== 'string') {
    throw new HttpsError('invalid-argument', 'itemId가 필요해요.');
  }

  const userRef = db.collection('users').doc(uid);
  const shopItemRef = db.collection('shopItems').doc(itemId);

  return db.runTransaction(async (tx) => {
    const [userSnap, shopItemSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(shopItemRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError('not-found', '유저 프로필을 찾을 수 없어요.');
    }

    const fallback = SHOP_CATALOG[itemId];
    const remote = shopItemSnap.exists ? shopItemSnap.data() : null;
    const price = Number(fallback?.price ?? remote?.price);
    if (!Number.isFinite(price)) {
      throw new HttpsError('not-found', '존재하지 않는 상품이에요.');
    }
    const kind = fallback?.kind ?? 'cosmetic';

    const user = userSnap.data();
    const seeds = user.seeds ?? 0;

    if (kind === 'studyGuard') {
      const studyGuardCount = user.studyGuardCount ?? 0;
      if (studyGuardCount >= MAX_STUDY_GUARD) {
        throw new HttpsError(
          'failed-precondition',
          '방어권은 최대 4개까지 보유할 수 있어요.',
          { code: 'studyGuardMaxCapacity' },
        );
      }
      if (seeds < price) {
        throw new HttpsError(
          'failed-precondition',
          '씨앗이 부족해요.',
          { code: 'insufficientSeeds' },
        );
      }
      const newSeeds = seeds - price;
      const newStudyGuardCount = studyGuardCount + 1;
      tx.update(userRef, { seeds: newSeeds, studyGuardCount: newStudyGuardCount });
      return { seeds: newSeeds, studyGuardCount: newStudyGuardCount };
    }

    if (kind === 'energyPack') {
      const today = todayKey();
      const { energy, lastEnergyResetDate } = resolveEnergy(user, today);
      if (energy >= MAX_ENERGY) {
        throw new HttpsError(
          'failed-precondition',
          '에너지가 이미 가득 차 있어요.',
          { code: 'energyAlreadyFull' },
        );
      }
      if (seeds < price) {
        throw new HttpsError(
          'failed-precondition',
          '씨앗이 부족해요.',
          { code: 'insufficientSeeds' },
        );
      }
      const amount = Number(fallback?.amount ?? ENERGY_PACK_AMOUNT);
      const newSeeds = seeds - price;
      const newEnergy = Math.min(MAX_ENERGY, energy + amount);
      tx.update(userRef, {
        seeds: newSeeds,
        energy: newEnergy,
        lastEnergyResetDate,
      });
      return { seeds: newSeeds, energy: newEnergy };
    }

    // 코스메틱 (스킨/무늬/배경/악세서리) — 이미 소유했으면 재구매 없이 그대로 성공.
    const ownedShopItemIds = user.ownedShopItemIds || [];
    if (ownedShopItemIds.includes(itemId)) {
      return { seeds, ownedShopItemIds };
    }
    if (seeds < price) {
      throw new HttpsError(
        'failed-precondition',
        '씨앗이 부족해요.',
        { code: 'insufficientSeeds' },
      );
    }
    const newSeeds = seeds - price;
    tx.update(userRef, {
      seeds: newSeeds,
      ownedShopItemIds: FieldValue.arrayUnion(itemId),
    });
    return { seeds: newSeeds, ownedShopItemIds: [...ownedShopItemIds, itemId] };
  });
});

// ── 뉴스 RSS 프록시 ─────────────────────────────────────────────────────────
//
// 언론사 RSS는 CORS 헤더가 없어서 웹(Chrome) 빌드에서는 브라우저가 응답을
// 막는다. 서버에서 대신 받아 XML 문자열로 돌려주면 `flutter run -d chrome`만으로
// 뉴스가 뜬다 (로컬 `tool/cors_proxy.dart`를 따로 띄울 필요가 없다).
// 열린 프록시가 되지 않도록 아는 언론사의 RSS 경로만 허용하고, 로그인 사용자만 부른다.
// Dart `NewsService._feedUri`와 맞춰야 한다 (lib/services/news_service.dart).
const NEWS_FEED_ALLOW = {
  'www.yna.co.kr': '/rss/',
  'news.google.com': '/rss/',
};

exports.fetchNewsFeed = onCall({ region: 'asia-northeast3' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  }

  const raw = request.data?.url;
  let target;
  try {
    target = new URL(String(raw ?? ''));
  } catch (_) {
    throw new HttpsError('invalid-argument', 'url이 올바르지 않아요.');
  }
  const allowedPrefix = NEWS_FEED_ALLOW[target.hostname];
  if (
    target.protocol !== 'https:' ||
    !allowedPrefix ||
    !target.pathname.startsWith(allowedPrefix)
  ) {
    throw new HttpsError('invalid-argument', '허용된 뉴스 RSS 주소만 받을 수 있어요.');
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10_000);
  let res;
  try {
    res = await fetch(target, {
      signal: controller.signal,
      headers: { 'User-Agent': 'hamfinz-news/1.0' },
    });
  } catch (e) {
    throw new HttpsError('unavailable', `뉴스 서버에 연결하지 못했어요: ${e.message}`);
  } finally {
    clearTimeout(timer);
  }
  if (!res.ok) {
    throw new HttpsError('unavailable', `뉴스 응답 오류 (${res.status})`);
  }
  return { xml: await res.text() };
});
