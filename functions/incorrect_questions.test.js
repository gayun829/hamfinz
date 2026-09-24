const test = require('node:test');
const assert = require('node:assert/strict');

const {
  nextIncorrectQuestionCounts,
  aggregateIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
  planSessionIncorrectQuestions,
} = require('./incorrect_questions');

test('wrong answers increment only that category', () => {
  const next = nextIncorrectQuestionCounts({
    counts: { saving: 11, stock: 2 },
    categoryId: 'stock',
    isCorrect: false,
    alreadyTracked: false,
  });
  assert.deepEqual(next, { saving: 11, stock: 3 });
  assert.equal(totalIncorrectQuestionCount(next), 14);
});

test('a correct review answer decrements only that category', () => {
  const next = nextIncorrectQuestionCounts({
    counts: { saving: 11, stock: 1 },
    categoryId: 'stock',
    isCorrect: true,
    alreadyTracked: true,
  });
  assert.deepEqual(next, { saving: 11 });
});

test('existing incorrect docs are counted per category', () => {
  const counts = aggregateIncorrectQuestionCounts([
    { categoryId: 'saving' },
    { categoryId: 'saving' },
    { categoryId: 'stock' },
    {},
  ]);
  assert.deepEqual(counts, { saving: 2, stock: 1, allowance: 1 });
});

test('an account without the map is backfilled when the session completes', () => {
  const plan = planSessionIncorrectQuestions({
    user: { incorrectQuestionCount: 3 },
    incorrectDocs: [{ categoryId: 'saving' }, { categoryId: 'saving' }, {}],
    answers: [{ questionId: 's9', isCorrect: false, categoryId: 'stock' }],
    trackedById: {},
  });
  assert.deepEqual(plan.counts, { saving: 2, allowance: 1, stock: 1 });
  assert.equal(plan.total, 4);
  assert.equal(plan.writeCounts, true);
});

test('backfill writes an empty map when there are no incorrect docs', () => {
  const plan = planSessionIncorrectQuestions({
    user: {},
    incorrectDocs: [],
    answers: [{ questionId: 's1', isCorrect: true, categoryId: 'saving' }],
    trackedById: {},
  });
  assert.deepEqual(plan.counts, {});
  assert.equal(plan.writeCounts, true);
  assert.deepEqual(plan.masteredIds, ['s1']);
});

test('a map change is saved even when the stored total already matches', () => {
  // 예전 앱이 합계만 올려서 합계가 맵보다 1 큰 계정.
  const plan = planSessionIncorrectQuestions({
    user: { incorrectQuestionCounts: { saving: 3 }, incorrectQuestionCount: 4 },
    incorrectDocs: null,
    answers: [{ questionId: 's1', isCorrect: false, categoryId: 'saving' }],
    trackedById: {},
  });
  assert.deepEqual(plan.counts, { saving: 4 });
  assert.equal(plan.writeCounts, true);
});

test('a session sorts answers into mastered, cleared and wrong', () => {
  const plan = planSessionIncorrectQuestions({
    user: { incorrectQuestionCounts: { saving: 10 }, incorrectQuestionCount: 10 },
    incorrectDocs: null,
    answers: [
      { questionId: 'new-right', isCorrect: true, categoryId: 'saving' },
      { questionId: 'old-right', isCorrect: true, categoryId: 'saving' },
      { questionId: 'new-wrong', isCorrect: false, categoryId: 'saving' },
      { questionId: 'old-wrong', isCorrect: false, categoryId: 'saving' },
    ],
    trackedById: {
      'old-right': { categoryId: 'saving', wrongCount: 1 },
      'old-wrong': { categoryId: 'saving', wrongCount: 2 },
    },
  });
  assert.deepEqual(plan.masteredIds, ['new-right', 'old-right']);
  assert.deepEqual(plan.removeIds, ['old-right']);
  assert.deepEqual(
    plan.wrong.map((w) => [w.answer.questionId, w.isNew, w.previousWrongCount]),
    [['new-wrong', true, 0], ['old-wrong', false, 2]],
  );
  // old-right -1, new-wrong +1, old-wrong 그대로.
  assert.deepEqual(plan.counts, { saving: 10 });
  assert.equal(plan.writeCounts, false);
});

test('a tracked wrong answer stays in the category it was recorded under', () => {
  // 문제가 saving → stock으로 옮겨졌어도 오답 문서와 오답 수는 saving에 남는다.
  const plan = planSessionIncorrectQuestions({
    user: { incorrectQuestionCounts: { saving: 1 }, incorrectQuestionCount: 1 },
    incorrectDocs: null,
    answers: [{ questionId: 'moved', isCorrect: true, categoryId: 'stock' }],
    trackedById: { moved: { categoryId: 'saving', wrongCount: 1 } },
  });
  assert.deepEqual(plan.counts, {});
  assert.deepEqual(plan.removeIds, ['moved']);
});

const {
  isReviewableQuestion,
  reconcileCategoryIncorrectQuestions,
} = require('./incorrect_questions');

test('inactive, deleted or moved questions are not reviewable', () => {
  assert.equal(isReviewableQuestion({ isActive: true, categoryId: 'saving' }, 'saving'), true);
  assert.equal(isReviewableQuestion({ isActive: false, categoryId: 'saving' }, 'saving'), false);
  assert.equal(isReviewableQuestion(null, 'saving'), false);
  assert.equal(isReviewableQuestion({ isActive: true, categoryId: 'stock' }, 'saving'), false);
  assert.equal(isReviewableQuestion({ isActive: true }, 'allowance'), true);
});

test('reconcile drops unreviewable wrong answers so review can end', () => {
  // 11개 중 2개가 비활성화·삭제 → 9개만 남아 복습 기준(10 초과) 아래로 내려간다.
  const incorrectDocs = Array.from({ length: 11 }, (_, i) => ({
    id: `q${i}`,
    data: { categoryId: 'saving' },
  }));
  const questionsById = {};
  for (const doc of incorrectDocs) {
    questionsById[doc.id] = { isActive: true, categoryId: 'saving' };
  }
  questionsById.q3 = { isActive: false, categoryId: 'saving' };
  questionsById.q7 = null;

  const plan = reconcileCategoryIncorrectQuestions({
    counts: { saving: 11, stock: 2 },
    categoryId: 'saving',
    incorrectDocs,
    questionsById,
  });
  assert.deepEqual(plan.removeIds, ['q3', 'q7']);
  assert.deepEqual(plan.counts, { saving: 9, stock: 2 });
  assert.equal(plan.total, 11);
  assert.equal(plan.changed, true);
});

test('reconcile resets a count that has no wrong-answer docs behind it', () => {
  const plan = reconcileCategoryIncorrectQuestions({
    counts: { saving: 12 },
    categoryId: 'saving',
    incorrectDocs: [],
    questionsById: {},
  });
  assert.deepEqual(plan.counts, {});
  assert.equal(plan.changed, true);
});

test('reconcile leaves a consistent category alone', () => {
  const plan = reconcileCategoryIncorrectQuestions({
    counts: { allowance: 1 },
    categoryId: 'allowance',
    incorrectDocs: [{ id: 'a1', data: {} }],
    questionsById: { a1: { isActive: true } },
  });
  assert.equal(plan.changed, false);
  assert.deepEqual(plan.removeIds, []);
});
