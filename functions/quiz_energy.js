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

// 세션을 시작한 날(KST). 시작할 때 기록한 seedDate, 없으면 startedAt으로 본다.
function sessionDateKey(session) {
  if (typeof session?.seedDate === 'string') return session.seedDate;
  const startedAt = session?.startedAt?.toDate?.();
  return startedAt ? kstDateKey(startedAt) : null;
}

// 중도 종료한 세션에서 쓴 에너지를 돌려준다. 에너지는 날짜가 바뀌면 최대치로
// 리셋되므로 오늘 시작한 세션만 돌려준다. 이전 날짜 세션에서 쓴 에너지는 리셋으로
// 이미 사라졌어야 해서, 돌려주면 오늘 에너지 위에 어제치가 얹힌다.
function abandonRefund({ energy, spent, sessionDate, today, maxEnergy }) {
  const refundable =
    sessionDate === today && Number.isFinite(spent) ? Math.max(0, spent) : 0;
  // 환불이 에너지를 줄이는 일은 없게 한다.
  const energyRemaining = Math.max(
    energy,
    Math.min(maxEnergy, energy + refundable),
  );
  return { energyRemaining, energyRefunded: energyRemaining - energy };
}

module.exports = {
  abandonRefund,
  completionEnergyReward,
  kstDateKey,
  sessionDateKey,
};
