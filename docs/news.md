# 뉴스

관련 코드: `lib/services/news_service.dart`, `lib/data/finance_terms.dart`, `lib/screens/news/`, `lib/screens/home/home_screen.dart`

## 목적

**지금 가장 큰 금융 뉴스 TOP 10**을 보여 주고, 기사에 나온 금융 용어를 학습으로 이어 준다.

## 소스

**연합뉴스 경제 RSS** 1회 호출.

```
www.yna.co.kr/rss/economy.xml
```

기사마다 `<media:content>`로 대표 사진이 붙어 있고(실측 120건 중 111건), `<link>`가 기사 원문이라 WebView에서 바로 열린다. 순서는 피드가 준 최신순.

### 왜 구글뉴스에서 바꿨나

처음엔 Google News 비즈니스 토픽 헤드라인(`news.google.com/rss/headlines/section/topic/BUSINESS`)을 썼다. 구글이 고른 큰 기사가 위로 오는 건 장점이었지만,

- RSS에 **사진이 없다** (`title / link / source / pubDate / description`뿐)
- `<link>`가 `news.google.com/rss/articles/...` 리다이렉트라 원문 og:image를 긁을 수도 없다 (2024년부터 디코딩도 막힘)

그래서 목록에 사진을 띄우려면 소스를 바꿔야 했다. 후보 실측(용어 필터 통과 / 사진):

| 피드 | 건수 | 용어 매칭 | 사진 |
|---|---:|---:|---:|
| 연합뉴스 경제 | 120 | 22 | 20 |
| 동아일보 경제 | 50 | 3 | 3 |
| 조선비즈 | 100 | 1 | 1 |
| 한국경제 경제 | 50 | – | 없음 |
| 매일경제 | 403 | – | – |

> **조회수 순은 만들 수 없다.** 어느 RSS도 조회수 필드가 없다.

### 왜 카테고리를 안 나누나

이전에는 6개 카테고리마다 검색 질의를 던져 각 TOP 3을 보여 줬다. 실측하니:

| 쿼리 | 용어 매칭 |
|---|---:|
| 신용 | 98% |
| 저축&예금 | 83% |
| 주식&투자 | 39% |
| 보험 | 33% |
| 세금 | 27% |
| 용돈&지출 | **6%** |

카테고리 쿼리 자체는 필터로 잘 작동했지만, 보험·세금·용돈은 주에 따라 섹션이 비어 「표시할 뉴스가 없어요」가 떴다. 호출도 6번이라 웹 프록시가 502를 뱉는 원인이었다. 지금은 한 번 호출해서 한 목록으로 보여 준다.

## 용어 필터 (`finance_terms.dart`)

비즈니스 헤드라인에는 기업 인사·수출 실적·부동산 시황처럼 학습 소재가 안 되는 기사가 섞여 있다. **제목에 금융 용어가 없으면 목록에서 뺀다.**

- 용어 47개 (`FinanceTerm`: `term` + `categoryId`)
- `matchFinanceTerm(title)` — 가장 **긴** 용어를 고른다. `주택담보대출`이 걸렸는데 `대출`로 가르치면 기사와 어긋난다
- 실측: 피드 70건 중 약 24%가 통과 → TOP 10이 여유 있게 채워진다
- `categoryId`는 목록의 용어 칩 이모지에 쓰고, 뉴스 퀴즈에서 카테고리를 정할 때 쓴다

같은 용어가 여러 기사에 겹치는 건 그대로 둔다(`금리` 3건 등).

## 갱신 주기 — 1시간

피드 기사 나이 중앙값이 약 19시간, 1시간 이내 신규는 3건 남짓이다. 필터 통과율 24%를 곱하면 목록에 새로 올라오는 건 **시간당 1건 꼴** — 더 짧게 잡으면 대부분 같은 목록을 다시 받는다.

`NewsService`가 TTL 캐시를 들고 있어서(`refreshInterval`), 세 갈래가 모두 같은 캐시를 쓴다:

| 트리거 | |
|---|---|
| 타이머 1시간 | 뉴스 탭이 `IndexedStack`에 물려 있어 앱 실행당 한 번만 만들어진다. 타이머 없이는 켜둔 채로 안 바뀐다 |
| 앱 복귀 | 백그라운드에선 타이머가 밀릴 수 있어 `resumed`에 한 번 더 확인 |
| 당겨서 새로고침 | `force: true` — 주기 무시 |

갱신 실패 시 **보여주던 목록을 유지**한다. 캐시가 아예 없는 첫 로딩에서만 오류를 띄운다.

## 웹 CORS

브라우저는 언론사 RSS에 CORS가 없어 직접 호출이 막힌다. 웹 빌드는 두 경로 중 하나로 우회한다.

| 경로 | 조건 | 비고 |
|---|---|---|
| 로컬 프록시 `tool/cors_proxy.dart` (포트 8766) | `--dart-define=NEWS_PROXY=http://localhost:8766` | 지금 쓰는 방식. cmd 하나 더 띄움 |
| Cloud Functions `fetchNewsFeed` (asia-northeast3) | `NEWS_PROXY` 없이 웹 빌드 | 배포(`firebase deploy --only functions`) 후 사용. 로그인 필수, `www.yna.co.kr/rss/*`·`news.google.com/rss/*`만 허용 |

- 모바일·데스크톱은 CORS가 없어 직접 RSS 호출

## 화면

### NewsScreen (뉴스 탭)

한 줄 목록 TOP 10. 제목만 나열하면 열 줄이 다 똑같아 보여서, **RSS가 주는데 안 쓰던 값**을 같이 띄운다.

| | |
|---|---|
| 순위 뱃지 | 상위 3건 주황, 나머지 민트 |
| 제목 | 최대 2줄, 상위 3건은 굵게 |
| 두 번째 줄 | `🏦 금리 · 한국경제 · 3시간 전` — 용어/언론사(`<source>`)/발행 시각(`<pubDate>`) |
| 용어 띠 | 목록 위, 오늘 걸린 용어를 중복 없이 가로로 훑어 준다 |
| 부제 | `TOP 10 · 3분 전 업데이트` (`NewsService.cachedAt`) |

- 「더보기」→ 같은 비즈니스 섹션 페이지
- Pull-to-refresh

`<pubDate>`는 RFC 822(`Tue, 02 Sep 2025 01:23:45 GMT`)다. `HttpDate.parse`는 `dart:io`라 웹 빌드에서 못 써서 `NewsService.parsePubDate`가 직접 읽는다 — 형식이 깨지면 null이고 그 기사만 시각을 안 띄운다.

> **사진은 못 넣는다.** 피드 전체에 `media:*`/`<enclosure>`/`thumbnail`이 **0개**(`xmlns:media` 선언만 있고 원소가 없다), `<image>` 1개는 채널 로고다. 기사 `<link>`도 `news.google.com` 안에서 로케일만 붙여 자기 자신으로 302 — 언론사 URL은 자바스크립트로 풀린다. og:image를 쓰려면 링크를 해석해 주는 서버(Cloud Function)가 따로 있어야 한다.

### 홈 뉴스바

- TOP 10을 **10초마다** 한 건씩 슬라이드 (`AnimatedSwitcher`)
- 누르면 그때 떠 있는 기사를 연다 — 뉴스 탭과 같은 경로(`ArticleScreen.open`)
- 아직 못 불러왔으면 비즈니스 섹션 페이지로 (빈 탭 방지)
- 뉴스 탭과 같은 캐시를 쓴다

### ArticleScreen

- Android/iOS: `webview_flutter` / Web·Windows: 외부 브라우저
- `ArticleScreen.open(context, url, title)` — 뉴스 탭·홈 뉴스바 공통 진입점
- 하단 CTA 자리: `onStartQuiz` — **현재 미전달**, 뉴스 퀴즈가 붙으면 연결

## 뉴스 용어 퀴즈

RSS는 제목·요약만 주고 본문은 안 준다. 그래서 기사 본문을 시험 보지 않고, **제목에서 잡은 용어 하나를 3지선다 한 문제로 묻고 해설로 가르친다.**

Figma `뉴스_퀴즈창 → 뉴스_정오답 → 뉴스_해설` 세 장면을 한 화면의 상태로 돈다.

| 단계 | 보기 | 버튼 |
|---|---|---|
| 문제 | 고른 보기만 하늘색 테두리 | 정답 보기 |
| 정오답 | 정답은 하늘색 채움, 내가 틀리게 고른 건 빨강 | 해설 보기 |
| 해설 | 정답 하나만 노랑으로 남기고 아래에 해설 상자(해설 + 용어 한 줄 정의) | 나가기 |

- 화면: `lib/screens/news/term_quiz_screen.dart` — 하단 탭을 그대로 두어 탭 안의 한 장면처럼 보인다
- 내용: `finance_terms.dart`의 `summary` / `forMe` / `quiz`(`TermQuiz` — 문제 / 보기 3 / 정답 index / 해설)
- 보상: 맞히면 **씨앗 +3** (`NewsQuizRepository`). 앱 실행당 용어별 1회. 개발은 클라이언트 트랜잭션이고, 배포 Rules는 seeds를 Functions만 쓰게 막아 두었으니 그때는 Callable로 옮긴다
- **`hasLesson`이 true인 용어만** 퀴즈로 이어진다. 나머지는 필터로만 쓰인다 — 자주 걸리는 용어부터 채워 나가면 된다

### 홈 퀴즈와 왜 안 엮었나

| | 홈 퀴즈(`QuizScreen`) | 뉴스 용어 학습 |
|---|---|---|
| 채점 | 서버 (`QuizSession`에 정답이 안 실려 온다) | 그 자리에서 |
| 에너지 | 10문제당 소모 | 안 쓴다 |
| 기록·보상 | 씨앗·연속일수 | 씨앗 +3만, 기록은 안 남긴다 |

기사 읽다 곁다리로 보는 학습이라 관문을 두면 안 들어온다. 진도로 세고 싶어지면 그때 `QuizService`에 붙이면 된다.

### 진입 경로

`ArticleScreen.open(..., onStartQuiz:)` 하나로 뉴스 탭·홈 뉴스바가 같이 들어간다.

| | |
|---|---|
| Android·iOS | 인앱 WebView 기사 **하단 CTA** 「이 기사 용어 학습하기」 |
| Web·Windows | 기사는 바깥 탭에서 열리고, 학습 화면을 앱에 바로 올려 둔다 — 읽고 돌아오면 기다리고 있다 |

용어에 학습 내용이 없으면 `onStartQuiz`가 null이라 CTA도 안 붙는다.
