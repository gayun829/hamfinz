import 'package:cloud_functions/cloud_functions.dart';

import '../models/shop_purchase_result.dart';

/// 배포용 — Cloud Functions Callable `purchaseShopItem` (Admin SDK).
class ShopFunctionsRepository {
  ShopFunctionsRepository._();
  static final instance = ShopFunctionsRepository._();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  Future<ShopPurchaseResult> purchaseItem(String itemId) async {
    try {
      final callable = _functions.httpsCallable('purchaseShopItem');
      final response = await callable.call<Map<String, dynamic>>({
        'itemId': itemId,
      });
      final data = response.data;
      return ShopPurchaseResult(
        status: ShopPurchaseStatus.success,
        seeds: (data['seeds'] as num?)?.toInt(),
        energy: (data['energy'] as num?)?.toInt(),
        studyGuardCount: (data['studyGuardCount'] as num?)?.toInt(),
        ownedShopItemIds: data['ownedShopItemIds'] == null
            ? null
            : List<String>.from(data['ownedShopItemIds'] as List),
      );
    } on FirebaseFunctionsException catch (e) {
      return ShopPurchaseResult(
        status: _statusFromCode(e),
        errorMessage: _functionsErrorMessage(e),
      );
    } catch (_) {
      return const ShopPurchaseResult(
        status: ShopPurchaseStatus.failed,
        errorMessage: '구매에 실패했어요. Cloud Functions 배포·설정을 확인해 주세요.',
      );
    }
  }

  ShopPurchaseStatus _statusFromCode(FirebaseFunctionsException e) {
    if (e.code != 'failed-precondition') return ShopPurchaseStatus.failed;
    final message = e.message ?? '';
    if (message.contains('씨앗이 부족')) return ShopPurchaseStatus.insufficientSeeds;
    if (message.contains('최대 3개')) return ShopPurchaseStatus.studyGuardMaxCapacity;
    if (message.contains('가득 차')) return ShopPurchaseStatus.energyAlreadyFull;
    return ShopPurchaseStatus.failed;
  }

  String? _functionsErrorMessage(FirebaseFunctionsException e) {
    final detail = e.message?.trim();
    if (detail != null && detail.isNotEmpty && detail != 'internal') {
      return detail;
    }
    if (e.code == 'unavailable' || e.code == 'internal') {
      return '구매에 실패했어요 (Functions 연결 실패 — firebase deploy --only functions 후 cloudFunctions 전환)';
    }
    return '구매에 실패했어요.';
  }
}
