# 인증

관련 코드: `lib/services/auth_service.dart`, `lib/screens/auth/`

**Firebase Auth + Firestore(`users/{uid}`)** 기반. 로컬 저장(SharedPreferences)은 더 이상 안 씀.

## 회원가입 (이메일)

2단계로 나뉜다 — 이메일 인증을 완료해야 가입이 끝난다.

1. 이메일·비밀번호 입력 후 "인증하기" → `AuthService.beginSignUp`이 계정을 만들고 인증 메일 발송 (Firestore 프로필은 아직 안 만듦)
2. 메일함에서 링크 클릭 → 앱에서 "확인" → `AuthService.checkEmailVerified`로 서버 상태 재확인
3. 인증 완료 + 닉네임 입력 + **(필수)** 이용약관/개인정보 처리방침 동의 → `AuthService.completeSignUp`이 `users/{uid}` 문서 생성
4. `CategorySelectScreen`에서 관심 카테고리 저장
5. `onAuthenticated` → MainShell

약관 본문: `lib/data/legal_documents.dart` (임시, 추후 교체).

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
