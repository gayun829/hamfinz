const test = require('node:test');
const assert = require('node:assert/strict');

const {
  nextIncorrectQuestionCounts,
  aggregateIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
  planIncorrectQuestionCounts,
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

test('an account without the map is backfilled in the same submit', () => {
  const plan = planIncorrectQuestionCounts({
    user: { incorrectQuestionCount: 3 },
    incorrectDocs: [{ categoryId: 'saving' }, { categoryId: 'saving' }, {}],
    categoryId: 'stock',
    isCorrect: false,
    alreadyTracked: false,
  });
  assert.deepEqual(plan.counts, { saving: 2, allowance: 1, stock: 1 });
  assert.equal(plan.total, 4);
  assert.equal(plan.write, true);
});

test('backfill writes an empty map when there are no incorrect docs', () => {
  const plan = planIncorrectQuestionCounts({
    user: {},
    incorrectDocs: [],
    categoryId: 'saving',
    isCorrect: true,
    alreadyTracked: false,
  });
  assert.deepEqual(plan.counts, {});
  assert.equal(plan.total, 0);
  assert.equal(plan.write, true);
});

test('a map change is saved even when the stored total already matches', () => {
  // 예전 앱이 합계만 올려서 합계가 맵보다 1 큰 계정.
  const plan = planIncorrectQuestionCounts({
    user: { incorrectQuestionCounts: { saving: 3 }, incorrectQuestionCount: 4 },
    incorrectDocs: null,
    categoryId: 'saving',
    isCorrect: false,
    alreadyTracked: false,
  });
  assert.deepEqual(plan.counts, { saving: 4 });
  assert.equal(plan.write, true);
});

test('a repeated wrong answer leaves a consistent map untouched', () => {
  const plan = planIncorrectQuestionCounts({
    user: { incorrectQuestionCounts: { saving: 3 }, incorrectQuestionCount: 3 },
    incorrectDocs: null,
    categoryId: 'saving',
    isCorrect: false,
    alreadyTracked: true,
  });
  assert.equal(plan.write, false);
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
