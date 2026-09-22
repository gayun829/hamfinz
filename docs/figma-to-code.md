# Figma → Flutter 코드 변환 가이드

Figma 화면을 Flutter에서 **디자인과 동일하게** 구현할 때 따르는 규칙입니다.

## 핵심 원칙

### 1. 한 프레임씩 작업 (컨텍스트 과부하 방지)

- MCP `get_design_context`는 **화면 프레임 node 하나**만 대상으로 호출한다.
- fileKey 전체·페이지 전체·여러 프레임을 한 번에 넘기지 않는다.
- 화면이 크면 **섹션 node**로 나눠 순차 구현한다 (hero → form → social → footer).

```
# ✅ 좋음 — 프레임 하나
get_design_context(fileKey: PLn1jwyOU2194plYlLdRkl, nodeId: 1:152)

# ❌ 나쁨 — 파일/페이지 통째
get_design_context(..., nodeId: 0:1)
```

| 순서 | 화면 | node ID | 상태 |
|------|------|---------|------|
| 1 | 로그인 | `1:152` | ✅ 위젯 방식 완료 |
| 2 | 회원가입 | `1:195` | ✅ 위젯 방식 완료 |
| 3 | 홈 | `83:2` | ⏳ FigmaCanvas (마이그레이션 예정) |
| 4 | 퀴즈 객관식1 / OX | `1:242` / `1:376` | ✅ 위젯 + `figma_quiz_tokens` / `quiz_widgets` |
| 5 | 설정 | `27:3` | ✅ 위젯 + `figma_settings_tokens` |
| 6 | 아이템 상점 | `235:479` | ✅ 위젯 + `figma_shop_tokens` |
| 7 | 햄핀이 옷장 | `235:382` | ✅ 위젯 + `figma_shop_tokens` |
| 8 | 연속학습 캘린더 | `235:53` | ✅ 위젯 + `figma_calendar_tokens` |

fileKey: `PLn1jwyOU2194plYlLdRkl`

### 온보딩 (파일이 다르다)

fileKey: `xC5ZE0FcHnWZi0VEpttVp8` (`👀 9.6 화면작업중`)

| 순서 | 화면 | node ID | 상태 |
|------|------|---------|------|
| 1 | 로고+햄핀 등장창 | `478:1213` | ✅ 프레임 PNG 1장 (벡터 20개 초과) |
| 2 | 맨처음 설치 시 초기 화면 | `102:12145` | ✅ 위젯 + `figma_onboarding_tokens` |
| 3 | 다른 방법 로그인_닉네임 | `439:419` | ✅ 공통 `OnboardingStepScaffold` |
| 4 | 다른 방법 로그인_이메일 | `439:463` | ✅ |
| 5 | 다른 방법 로그인_비밀번호 | `439:700` | ✅ |
| 6 | 다른 방법 로그인_인증번호 | `439:644` | ✅ (링크 인증으로 대체 — `auth.md` 참고) |
| 7 | 다른 방법 로그인_약관 | `439:2779` | ✅ |

입력 화면 4개는 좌표가 같다 — 말풍선·햄스터·라벨·밑줄을 `OnboardingStepScaffold`·
`OnboardingField`로 묶고, 밑줄 아래 보조 영역만 화면별로 넘긴다.
디자인의 `goolge로 계속하기`는 오타라 `Google로 계속하기`로 고쳤다 (디자이너 확인 완료).

---

### 2. Code Connect (컴포넌트 재사용)

Figma에 **Component / Variant**가 정리돼 있으면 Code Connect로 디자인 ↔ 코드 위젯을 매핑한다.

```
get_code_connect_map(fileKey, nodeId)
get_code_connect_suggestions(fileKey, nodeId)  # 매핑 제안
```

- 매핑된 노드 → 기존 Flutter 위젯 재사용 (`FigmaAuthField`, `FigmaAuthPrimaryButton` 등)
- 새 컴포넌트를 만들기 전에 `lib/widgets/` 검색 + Code Connect 결과 확인
- **조직 Code Connect 미지원 시**: 수동으로 `figma_auth_widgets.dart` 등 공통 위젯에 대응

---

### 3. 에셋 분리

| 종류 | export | 저장 경로 | Flutter |
|------|--------|-----------|---------|
| 벡터 아이콘·일러스트·구분선 | SVG | `assets/icons/{화면}/` | `FigmaSvg` |
| 3D 캐릭터·브랜드 로고·사진 | PNG | `assets/figma/{화면}/` | `FigmaPng` / `Image.asset` |
| 단색 배경·버튼·필드 | 코드 | — | `DecoratedBox`, `TextField`, `ElevatedButton` |

- **벡터만** SVG export → `assets/icons/` (예: `assets/icons/auth/divider_line.svg`)
- **레이아웃·텍스트·버튼**은 MCP spacing/CSS 값 그대로 Flutter 위젯 트리로 구성
- 햄스터: `download_assets(nodeId).export` PNG (`87:7`, `87:19`) — 스프라이트 URL 금지
- hero glow: SVG blur 미지원 → `ImageFiltered` + 원형 `Container`

---

## 워크플로 (프레임 1개 기준)

1. **Dev Mode** — spacing · color · typography CSS 값 확인
2. **`get_design_context(fileKey, nodeId)`** — 해당 프레임만
3. **`get_code_connect_map`** — 재사용 위젯 매핑 확인 (가능할 때)
4. Dev Mode CSS → `lib/theme/*_tokens.dart` 또는 layout 상수
5. 벡터 SVG → `assets/icons/{화면}/` + `figma_assets.dart` 등록
6. 래스터/3D PNG → `assets/figma/{화면}/` (필요할 때만)
7. Flutter 위젯 트리 구현 (`Column` spacing = MCP px × scale)
8. `flutter analyze` + Hot **Restart**

---

## 인증 화면 — Flutter 위젯 방식 (완료)

Dev Mode CSS → `lib/theme/figma_auth_tokens.dart`  
공통 위젯 → `lib/widgets/figma_auth_widgets.dart`

| Dev Mode CSS | Flutter |
|--------------|---------|
| `bg-[#f5faff]` | `FigmaAuthTokens.background` |
| `text-[42px] text-black` | `FigmaAuthTokens.labelStyle(scale)` |
| `text-[30px] text-[#93a8bd]` | `FigmaAuthTokens.bodyStyle(scale)` |
| `rounded-[50px] h-[131px]` | `FigmaAuthField` |
| `bg-[#67d3fa] rounded-[82.5px]` | `FigmaAuthPrimaryButton` |
| 구분선 SVG | `FigmaAuthDivider` → `assets/icons/auth/divider_line.svg` |
| 햄스터 PNG | `FigmaHamsterHero` |

**하지 말 것**

- `FigmaCanvas` + 절대 좌표 Stack (인증 화면)
- 여러 프레임을 한 MCP 호출에 묶기
- MCP 스프라이트 URL을 햄스터에 직접 사용

**참고**

- `lib/screens/auth/login_screen.dart` (`1:152`)
- 회원가입(`1:195`)은 온보딩 단계형 화면으로 교체됐다 — 위 [온보딩](#온보딩-파일이-다르다) 표 참고

---

## 홈 — 레거시 FigmaCanvas (마이그레이션 예정)

홈은 당분간 `FigmaCanvas` + `FigmaBox` 유지.  
퀴즈·설정은 위젯 방식으로 이전됨 (`figma_quiz_tokens.dart`, `quiz_widgets.dart`, `figma_settings_tokens.dart`).

```dart
FigmaCanvas(
  designWidth: FigmaScale.homeDesignWidth,
  designHeight: FigmaScale.homeContentHeight,
  builder: (context, figma) => [ /* 레이어 */ ],
);
```

---

## 코드베이스 구조

```
lib/theme/figma_auth_tokens.dart
lib/theme/figma_onboarding_tokens.dart
lib/theme/figma_quiz_tokens.dart
lib/theme/figma_settings_tokens.dart
lib/widgets/figma_auth_widgets.dart
lib/widgets/figma_onboarding_widgets.dart
lib/widgets/quiz_widgets.dart
lib/widgets/figma/                    # FigmaSvg, FigmaScale, FigmaCanvas
lib/screens/auth/onboarding/          # 스플래시·초기 화면·가입 5단계
lib/constants/figma_assets.dart

assets/icons/{auth,onboarding,home,quiz}/
assets/figma/{auth,onboarding,home,quiz}/
```
## 알려진 한계

- **폰트**: Figma Inter ≠ 시스템 폰트 → 한글/자간 미세 차이
- **Code Connect**: 조직 플랜에 따라 미지원 — 수동 위젯 매핑
- **소셜 로고**: Figma 래스터 PNG 유지 (SVG 변환 안 함)
