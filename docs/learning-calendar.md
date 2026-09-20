# Calendar learning dates

`users/{uid}.learningDates` stores unique `YYYY-MM-DD` strings, newest first.
It contains only dates from today through 31 days before today, inclusive.
Multiple completed quiz sessions on the same day contribute one date.

Both client transactions and Cloud Functions update this array when a session
completes. The array update is part of the existing user/session transaction.
The calendar and profile consume dates only; no per-session summary is stored
in this user field. Existing session/answer documents and category statistics
continue to support quiz completion, review and correctness reporting.

Readers merge dates from learningDates and legacy learningHistory, deduplicate and filter them. The next completed session writes the retained dates to learningDates and deletes learningHistory in the same transaction. Older app versions are developer-only and are not supported after this migration. New profiles start with an empty learningDates array.

Expired dates are filtered on profile read and removed from the stored array on
the next completed session. There is no scheduled database deletion for inactive
accounts. This is a rolling 32-day calendar, not a monthly archive: older dates
are intentionally no longer shown, including when navigating to earlier months.

Production rollout requires the updated app, `completeSession` function and
`firestore.rules.production` (which protects `learningDates` from direct writes).
No production deployment or bulk migration is performed by these code changes.

Validation: `flutter test` and `node --test functions/learning_dates.test.js`.

App date keys and calendar today/month use KST, matching the server. Explicit calendar dates are formatted without time-zone conversion.
