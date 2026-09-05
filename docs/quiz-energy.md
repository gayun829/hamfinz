# 퀴즈 · 에너지

관련 코드: `lib/data/quiz_data.dart` (상수), `lib/services/quiz_session_repository.dart`, `lib/services/quiz_service.dart`, `lib/screens/quiz/`

## 핵심 규칙

| 항목 | 값 |
|------|-----:|
| 세션당 문제 수 | 10 |
| 문제 풀 | Firestore `quizQuestions` (`isActive == true`) |
| 정답 XP | +10 |
| 오답 XP | +2 |
| 정답당 씨앗 | +5 |
| 최대 에너지 | 100 |
| 문제 1개당 에너지 | −5 (잠정, 변동 가능) |
| 세션 시작 최소 에너지 | **50** (10×5) |
| 일일 학습 횟수 제한 | **없음** (에너지만 있으면 반복) |
| 에너지 회복 | 날짜가 바뀌면 100으로 리셋 |

## 출제

`QuizService.startSession` → `QuizSessionRepository.startSession`:

1. `profile.energy >= 50` 확인  
2. `users/{uid}/mastered`에 있는 id **제외**  
3. `interestCategories`에서 **활성 카테고리 1개** 기준으로 `quizQuestions` 쿼리 (카테고리당 최대 200건)  
4. 난이도·랜덤으로 **10문항** 선정 → `users/{uid}/sessions/{sessionId}` (`inProgress`)  
5. `QuizQuestionLearning` 반환 — **`correctIndex` 없음**

같은 유저라도 세션마다 문제 구성이 달라질 수 있다.  
오답 문제는 `mastered`에 기록되지 않아 **다음 세션에 재출제**될 수 있다.

자세한 API: [quiz-session-api.md](./quiz-session-api.md) §1

## 세션 진행 (`QuizScreen`)

1. 보기 선택  
2. **정답 제출** → `QuizService.submitAnswer`  
   - Firestore 트랜잭션(개발) 또는 Cloud Functions(배포)  
   - `selectedIndex` vs DB `correctIndex` **서버 채점**  
   - `users.energy -= 5`  
   - 정답 시 `mastered/{questionId}` upsert  
3. 정·오답 UI + XP 배너  
4. 풀이확인 / 다음문제  
5. 마지막 문제 → `completeSession` → `QuizResultScreen`  

에너지가 부족하면 제출 시 스낵바 후 진행 중단.

### UI

- **객관식:** MC1 스타일 (중앙 햄스터 + 옵션 버튼) — `quiz_widgets.dart`  
- **OX:** 짝수 인덱스 → 가로 카드, 홀수 → 세로 버튼  

## 세션 완료 (`completeSession`)

- XP · 씨앗(`정답 수 × 5`) · 카테고리 통계 · `LearningRecord` · streak 갱신  
- **Streak:** `todayQuizCompleted`가 false일 때만 (하루 첫 세션)  
  - 어제 완료 → +1  
  - 그 외 → 1  
- Firestore `users/{uid}` 반영 후 프로필 재조회

자세한 API: [quiz-session-api.md](./quiz-session-api.md) §3

### 햄스터 해금

| ID | 조건 |
|----|------|
| `hamster_basic` | 가입 시 |
| `hamster_study` | 학습 기록 1건 이상 |
| `hamster_streak` | streak ≥ 3 |
| `hamster_level3` | level ≥ 3 |
| `hamster_level5` | level ≥ 5 |
| `hamster_master` | level ≥ 10 |

정의: `lib/data/hamster_data.dart`

## 레벨

`LevelUtils` (`user_profile.dart`):

- 100 XP = 1레벨, 최대 Lv.10  
- 칭호: 금융 새싹 … 금융 고수  

## 홈에서의 표시

- 에너지 · 씨앗 · streak 숫자 (프로필 / Firestore `users.energy`)  
- **오늘의 학습** 버튼 (에너지 ≥ 50) / **에너지 부족**  
- 부족 시 스낵Bar로 필요량(50)·현재량 안내  

## 뉴스 퀴즈와의 관계

일일/에너지 세션(**10문제**)과 **별개**로, 기사 단위 퀴즈를 붙일 예정.  
→ [roadmap.md](./roadmap.md), [news.md](./news.md)
