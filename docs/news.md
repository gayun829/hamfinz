# 뉴스

관련 코드: `lib/services/news_service.dart`, `lib/screens/news/`

## 목적

관심 주제별 **최근 인기 금융 뉴스 TOP 3**를 보여 주고, 원문을 읽게 한다.  
(기사 기반 LLM 퀴즈는 별도 로드맵.)

## NewsService

- 소스: Google News RSS (`news.google.com/rss/search`)  
- 파라미터: `hl=ko`, `gl=KR`, `ceid=KR:ko`  
- 질의에 `when:7d`로 최근 1주일 제한  
- `topFor(categoryId, limit: 3)` → `List<NewsItem>` (`title`, `url`)  
- `searchPageFor(categoryId)` → 「더보기」용 검색 페이지 URI  

### 카테고리 질의 (`categoryQueries`)

| id | 검색어 요약 |
|----|-------------|
| `allowance` | 용돈 OR 생활비 OR 소비습관 |
| `saving` | 예금 OR 적금 OR 저축 금리 |
| `stock` | 주식 OR 증시 OR 투자 |
| `insurance` | 보험 |
| `tax` | 세금 OR 연말정산 OR 소득공제 |
| `credit` | 신용점수 OR 대출 |

### 웹 CORS

브라우저는 구글뉴스에 CORS가 없어 직접 호출이 막힌다.

```bash
dart run tool/cors_proxy.dart
flutter run -d chrome --dart-define=NEWS_PROXY=http://localhost:8766
```

- 프록시: `tool/cors_proxy.dart` (포트 **8766**)  
- 앱: `String.fromEnvironment('NEWS_PROXY')` — 비어 있으면(모바일) 직접 RSS 호출  

## NewsScreen

- 6개 `kInterestCategories` 섹션  
- 섹션별 병렬 fetch, 한 주제 실패해도 나머지 표시  
- Pull-to-refresh  
- 기사 탭 → `ArticleScreen` 또는 외부 브라우저  

## ArticleScreen

- Android/iOS: `webview_flutter`  
- 상단/하단 CTA 자리: `onStartQuiz`  
  - 문구 예: 「이 기사로 퀴즈 풀기」 / 웹뷰 배너 디자인 참고  
  - **현재 NewsScreen에서 콜백 미전달** → UI만 준비된 상태  

## 본문 한계

RSS는 **제목+URL만** 제공한다.  
「기사 내용」 기반 LLM 퀴즈를 하려면 서버에서 본문 추출·요약이 필요하다. → [roadmap.md](./roadmap.md)
