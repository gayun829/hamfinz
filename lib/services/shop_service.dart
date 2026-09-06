import '../config/shop_backend_config.dart';
import '../models/shop_purchase_result.dart';
import '../models/user_profile.dart';
import 'shop_functions_repository.dart';
import 'shop_purchase_repository.dart';

/// 씨앗이 관여하는 모든 구매(스킨/무늬/배경/악세서리, 연속 학습 방어권, 에너지 팩)를
/// 한 곳에서 처리한다. 서버(트랜잭션/Functions)가 계산한 최신 값으로만 [profile]을
/// 갱신하므로, 화면이 들고 있던 프로필로 seeds를 직접 뺄셈해서 덮어쓰지 않는다.
///
/// 백엔드: [ShopBackendConfig.purchaseBackend]
class ShopService {
  ShopService._();
  static final instance = ShopService._();

  Future<ShopPurchaseResult> purchaseItem({
    required UserProfile profile,
    required String itemId,
  }) async {
    final result = ShopBackendConfig.usesCloudFunctions
        ? await ShopFunctionsRepository.instance.purchaseItem(itemId)
        : await ShopPurchaseRepository.instance.purchaseItem(itemId);

    if (result.isSuccess) {
      if (result.seeds != null) profile.seeds = result.seeds!;
      if (result.energy != null) profile.energy = result.energy!;
      if (result.studyGuardCount != null) {
        profile.studyGuardCount = result.studyGuardCount!;
      }
      if (result.ownedShopItemIds != null) {
        profile.ownedShopItemIds = result.ownedShopItemIds!;
      }
    }
    return result;
  }
}
