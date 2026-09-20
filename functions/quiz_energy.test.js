const test = require('node:test');
const assert = require('node:assert/strict');

const { completionEnergyReward } = require('./quiz_energy');

test('completion reward never exceeds the energy spent', () => {
  assert.equal(completionEnergyReward(5, 20), 5);
  assert.equal(completionEnergyReward(50, 20), 20);
  assert.equal(completionEnergyReward(0, 20), 0);
  assert.equal(completionEnergyReward(-5, 20), 0);
});
