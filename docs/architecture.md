# 아키텍처

## 개요

햄핀즈는 **로컬 전용 Flutter MVP**입니다. 서버 없이 `SharedPreferences`에 사용자·세션·학습 데이터를 저장합니다.

| 레이어 | 역할 | 주요 경로 |
|--------|------|-----------|
| Entry | 앱 기동, 인증 분기 | `lib/main.dart` |
| Screens | UI·사용자 흐름 | `lib/screens/` |
| Widgets | 재사용 UI, Figma 스케일 | `lib/widgets/` |
| Services | 비즈니스 로직 | `lib/services/` |
| Data / Models | 정적 데이터·도메인 모델 | `lib/data/`, `lib/models/` |
| Theme | 색·토큰 | `lib/theme/` |

## 진입점

```
main()
  → StorageService.init()
  → HamfinzApp (MaterialApp + MobileViewport)
  → AppRoot
       ├─ 세션 있음 → MainShell
       └─ 없음     → AuthGate
```

- `MobileViewport`: 웹/데스크톱에서 콘텐츠를 약 **390×846**으로 제한
- 테마: `AppTheme.theme` (`lib/theme/app_theme.dart`)

## 서비스

| 서비스 | 파일 | 책임 |
|--------|------|------|
| `StorageService` | `lib/services/storage_service.dart` | SharedPreferences 래퍼 |
| `AuthService` | `lib/services/auth_service.dart` | 가입·로그인·세션·프로필·약관 이후 카테고리·에너지 일일 회복 |
| `QuizService` | `lib/services/quiz_service.dart` | 일일 문제 세트, 에너지 차감, 세션 완료(XP/streak/해금) |
| `NewsService` | `lib/services/news_service.dart` | 구글뉴스 RSS TOP N, CORS 프록시 옵션 |

## UI 구현 방식

| 영역 | 방식 | 비고 |
|------|------|------|
| 로그인·회원가입 | Column + 토큰 위젯 | `figma_auth_widgets.dart` |
| 퀴즈(객관식·OX) | 위젯 + `FigmaQuizTokens` | `quiz_widgets.dart` |
| 홈 | `FigmaCanvas` 절대 좌표 | 프레임 단위 마이그레이션 예정 |
| 설정 | 토큰 + 메뉴 버튼 | `figma_settings_tokens.dart` |

상세: [figma-to-code.md](./figma-to-code.md)

## 의존성 (주요)

- `shared_preferences` — 로컬 저장
- `crypto` — 비밀번호 해시
- `http` — 뉴스 RSS
- `url_launcher` — 외부 링크
- `flutter_svg` — SVG 에셋
- `webview_flutter` — 기사 인앱 뷰 (모바일)

## 관련 문서

- [screens-and-navigation.md](./screens-and-navigation.md)
- [data-models.md](./data-models.md)
- [development-guide.md](./development-guide.md)
