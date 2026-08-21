# 인증

관련 코드: `lib/services/auth_service.dart`, `lib/screens/auth/`

## 저장 키

| 키 | 내용 |
|----|------|
| `finquiz_users` | 이메일 → `{ passwordHash, salt, nickname, profile }` |
| `finquiz_session` | 현재 로그인 이메일 |

## 비밀번호

- salt: 16바이트 secure random → `base64Url`
- hash: `sha256('$salt:$password')`
- 평문 저장 없음

## 회원가입

1. 닉네임·이메일·비밀번호 입력  
2. **(필수)** 이용약관 동의 + 개인정보 처리방침 동의  
3. `AuthService.signUp`  
4. `CategorySelectScreen`에서 관심 카테고리 저장  
5. `onAuthenticated` → MainShell  

동의하지 않으면 가입 불가.  
약관 본문: `lib/data/legal_documents.dart` (임시, 추후 교체).

## 로그인

- 이메일 소문자 trim  
- 테스트 계정으로 로그인 시 `_ensureTestAccount`로 계정 자동 생성  
- 미가입 이메일은 오류 (자동 가입 없음)

### 테스트 계정

| 항목 | 값 |
|------|-----|
| 이메일 | `test@finquiz.com` |
| 비밀번호 | `test1234` |
| 상수 | `AuthService.testEmail` / `testPassword` |

## 비밀번호 재설정

`FindPasswordScreen` → `AuthService.resetPassword`  
- 가입된 이메일만 가능  
- 새 비밀번호 6자 이상  

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

## 소셜 로그인

Google / Apple / Kakao 버튼 UI만 존재. 핸들러는 스텁.

## 약관 UI

| 진입 | 동작 |
|------|------|
| 회원가입 링크 | `LegalDocumentScreen.openTerms` / `openPrivacy` |
| 설정 → 규정&개인정보 | 바텀시트에서 약관/방침 선택 |
