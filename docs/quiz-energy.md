# 퀴즈 · 에너지

관련 코드: `lib/data/quiz_data.dart`, `lib/services/quiz_service.dart`, `lib/screens/quiz/`

## 핵심 규칙

| 항목 | 값 |
|------|-----:|
| 세션당 문제 수 | 10 |
| 문제 풀 `allQuestions` | 15 |
| 정답 XP | +10 |
| 오답 XP | +2 |
| 최대 에너지 | 100 |
| 문제 1개당 에너지 | −5 (잠정, 변동 가능) |
| 세션 시작 최소 에너지 | **50** (10×5) |
| 일일 학습 횟수 제한 | **없음** (에너지만 있으면 반복) |
| 에너지 회복 | 날짜가 바뀌면 100으로 리셋 |

## 출제

`QuizData.dailyQuestions(date)`:

1. 시드 = `day + month * 31`  
2. `id.hashCode + seed`로 정렬  
3. 상위 10문항  

같은 날이면 같은 세트.  
카테고리: 용돈·저축·주식·보험·세금·신용 (`QuizCategory`).  
유형: OX / 4지선다.

## 세션 진행 (`QuizScreen`)

1. 보기 선택  
2. **정답 제출** → `QuizService.consumeEnergyForQuestion` (−5, 즉시 저장)  
3. 정·오답 UI + XP 배너  
4. 풀이확인 / 다음문제  
5. 마지막 문제 → `completeSession` → `QuizResultScreen`  

에너지가 부족하면 제출 시 스낵바 후 진행 중단.

### UI

- **객관식:** MC1 스타일 (중앙 햄스터 + 옵션 버튼) — `quiz_widgets.dart`  
- **OX:** 짝수 인덱스 → 가로 카드, 홀수 → 세로 버튼  

## 세션 완료 (`completeSession`)

- XP·카테고리 통계·`LearningRecord` 추가  
- **Streak:** `todayQuizCompleted`가 false일 때만 (하루 첫 세션)  
  - 어제 완료 → +1  
  - 그 외 → 1  
- 햄스터 해금 검사 후 `saveProfile`

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

- 에너지 숫자 + `에너지 n / 100` 진행 바  
- 버튼: `학습 시작` (에너지 ≥ 50) / `에너지 부족`  
- 부족 시 스낵바로 필요량(50)·현재량 안내  

## 뉴스 퀴즈와의 관계

일일/에너지 세션(**10문제**)과 **별개**로, 기사 단위 퀴즈(LLM)를 붙일 예정.  
→ [roadmap.md](./roadmap.md), [news.md](./news.md)
