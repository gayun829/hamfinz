# 퀴즈 세션 API (startSession · submitAnswer · completeSession)

Firestore `quizQuestions` 풀 기반 **유저별 10문항** 학습 세션.  
§2 출제 · §3 제출·채점·기록.

관련 스키마: [database/backend-schema.md](./database/backend-schema.md) §3 · `mastered`

---

## 개요

| 단계 | 진입점 | 구현 |
|------|--------|------|
| **출제** | `QuizService.startSession(profile)` | `lib/services/quiz_session_repository.dart` (클라이언트) |
| **제출·채점** | `QuizService.submitAnswer(...)` | Cloud Function `submitAnswer` |
| **세션 완료** | `QuizService.completeSession(...)` | Cloud Function `completeSession` |

| 모델 | 파일 |
|------|------|
| `QuizSession`, `QuizQuestionLearning`, `SubmitAnswerResult` | `lib/models/quiz_session.dart` |
| Callable 래퍼 | `lib/services/quiz_functions_repository.dart` |

---

## 1. startSession (출제)

```
1. Auth uid + energy >= 50
2. mastered id 조회 → 제외
3. interestCategories별 quizQuestions 쿼리 (limit 200)
4. 10문항 선정 → users/{uid}/sessions/{sessionId} 생성 (inProgress)
5. QuizQuestionLearning 반환 (correctIndex 없음)
```

---

## 2. submitAnswer (제출 · 채점)

**Cloud Function** `submitAnswer` · region `asia-northeast3`

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

**Cloud Function** `completeSession`

### 요청

```json
{ "sessionId": "..." }
```

### 서버 처리

1. `answers` subcollection 전부 존재 확인 (10문항)
2. XP (+10 / +2) · 씨앗 (정답 × 5) · `categoryStats` (한글 label 키)
3. streak · `learningHistory` · 햄스터 해금
4. `sessions/{id}` → `status: completed`
5. `users/{uid}` 갱신 (Admin SDK — 클라이언트 xp/energy 직접 쓰기 불필요)

### 응답 → `QuizSessionResult`

앱은 `AuthService.getCurrentUser()`로 프로필 재동기화.

---

## Firestore Rules · Functions

| 경로 | 클라이언트 |
|------|-----------|
| `quizQuestions` | read (`isActive`) |
| `mastered` | read |
| `sessions` | read · create (inProgress) |
| `sessions/.../answers` | read · **write: Functions only** |
| `mastered` write | **Functions only** |
| `users` xp/energy/seeds | **completeSession**이 서버 갱신 |

### 배포

```bash
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Functions 미배포 시 앱 제출 단계에서 오류 (SnackBar 안내).

---

## UI 흐름 (`QuizScreen`)

```
startSession (로딩)
  → 문제 표시 (correctIndex 없음)
  → [정답 제출] → submitAnswer (서버 채점)
  → 정·오답 UI (서버가 준 correctIndex)
  → [다음] × 9
  → [결과 보기] → completeSession → QuizResultScreen
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
| `functions/index.js` | submitAnswer · completeSession |
| `lib/services/quiz_functions_repository.dart` | Callable |
| `lib/services/quiz_service.dart` | Facade |
| `lib/screens/quiz/quiz_screen.dart` | 서버 제출 UI |
| `lib/models/quiz_session.dart` | correctIndex 클라이언트 제거 |

---

## 추후

- [ ] `startSession` callable 이전 (선택)
- [ ] `users` Rules — xp/energy 클라이언트 write 차단 강화
- [ ] Emulator 로컬 테스트 (`firebase emulators:start`)
