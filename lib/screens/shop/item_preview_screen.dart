import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';

class ItemPreviewScreen extends StatelessWidget {
  const ItemPreviewScreen({
    super.key,
    required this.item,
    required this.profile,
    required this.catalogItems,
    required this.onPurchase,
  });

  final ShopItem item;
  final UserProfile profile;
  final List<ShopItem> catalogItems;
  final Future<bool> Function() onPurchase;

  Future<void> _buy(BuildContext context) async {
    if (profile.ownedShopItemIds.contains(item.id)) {
      await onPurchase();
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${item.name}을 구매할까요?'),
        content: ShopSeedChip(
          figma: FigmaScale.ofLayout(
            const BoxConstraints.tightFor(width: 393, height: 852),
            designWidth: FigmaShopTokens.designWidth,
          ),
          seeds: item.price,
          iconSize: FigmaShopTokens.seedIconList,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('구매하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final purchased = await onPurchase();
    if (!purchased || !context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _PurchaseCompleteScreen(
          item: item,
          profile: profile,
          catalogItems: catalogItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final clampedScaler = TextScaler.linear(
      textScaler.scale(1).clamp(0.9, 1.1),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final figma = FigmaScale.ofLayout(
                constraints,
                designWidth: FigmaShopTokens.designWidth,
              );
              final s = figma.s;
              return Column(
                children: [
                  ShopHeader(
                    figma: figma,
                    title: '미리보기',
                    seeds: profile.seeds,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(s(10)),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: const Color(0xFFB6B6B6),
                              child: Center(
                                child: SizedBox(
                                  width: s(235),
                                  height: s(235),
                                  child: _PreviewHamster(
                                    item: item,
                                    profile: profile,
                                    catalogItems: catalogItems,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: s(14)),
                          Text(
                            item.name,
                            style: FigmaShopTokens.cardTitle(figma.scale),
                          ),
                          SizedBox(height: s(6)),
                          Text(
                            item.description,
                            style: FigmaShopTokens.body(figma.scale),
                          ),
                          SizedBox(height: s(14)),
                          _ActionButton(
                            label: profile.ownedShopItemIds.contains(item.id)
                                ? '착용하기'
                                : '구매하기',
                            onPressed: () => _buy(context),
                          ),
                          SizedBox(height: s(14)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewHamster extends StatelessWidget {
  const _PreviewHamster({
    required this.item,
    required this.profile,
    required this.catalogItems,
  });
  final ShopItem item;
  final UserProfile profile;
  final List<ShopItem> catalogItems;

  @override
  Widget build(BuildContext context) {
    final accessoryIds = item.category == ShopCategory.accessory
        ? [item.id]
        : profile.equippedAccessoryIds;
    final skinId = item.category == ShopCategory.skin
        ? item.id
        : profile.equippedSkinId;
    final patternId = item.category == ShopCategory.pattern
        ? item.id
        : profile.equippedPatternId;
    final backgroundId = item.category == ShopCategory.background
        ? item.id
        : profile.equippedBackgroundId;
    final layers = <Widget>[
      Image.asset(FigmaAssets.hamsterAuth, fit: BoxFit.contain),
    ];
    final ids = [backgroundId, skinId, patternId, ...accessoryIds];
    for (final id in ids) {
      final match = catalogItems.where((entry) => entry.id == id);
      if (match.isNotEmpty) {
        layers.add(
          ShopHamsterSprite(
            column: match.first.spriteCol,
            row: match.first.spriteRow,
          ),
        );
      }
    }
    return Stack(children: layers);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(onPressed: onPressed, child: Text(label)),
  );
}

class _PurchaseCompleteScreen extends StatelessWidget {
  const _PurchaseCompleteScreen({
    required this.item,
    required this.profile,
    required this.catalogItems,
  });
  final ShopItem item;
  final UserProfile profile;
  final List<ShopItem> catalogItems;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFD9F5FF),
    body: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          const Text(
            '구매 완료!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: _PreviewHamster(
                  item: item,
                  profile: profile,
                  catalogItems: catalogItems,
                ),
              ),
            ),
          ),
          Text(
            '${item.name}을 얻었어요!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
