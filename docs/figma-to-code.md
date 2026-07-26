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
| 3 | 홈 | `83:2` | FigmaCanvas (프레임 단위 마이그레이션 예정) |
| 4 | 퀴즈 | `1:242` … | FigmaCanvas (프레임 단위 마이그레이션 예정) |

fileKey: `PLn1jwyOU2194plYlLdRkl`

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
- `lib/screens/auth/signup_screen.dart` (`1:195`)

---

## 홈 · 퀴즈 — 레거시 FigmaCanvas (프레임별 마이그레이션 예정)

레이어가 많은 화면은 당분간 `FigmaCanvas` + `FigmaBox` 유지.  
**다음 프레임 작업 시** 위젯 방식 + `assets/icons/` 규칙을 동일 적용.

```dart
FigmaCanvas(
  designWidth: FigmaScale.homeDesignWidth,
  designHeight: FigmaScale.homeDesignHeight,
  builder: (context, figma) => [ /* 레이어 */ ],
);
```

---

## 코드베이스 구조

```
lib/theme/figma_auth_tokens.dart      # Dev Mode CSS 토큰 (프레임별)
lib/widgets/figma_auth_widgets.dart   # Code Connect 대응 공통 위젯
lib/widgets/figma/                    # FigmaSvg, FigmaScale, FigmaCanvas
lib/constants/figma_assets.dart       # 에셋 경로

assets/icons/{auth,home,quiz}/        # 벡터 SVG만
assets/figma/{auth,home,quiz}/        # PNG (캐릭터·브랜드)
```

## 알려진 한계

- **폰트**: Figma Inter ≠ 시스템 폰트 → 한글/자간 미세 차이
- **Code Connect**: 조직 플랜에 따라 미지원 — 수동 위젯 매핑
- **소셜 로고**: Figma 래스터 PNG 유지 (SVG 변환 안 함)
