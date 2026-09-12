'use strict';

// Keep today and the preceding 31 calendar days, newest first.
function learningDatesFromUser(user, today, markToday = false) {
  const dates = Array.isArray(user.learningDates)
    ? user.learningDates
    : Array.isArray(user.learningHistory)
      ? user.learningHistory.map((entry) => entry?.date)
      : [];
  const end = new Date(`${today}T00:00:00Z`);
  const start = new Date(end.getTime() - 31 * 86400000).toISOString().slice(0, 10);
  return [...new Set([...dates, ...(markToday ? [today] : [])].filter((date) => {
    if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
    const parsed = new Date(`${date}T00:00:00Z`);
    return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === date
      && date >= start && date <= today;
  }))].sort().reverse();
}

module.exports = { learningDatesFromUser };
