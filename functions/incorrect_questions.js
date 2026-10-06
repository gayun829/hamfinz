function nextIncorrectQuestionCount({ currentCount, isCorrect, alreadyTracked }) {
  const current = Number(currentCount) || 0;
  if (isCorrect) {
    if (!alreadyTracked) return current;
    return current > 0 ? current - 1 : 0;
  }
  if (alreadyTracked) return current;
  return current + 1;
}

function readIncorrectQuestionCounts(user) {
  const raw = user?.incorrectQuestionCounts;
  if (!raw || typeof raw !== 'object') return {};
  const counts = {};
  for (const [key, value] of Object.entries(raw)) {
    counts[key] = Number(value) || 0;
  }
  return counts;
}

function nextIncorrectQuestionCounts({
  counts,
  categoryId,
  isCorrect,
  alreadyTracked,
}) {
  const next = { ...(counts || {}) };
  const updated = nextIncorrectQuestionCount({
    currentCount: next[categoryId] ?? 0,
    isCorrect,
    alreadyTracked,
  });
  if (updated <= 0) delete next[categoryId];
  else next[categoryId] = updated;
  return next;
}

function totalIncorrectQuestionCount(counts) {
  return Object.values(counts || {}).reduce(
    (sum, value) => sum + (Number(value) || 0),
    0,
  );
}

function aggregateIncorrectQuestionCounts(docs) {
  const counts = {};
  for (const data of docs) {
    const categoryId = data?.categoryId || 'allowance';
    counts[categoryId] = (counts[categoryId] || 0) + 1;
  }
  return counts;
}

function hasIncorrectQuestionCounts(user) {
  const raw = user?.incorrectQuestionCounts;
  return Boolean(raw) && typeof raw === 'object';
}

function sameIncorrectQuestionCounts(a, b) {
  const aKeys = Object.keys(a);
  if (aKeys.length !== Object.keys(b).length) return false;
  return aKeys.every((key) => a[key] === b[key]);
}

// 끝까지 푼 세션의 답을 정답(mastered)·오답(incorrectQuestions)에 반영할 계획.
// 세션을 완료할 때만 부른다 — 중간에 나간 세션의 답은 반영하지 않으므로 그
// 문제들은 안 푼 문제로 남는다.
//
// answers: [{ questionId, isCorrect, categoryId, ... }]
// trackedById: { [questionId]: 이미 있는 오답 문서 데이터 } — 없는 문제는 키가 없다
// incorrectDocs: 맵이 없는 예전 계정일 때만 — 그 사용자의 오답 문서 데이터 전부
function planSessionIncorrectQuestions({
  user,
  incorrectDocs,
  answers,
  trackedById,
}) {
  const backfilled = !hasIncorrectQuestionCounts(user);
  const counts = backfilled
    ? aggregateIncorrectQuestionCounts(incorrectDocs || [])
    : readIncorrectQuestionCounts(user);

  let nextCounts = counts;
  const masteredIds = [];
  const removeIds = [];
  const wrong = [];
  for (const answer of answers) {
    const tracked = trackedById[answer.questionId];
    const isCorrect = answer.isCorrect === true;
    // 이미 오답 목록에 있는 문제는 기록된 카테고리로 센다. 문제의 카테고리가
    // 나중에 바뀌어도 오답 수와 오답 문서가 같은 카테고리에 남아야 한다.
    const categoryId = tracked
      ? tracked.categoryId || 'allowance'
      : answer.categoryId || 'allowance';
    nextCounts = nextIncorrectQuestionCounts({
      counts: nextCounts,
      categoryId,
      isCorrect,
      alreadyTracked: Boolean(tracked),
    });
    if (isCorrect) {
      masteredIds.push(answer.questionId);
      if (tracked) removeIds.push(answer.questionId);
    } else {
      wrong.push({
        answer,
        categoryId,
        isNew: !tracked,
        previousWrongCount: Number(tracked?.wrongCount ?? 0),
      });
    }
  }

  const nextTotal = totalIncorrectQuestionCount(nextCounts);
  const currentTotal = Number(user?.incorrectQuestionCount ?? 0);
  return {
    counts: nextCounts,
    total: nextTotal,
    // 합계가 같아도 맵이 바뀌었으면 저장한다 (합계가 맵과 어긋난 계정).
    writeCounts:
      backfilled ||
      nextTotal !== currentTotal ||
      !sameIncorrectQuestionCounts(counts, nextCounts),
    masteredIds,
    removeIds,
    wrong,
  };
}

// 복습에 낼 수 있는 문제인지. 삭제·비활성화되었거나 카테고리가 바뀐 문제는
// 복습에서 나오지 않으므로 오답 수에 세면 안 된다 (복습 홈에 갇힘).
function isReviewableQuestion(question, categoryId) {
  if (!question || question.isActive !== true) return false;
  return (question.categoryId || 'allowance') === categoryId;
}

// 한 카테고리의 오답 문서를 실제 출제 가능한 문제와 맞춘다.
// 문제가 삭제된 오답 문서만 지운다. 비활성화되었거나 카테고리가 바뀐 문제는
// 문서(wrongCount, firstWrongAt)를 남기고 오답 수에서만 빼서, 다시 복습할 수
// 있게 되면 다음 정리 때 오답 수로 돌아온다.
// incorrectDocs: [{ id, data }] — 이 카테고리 오답 문서
// questionsById: { [id]: 문제 데이터 | null(삭제됨) }
function reconcileCategoryIncorrectQuestions({
  counts,
  categoryId,
  incorrectDocs,
  questionsById,
}) {
  const removeIds = [];
  let available = 0;
  for (const doc of incorrectDocs) {
    if ((doc.data?.categoryId || 'allowance') !== categoryId) continue;
    const question = questionsById[doc.id];
    if (question === null) {
      removeIds.push(doc.id);
    } else if (isReviewableQuestion(question, categoryId)) {
      available += 1;
    }
  }
  const next = { ...(counts || {}) };
  if (available > 0) next[categoryId] = available;
  else delete next[categoryId];
  return {
    removeIds,
    available,
    counts: next,
    total: totalIncorrectQuestionCount(next),
    changed:
      removeIds.length > 0 || !sameIncorrectQuestionCounts(counts || {}, next),
  };
}

module.exports = {
  isReviewableQuestion,
  reconcileCategoryIncorrectQuestions,
  nextIncorrectQuestionCount,
  readIncorrectQuestionCounts,
  nextIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
  aggregateIncorrectQuestionCounts,
  hasIncorrectQuestionCounts,
  sameIncorrectQuestionCounts,
  planSessionIncorrectQuestions,
};
