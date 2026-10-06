# 퀴즈 · 에너지

관련 코드: `lib/data/quiz_data.dart` (상수), `lib/services/quiz_session_repository.dart`, `lib/services/quiz_service.dart`, `lib/screens/quiz/`

## 핵심 규칙

| 항목 | 값 |
|------|-----:|
| 세션당 문제 수 | 10 |
| 문제 풀 | Firestore `quizQuestions` (`isActive == true`) |
| 정답당 씨앗 | +5 |
| 에너지 한도 | **없음** |
| 문제 1개당 에너지 | −5 (잠정, 변동 가능) |
| 세션 완료 에너지 보상 | 실제 소모량 이내에서 **최대 +20** |
| 세션 시작 최소 에너지 | **50** (10×5) |
| 일일 학습 횟수 제한 | **없음** (에너지만 있으면 반복) |
| 매일 지급 | 그날 **첫 접속** 때 +100 (접속하지 않은 날 몫은 쌓이지 않음) |
| 추가 획득 | 상점 에너지팩 구매 (씨앗) |

매일 지급은 **접속할 때 저장한다**. `AuthService.getCurrentUser`가 그날 첫 조회에서
`lastEnergyResetDate`가 오늘이 아니면 `energy += 100`, `lastEnergyResetDate = 오늘`을
저장한다 (개발: 클라이언트 트랜잭션, 배포: Cloud Function `claimDailyEnergy`).

그 저장이 실패해도 한 날에 한 번만 지급되도록, 에너지를 쓰는 쪽
(`submitAnswer`·`completeSession`·`abandonSession`·`ShopPurchaseRepository`·
Functions `resolveEnergy`)도 같은 규칙(`lib/utils/energy_reset.dart`
`resolveDailyEnergy`)으로 계산하고 `energy`와 `lastEnergyResetDate`를 **같이** 쓴다.

## 출제

`QuizService.startSession` → `QuizSessionRepository.startSession`:

1. `profile.energy >= 50` 확인  
2. `users/{uid}/mastered`에 있는 id **제외**  
3. `interestCategories`에서 **활성 카테고리 1개** 기준으로 `quizQuestions` 쿼리 (카테고리당 최대 200건)  
4. 난이도·랜덤으로 **10문항** 선정 → `users/{uid}/sessions/{sessionId}` (`inProgress`)  
5. `QuizQuestionLearning` 반환 — **`correctIndex` 없음**

같은 유저라도 세션마다 문제 구성이 달라질 수 있다.  
오답 문제는 `mastered`에 기록되지 않아 **다음 세션에 재출제**될 수 있다.

홈 맵의 1~200 숫자는 **출제 step 표기**일 뿐, 숫자마다 고정 문제가 있지 않다.  
한 세션(10문제)을 완료하면 활성 카테고리 `categoryStats.completedSessions`가 1 증가하고, 홈에는 `completedSessions + 1`과 그보다 2 큰 수(예: 1과 3)를 보여 준다. 단계당 문제 풀 200개 × 10단계 = 최대 200 step.

자세한 API: [quiz-session-api.md](./quiz-session-api.md) §1

## 세션 진행 (`QuizScreen`)

1. 보기 선택  
2. **정답 제출** → `QuizService.submitAnswer`  
   - Firestore 트랜잭션(개발) 또는 Cloud Functions(배포)  
   - `selectedIndex` vs DB `correctIndex` **서버 채점**  
   - `users.energy -= 5`  
   - 정답 시 `mastered/{questionId}` upsert  
   - 오답 시 `incorrectQuestions/{questionId}` upsert  
   - 복습 세션에서 정답이면 `incorrectQuestions/{questionId}` 삭제 + 카운트 −1  
4. 정·오답 UI  
4. 풀이확인 / 다음문제  
5. 마지막 문제 → `completeSession` → 축하창 → 연속학습일 → 결과보기창  

에너지가 부족하면 제출 시 스낵바 후 진행 중단.

### UI

- **객관식:** MC1 스타일 (중앙 햄스터 + 옵션 버튼) — `quiz_widgets.dart`  
- **OX:** 짝수 인덱스 → 가로 카드, 홀수 → 세로 버튼  

## 세션 완료 (`completeSession`)

- 씨앗(`정답 수 × 5`) · 카테고리 통계 · `learningDates` · streak 갱신  
- **에너지 보상:** 실제 소모량 이내에서 최대 `+20`
  (`QuizData.sessionCompleteEnergyReward`). 1문제 복습에서 5를 썼다면 5만
  돌려준다. 한도가 없으므로 보상 전체가 `energyEarned`로 내려간다.
  Functions 쪽 `ENERGY_SESSION_COMPLETE_REWARD`와 값을 맞춰야 한다.  
- **Streak:** `todayQuizCompleted`가 false일 때만 (하루 첫 세션)  
  - 어제 완료 → +1  
  - 그 외 → 1  
- Firestore `users/{uid}` 반영 후 프로필 재조회

자세한 API: [quiz-session-api.md](./quiz-session-api.md) §3

## 홈에서의 표시

- 에너지 · 씨앗 · streak 숫자 (프로필 / Firestore `users.energy`)  
- **오늘의 학습** 버튼 (에너지 ≥ 50) / **에너지 부족**  
- 부족 시 스낵Bar로 필요량(50)·현재량 안내  

## 뉴스 퀴즈와의 관계

일일/에너지 세션(**10문제**)과 **별개**로, 기사 단위 퀴즈를 붙일 예정.  
→ [roadmap.md](./roadmap.md), [news.md](./news.md)
