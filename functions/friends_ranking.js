'use strict';

// 앱(`AuthService._profileFromJson`)과 같은 규칙: 마지막 학습일이 오늘·어제가
// 아니면 연속학습은 이미 끊긴 것이라 0으로 본다.
function effectiveStreak(user, today, yesterday) {
  const last = user.lastQuizCompletedDate ?? null;
  const streak = Number.isInteger(user.streak) ? user.streak : 0;
  if (last !== today && last !== yesterday) return 0;
  return Math.max(0, streak);
}

// 연속학습이 긴 순서. 같으면 오늘 이미 학습한 사람, 그다음 닉네임 순으로 고정한다.
function rankParticipants(participants) {
  return [...participants]
    .sort((a, b) =>
      b.streak - a.streak
      || Number(b.todayCompleted) - Number(a.todayCompleted)
      || a.nickname.localeCompare(b.nickname, 'ko'))
    .map((p, i) => ({ ...p, rank: i + 1 }));
}

module.exports = { effectiveStreak, rankParticipants };
