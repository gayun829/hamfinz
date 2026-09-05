import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// 상점 구매(씨앗 차감) 백엔드 모드.
///
/// [QuizBackendConfig]와 같은 전환 패턴 — 배포 절차:
/// [docs/quiz-production-deployment.md](../../docs/quiz-production-deployment.md)
enum ShopPurchaseBackend {
  /// 개발 — Blaze 없이 Firestore 클라이언트 트랜잭션 (`firestore.rules`)
  clientTransaction,

  /// 배포 — Cloud Functions Callable + Admin SDK (`firestore.rules.production`)
  cloudFunctions,
}

/// 상점 구매(`purchaseShopItem`) 백엔드 전환 설정.
///
/// **배포 전** [ShopPurchaseBackend.cloudFunctions] 로 변경하고
/// [docs/quiz-production-deployment.md] 체크리스트를 따른다 (퀴즈와 같은 절차).
class ShopBackendConfig {
  ShopBackendConfig._();

  /// 로컬/개발: clientTransaction + `node scripts/deploy_firestore_rules.mjs`
  /// 스토어 배포: cloudFunctions + Functions 배포 + production rules
  static const configuredBackend = ShopPurchaseBackend.clientTransaction;

  /// [configuredBackend] + 웹 디버그 시 Functions(CORS) 대신 Firestore 트랜잭션.
  static ShopPurchaseBackend get purchaseBackend {
    if (kDebugMode &&
        kIsWeb &&
        configuredBackend == ShopPurchaseBackend.cloudFunctions) {
      return ShopPurchaseBackend.clientTransaction;
    }
    return configuredBackend;
  }

  static bool get usesClientTransaction =>
      purchaseBackend == ShopPurchaseBackend.clientTransaction;

  static bool get usesCloudFunctions =>
      purchaseBackend == ShopPurchaseBackend.cloudFunctions;
}
