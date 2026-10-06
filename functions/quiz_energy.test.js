const test = require('node:test');
const assert = require('node:assert/strict');

const {
  abandonRefund,
  completionEnergyReward,
  kstDateKey,
} = require('./quiz_energy');

test('abandoning a session refunds the energy spent with no cap', () => {
  assert.deepEqual(abandonRefund({ energy: 60, spent: 25 }), {
    energyRemaining: 85,
    energyRefunded: 25,
  });
  assert.deepEqual(abandonRefund({ energy: 190, spent: 25 }), {
    energyRemaining: 215,
    energyRefunded: 25,
  });
});

test('a bad spent value refunds nothing', () => {
  assert.equal(abandonRefund({ energy: 60, spent: NaN }).energyRefunded, 0);
  assert.equal(abandonRefund({ energy: 60, spent: -10 }).energyRefunded, 0);
});

test('dates are counted in KST', () => {
  assert.equal(kstDateKey(new Date('2026-09-26T14:59:00Z')), '2026-09-26');
  assert.equal(kstDateKey(new Date('2026-09-26T16:00:00Z')), '2026-09-27');
});

test('completion reward never exceeds the energy spent', () => {
  assert.equal(completionEnergyReward(5, 20), 5);
  assert.equal(completionEnergyReward(50, 20), 20);
  assert.equal(completionEnergyReward(0, 20), 0);
  assert.equal(completionEnergyReward(-5, 20), 0);
});
