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

/// Figma `image 64` 스프라이트 한 칸.
class ShopHamsterSprite extends StatelessWidget {
  const ShopHamsterSprite({
    super.key,
    required this.column,
    required this.row,
  });

  final int column;
  final int row;

  @override
  Widget build(BuildContext context) {
        return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth;
        final cellH = constraints.maxHeight;
        if (!cellW.isFinite ||
            !cellH.isFinite ||
            cellW <= 0 ||
            cellH <= 0) {
          return const SizedBox.shrink();
        }
        final cols = ShopData.spriteColumns;
        final rows = ShopData.spriteRows;
        return ClipRect(
          child: OverflowBox(
            maxWidth: cellW * cols,
            maxHeight: cellH * rows,
            alignment: Alignment(
              cols == 1 ? 0 : -1 + (2 * column / (cols - 1)),
              rows == 1 ? 0 : -1 + (2 * row / (rows - 1)),
            ),
            child: Image.asset(
              FigmaAssets.shopHamsterSheet,
              width: cellW * cols,
              height: cellH * rows,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  FigmaAssets.hamsterAuth,
                  width: cellW,
                  height: cellH,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
        );
      },
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
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? ShopHamsterSprite(
                        column: item.spriteCol,
                        row: item.spriteRow,
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            ShopHamsterSprite(
                              column: item.spriteCol,
                              row: item.spriteRow,
                            ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(20), 0, s(20), s(16)),
              child: Container(
                height: s(32),
                decoration: BoxDecoration(
                  color: FigmaShopTokens.chip,
                  borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
                ),
                alignment: Alignment.center,
                child: owned
                    ? Text(
                        'Owned',
                        style: FigmaShopTokens.body(figma.scale).copyWith(
                          fontSize: 15 * figma.scale,
                        ),
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
