function completionEnergyReward(energySpent, configuredReward) {
  const spent = Number.isFinite(energySpent) ? energySpent : 0;
  return Math.min(configuredReward, Math.max(0, spent));
}

function kstDateKey(date) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

// 중도 종료한 세션에서 쓴 에너지를 그대로 돌려준다. 에너지는 날이 바뀌어도
// 사라지지 않으므로 세션을 시작한 날과 상관없다.
function abandonRefund({ energy, spent }) {
  const energyRefunded = Number.isFinite(spent) ? Math.max(0, spent) : 0;
  return { energyRemaining: energy + energyRefunded, energyRefunded };
}

module.exports = {
  abandonRefund,
  completionEnergyReward,
  kstDateKey,
};
