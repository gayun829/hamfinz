function completionEnergyReward(energySpent, configuredReward) {
  const spent = Number.isFinite(energySpent) ? energySpent : 0;
  return Math.min(configuredReward, Math.max(0, spent));
}

module.exports = { completionEnergyReward };
