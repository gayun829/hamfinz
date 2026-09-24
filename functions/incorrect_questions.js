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

// 답 하나를 반영한 오답 수와 저장 여부. 맵이 없는 예전 계정이면
// incorrectDocs(그 사용자의 incorrectQuestions 문서 데이터)로 먼저 채운다.
function planIncorrectQuestionCounts({
  user,
  incorrectDocs,
  categoryId,
  isCorrect,
  alreadyTracked,
}) {
  const backfilled = !hasIncorrectQuestionCounts(user);
  const counts = backfilled
    ? aggregateIncorrectQuestionCounts(incorrectDocs || [])
    : readIncorrectQuestionCounts(user);
  const nextCounts = nextIncorrectQuestionCounts({
    counts,
    categoryId,
    isCorrect,
    alreadyTracked,
  });
  const nextTotal = totalIncorrectQuestionCount(nextCounts);
  const currentTotal = Number(user?.incorrectQuestionCount ?? 0);
  return {
    counts: nextCounts,
    total: nextTotal,
    // 합계가 같아도 맵이 바뀌었으면 저장한다 (합계가 맵과 어긋난 계정).
    write:
      backfilled ||
      nextTotal !== currentTotal ||
      !sameIncorrectQuestionCounts(counts, nextCounts),
  };
}

module.exports = {
  nextIncorrectQuestionCount,
  readIncorrectQuestionCounts,
  nextIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
  aggregateIncorrectQuestionCounts,
  hasIncorrectQuestionCounts,
  sameIncorrectQuestionCounts,
  planIncorrectQuestionCounts,
};
