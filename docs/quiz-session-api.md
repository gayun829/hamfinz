# 퀴즈 세션 API (startSession · submitAnswer · completeSession)

Firestore `quizQuestions` 풀 기반 **유저별 10문항** 학습 세션.  
§2 출제 · §3 제출·채점·기록.

관련 스키마: [database/backend-schema.md](./database/backend-schema.md) §3 · `mastered`

---

## 개요

| 단계 | 진입점 | 구현 |
|------|--------|------|
| **출제** | `QuizService.startSession(profile)` | `QuizSessionRepository.startSession` (클라이언트) |
| **오답 복습** | `QuizService.startReviewSession(profile)` | `QuizSessionRepository.startReviewSession` (클라이언트) |
| **제출·채점** | `QuizService.submitAnswer(...)` | `QuizSessionRepository.submitAnswer` (클라이언트 트랜잭션) |
| **세션 완료** | `QuizService.completeSession(...)` | `QuizSessionRepository.completeSession` (클라이언트 트랜잭션) |

> **개발(현재):** Blaze 없이 동작 — `QuizBackendConfig.submitBackend = clientTransaction` + `firestore.rules`  
> **배포(추후):** [quiz-production-deployment.md](./quiz-production-deployment.md) 체크리스트

| 모델 | 파일 |
|------|------|
| `QuizSession`, `QuizQuestionLearning`, `SubmitAnswerResult` | `lib/models/quiz_session.dart` |
| Callable (배포용, 현재 미사용) | `lib/services/quiz_functions_repository.dart` |

---

## 1. startSession (출제)

```
1. Auth uid + energy >= 50
2. mastered id 조회 → 제외
3. interestCategories별 quizQuestions 쿼리 (limit 200)
4. 10문항 선정 → users/{uid}/sessions/{sessionId} 생성 (inProgress)
5. QuizQuestionLearning 반환 (correctIndex 없음)
```

고유 오답이 10개를 넘으면 홈은 복습 화면으로 바뀌고, **오늘의 학습**은 `startReviewSession`을 탄다.

```
1. Auth uid + energy >= 50
2. users/{uid}/incorrectQuestions 조회 후 최대 10문항 선정
3. users/{uid}/sessions/{sessionId} 생성 (`source: reviewSession`)
4. QuizQuestionLearning 반환 (correctIndex 없음)
```

---

## 2. submitAnswer (제출 · 채점)

**구현:** `QuizSessionRepository.submitAnswer` — Firestore 트랜잭션  
(배포 시 동일 로직이 Cloud Function `submitAnswer` · region `asia-northeast3`)

### 요청

```json
{
  "sessionId": "...",
  "questionId": "allowance_0001",
  "selectedIndex": 0
}
```

### 서버 처리 (트랜잭션)

1. 세션 `inProgress` · questionId ∈ `questionIds` · 미제출 확인
2. `quizQuestions/{id}.correctIndex` 와 **서버 비교**
3. `users.energy -= 5`
4. `sessions/.../answers/{questionId}` 저장 (`isCorrect`, `categoryId`, …)
5. 정답 시 `users/.../mastered/{questionId}` upsert
   - 오답 목록에 있던 문제면 `incorrectQuestions/{questionId}` 삭제
   - `users.incorrectQuestionCount`를 1 감소 (0 미만으로 내려가지 않음)
6. 오답 시 `users/.../incorrectQuestions/{questionId}` upsert
   - 최초 오답인 문제만 `users.incorrectQuestionCount`를 1 증가
   - 반복 오답은 `wrongCount`와 최근 오답 정보만 갱신

### 응답

```json
{
  "isCorrect": true,
  "correctIndex": 0,
  "energyRemaining": 45
}
```

클라이언트는 **제출 후에만** `correctIndex`를 받아 결과 UI에 사용.

---

## 3. completeSession (세션 완료)

**구현:** `QuizSessionRepository.completeSession` — Firestore 트랜잭션  
(배포 시 Cloud Function `completeSession`)

### 요청

```json
{ "sessionId": "..." }
```

### 서버 처리

1. `answers` subcollection 전부 존재 확인 (10문항)
2. 씨앗 (정답 × 5) · `categoryStats` (한글 label 키, 에너지 세션이면 `completedSessions + 1`)
3. streak · `learningDates` 갱신
3-1. 실제 소모량 이내에서 에너지 최대 `+20` (최대 100까지)
     → 채워진 양을 `energyEarned`로 반환
4. `sessions/{id}` → `status: completed`
5. `users/{uid}` 갱신 (Admin SDK — 클라이언트 energy/seeds 직접 쓰기 불필요)

### 응답 → `QuizSessionResult`

`energyRemaining`은 보상을 더한 뒤 값이고, `energyEarned`는 이번에 실제로
채워진 양이다 (퀴즈_결과보기창 오른쪽 수치).

앱은 `AuthService.getCurrentUser()`로 프로필 재동기화.

---

## Firestore Rules

| 경로 | 클라이언트 (개발) |
|------|-------------------|
| `quizQuestions` | read (`isActive`) |
| `mastered` | read · create · update |
| `incorrectQuestions` | read · create · update · delete |
| `sessions` | read · create · update (`inProgress`만) |
| `sessions/.../answers` | read · create |
| `users` | read · write (본인) — energy/seeds 등 트랜잭션 갱신 |

### 배포 (Blaze 후)

```bash
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes
```

배포 시 Rules에서 `mastered`/`answers` 클라이언트 write를 막고 Functions Admin SDK로 전환.

---

## UI 흐름 (`QuizScreen`)

```
startSession (로딩)
  → 문제 표시 (correctIndex 없음)
  → [정답 제출] → submitAnswer (Firestore 트랜잭션)
  → 정·오답 UI (채점 결과 correctIndex)
  → [다음] × 9
  → 마지막 문제 → completeSession
  → QuizCompleteScreen (터치)
  → QuizStreakScreen (다음으로)
  → QuizRewardScreen (보상획득) → 홈
```

---

## 상수 (Functions · 앱 공통)

| 항목 | 값 |
|------|-----|
| `ENERGY_PER_QUESTION` | 5 |
| `SESSION_ENERGY_COST` | 50 |
| `XP_CORRECT` / `XP_WRONG` | 10 / 2 |
| `SEEDS_PER_CORRECT` | 5 |

---

## 변경 파일

| 파일 | § |
|------|---|
| `lib/config/quiz_backend_config.dart` | **개발/배포 전환 스위치** |
| `lib/services/quiz_session_repository.dart` | startSession · submitAnswer · completeSession (클라이언트) |
| `functions/index.js` | 배포용 Callable (동일 로직 참고) |
| `lib/services/quiz_functions_repository.dart` | 배포용 Callable 래퍼 |
| `lib/services/quiz_service.dart` | Facade |
| `lib/screens/quiz/quiz_screen.dart` | 제출 UI |
| `lib/models/quiz_session.dart` | correctIndex 클라이언트 제거 |

---

## 추후

- [ ] Blaze 전환 후 Functions 배포 · Rules에서 클라이언트 quiz write 제한
- [ ] `startSession` callable 이전 (선택)
- [ ] Emulator 로컬 테스트 (`firebase emulators:start`)
