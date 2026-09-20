# 인증

관련 코드: `lib/services/auth_service.dart`, `lib/screens/auth/`

**Firebase Auth + Firestore(`users/{uid}`)** 기반. 로컬 저장(SharedPreferences)은 더 이상 안 씀.

## 시작 화면

앱을 열면 `SplashScreen`(로고+햄핀 등장창)이 1.6초 동안 뜨면서 세션을 확인한다.
세션이 있으면 바로 홈, 없으면 `IntroScreen`(맨처음 설치 시 초기 화면)이다.

초기 화면은 **원터치 가입**이 기본이라 소셜 버튼 3개(카카오톡·Apple·Google)가 먼저 오고,
이메일로 가입할 사람만 "다른 방법으로 계속하기"로 들어간다.
디자인에는 없지만 이메일로 가입한 기존 회원이 들어올 입구가 필요해서
아래에 "이미 계정이 있나요? 로그인" 링크를 하나 뒀다.

## 회원가입 (이메일)

한 화면에 질문 하나씩 받는다. 입력값은 `SignupDraft` 하나를 단계 사이에서 들고 다니고,
프로필 문서(`users/{uid}`)는 **마지막 약관 화면에서 한 번에** 만든다.

| 단계 | 화면 | CTA | 하는 일 |
|------|------|-----|---------|
| 1 | 닉네임 | 다음 | 2~12자 확인 → `nicknames/`로 중복 확인 |
| 2 | 이메일 | 다음 | 형식만 확인 |
| 3 | 비밀번호 | 인증번호 전송 | 규칙 4개 확인 → `beginSignUp`이 계정 생성 + 인증 메일 발송 |
| 4 | 인증 | 다음 | `checkEmailVerified`로 서버 재확인 (타이머 3:00, 재전송) |
| 5 | 약관 | 회원가입 | `completeSignUp`이 `users/{uid}` 생성 → `CategorySelectScreen` |

닉네임이 이미 있으면 다음 화면으로 넘기지 않고 **"이미 사용중인 아이디입니다."**를 띄운다.
로그인 전에 확인해야 해서 `nicknames/{nicknameLower}`의 **`get`을 공개**로 열었다
(`list`는 계속 로그인 필요 — 닉네임을 통째로 긁어가지 못하게).

약관은 이용약관·개인정보(필수) + 광고성 정보/마케팅(선택) 3개이고,
선택 동의 값은 `users/{uid}.consents.marketing`에 남는다.

### 디자인과 다른 점 2가지

- **인증번호 → 인증 링크**: 디자인은 6자리 인증번호지만 Firebase는 이메일 인증 링크를 쓴다.
  입력칸 자리에 받는 주소를 보여주고 "다음"이 인증 여부를 다시 묻는다.
  타이머·재전송 링크는 디자인 그대로다. 진짜 6자리 코드를 쓰려면 Cloud Functions + 메일 발송
  서비스가 필요하다.
- **비밀번호 ↔ 인증 순서**: 디자인은 이메일 → 인증번호 → 비밀번호지만, Firebase는 계정을
  만들 때 비밀번호가 있어야 하고 인증 메일은 계정이 있어야 보낼 수 있다. 그래서 비밀번호를
  먼저 받는다. 위 OTP를 붙이면 디자인 순서로 되돌릴 수 있다.

### 중간에 그만두면

3단계에서 계정이 먼저 생기므로, 인증 단계에서 앱을 끄면 "Auth 계정만 있고 프로필이 없는"
상태가 남는다.

- `AuthGate`가 이 상태를 찾아 **로그아웃**시킨다 (`discardIncompleteEmailSignUp`).
- 같은 메일·비밀번호로 다시 가입하면 `email-already-in-use` 대신 `_resumeSignUp`이
  다시 로그인시켜 인증 단계부터 이어준다.

## 로그인

- 이메일 소문자 trim
- 이메일 인증이 안 된 계정은 로그인 거부 + 인증 메일 재발송 (`AuthService.login`)
- 미가입 이메일은 오류 (자동 가입 없음)

## 소셜 로그인

Google, 카카오(OIDC) 연동 완료 — `AuthService.signInWithGoogle` / `signInWithKakao`.
Apple은 미구현 (Apple Developer Program 계정 필요) — 버튼 핸들러가 빈 스텁이다.

카카오는 Firebase의 OpenID Connect 커스텀 provider(`oidc.kakao`)로 연결 — Cloud Functions 없이 동작하지만 Blaze(종량제) 플랜 필요.

### 첫 가입 온보딩

로그인 결과는 `SocialSignInResult`로 돌아온다. `users/{uid}` 문서가 이미 있으면 그대로 로그인,
없으면 `needsProfileSetup: true` — 이 단계에서는 아직 문서를 만들지 않는다.

1. `SocialProfileSetupScreen` — 닉네임 직접 입력(제공자 이름이 기본값, 중복확인 가능) + **(필수)** 약관/개인정보 동의
2. `AuthService.completeSocialSignUp` → `users/{uid}` 문서 생성 (이메일 가입과 같은 `_createProfile`)
3. `CategorySelectScreen`에서 관심 카테고리 저장
4. `onAuthenticated` → MainShell

이메일 인증 절차는 없다 (제공자가 이미 검증).

중간에 그만두면 로그아웃해서 프로필 없는 로그인 상태를 남기지 않는다.
그래도 앱이 강제 종료돼 그 상태가 남으면, `AuthGate`가 `AuthService.pendingSocialSignUp`으로
찾아내 닉네임 화면부터 이어받는다.

## 비밀번호 재설정

`FindPasswordScreen` → `AuthService.resetPassword`
- Firebase Auth는 클라이언트에서 비밀번호를 직접 바꿀 수 없어서, 재설정 링크를 이메일로 발송하는 방식

## 관심 카테고리

마스터: `lib/data/interest_categories.dart` (`kInterestCategories`)

| id | 표시명 |
|----|--------|
| `allowance` | 용돈&지출관리 |
| `saving` | 저축&예금 |
| `stock` | 주식&투자 |
| `insurance` | 보험 |
| `tax` | 세금 |
| `credit` | 신용&대출 |

- id는 `QuizCategory` enum name과 동일  
- 홈 메뉴 → `CategorySwitcherSheet`: 전체 목록 표시, 탭으로 선택/해제, **최소 1개**  
- 저장: `AuthService.saveInterestCategories`

## 약관 UI

| 진입 | 동작 |
|------|------|
| 회원가입 링크 | `LegalDocumentScreen.openTerms` / `openPrivacy` |
| 설정 → 규정&개인정보 | 바텀시트에서 약관/방침 선택 |
