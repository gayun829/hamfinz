import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../theme/figma_home_fonts.dart';
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
    this.titleSize = 22,
  });

  final FigmaScale figma;
  final String title;
  final int seeds;
  final VoidCallback onBack;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Container(
      height: s(57),
      width: double.infinity,
      // Figma 글자 줄은 머리띠 가운데보다 살짝 아래(y=87)에 놓인다.
      padding: EdgeInsets.only(top: s(3)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: FigmaShopTokens.headerBorder, width: 2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: FigmaShopTokens.headerTitle(figma.scale, size: titleSize),
          ),
          Positioned(
            left: s(10),
            child: Tooltip(
              message: '뒤로',
              child: Semantics(
                button: true,
                label: '뒤로',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Padding(
                    padding: EdgeInsets.all(s(16)),
                    child: FigmaSvg(
                      FigmaAssets.friendsBackChevron,
                      width: s(10.644),
                      height: s(21.069),
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFD9D9D9),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: s(23),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: s(100)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShopSeedChip(
                  figma: figma,
                  seeds: seeds,
                  iconSize: FigmaShopTokens.seedIconHeader,
                  amountSize: 17.243,
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
    this.amountColor,
  });

  final FigmaScale figma;
  final int seeds;
  final Size iconSize;
  final double amountSize;
  final Color? amountColor;

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
          style: FigmaShopTokens.seedAmount(
            figma.scale,
            size: amountSize,
          ).copyWith(color: amountColor),
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
    this.displayPrice,
    this.selected = false,
  });

  final FigmaScale figma;
  final ShopItem item;
  final bool owned;
  final String? actionLabel;
  final int? displayPrice;
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
              ? Border.all(color: FigmaShopTokens.purchaseAction, width: 2)
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
                          item,
                          ...item.componentIds
                              .map(ShopData.find)
                              .whereType<ShopItem>(),
                        ],
                        skinId:
                            item.category == ShopCategory.skin ||
                                item.category == ShopCategory.bundle
                            ? item.id
                            : null,
                        patternId:
                            item.category == ShopCategory.clothing ||
                                item.category == ShopCategory.pattern
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
            if (item.componentIds.isNotEmpty && !owned)
              Text(
                '미보유 구성품 20% 할인',
                style: TextStyle(
                  fontSize: s(9),
                  color: const Color(0xFFF99832),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(9), 0, s(9), s(13)),
              child: Container(
                height: s(30),
                decoration: BoxDecoration(
                  color: owned && actionLabel == null
                      ? FigmaShopTokens.chipOwned
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
                          fontFamily: FigmaHomeFonts.inter,
                          fontFamilyFallback: const [FigmaHomeFonts.pretendard],
                          fontWeight: FontWeight.w600,
                          fontSize: 13.9 * figma.scale,
                          color: FigmaShopTokens.chipAmount,
                        ),
                      )
                    : ShopSeedChip(
                        figma: figma,
                        seeds: displayPrice ?? item.price,
                        iconSize: const Size(17, 17),
                        amountSize: 13.9,
                        amountColor: FigmaShopTokens.chipAmount,
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
    if (item.imageLayers.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          for (final path in item.imageLayers)
            Image.asset(path, fit: BoxFit.contain),
        ],
      );
    }
    if (item.assetPath != null) {
      if (item.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(item.assetPath!, fit: BoxFit.contain);
      }
      return Image.asset(item.assetPath!, fit: BoxFit.contain);
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
  /// 기준이라, 카탈로그에 없는 아이템은 안 입은 것으로 보고 기본 햄핀이를 그린다.
  factory EquippedLook.of(UserProfile profile, List<ShopItem> catalog) {
    // 소모품(방어권·에너지)은 그릴 이미지가 없어 입은 것으로 치지 않는다.
    final drawable = {
      for (final item in catalog)
        if (item.assetPath != null || item.imageLayers.isNotEmpty) item.id,
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

  Widget avatar() => ShopAvatar(
    catalogItems: catalog,
    skinId: skinId,
    patternId: patternId,
    accessoryIds: accessoryIds,
  );
}

/// 동그라미 안에 햄스터 얼굴만 보이도록 [ShopAvatar]를 키워서 자른다.
/// 친구 순위 리스트처럼 옷·무늬·배경 없이 스킨과 악세서리만 그린다.
class HamsterFace extends StatelessWidget {
  const HamsterFace({super.key, this.skinId, this.accessoryIds = const []});

  final String? skinId;
  final List<String> accessoryIds;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;
      // 전신 캔버스에서 머리는 폭의 73%를 차지하고 세로 35% 지점이 중심이다.
      // Figma처럼 귀까지 동그라미 안에 들어오게 머리를 폭의 79%로 두고,
      // 중심은 살짝 아래(56%)에 맞춘다.
      return ClipOval(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -size * 0.04,
              top: size * 0.18,
              width: size * 1.08,
              height: size * 1.08,
              child: ShopAvatar(skinId: skinId, accessoryIds: accessoryIds),
            ),
          ],
        ),
      );
    },
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

    ShopItem? resolve(String? id) => lookup(id) ?? ShopData.find(id);
    var skin = resolve(skinId);
    ShopItem? clothes = resolve(patternId);
    ShopItem? accessory = accessoryIds.isEmpty
        ? null
        : resolve(accessoryIds.last);
    if (skin?.componentIds.isNotEmpty == true) {
      final bundle = skin!;
      skin = null;
      for (final id in bundle.componentIds) {
        final part = resolve(id);
        if (part?.category == ShopCategory.skin) skin = part;
        if (part?.category == ShopCategory.clothing) clothes = part;
        if (part?.category == ShopCategory.accessory) accessory = part;
      }
    }
    final layers = [
      resolve(backgroundId),
      skin ?? ShopData.find(ShopData.defaultSkinId),
      clothes,
      accessory,
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
