# 퀴즈 프로덕션 배포 (Functions 전환)

Blaze 플랜 전환 후 **submitAnswer · completeSession**을 Cloud Functions로 옮길 때 따르는 체크리스트.

현재(개발)는 Blaze 없이 동작하도록 **클라이언트 Firestore 트랜잭션**을 사용한다.  
API 상세: [quiz-session-api.md](./quiz-session-api.md)

---

## 현재 vs 배포

| 항목 | 개발 (현재) | 프로덕션 (배포 후) |
|------|-------------|---------------------|
| 앱 설정 | `QuizBackendConfig.submitBackend = clientTransaction` | `cloudFunctions` |
| Rules 파일 | `firestore.rules` | `firestore.rules.production` |
| submitAnswer | `QuizSessionRepository` (클라이언트 트랜잭션) | Callable `submitAnswer` |
| completeSession | `QuizSessionRepository` (클라이언트 트랜잭션) | Callable `completeSession` |
| 복습 불가 오답 정리 | `QuizSessionRepository` (클라이언트 트랜잭션) | Callable `reconcileIncorrectQuestions` |
| 중도 종료 (에너지 환불) | `QuizSessionRepository` (클라이언트 트랜잭션) | Callable `abandonSession` |
| mastered / answers write | 클라이언트 허용 | **Functions Admin SDK만** |
| sessions update (completed) | 클라이언트 (`inProgress`일 때) | **Functions만** |
| startSession | 클라이언트 (변경 없음) | 클라이언트 (변경 없음) |

---

## 배포 체크리스트

### 1. Firebase Blaze 플랜

- [ ] Firebase Console → 프로젝트 `hamfins-719b8` → Blaze(종량제) 전환
- [ ] 결제·예산 알림 설정 (선택)

### 2. Cloud Functions 배포

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

- [ ] `submitAnswer`, `completeSession`, `abandonSession`, `reconcileIncorrectQuestions` 배포 확인 (region: `asia-northeast3`)
- [ ] Firebase Console → Functions → 로그에서 cold start / 오류 없음 확인

참고 구현: `functions/index.js` (Dart `QuizSessionRepository`와 동일 로직)

### 3. Firestore Rules (프로덕션)

프로덕션 Rules는 quiz `mastered` / `answers` / `sessions` update를 **클라이언트에서 차단**한다.

```bash
node scripts/deploy_firestore_rules.mjs --production
```

또는 Console에 `firestore.rules.production` 내용을 붙여넣어 게시.

- [ ] `mastered` — read만, write `false`
- [ ] `sessions/.../answers` — read만, write `false`
- [ ] `sessions` — read · create만, update/delete `false`

### 4. 앱 설정 전환

`lib/config/quiz_backend_config.dart`:

```dart
static const submitBackend = QuizSubmitBackend.cloudFunctions;
```

- [ ] 값 변경 후 앱 재빌드·스토어 배포
- [ ] `QuizService`가 `QuizFunctionsRepository` 경로로 라우팅되는지 확인

### 5. 동작 검증

- [ ] 로그인 → 퀴즈 시작 (10문항 출제)
- [ ] 답안 제출 → 정·오답 UI · energy 차감
- [ ] 세션 완료 → 씨앗 · streak · 에너지 보상 · 결과 화면
- [ ] Firestore Console: `users/{uid}/sessions/.../answers` 생성 확인
- [ ] 세션 완료 후 정답은 `users/{uid}/mastered/{questionId}`, 오답은 `incorrectQuestions` 생성 확인
- [ ] 3문제 풀고 뒤로가기 → 세션 `abandoned`, 에너지 환불, `mastered`·`incorrectQuestions` 변화 없음
- [ ] 클라이언트에서 `mastered` 직접 write 시도 → permission-denied (Rules 검증)

### 6. (선택) Emulator 로컬 테스트

배포 전 로컬에서 Functions + Firestore Emulator로 Callable 테스트:

```bash
firebase emulators:start --only functions,firestore
```

앱에서 Emulator 호스트 설정 후 `cloudFunctions` 모드로 E2E.

---

## 파일 맵

| 파일 | 역할 |
|------|------|
| `lib/config/quiz_backend_config.dart` | **전환 스위치** (한 줄 변경) |
| `lib/services/quiz_service.dart` | config에 따라 Repository / Functions 라우팅 |
| `lib/services/quiz_session_repository.dart` | 개발용 클라이언트 트랜잭션 |
| `lib/services/quiz_functions_repository.dart` | 배포용 Callable 래퍼 |
| `functions/index.js` | 서버 채점·기록 (Admin SDK) |
| `firestore.rules` | **개발** Rules (클라이언트 quiz write 허용) |
| `firestore.rules.production` | **프로덕션** Rules (quiz write Functions 전용) |
| `scripts/deploy_firestore_rules.mjs` | Rules 배포 (`--production` 플래그) |

---

## 롤백 (개발 모드로 되돌리기)

1. `QuizBackendConfig.submitBackend` → `clientTransaction`
2. `node scripts/deploy_firestore_rules.mjs` (개발 Rules 재배포)
3. 앱 재배포

Functions는 Blaze에서도 그대로 두어도 무방 (미호출 시 비용 없음).

---

## 보안 메모

- ~~`users` 문서에 `allow read, write: if uid == auth.uid`가 있어 클라이언트가 energy를 직접 수정할 수 있다.~~
  `firestore.rules.production`의 `users/{uid}` `update`에 **필드별 제한**을 추가했다 —
  energy/streak/seeds/ownedShopItemIds/studyGuardCount 등은 `request.resource.data.diff(resource.data).affectedKeys().hasAny([...])`로
  막아서 Functions(Admin SDK, `submitAnswer`·`completeSession`·`purchaseShopItem`)만 쓸 수 있다.
  상점 쪽 상세: [shop-production-deployment.md](./shop-production-deployment.md)
- (개발 Rules `firestore.rules`는 그대로 블랭킷 허용 — 클라이언트 트랜잭션이 이 필드들을 직접 쓰기 때문.)
- `startSession`을 Callable로 옮기면 energy 선차감·출제 로직도 서버에서 통제 가능 (추후).

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-08-30 | Blaze 미사용 개발 — 클라이언트 트랜잭션 + 전환 config·프로덕션 Rules 초안 |
