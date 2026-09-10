# Firestore 스키마 (임시 초안)

백엔드는 **Cloud Firestore + Firebase Authentication**을 전제로 한다.  
현재 앱의 SharedPreferences 구조를 컬렉션/문서로 옮긴 초안이다.

> 확정 전. 필드명·서브컬렉션 깊이는 구현하면서 바꿀 수 있다.

관련: [data-models.md](../data-models.md), [quiz-energy.md](../quiz-energy.md), [roadmap.md](../roadmap.md)

---

## 스택

| 구성                       | 역할                                                |
| -------------------------- | --------------------------------------------------- |
| **Firebase Auth**          | 이메일/비번, 이후 Google·Apple·Kakao                |
| **Cloud Firestore**        | 프로필, 퀴즈, 뉴스 캐시, 학습 기록                  |
| **Cloud Functions** (권장) | 에너지 차감·세션 완료를 트랜잭션으로, 뉴스 LLM 생성 |
| **클라이언트 직접 쓰기**   | 관심 카테고리 정도만. XP·에너지는 Functions 권장    |

비밀번호 해시(`passwordHash`/`salt`)는 Firestore에 **넣지 않는다**. Auth가 담당한다.

로컬 키 `finquiz_users` / `finquiz_session` → Auth UID + `users/{uid}`.

---

## 설계 원칙

| 원칙                       | Firestore에서                                                  |
| -------------------------- | -------------------------------------------------------------- |
| 앱 규칙 유지               | 에너지 100, 문제당 −5, 세션 10문제, XP 10/2 (에너지 수치 잠정) |
| 레벨은 저장하지 않음       | `xp`만. 레벨 = `min(xp ~/ 100 + 1, 10)`                        |
| 작은 목록은 배열           | 관심 카테고리, 해금 햄스터 id (개수 고정·적음)                 |
| 늘어나는 기록은 서브컬렉션 | 퀴즈 세션, 답안, 뉴스 퀴즈 기록                                |
| 마스터는 탑레벨            | `categories`, `hamsters`, `quizQuestions`, `legalDocuments`    |
| 문서 ID                    | 의미 있는 id면 그대로 (`saving`, `q1`, `hamster_basic`)        |

### 게임 상수 (앱·Functions 공유)

```
MAX_ENERGY = 100
ENERGY_PER_QUESTION = 5
QUESTIONS_PER_SESSION = 10
SESSION_ENERGY_COST = 50
XP_CORRECT = 10
XP_WRONG = 2
XP_PER_LEVEL = 100
MAX_LEVEL = 10
```

---

## 컬렉션 트리

```
categories/{categoryId}
hamsters/{hamsterId}
quizQuestions/{questionId}
legalDocuments/{docType}_{version}

users/{uid}                          # Auth uid
  ├── mastered/{questionId}
  ├── incorrectQuestions/{questionId}
  └── sessions/{sessionId}
        └── answers/{questionId}

newsArticles/{urlHash}
newsQuizPacks/{urlHash}
  └── questions/{autoId}

newsQuizSessions/{sessionId}         # 또는 users/{uid}/newsSessions/{id}
  └── answers/{autoId}

bookmarks/{uid}_{urlHash}            # 예정
feedbacks/{autoId}                   # 예정
announcements/{autoId}               # 예정
```

```mermaid
flowchart TB
  auth[Firebase Auth]
  auth --> users["users/{uid}"]
  users --> sessions["sessions/{sessionId}"]
  sessions --> answers["answers/{questionId}"]
  users --> mastered["mastered/{questionId}"]
  users --> incorrect["incorrectQuestions/{questionId}"]

  cats[categories]
  ham[hamsters]
  qs[quizQuestions]
  legal[legalDocuments]

  news[newsArticles]
  packs[newsQuizPacks]
  packs --> nq[questions]
```

---

## 1. 마스터 (읽기 공개)

### `categories/{id}`

id: `allowance` | `saving` | `stock` | `insurance` | `tax` | `credit`

```json
{
  "name": "저축&예금",
  "quizLabel": "저축",
  "emoji": "🏦",
  "description": "차곡차곡 모으기",
  "newsQuery": "예금 OR 적금 OR 저축 금리 when:7d",
  "sortOrder": 1
}
```

### `hamsters/{id}`

```json
{
  "name": "기본 햄스터",
  "emoji": "🐹",
  "unlockDescription": "회원가입 시 기본 제공",
  "unlockType": "signup",
  "unlockValue": null
}
```

| id               | unlockType      | unlockValue |
| ---------------- | --------------- | ----------- |
| `hamster_basic`  | `signup`        | —           |
| `hamster_study`  | `first_session` | —           |
| `hamster_streak` | `streak`        | 3           |
| `hamster_level3` | `level`         | 3           |
| `hamster_level5` | `level`         | 5           |
| `hamster_master` | `level`         | 10          |

### `quizQuestions/{questionId}`

문서 id 예: `q0001`, `q0002` … (의미 있는 id 권장)

| 필드           | 타입        | 설명                                                  |
| -------------- | ----------- | ----------------------------------------------------- | ---------------- | ------- | ----------- | ----- | -------- |
| `categoryId`   | string      | `allowance`                                           | `saving`         | `stock` | `insurance` | `tax` | `credit` |
| `difficulty`   | number      | **1~10** (클수록 어려움)                              |
| `type`         | string      | `ox`                                                  | `multipleChoice` |
| `question`     | string      | 지문                                                  |
| `options`      | arraystring | 보기 (`ox`: `["O","X"]`, 4지선다: 4개)                |
| `correctIndex` | number      | 정답 보기 인덱스 (0부터)                              |
| `explanation`  | string      | 해설                                                  |
| `isActive`     | boolean     | `true` = 출제 풀 포함 · `false` = soft delete(비공개) |

**CRUD (현재):** Firebase Console / Admin SDK. 클라이언트 `write: false` (Rules).

**시드 예시** (`quizQuestions/q0001`):

```json
{
  "categoryId": "allowance",
  "difficulty": 1,
  "type": "ox",
  "question": "예산은 돈을 쓰기 전에 수입과 지출 계획을 세운 것을 뜻한다. (1번째 사례)",
  "options": ["O", "X"],
  "correctIndex": 0,
  "explanation": "예산은 돈을 쓰기 전에 수입과 지출 계획을 세운 것이다.",
  "isActive": true
}
```

`type`: `ox` | `multipleChoice`

### `legalDocuments/{docType}_{version}`

예: `terms_draft-1`, `privacy_draft-1`

```json
{
  "docType": "terms",
  "version": "draft-1",
  "title": "이용약관",
  "body": "...",
  "isCurrent": true,
  "publishedAt": "<timestamp>"
}
```

현재 버전만 쓰려면 `legalDocuments/terms_current`처럼 고정 id를 하나 더 두거나, `isCurrent == true` 쿼리.

---

## 2. 유저

### `users/{uid}`

Auth `uid` = 문서 id. 로컬 `profile` + 닉네임 + 동의 요약을 한 문서에 둔다.  
세션 기록은 서브컬렉션으로 빼서 문서 크기(1MB)를 지킨다.

```json
{
  "email": "user@example.com",
  "nickname": "닉네임",
  "xp": 0,
  "streak": 0,
  "lastQuizCompletedOn": "2026-08-21",
  "energy": 100,
  "energyResetOn": "2026-08-21",
  "selectedHamsterId": "hamster_basic",
  "unlockedHamsterIds": ["hamster_basic"],
  "interestCategoryIds": ["saving", "credit"],
  "categoryStats": {
    "saving": { "correct": 3, "total": 5 },
    "credit": { "correct": 1, "total": 2 }
  },
  "incorrectQuestionCount": 11,
  "consents": {
    "termsVersion": "draft-1",
    "privacyVersion": "draft-1",
    "agreedAt": "<timestamp>"
  },
  "providers": ["password"],
  "status": "active",
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>",
  "withdrawnAt": null
}
```

| 필드                       | 로컬 대응                       | 메모                                    |
| -------------------------- | ------------------------------- | --------------------------------------- |
| `energy` / `energyResetOn` | `energy`, `lastEnergyResetDate` | 날짜 문자열 `yyyy-MM-dd` 또는 Timestamp |
| `lastQuizCompletedOn`      | `lastQuizCompletedDate`         | streak용                                |
| `todayQuizCompleted`       | **저장 안 함**                  | `lastQuizCompletedOn == today`로 계산   |
| `unlockedHamsterIds`       | 배열 (최대 6)                   |                                         |
| `interestCategoryIds`      | 배열 (1~6, 최소 1)              |                                         |
| `categoryStats`            | map                             | 카테고리 6개뿐이라 문서에 포함          |
| `incorrectQuestionCount`   | number                          | 고유 오답 문서 수. 11개부터 복습 홈     |
| `consents`                 | 약관 체크                       | 버전 바뀌면 재동의 필드 추가 가능       |
| `providers`                | 예정 소셜                       | `password`, `google`, `apple`, `kakao`  |

가입 Cloud Function / 클라이언트 최초 쓰기:

- `energy: 100`, `energyResetOn: today`
- `unlockedHamsterIds: ["hamster_basic"]`
- `selectedHamsterId: "hamster_basic"`
- `interestCategoryIds`는 카테고리 선택 화면 이후 갱신

닉네임 중복은 `nicknames/{nicknameLower}` 문서 예약 패턴을 쓴다.

### `nicknames/{nicknameLower}` (선택)

```json
{ "uid": "<auth uid>", "nickname": "닉네임" }
```

중복 확인 트랜잭션용. 탈퇴 시 삭제 여부 정책 추후.

---

## 3. 학습 세션 (에너지 10문제)

로컬 `learningHistory`는 세션 요약만 있었다. Firestore에서는 세션 + 문항 답을 남긴다.

### `users/{uid}/sessions/{sessionId}`

`sessionId`: Auto ID.

```json
{
  "source": "energySession",
  "questionIds": ["q3", "q7", "..."],
  "questionCount": 7,
  "correctCount": 0,
  "xpEarned": 0,
  "energySpent": 0,
  "seedDate": "2026-08-21",
  "status": "inProgress",
  "startedAt": "<timestamp>",
  "completedAt": null
}
```

`source`: `energySession` | `reviewSession`  
`status`: `inProgress` | `completed` | `abandoned`

### `users/{uid}/sessions/{sessionId}/answers/{questionId}`

문서 id = 문제 id. 같은 문제 중복 제출 방지.

```json
{
  "selectedIndex": 1,
  "isCorrect": true,
  "categoryId": "saving",
  "energySpent": 5,
  "answeredAt": "<timestamp>"
}
```

### `users/{uid}/incorrectQuestions/{questionId}`

오답이 제출되는 즉시 생성하거나 갱신한다. 문서 id가 문제 id이므로 같은 문제를
여러 번 틀려도 `incorrectQuestionCount`는 한 번만 증가한다.

```json
{
  "questionId": "q0001",
  "categoryId": "saving",
  "difficulty": 3,
  "wrongCount": 2,
  "lastSelectedIndex": 1,
  "lastSessionId": "<sessionId>",
  "firstWrongAt": "<timestamp>",
  "lastWrongAt": "<timestamp>"
}
```

- `incorrectQuestionCount > 10`이면 해당 티어의 복습 집 홈을 표시한다.
- 복습 세션(`source: reviewSession`)에서 정답을 맞추면 해당 문서를 삭제하고
  `incorrectQuestionCount`를 1 줄인다. 개수가 10 이하가 되면 일반 홈으로 돌아간다.

**쓰기 권장 경로 (Cloud Function)**

1. `startSession`: `energy >= 50` 확인, 세션 문서 생성 (에너지 아직 안 깎음 또는 예약)
2. `submitAnswer`: 트랜잭션으로 `users.energy -= 5`, answers 문서 생성
3. `completeSession`: XP·categoryStats·streak·해금 배열 갱신, `status: completed`

클라이언트가 energy/xp를 직접 쓰면 치트가 되므로 Functions + Admin SDK가 맞다.

---

## 4. 뉴스 · 뉴스 퀴즈 (예정)

에너지 세션과 **다른 컬렉션**. 기사 1건 ↔ 퀴즈 팩 1개.

### `newsArticles/{urlHash}`

```json
{
  "categoryId": "saving",
  "title": "...",
  "url": "https://...",
  "sourceName": "연합뉴스",
  "summary": null,
  "fetchedAt": "<timestamp>",
  "publishedAt": null
}
```

### `newsQuizPacks/{urlHash}`

문서 id를 기사 `urlHash`와 같게 두면 재생성 조회가 쉽다.

```json
{
  "articleId": "<urlHash>",
  "model": "gemini-...",
  "status": "ready",
  "createdAt": "<timestamp>"
}
```

`status`: `pending` | `ready` | `failed`

### `newsQuizPacks/{urlHash}/questions/{autoId}`

```json
{
  "sortOrder": 1,
  "type": "ox",
  "question": "...",
  "options": ["O", "X"],
  "correctIndex": 0,
  "explanation": "..."
}
```

### `users/{uid}/newsSessions/{sessionId}`

```json
{
  "articleId": "<urlHash>",
  "packId": "<urlHash>",
  "correctCount": 0,
  "xpEarned": 0,
  "energySpent": null,
  "status": "completed",
  "startedAt": "<timestamp>",
  "completedAt": "<timestamp>"
}
```

에너지 차감 여부는 미정 → `energySpent`는 null 가능.

### `users/{uid}/bookmarks/{urlHash}` (예정)

```json
{
  "articleId": "<urlHash>",
  "title": "...",
  "url": "...",
  "createdAt": "<timestamp>"
}
```

---

## 5. 기타 예정

### `feedbacks/{autoId}`

```json
{
  "uid": "<auth uid>",
  "message": "...",
  "createdAt": "<timestamp>"
}
```

### `announcements/{autoId}`

```json
{
  "title": "...",
  "body": "...",
  "isPublished": true,
  "publishedAt": "<timestamp>"
}
```

소셜 로그인은 Auth provider만 쓰고, `users.providers` 배열을 갱신하면 된다. 별도 `socialAccounts` 컬렉션은 필수는 아니다.

---

## 6. 친구 (Friends) — 제안 (초안)

> 상태: 제안. `database-schema.md` 미반영. `firestore.rules` · `firestore.indexes.json` · `firestore/{nicknames,emails,friendships}/*.example.json` · `scripts/init_friends_collections.mjs` · `lib/services/friend_service.dart`는 이 절 내용대로 이미 구현됨(quizQuestions와 같은 흐름 — draft 문서 + 실제 코드).  
> 영향 범위: `users/{uid}` 읽기 권한(§2 초안은 본인만 read)과 겹친다 — Auth owner 리뷰 필요.

닉네임/이메일로 다른 유저를 검색하려면 상대 `users/{uid}` 문서를 읽어야 하는데, 이 문서 아래쪽 "Security Rules 초안"은 `users`를 **본인만 read** 하도록 막아뒀다. 그래서 `users` 자체를 공개하는 대신, §2에서 이미 언급된 `nicknames/{nicknameLower}` 예약 문서를 검색 인덱스로 겸용하고, 이메일 검색용으로 `emails/{emailLower}` 문서를 같은 방식으로 하나 더 두는 안을 제안한다.

**검색 → 요청 흐름**: 검색창 입력 → `nicknames`(접두어) 또는 `emails`(정확히 일치) 조회 → uid 확보 → 결과에 닉네임 표시 + 이미 친구/요청 상태 있으면 `friendships/{uidA}_{uidB}` 확인 후 표시 → "추가" 누르면 `friendships` 문서 생성. `users` 원본 필드(레벨·streak 등)는 이 흐름에서 한 번도 읽지 않는다.

### `nicknames/{nicknameLower}`

§2 "닉네임 중복 예약" 문서와 동일한 문서를 재사용한다. 닉네임 변경 시 이전 id는 지우고 새 id로 다시 만든다.

```json
{
  "uid": "<auth uid>",
  "nickname": "닉네임"
}
```

- write: `users/{uid}` 생성·닉네임 변경 시에만 (Auth owner 영역, 클라이언트는 자기 uid로만 생성)
- read: `if request.auth != null` — PII 없이 uid·닉네임만 있어 공개 read 해도 `users` 원본을 열 필요가 없다

**CRUD (현재):** 클라이언트가 본인 uid로 1회 `create`만 가능 (Rules `allow update, delete: if false`). 예시: [`firestore/nicknames/gini.example.json`](../../firestore/nicknames/gini.example.json)

### `emails/{emailLower}`

`nicknames`와 같은 목적 · 같은 구조. 이메일로 찾을 때도 `users`를 열 필요 없이 이 문서만 본다.

```json
{
  "uid": "<auth uid>",
  "nickname": "닉네임"
}
```

- write: 본인 이메일로만 생성 가능. `emailLower == request.auth.token.email` 로 Auth ID 토큰의 이메일 클레임과 대조해 타인 이메일 도용을 막는다 (`users/{uid}` 생성 시 같이 만든다). 토큰 이메일과 대소문자까지 정확히 일치해야 해서, 가입 시 이메일을 소문자로 저장하는 지금 방식(이메일/비번 가입)에서만 우선 보장되고 소셜 로그인이 대문자 섞인 이메일을 주면 생성이 막힐 수 있다 — 필요해지면 다시 본다
- read: `if request.auth != null` — 이메일 자체는 노출하지 않고, 검색 결과로는 uid·닉네임만 보여준다

**CRUD (현재):** `nicknames`와 동일 — 본인만 1회 `create`. 예시: [`firestore/emails/gini@example.com.example.json`](../../firestore/emails/gini@example.com.example.json)

### `friendships/{uidA}_{uidB}`

두 uid를 정렬해 이어붙인 id로 관계당 문서 하나. 요청 → 수락 상태를 한 문서에서 관리한다.

```json
{
  "uids": ["<uidA>", "<uidB>"],
  "requestedBy": "<uid>",
  "requestedByNickname": "<요청 시점 닉네임>",
  "status": "pending",
  "createdAt": "<timestamp>",
  "accepterNickname": "<수락 시점 닉네임>",
  "acceptedAt": "<timestamp>"
}
```

`status`: `pending` | `accepted`. `accepterNickname`/`acceptedAt`은 수락(`pending → accepted`) 시에만 생긴다.

- create: `request.auth.uid`가 `uids`에 포함, `requestedBy == request.auth.uid`, `status == 'pending'`, 필드는 `uids`/`requestedBy`/`requestedByNickname`/`status`/`createdAt` 5개만 허용
- update: `requestedBy`가 아닌 상대방만 `pending → accepted`로 바꿀 수 있고, 이때 `accepterNickname`/`acceptedAt`을 추가로 적는다. `uids`/`requestedBy`/`requestedByNickname`은 못 바꾸고, 필드는 위 5개 + `accepterNickname`/`acceptedAt` 총 7개만 허용
- read/delete: `request.auth.uid in resource.data.uids`인 당사자만
- `users/{uid}` 문서는 전혀 건드리지 않아 §2 규칙과 충돌하지 않는다
- `requestedByNickname`/`accepterNickname`을 문서에 그대로 박아두는 이유: "받은 요청"·"내 친구" 목록에 상대 닉네임을 보여줘야 하는데, `users/{상대uid}`는 본인만 read라 열어볼 수 없다. 매번 `nicknames` 인덱스를 역으로 훑는 대신 요청/수락 시점 닉네임을 복사해둔다 (그 이후 닉네임이 바뀌어도 문서엔 그때 닉네임이 남는다 — 스냅샷)
- 이 필드들이 없는 옛날 문서(필드 추가 전에 만들어진 문서) 대비: `friend_service.dart`의 `getIncomingRequests`/`getFriends`는 스냅샷이 null이면 `nicknames`에서 `uid`로 현재 닉네임을 찾는 fallback을 탄다(`_lookupNicknameByUid`). 상대가 한 번도 로그인 안 해서 `nicknames` 인덱스 자체가 없으면 그래도 "알 수 없음"
- **내 친구 목록**: `friendships`에서 `uids` array-contains 내 uid, `status == 'accepted'`로 쿼리한다. 상대 닉네임은 내가 `requestedBy`면 `accepterNickname`, 아니면 `requestedByNickname`. 친구 요청 조회와 같은 복합 인덱스를 그대로 쓴다(값만 다른 equality라 인덱스 추가 불필요)
- **친구 끊기**: `friendships` 문서를 그냥 삭제한다. `allow delete`가 당사자 누구에게나 이미 열려 있어서 별도 규칙 불필요

**CRUD (현재):** create/update/delete 모두 당사자만 (위 규칙). 예시: [`firestore/friendships/uid_example_1_uid_example_2.example.json`](../../firestore/friendships/uid_example_1_uid_example_2.example.json)

### 컬렉션 트리 추가

```
nicknames/{nicknameLower}        # §2 예약 패턴과 겸용, 공개 read
emails/{emailLower}              # 이메일 검색용, 공개 read
friendships/{uidA}_{uidB}
```

### 인덱스 추가

| 쿼리                     | 인덱스                                           |
| ------------------------ | ------------------------------------------------ |
| 내가 받은/보낸 친구 요청 | `friendships`: `uids`(array-contains) + `status` |

### 아직 안 정한 것 (친구)

- **닉네임 유일성**: Rules가 `nicknames/{nicknameLower}` 문서를 본인 uid로 딱 1번만 `create`하게 막아둬서(같은 닉네임으로 두 번째 `create`는 자동으로 거부됨) 데이터 레이어에서는 유일성이 지켜진다. 다만 회원가입 화면(`signup_screen.dart`)의 "중복 확인" 버튼(`_checkNicknameDuplicate()`)은 아직 빈 함수라, 유저 입장에선 가입 마지막 단계에서야 "이미 있는 닉네임"으로 실패하는 게 지금 흐름이다 — 가입 중간에 미리 확인시켜줄지는 §2 owner와 UX 상의 필요.
- ~~**기존 유저 마이그레이션**~~ 결정함 — lazy 백필. `AuthService`의 `login`/`signInWithGoogle`/`signInWithKakao` 성공 시마다 `_backfillSearchIndexes(user)`를 호출해서, 내 uid로 된 인덱스가 없으면 그때 만든다(있으면 조회 1번으로 끝나 저렴). 별도 1회성 스크립트는 필요 없음.
- **이메일 검색 남용**: `emails/{emailLower}`는 로그인한 사용자면 누구나 특정 이메일의 가입 여부·닉네임을 확인할 수 있게 된다 (이메일 존재 확인/enumeration). 우선은 로그인 필요 조건만 걸어두고, 문제 되면 요청 빈도 제한 등을 나중에 추가한다.
- **친구 삭제(unfriend)**: 결정함 — `friendships` 문서를 그냥 삭제한다 (`allow delete`는 이미 당사자 누구에게나 열려 있어서 별도 작업 불필요, `status: removed` 같은 이력은 안 남긴다).
- 캘린더 "친구와의 경쟁" 랭킹처럼 진행률을 보여주려면 `users`의 일부 필드(streak 등) 노출이 필요 — §2 owner(Auth)와 범위 논의 필요

---

## 로컬 JSON → Firestore

| 로컬                            | Firestore                   |
| ------------------------------- | --------------------------- |
| `users[email]` + session 이메일 | Auth + `users/{uid}`        |
| `profile.xp/streak/energy`      | `users/{uid}` 필드          |
| `interestCategories[]`          | `interestCategoryIds`       |
| `unlockedHamsterIds[]`          | 동일 배열                   |
| `learningHistory[]`             | `users/{uid}/sessions`      |
| `categoryStats{}`               | `users/{uid}.categoryStats` |
| (구) `QuizData.allQuestions`    | `quizQuestions` (Firestore · 12k+ 문항) |
| `kInterestCategories`           | `categories`                |
| `HamsterData`                   | `hamsters`                  |
| 약관 체크                       | `users.consents`            |
| `NewsItem`                      | `newsArticles`              |

---

## 인덱스 (예상)

| 쿼리            | 인덱스                                                           |
| --------------- | ---------------------------------------------------------------- |
| 내 세션 최신순  | `sessions`: `status` + `completedAt` DESC (컬렉션 그룹이면 복합) |
| 현재 약관       | `legalDocuments`: `docType` + `isCurrent`                        |
| 공개 공지       | `announcements`: `isPublished` + `publishedAt`                   |
| 카테고리별 기사 | `newsArticles`: `categoryId` + `fetchedAt`                       |

유저 서브컬렉션 `sessions`를 `uid` 아래에서만 읽으면 단일 필드 `completedAt`로 충분한 경우가 많다.

---

## Security Rules 초안

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /categories/{id} {
      allow read: if true;
      allow write: if false;
    }
    match /hamsters/{id} {
      allow read: if true;
      allow write: if false;
    }
    match /quizQuestions/{id} {
      allow read: if request.auth != null;
      allow write: if false;  // Admin / 콘솔만
    }
    match /legalDocuments/{id} {
      allow read: if true;
      allow write: if false;
    }

    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth.uid == uid;
      // energy, xp, streak, unlockedHamsterIds 는 Functions만 수정하는 편이 안전
      allow update: if request.auth.uid == uid
                    && !request.resource.data.diff(resource.data)
                         .affectedKeys()
                         .hasAny(['xp', 'energy', 'streak', 'unlockedHamsterIds', 'categoryStats']);
      allow delete: if false;

      match /sessions/{sid} {
        allow read: if request.auth.uid == uid;
        allow write: if false;  // Functions
      }
      match /sessions/{sid}/answers/{qid} {
        allow read: if request.auth.uid == uid;
        allow write: if false;
      }
      match /bookmarks/{id} {
        allow read, write: if request.auth.uid == uid;
      }
    }

    match /newsArticles/{id} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /newsQuizPacks/{id} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /announcements/{id} {
      allow read: if resource.data.isPublished == true;
      allow write: if false;
    }
  }
}
```

관심 카테고리·닉네임·선택 햄스터만 클라이언트가 고치고, 재화·진행도는 Functions가 고친다.

---

## Cloud Functions에서 처리할 규칙

앱이 지금 로컬에서 하는 일:

1. **프로필 get**
   `energyResetOn != today`이면 `energy = 100`, `energyResetOn = today` (트랜잭션).
2. **세션 시작**
   `energy < 50`이면 거부.
3. **답 제출**
   `energy >= 5`일 때만 −5 + answers 문서.
4. **세션 완료**
   XP 합산, `categoryStats`, 당일 첫 완료면 streak, 해금 id 배열에 추가.
5. **관심 카테고리**
   배열 길이가 1이면 마지막 id 제거 거부.
6. **탈퇴**
   Auth disable + `status: withdrawn` + 개인정보 마스킹. 실제 삭제 Retention은 추후.

뉴스 퀴즈 생성은 Functions에서 본문 요약 → LLM → `newsQuizPacks` 쓰기. API 키는 클라이언트에 두지 않는다.

---

## 아직 안 정한 것

- 뉴스 퀴즈가 에너지를 쓰는지
- 세션 시작 시 50을 한 번에 깎을지, 문제마다 5씩 깎을지 (앱은 **문제 제출 시 −5**, 수치 잠정)
- 닉네임 예약 컬렉션 사용 여부
- LLM 팩 TTL·재생성
- Kakao는 Firebase 커스텀 토큰 필요
