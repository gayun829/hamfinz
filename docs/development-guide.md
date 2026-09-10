# 개발 가이드

## 환경

- Flutter / Dart SDK `^3.12.2` (`pubspec.yaml`)
- 패키지명: `testapp`

## 실행

```bash
flutter pub get
flutter run
```

플랫폼 예:

```bash
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

## 테스트 계정

| | |
|--|--|
| 이메일 | `test@finquiz.com` |
| 비밀번호 | `test1234` |

코드: `AuthService.testEmail` / `testPassword`  
최초 로그인 시 로컬에 테스트 계정이 없으면 자동 생성된다.

## 웹에서 뉴스 보기

Chrome 등에서는 구글뉴스 CORS 때문에 직접 호출이 막힌다. 지금은 로컬 프록시를 같이 띄운다.

터미널 1:

```bash
dart run tool/cors_proxy.dart
```

터미널 2:

```bash
flutter run -d chrome --dart-define=NEWS_PROXY=http://localhost:8766
```

- 프록시 포트: **8766**
- 모바일·데스크톱 빌드는 `NEWS_PROXY` 없이 RSS 직접 호출
- Cloud Functions `fetchNewsFeed`(`functions/index.js`)를 `firebase deploy --only functions`로 올리면,
  `NEWS_PROXY` 없이 `flutter run -d chrome`만으로 뉴스가 뜬다 (웹은 함수를 거쳐 RSS를 받는다)

## 프로젝트 디렉터리 (요약)

```
lib/
  main.dart
  constants/          # Figma 에셋 경로
  data/               # 퀴즈·햄스터·카테고리·약관
  models/
  services/           # auth, quiz, news, storage
  screens/            # auth, home, quiz, news, settings, legal
  widgets/            # 네비, 퀴즈, Figma 헬퍼
  theme/
  utils/
tool/
  cors_proxy.dart
test/
  widget_test.dart
  news_service_test.dart
docs/                 # 이 문서들
```

## 테스트

```bash
flutter test
```

| 파일 | 내용 |
|------|------|
| `test/widget_test.dart` | 스모크 (Storage init) |
| `test/news_service_test.dart` | RSS 파싱·카테고리 질의 |

## 분석

```bash
flutter analyze
```

## Figma

디자인 반영 규칙: [figma-to-code.md](./figma-to-code.md)  
fileKey 예: `PLn1jwyOU2194plYlLdRkl`

## 주의

- 루트 `README.md`는 일부 내용이 코드보다 오래됐을 수 있다. **현재 동작은 `docs/`를 우선**한다.
- 백엔드·실서비스 인증은 아직 없다. 로컬 MVP용이다.
