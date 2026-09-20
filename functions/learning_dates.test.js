'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { learningDatesFromUser } = require('./learning_dates');

test('repeated dates are deduplicated without losing an earlier day', () => {
  const learningDates = ['2026-09-01', ...Array.from({ length: 60 }, () => '2026-09-12')];
  assert.deepEqual(learningDatesFromUser({ learningDates }, '2026-09-12', true), ['2026-09-12', '2026-09-01']);
});
test('inclusive 32 days exclude invalid and future dates', () => {
  assert.deepEqual(learningDatesFromUser({ learningDates: ['2026-08-11', '2026-08-12', '2026-09-12', '2026-09-13', '2026-08-32', null] }, '2026-09-12'), ['2026-09-12', '2026-08-12']);
});
test('leap day and year rollover', () => {
  assert.deepEqual(learningDatesFromUser({ learningDates: ['2024-02-28', '2024-02-29'] }, '2024-03-31', true), ['2024-03-31', '2024-02-29']);
  assert.deepEqual(learningDatesFromUser({ learningDates: ['2025-12-01', '2025-12-02'] }, '2026-01-02', true), ['2026-01-02', '2025-12-02']);
});
test('rolling window never exceeds 32 dates', () => {
  const learningDates = Array.from({ length: 70 }, (_, i) => new Date(Date.UTC(2026, 8, 12) - i * 86400000).toISOString().slice(0, 10));
  const saved = learningDatesFromUser({ learningDates }, '2026-09-12', true);
  assert.equal(saved.length, 32);
  assert.equal(saved.at(-1), '2026-08-12');
  assert.equal(learningDatesFromUser({ learningDates: saved }, '2026-09-13', true).length, 32);
  assert.deepEqual(learningDatesFromUser({ learningDates: saved }, '2026-11-01'), []);
});
