/**
 * 가입 이메일 화면의 중복 확인 판정.
 *
 * Auth 계정이 있어도 "비밀번호 가입인데 프로필이 없는" 계정은 가입 도중 멈춘 본인일
 * 수 있어서 통과시킨다 — 비밀번호 화면의 Dart `_resumeSignUp`이 이어받는다.
 * 소셜 로그인 계정이 붙어 있으면 이메일 가입은 어차피 막히니 그쪽으로 안내한다.
 *
 * @param {{providerIds: string[]} | null} account Auth 계정 (없으면 null)
 * @param {boolean} hasProfile users/{uid} 문서가 있는지
 * @returns {{available: boolean, reason?: 'registered' | 'social'}}
 */
function emailAvailability(account, hasProfile) {
  if (!account) return { available: true };
  const social = account.providerIds.some((id) => id !== 'password');
  if (social) return { available: false, reason: 'social' };
  if (!hasProfile) return { available: true };
  return { available: false, reason: 'registered' };
}

module.exports = { emailAvailability };
