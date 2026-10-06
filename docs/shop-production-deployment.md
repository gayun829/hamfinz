# 상점 프로덕션 배포 (Functions 전환)

Blaze 플랜 전환 후 **purchaseShopItem**(씨앗 차감 상점 구매)을 Cloud Functions로
옮길 때 따르는 체크리스트. [quiz-production-deployment.md](./quiz-production-deployment.md)와
같은 전환 패턴이다.

현재(개발)는 Blaze 없이 동작하도록 **클라이언트 Firestore 트랜잭션**을 사용한다.

> ⚠️ **배포 순서 주의**: `firestore.rules.production`은 퀴즈(seeds/streak 등)와 상점(seeds/energy/studyGuardCount/ownedShopItemIds)
> 필드를 같은 `users/{uid}` 문서에서 함께 제한한다. 그래서 [quiz-production-deployment.md](./quiz-production-deployment.md)와
> 이 문서의 **Rules 배포 + `QuizBackendConfig`/`ShopBackendConfig` 앱 설정 전환은 한 세트로 같이** 해야 한다 — 예를 들어
> production rules를 배포한 채로 `ShopBackendConfig`만 `clientTransaction`으로 남겨두면, 클라이언트 트랜잭션의 `seeds` write가
> permission-denied로 막혀 상점이 통째로 깨진다. Quiz/Shop 중 하나만 먼저 전환해야 한다면, 그 기능만 아직 개발 Rules로
> 남겨두는 식으로 Rules와 BackendConfig 조합을 항상 짝지어 맞춰야 한다.

---

## 배경 — 왜 서버 트랜잭션이 필요한가

기존 구매 코드(`shop_screen.dart`/`closet_screen.dart`)는 화면이 들고 있는
`UserProfile`에서 `seeds -= price`를 계산해 `AuthService.saveProfile`로 절대값을
덮어썼다. 두 가지 문제가 있었다:

1. **동시성**: 다른 화면/기기에서 퀴즈로 번 씨앗이 반영되기 전에 구매하면,
   구매 화면이 들고 있던 오래된 값으로 덮어써서 방금 번 씨앗이 사라진다.
2. **신뢰 경계**: `firestore.rules`(개발/프로덕션 모두) 이전 버전은 `users/{uid}`에
   `allow read, write: if uid == auth.uid`만 있어, 클라이언트가 seeds/energy/
   studyGuardCount/ownedShopItemIds를 원하는 값으로 직접 바꿔 쓸 수 있었다.

`ShopService` → (`ShopPurchaseRepository` 트랜잭션 | `purchaseShopItem` Functions)로
바꾸면 항상 **서버가 그 순간의 최신 값**을 읽어 계산하므로 1번이 구조적으로
해결되고, 배포 후 Rules를 잠그면 2번도 막힌다.

---

## 현재 vs 배포

| 항목 | 개발 (현재) | 프로덕션 (배포 후) |
|------|-------------|---------------------|
| 앱 설정 | `ShopBackendConfig.purchaseBackend = clientTransaction` | `cloudFunctions` |
| Rules 파일 | `firestore.rules` | `firestore.rules.production` |
| purchaseShopItem | `ShopPurchaseRepository` (클라이언트 트랜잭션) | Callable `purchaseShopItem` |
| seeds/energy/ownedShopItemIds/studyGuardCount write | 클라이언트 허용 (블랭킷) | **Functions Admin SDK만** (필드별 Rules) |
| equipped*/nickname/interestCategories write | 클라이언트 (변경 없음) | 클라이언트 (변경 없음) |

---

## 배포 체크리스트

### 1. Firebase Blaze 플랜

퀴즈 Functions 배포 때 이미 전환했다면 생략.

### 2. Cloud Functions 배포

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

- [ ] `purchaseShopItem` 배포 확인 (region: `asia-northeast3`)
- [ ] Firebase Console → Functions → 로그에서 cold start / 오류 없음 확인

참고 구현: `functions/index.js`의 `purchaseShopItem` (Dart `ShopPurchaseRepository`와 동일 로직)

### 3. Firestore Rules (프로덕션)

`firestore.rules.production`의 `users/{uid}` `update`는 `seeds`/`energy`/
`lastEnergyResetDate`/`studyGuardCount`/`ownedShopItemIds`(+퀴즈 필드)를
클라이언트가 건드리면 거부한다.

```bash
node scripts/deploy_firestore_rules.mjs --production
```

- [ ] 클라이언트에서 `users/{uid}`의 `seeds`만 직접 write 시도 → permission-denied 확인
- [ ] `equippedSkinId` 등만 write하는 기존 흐름(장착)은 그대로 성공하는지 확인

### 4. 앱 설정 전환

`lib/config/shop_backend_config.dart`:

```dart
static const configuredBackend = ShopPurchaseBackend.cloudFunctions;
```

- [ ] 값 변경 후 앱 재빌드·스토어 배포
- [ ] `ShopService`가 `ShopFunctionsRepository` 경로로 라우팅되는지 확인

### 5. 동작 검증

- [ ] 씨앗 충분 → 코스메틱 구매 → 장착까지 정상 동작
- [ ] 씨앗 부족 → `insufficientSeeds` 스낵바
- [ ] 방어권 3개 보유 상태에서 추가 구매 시도 → `studyGuardMaxCapacity`
- [ ] 에너지가 100 이상이어도 에너지팩 구매 → 한도 없이 +20
- [ ] 두 기기/탭에서 거의 동시에 구매 → 씨앗이 두 번 차감되거나 유실되지 않는지 확인

### 6. (선택) Emulator 로컬 테스트

```bash
firebase emulators:start --only functions,firestore
```

---

## 파일 맵

| 파일 | 역할 |
|------|------|
| `lib/config/shop_backend_config.dart` | **전환 스위치** (한 줄 변경) |
| `lib/services/shop_service.dart` | config에 따라 Repository / Functions 라우팅 + 프로필 동기화 |
| `lib/services/shop_purchase_repository.dart` | 개발용 클라이언트 트랜잭션 |
| `lib/services/shop_functions_repository.dart` | 배포용 Callable 래퍼 |
| `lib/models/shop_purchase_result.dart` | 구매 결과 (status/메시지/최신 값) |
| `functions/index.js` | 서버 구매 처리 `purchaseShopItem` (Admin SDK) |
| `firestore.rules` | **개발** Rules (클라이언트 write 허용) |
| `firestore.rules.production` | **프로덕션** Rules (필드별 제한) |

---

## 롤백 (개발 모드로 되돌리기)

1. `ShopBackendConfig.configuredBackend` → `clientTransaction`
2. `node scripts/deploy_firestore_rules.mjs` (개발 Rules 재배포)
3. 앱 재배포

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-09-05 | `purchaseShopItem` 서버 트랜잭션 도입 + 프로덕션 Rules 필드 제한. `study_guard`(방어권) streak 보호 로직도 함께 수정 — 결석일수를 다 못 막으면 방어권을 쓰지 않도록 변경. |
