import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../theme/figma_shop_tokens.dart';
import '../figma/figma_asset_image.dart';
import '../figma/figma_scale.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.figma,
    required this.title,
    required this.seeds,
    required this.onBack,
  });

  final FigmaScale figma;
  final String title;
  final int seeds;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Padding(
      padding: EdgeInsets.fromLTRB(s(4), s(4), s(8), s(4)),
      child: SizedBox(
        height: s(48).clamp(44, 56),
        child: Row(
          children: [
            SizedBox(
              width: s(48),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onBack,
                icon: Text(
                  '<',
                  style: TextStyle(
                    fontSize: s(32),
                    fontWeight: FontWeight.w600,
                    color: FigmaShopTokens.seed,
                    height: 1,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: FigmaShopTokens.headerTitle(figma.scale),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: s(14)),
              child: ShopSeedChip(
                figma: figma,
                seeds: seeds,
                iconSize: FigmaShopTokens.seedIconHeader,
                amountSize: 17.243,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopSeedChip extends StatelessWidget {
  const ShopSeedChip({
    super.key,
    required this.figma,
    required this.seeds,
    required this.iconSize,
    this.amountSize = 10,
  });

  final FigmaScale figma;
  final int seeds;
  final Size iconSize;
  final double amountSize;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FigmaSvg(
          FigmaAssets.shopSeedPouch,
          width: s(iconSize.width),
          height: s(iconSize.height),
          fit: BoxFit.contain,
        ),
        SizedBox(width: s(6)),
        Text(
          '$seeds',
          style: FigmaShopTokens.seedAmount(figma.scale, size: amountSize),
        ),
      ],
    );
  }
}

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.figma,
    required this.item,
    required this.owned,
    required this.onTap,
  });

  final FigmaScale figma;
  final ShopItem item;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FigmaShopTokens.card,
          borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(s(12), s(12), s(12), s(8)),
                child: item.usesSharedCanvas
                    ? ShopAvatar(
                        catalogItems: [
                          ...ShopData.items.where((i) => i.id != item.id),
                          item,
                        ],
                        skinId: item.category == ShopCategory.skin
                            ? item.id
                            : null,
                        patternId: item.category == ShopCategory.pattern
                            ? item.id
                            : null,
                        backgroundId: item.category == ShopCategory.background
                            ? item.id
                            : null,
                        accessoryIds: item.category == ShopCategory.accessory
                            ? [item.id]
                            : const [],
                      )
                    : ShopItemImage(item: item),
              ),
            ),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigmaShopTokens.body(figma.scale),
            ),
            SizedBox(height: s(6)),
            Padding(
              padding: EdgeInsets.fromLTRB(s(20), 0, s(20), s(16)),
              child: Container(
                height: s(32),
                decoration: BoxDecoration(
                  color: FigmaShopTokens.chip,
                  borderRadius: BorderRadius.circular(
                    s(FigmaShopTokens.cardRadius),
                  ),
                ),
                alignment: Alignment.center,
                child: owned
                    ? Text(
                        item.included ? '기본 제공' : '보유 중',
                        style: FigmaShopTokens.body(
                          figma.scale,
                        ).copyWith(fontSize: 15 * figma.scale),
                      )
                    : ShopSeedChip(
                        figma: figma,
                        seeds: item.price,
                        iconSize: FigmaShopTokens.seedIconList,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every local layer keeps its original common canvas coordinates.
class ShopItemImage extends StatelessWidget {
  const ShopItemImage({super.key, required this.item});
  final ShopItem item;
  @override
  Widget build(BuildContext context) {
    if (item.assetPath != null) {
      return Image.asset(item.assetPath!, fit: BoxFit.contain);
    }
    if (item.imageUrl?.isNotEmpty == true) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) =>
            const Icon(Icons.broken_image_outlined),
      );
    }
    return Icon(
      item.id == 'study_guard'
          ? Icons.shield_rounded
          : item.id == 'energy_pack'
          ? Icons.bolt_rounded
          : Icons.checkroom_rounded,
      size: 64,
      color: const Color(0xFF38C5F5),
    );
  }
}

class ShopAvatar extends StatelessWidget {
  const ShopAvatar({
    super.key,
    this.catalogItems = ShopData.items,
    this.skinId,
    this.patternId,
    this.backgroundId,
    this.accessoryIds = const [],
  });
  final List<ShopItem> catalogItems;
  final String? skinId, patternId, backgroundId;
  final List<String> accessoryIds;
  @override
  Widget build(BuildContext context) {
    ShopItem? lookup(String? id) {
      for (final item in catalogItems) {
        if (item.id == id) return item;
      }
      return null;
    }

    final skin =
        lookup(skinId) ??
        ShopData.items.firstWhere((i) => i.id == 'skin_default');
    final layers = [
      lookup(backgroundId),
      skin,
      lookup(patternId),
      ...accessoryIds.map(lookup),
    ].whereType<ShopItem>();
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final item in layers)
                Transform.scale(
                  scale: item.usesSharedCanvas ? 1.65 : 1,
                  child: ShopItemImage(key: ValueKey(item.id), item: item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
