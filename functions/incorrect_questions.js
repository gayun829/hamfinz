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

module.exports = {
  nextIncorrectQuestionCount,
  readIncorrectQuestionCounts,
  nextIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
  aggregateIncorrectQuestionCounts,
};
