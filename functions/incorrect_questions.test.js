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
