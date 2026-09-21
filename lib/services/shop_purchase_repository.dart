import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/shop_data.dart';
import '../models/shop_purchase_result.dart';
import '../utils/date_helper.dart';

/// 개발용 — Blaze 없이 클라이언트 Firestore 트랜잭션으로 상점 구매를 처리한다.
/// `functions/index.js`의 `purchaseShopItem`과 동일한 로직 (배포 시 그쪽으로 전환).
class ShopPurchaseRepository {
  ShopPurchaseRepository._();
  static final instance = ShopPurchaseRepository._();

  static const maxStudyGuardCount = 4;
  static const energyPackAmount = 20;
  static const maxEnergy = 100;

  Future<ShopPurchaseResult> purchaseItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const ShopPurchaseResult(status: ShopPurchaseStatus.notLoggedIn);
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final shopItemRef = FirebaseFirestore.instance
        .collection('shopItems')
        .doc(itemId);

    try {
      return await FirebaseFirestore.instance.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          return const ShopPurchaseResult(
            status: ShopPurchaseStatus.failed,
            errorMessage: '유저 프로필을 찾을 수 없어요.',
          );
        }

        ShopItem? fallback;
        try {
          fallback = ShopData.items.firstWhere((item) => item.id == itemId);
        } catch (_) {
          fallback = null;
        }
        // Bundled products do not require a Firestore catalog document.
        // Reading a missing document is denied by the active-item read rules.
        final shopItemSnap = fallback == null
            ? await tx.get(shopItemRef)
            : null;
        final price =
            fallback?.price ??
            (shopItemSnap?.data()?['price'] as num?)?.toInt();
        if (price == null) {
          return const ShopPurchaseResult(
            status: ShopPurchaseStatus.failed,
            errorMessage: '존재하지 않는 상품이에요.',
          );
        }

        final userData = userSnap.data()!;
        final seeds = (userData['seeds'] as num?)?.toInt() ?? 0;

        if (itemId == 'study_guard') {
          final studyGuardCount =
              (userData['studyGuardCount'] as num?)?.toInt() ?? 0;
          if (studyGuardCount >= maxStudyGuardCount) {
            return const ShopPurchaseResult(
              status: ShopPurchaseStatus.studyGuardMaxCapacity,
            );
          }
          if (seeds < price) {
            return const ShopPurchaseResult(
              status: ShopPurchaseStatus.insufficientSeeds,
            );
          }
          final newSeeds = seeds - price;
          final newStudyGuardCount = studyGuardCount + 1;
          tx.update(userRef, {
            'seeds': newSeeds,
            'studyGuardCount': newStudyGuardCount,
          });
          return ShopPurchaseResult(
            status: ShopPurchaseStatus.success,
            seeds: newSeeds,
            studyGuardCount: newStudyGuardCount,
          );
        }

        if (itemId == 'energy_pack') {
          final today = DateHelper.todayKey();
          var energy = (userData['energy'] as num?)?.toInt() ?? maxEnergy;
          var lastEnergyResetDate = userData['lastEnergyResetDate'] as String?;
          if (lastEnergyResetDate != today) {
            energy = maxEnergy;
            lastEnergyResetDate = today;
          }
          if (energy >= maxEnergy) {
            return const ShopPurchaseResult(
              status: ShopPurchaseStatus.energyAlreadyFull,
            );
          }
          if (seeds < price) {
            return const ShopPurchaseResult(
              status: ShopPurchaseStatus.insufficientSeeds,
            );
          }
          final newSeeds = seeds - price;
          final newEnergy = (energy + energyPackAmount).clamp(0, maxEnergy);
          tx.update(userRef, {
            'seeds': newSeeds,
            'energy': newEnergy,
            'lastEnergyResetDate': lastEnergyResetDate,
          });
          return ShopPurchaseResult(
            status: ShopPurchaseStatus.success,
            seeds: newSeeds,
            energy: newEnergy,
          );
        }

        // 코스메틱 (스킨/무늬/배경/악세서리).
        final ownedShopItemIds = List<String>.from(
          userData['ownedShopItemIds'] as List? ?? [],
        );
        if (ownedShopItemIds.contains(itemId)) {
          return ShopPurchaseResult(
            status: ShopPurchaseStatus.alreadyOwned,
            seeds: seeds,
            ownedShopItemIds: ownedShopItemIds,
          );
        }
        if (seeds < price) {
          return const ShopPurchaseResult(
            status: ShopPurchaseStatus.insufficientSeeds,
          );
        }
        final newSeeds = seeds - price;
        final newOwnedShopItemIds = [...ownedShopItemIds, itemId];
        tx.update(userRef, {
          'seeds': newSeeds,
          'ownedShopItemIds': newOwnedShopItemIds,
        });
        return ShopPurchaseResult(
          status: ShopPurchaseStatus.success,
          seeds: newSeeds,
          ownedShopItemIds: newOwnedShopItemIds,
        );
      });
    } on FirebaseException catch (e) {
      return ShopPurchaseResult(
        status: ShopPurchaseStatus.failed,
        errorMessage: '구매 처리에 실패했어요. (${e.code})',
      );
    }
  }
}
