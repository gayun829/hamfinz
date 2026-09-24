# 데이터 모델 · 저장소

## Firestore 사용자 문서

```json
{
  "nickname": "닉네임",
  "streak": 0,
  "lastQuizCompletedDate": "2026-08-21",
  "todayQuizCompleted": false,
  "energy": 100,
  "lastEnergyResetDate": "2026-08-21",
  "selectedHamsterId": "hamster_basic",
  "learningDates": [],
  "categoryStats": {},
  "interestCategories": ["saving"],
  "learningStage": 1,
  "incorrectQuestionCounts": {},
  "incorrectQuestionCount": 0,
  "seeds": 0,
  "ownedShopItemIds": []
}
```

## UserProfile

파일: `lib/models/user_profile.dart`

| 필드 | 설명 |
|------|------|
| `email`, `nickname` | 식별 |
| `streak` | 연속 학습 일수 |
| `lastQuizCompletedDate` | 마지막 세션 완료일 `yyyy-MM-dd` |
| `todayQuizCompleted` | 오늘 첫 세션 완료 여부 (streak용) |
| `energy` | 0~100 |
| `lastEnergyResetDate` | 에너지 일일 회복 기준일 |
| `selectedHamsterId` | 선택 중 햄스터 |
| `learningDates` | 최근 32일의 학습 완료일 |
| `categoryStats` | 카테고리 label → `CategoryStat` |
| `interestCategories` | 관심 카테고리 id 목록 |
| `learningStage` | 현재 학습과정(초급·중급·고급) |
| `incorrectQuestionCounts` | 카테고리 id → `incorrectQuestions`의 고유 문제 수. **활성 카테고리** 값이 10 초과면 복습 홈 |
| `incorrectQuestionCount` | `incorrectQuestionCounts`의 합(파생 값). 복습 판단에는 쓰지 않는다 |
| `seeds` | 상점 해바라기씨 잔액 |
| `ownedShopItemIds` | 구매한 상점 아이템 id |

### CategoryStat

`correct`, `total`, `completedSessions` → `accuracy`  
에너지 학습 세션을 끝낼 때마다 해당 카테고리 `completedSessions`가 1 늘어난다. 홈 맵 숫자는 `completedSessions + 1` (1~200). 복습 세션은 세지 않는다.

## Quiz 모델

파일: `lib/models/quiz_question.dart`

| 타입 | 내용 |
|------|------|
| `QuizType` | `ox`, `multipleChoice` |
| `QuizCategory` | allowance, saving, stock, insurance, tax, credit (+ label) |
| `QuizQuestion` | id, type, category, question, options, correctIndex, explanation |
| `QuizAnswer` | questionId, selectedIndex, isCorrect |
| `QuizSessionResult` | answers, seedsEarned, newStreak, energyRemaining, energyEarned, advancedLearningStage |

오답 상세는 `users/{uid}/incorrectQuestions/{questionId}`에 저장한다. 문제 id,
카테고리, 난이도, 누적 오답 횟수와 최초·최근 오답 시각을 포함하며 같은 문제는
문서 하나로 합친다. 복습 세션에서 맞추면 문서를 삭제하고 그 문제 카테고리의
`incorrectQuestionCounts` 값(과 합계)을 줄인다. 복습 세션은 활성 카테고리의 오답만
출제한다. `categoryId`가 없는 예전 문서는 `allowance`로 본다.

`incorrectQuestionCounts`가 없는 예전 계정은 `incorrectQuestions`를 세어 채운다
(지연 백필). 개발 모드는 클라이언트가 트랜잭션으로 저장하고, 프로덕션 규칙은 이
필드의 클라이언트 쓰기를 막으므로 첫 `submitAnswer`에서 Functions가 저장한다.
그 전까지 앱은 집계값을 메모리에 들고 화면에만 쓴다.

## 정적 데이터

| 파일 | 내용 |
|------|------|
| `lib/data/quiz_data.dart` | 세션 상수 (문항 수, 에너지, 씨앗) — 문제 본문은 Firestore |
| `lib/data/hamster_data.dart` | 햄스터 컬렉션 |
| `lib/data/interest_categories.dart` | 관심 카테고리 마스터 |
| `lib/data/legal_documents.dart` | 약관·개인정보 임시 본문 |

## NewsItem

`lib/services/news_service.dart` — `title`, `url` (본문 없음)

## 로드 시 보정 (`AuthService._profileFromJson`)

- streak: 마지막 완료일이 어제·오늘이 아니면 0  
- `todayQuizCompleted`: 오늘이 아니면 false  
- 에너지: `lastEnergyResetDate != today`이면 100으로 회복 후 저장  
