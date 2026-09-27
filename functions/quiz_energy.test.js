const test = require('node:test');
const assert = require('node:assert/strict');

const {
  abandonRefund,
  completionEnergyReward,
  kstDateKey,
  sessionDateKey,
} = require('./quiz_energy');

const refund = (overrides) =>
  abandonRefund({
    energy: 60,
    spent: 25,
    sessionDate: '2026-09-27',
    today: '2026-09-27',
    maxEnergy: 100,
    ...overrides,
  });

test('abandoning a session started today refunds the energy spent', () => {
  assert.deepEqual(refund(), { energyRemaining: 85, energyRefunded: 25 });
});

test('the refund never goes past the energy cap', () => {
  assert.deepEqual(refund({ energy: 90 }), { energyRemaining: 100, energyRefunded: 10 });
  assert.deepEqual(refund({ energy: 120 }), { energyRemaining: 120, energyRefunded: 0 });
});

test('a session from an earlier day is closed without a refund', () => {
  // 어제 쓴 에너지는 오늘 리셋으로 이미 사라졌다.
  assert.deepEqual(
    refund({ energy: 100, sessionDate: '2026-09-26' }),
    { energyRemaining: 100, energyRefunded: 0 },
  );
  assert.deepEqual(refund({ sessionDate: null }), { energyRemaining: 60, energyRefunded: 0 });
});

test('a bad spent value refunds nothing', () => {
  assert.equal(refund({ spent: NaN }).energyRefunded, 0);
  assert.equal(refund({ spent: -10 }).energyRefunded, 0);
});

test('session date comes from seedDate, then startedAt in KST', () => {
  assert.equal(sessionDateKey({ seedDate: '2026-09-27' }), '2026-09-27');
  // 2026-09-26T16:00Z = 9월 27일 01:00 KST
  const startedAt = { toDate: () => new Date('2026-09-26T16:00:00Z') };
  assert.equal(sessionDateKey({ startedAt }), '2026-09-27');
  assert.equal(sessionDateKey({}), null);
  assert.equal(kstDateKey(new Date('2026-09-26T14:59:00Z')), '2026-09-26');
});

test('completion reward never exceeds the energy spent', () => {
  assert.equal(completionEnergyReward(5, 20), 5);
  assert.equal(completionEnergyReward(50, 20), 20);
  assert.equal(completionEnergyReward(0, 20), 0);
  assert.equal(completionEnergyReward(-5, 20), 0);
});
