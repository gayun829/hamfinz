const test = require('node:test');
const assert = require('node:assert/strict');

const {
  nextIncorrectQuestionCounts,
  aggregateIncorrectQuestionCounts,
  totalIncorrectQuestionCount,
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
