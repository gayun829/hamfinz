'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { effectiveStreak, rankParticipants } = require('./friends_ranking');

test('streak counts only while the last study day is today or yesterday', () => {
  const today = '2026-09-28';
  const yesterday = '2026-09-27';
  assert.equal(effectiveStreak({ streak: 5, lastQuizCompletedDate: today }, today, yesterday), 5);
  assert.equal(effectiveStreak({ streak: 5, lastQuizCompletedDate: yesterday }, today, yesterday), 5);
  assert.equal(effectiveStreak({ streak: 5, lastQuizCompletedDate: '2026-09-25' }, today, yesterday), 0);
  assert.equal(effectiveStreak({}, today, yesterday), 0);
  assert.equal(effectiveStreak({ streak: 'x', lastQuizCompletedDate: today }, today, yesterday), 0);
});

test('ranking orders by streak, then today completion, then nickname', () => {
  const ranked = rankParticipants([
    { uid: 'a', nickname: '다람', streak: 3, todayCompleted: false },
    { uid: 'b', nickname: '가나', streak: 7, todayCompleted: true },
    { uid: 'c', nickname: '나비', streak: 3, todayCompleted: true },
    { uid: 'd', nickname: '가람', streak: 3, todayCompleted: false },
  ]);
  assert.deepEqual(ranked.map((p) => [p.uid, p.rank]), [['b', 1], ['c', 2], ['d', 3], ['a', 4]]);
});
