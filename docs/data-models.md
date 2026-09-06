# 데이터 모델 · 저장소

## SharedPreferences 키

| 키 | 타입 | 설명 |
|----|------|------|
| `finquiz_users` | JSON object | 이메일별 계정 |
| `finquiz_session` | string | 로그인 중 이메일 |

구현: `lib/services/storage_service.dart`

## 계정 JSON 구조

```json
{
  "user@example.com": {
    "passwordHash": "...",
    "salt": "...",
    "nickname": "닉네임",
    "profile": {
      "xp": 0,
      "streak": 0,
      "lastQuizCompletedDate": "2026-08-21",
      "todayQuizCompleted": false,
      "energy": 100,
      "lastEnergyResetDate": "2026-08-21",
      "unlockedHamsterIds": ["hamster_basic"],
      "selectedHamsterId": "hamster_basic",
      "learningHistory": [],
      "categoryStats": {},
      "interestCategories": ["saving", "credit"],
      "seeds": 0,
      "ownedShopItemIds": []
    }
  }
}
```

## UserProfile

파일: `lib/models/user_profile.dart`

| 필드 | 설명 |
|------|------|
| `email`, `nickname` | 식별 |
| `xp` | 경험치 → 레벨 |
| `streak` | 연속 학습 일수 |
| `lastQuizCompletedDate` | 마지막 세션 완료일 `yyyy-MM-dd` |
| `todayQuizCompleted` | 오늘 첫 세션 완료 여부 (streak용) |
| `energy` | 0~100 |
| `lastEnergyResetDate` | 에너지 일일 회복 기준일 |
| `unlockedHamsterIds` | 해금된 햄스터 |
| `selectedHamsterId` | 선택 중 햄스터 |
| `learningHistory` | `LearningRecord` 목록 (최신 앞) |
| `categoryStats` | 카테고리 label → `CategoryStat` |
| `interestCategories` | 관심 카테고리 id 목록 |
| `seeds` | 상점 해바라기씨 잔액 |
| `ownedShopItemIds` | 구매한 상점 아이템 id |

### LearningRecord

`date`, `correctCount`, `totalCount`, `xpEarned`

### CategoryStat

`correct`, `total` → `accuracy`

### LevelUtils

- `xpPerLevel = 100`, `maxLevel = 10`  
- `levelFromXp`, `progressInLevel`, `titleForLevel`

## Quiz 모델

파일: `lib/models/quiz_question.dart`

| 타입 | 내용 |
|------|------|
| `QuizType` | `ox`, `multipleChoice` |
| `QuizCategory` | allowance, saving, stock, insurance, tax, credit (+ label) |
| `QuizQuestion` | id, type, category, question, options, correctIndex, explanation |
| `QuizAnswer` | questionId, selectedIndex, isCorrect |
| `QuizSessionResult` | answers, xpEarned, leveledUp, levels, unlockedItems, newStreak |

## 정적 데이터

| 파일 | 내용 |
|------|------|
| `lib/data/quiz_data.dart` | 세션 상수 (문항 수, XP, 에너지, 씨앗) — 문제 본문은 Firestore |
| `lib/data/hamster_data.dart` | 햄스터 컬렉션 |
| `lib/data/interest_categories.dart` | 관심 카테고리 마스터 |
| `lib/data/legal_documents.dart` | 약관·개인정보 임시 본문 |

## NewsItem

`lib/services/news_service.dart` — `title`, `url` (본문 없음)

## 로드 시 보정 (`AuthService._profileFromJson`)

- streak: 마지막 완료일이 어제·오늘이 아니면 0  
- `todayQuizCompleted`: 오늘이 아니면 false  
- 에너지: `lastEnergyResetDate != today`이면 100으로 회복 후 저장  
