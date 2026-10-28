import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
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
    return Container(
      height: s(72),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E4E4))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: FigmaShopTokens.headerTitle(figma.scale)),
          Positioned(
            left: s(14),
            child: IconButton(
              tooltip: '뒤로',
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFFD6D6D6),
                size: s(26),
              ),
            ),
          ),
          Positioned(
            right: s(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: s(94)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShopSeedChip(
                  figma: figma,
                  seeds: seeds,
                  iconSize: FigmaShopTokens.seedIconHeader,
                  amountSize: 18,
                ),
              ),
            ),
          ),
        ],
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
    this.actionLabel,
    this.selected = false,
  });

  final FigmaScale figma;
  final ShopItem item;
  final bool owned;
  final String? actionLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FigmaShopTokens.card,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
          border: selected
              ? Border.all(color: const Color(0xFF38C5F5), width: 2)
              : null,
          borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(s(6), s(8), s(6), s(4)),
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
              padding: EdgeInsets.fromLTRB(s(9), 0, s(9), s(13)),
              child: Container(
                height: s(30),
                decoration: BoxDecoration(
                  color: owned && actionLabel == null
                      ? const Color(0xFFFFF7D0)
                      : FigmaShopTokens.chip,
                  borderRadius: BorderRadius.circular(
                    s(FigmaShopTokens.cardRadius),
                  ),
                ),
                alignment: Alignment.center,
                child: actionLabel != null || owned
                    ? Text(
                        actionLabel ?? '보유',
                        style: FigmaShopTokens.body(figma.scale).copyWith(
                          fontSize: 12 * figma.scale,
                          color: const Color(0xFFF99832),
                        ),
                      )
                    : ShopSeedChip(
                        figma: figma,
                        seeds: item.price,
                        iconSize: const Size(17, 17),
                        amountSize: 14,
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
      if (item.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(item.assetPath!, fit: BoxFit.contain);
      }
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

/// 프로필에 장착한 스킨·무늬·악세서리. 홈·마이페이지가 같은 판정을 쓴다.
///
/// 기본 모습(기본 스킨, 무늬·악세서리 없음)이면 [isCustom]이 false라
/// 각 화면이 원래 Figma 햄핀이를 그대로 쓴다. 배경은 화면마다 따로 있어 뺀다.
class EquippedLook {
  const EquippedLook({
    required this.catalog,
    this.skinId,
    this.patternId,
    this.accessoryIds = const [],
  });

  /// [catalog]에서 그릴 수 있는 아이템만 남긴다. 스킨·무늬·악세서리 모두 같은
  /// 기준이라, 카탈로그에 아직 없는 아이템(Firestore 전용)은 불러오기 전까지
  /// 안 입은 것으로 보고 기본 햄핀이를 그린다.
  factory EquippedLook.of(UserProfile profile, List<ShopItem> catalog) {
    // 소모품(방어권·에너지)은 그릴 이미지가 없어 입은 것으로 치지 않는다.
    final drawable = {
      for (final item in catalog)
        if (item.assetPath != null || item.imageUrl?.isNotEmpty == true)
          item.id,
    };
    String? keep(String? id) => drawable.contains(id) ? id : null;
    return EquippedLook(
      catalog: catalog,
      skinId: keep(profile.equippedSkinId),
      patternId: keep(profile.equippedPatternId),
      accessoryIds: [
        for (final id in profile.equippedAccessoryIds)
          if (drawable.contains(id)) id,
      ],
    );
  }

  final List<ShopItem> catalog;
  final String? skinId;
  final String? patternId;
  final List<String> accessoryIds;

  bool get isCustom =>
      (skinId != null && skinId != ShopData.defaultSkinId) ||
      patternId != null ||
      accessoryIds.isNotEmpty;

  /// 머리 장식이 있는 악세서리를 하나라도 끼고 있는지.
  bool get wearsHeadwear =>
      catalog.any((item) => item.coversHead && accessoryIds.contains(item.id));

  Widget avatar() => ShopAvatar(
    catalogItems: catalog,
    skinId: skinId,
    patternId: patternId,
    accessoryIds: accessoryIds,
  );
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
        ShopData.items.firstWhere((i) => i.id == ShopData.defaultSkinId);
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
