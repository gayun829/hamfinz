const { learningDatesFromUser } = require('./learning_dates');
/**
 * Quiz session — submitAnswer · completeSession (서버 채점 · 기록)
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
const ENERGY_PACK_AMOUNT = 20;

// Dart `ShopData.items`와 값을 맞춰야 한다 (lib/data/shop_data.dart).
// 코스메틱(스킨/무늬/배경/악세서리)은 `shopItems` Firestore 문서를 우선 신뢰하고,
// 여기 값은 그 문서가 없을 때만 쓰는 폴백이다.
const SHOP_CATALOG = {
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
  const incorrectRef = userRef.collection('incorrectQuestions').doc(questionId);

  return db.runTransaction(async (tx) => {
    const [userSnap, sessionSnap, answerSnap, questionSnap, incorrectSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(sessionRef),
      tx.get(answerRef),
      tx.get(questionRef),
      tx.get(incorrectRef),
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

    const userUpdate = { energy, lastEnergyResetDate };
    const currentCount = Number(user.incorrectQuestionCount ?? 0);
    const alreadyTracked = incorrectSnap.exists;
    let nextCount = currentCount;
    if (isCorrect) {
      if (alreadyTracked) {
        nextCount = Math.max(0, currentCount - 1);
      }
    } else if (!alreadyTracked) {
      nextCount = currentCount + 1;
    }
    if (nextCount !== currentCount) {
      userUpdate.incorrectQuestionCount = nextCount;
    }
    tx.update(userRef, userUpdate);

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
      if (incorrectSnap.exists) {
        tx.delete(incorrectRef);
      }
    } else {
      const previousWrongCount = Number(incorrectSnap.data()?.wrongCount ?? 0);
      const incorrectUpdate = {
        questionId,
        categoryId: q.categoryId || 'allowance',
        difficulty: Number(q.difficulty ?? 1),
        wrongCount: previousWrongCount + 1,
        lastSelectedIndex: selected,
        lastSessionId: sessionId,
        lastWrongAt: FieldValue.serverTimestamp(),
      };
      if (!incorrectSnap.exists) {
        incorrectUpdate.firstWrongAt = FieldValue.serverTimestamp();
      }
      tx.set(incorrectRef, incorrectUpdate, { merge: true });
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


    tx.update(userRef, {
      seeds: (user.seeds ?? 0) + seedsEarned,
      streak,
      lastQuizCompletedDate,
      todayQuizCompleted,
      studyGuardCount,
      categoryStats,
      learningDates,
      learningHistory: FieldValue.delete(),
    });

    tx.update(sessionRef, {
      status: 'completed',
      correctCount,
      energySpent: session.energySpent ?? answers.length * ENERGY_PER_QUESTION,
      completedAt: FieldValue.serverTimestamp(),
    });

    return {
      answers: answerResults,
      seedsEarned,
      correctCount,
      totalCount: answers.length,
      newStreak: streak,
      energyRemaining: user.energy ?? 0,
    };
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
    const price = Number(remote?.price ?? fallback?.price);
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
