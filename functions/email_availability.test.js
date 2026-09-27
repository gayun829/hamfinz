const test = require('node:test');
const assert = require('node:assert/strict');

const { emailAvailability } = require('./email_availability');

test('unused email is available', () => {
  assert.deepEqual(emailAvailability(null, false), { available: true });
});

test('finished email signup is taken', () => {
  assert.deepEqual(emailAvailability({ providerIds: ['password'] }, true), {
    available: false,
    reason: 'registered',
  });
});

test('email signup stopped before the profile can be resumed', () => {
  assert.deepEqual(emailAvailability({ providerIds: ['password'] }, false), {
    available: true,
  });
});

test('social accounts point the user to social login', () => {
  for (const hasProfile of [true, false]) {
    assert.deepEqual(emailAvailability({ providerIds: ['google.com'] }, hasProfile), {
      available: false,
      reason: 'social',
    });
  }
  assert.deepEqual(
    emailAvailability({ providerIds: ['password', 'oidc.kakao'] }, true),
    { available: false, reason: 'social' },
  );
});
