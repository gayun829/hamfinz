import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';

enum _ClosetTab { my, skin, pattern, accessory, background }

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  late UserProfile _profile;
  _ClosetTab _tab = _ClosetTab.accessory;
  ShopItem? _preview;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  List<ShopItem> get _visibleItems {
    switch (_tab) {
      case _ClosetTab.my:
        return ShopData.items
            .where((item) => _profile.ownedShopItemIds.contains(item.id))
            .toList();
      case _ClosetTab.skin:
        return ShopData.byCategory(ShopCategory.skin);
      case _ClosetTab.pattern:
        return ShopData.byCategory(ShopCategory.pattern);
      case _ClosetTab.accessory:
        return ShopData.byCategory(ShopCategory.accessory);
      case _ClosetTab.background:
        return ShopData.byCategory(ShopCategory.background);
    }
  }

  Future<void> _onItemTap(ShopItem item) async {
    final owned = _profile.ownedShopItemIds.contains(item.id);
    if (owned) {
      setState(() => _preview = item);
      return;
    }
    if (_profile.seeds < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '씨앗이 부족해요. ${item.name}은(는) ${item.price}씨앗이 필요해요.',
          ),
        ),
      );
      return;
    }
    _profile.seeds -= item.price;
    _profile.ownedShopItemIds = [..._profile.ownedShopItemIds, item.id];
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() => _preview = item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name}을(를) 구매했어요!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
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
              final previewHeight =
                  (constraints.maxHeight * 0.34).clamp(160.0, 280.0);
              final hamsterSize = (previewHeight * 0.58).clamp(96.0, 180.0);
              return Column(
                children: [
                  ShopHeader(
                    figma: figma,
                    title: '햄핀이 옷장',
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(
                    height: previewHeight,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(
                            color: FigmaShopTokens.previewBackground,
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: hamsterSize,
                            height: hamsterSize,
                            child: _preview == null
                                ? FigmaPng(
                                    FigmaAssets.hamsterAuth,
                                    width: hamsterSize,
                                    height: hamsterSize,
                                    fit: BoxFit.contain,
                                  )
                                : ShopHamsterSprite(
                                    column: _preview!.spriteCol,
                                    row: _preview!.spriteRow,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: s(14),
                          bottom: s(16),
                          child: GestureDetector(
                            onTap: () => setState(() => _preview = null),
                            child: Container(
                              width: s(FigmaShopTokens.resetButton)
                                  .clamp(36, 48),
                              height: s(FigmaShopTokens.resetButton)
                                  .clamp(36, 48),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '↺',
                                style: TextStyle(
                                  fontSize: s(22),
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(s(16), s(10), s(16), s(8)),
                    child: Row(
                      children: [
                        _tabLabel(figma, _ClosetTab.my, 'MY'),
                        SizedBox(width: s(16)),
                        _tabLabel(figma, _ClosetTab.skin, '스킨'),
                        SizedBox(width: s(16)),
                        _tabLabel(figma, _ClosetTab.pattern, '무늬'),
                        SizedBox(width: s(16)),
                        _tabLabel(figma, _ClosetTab.accessory, '악세서리'),
                        SizedBox(width: s(16)),
                        _tabLabel(figma, _ClosetTab.background, '배경'),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              _tab == _ClosetTab.my
                                  ? '아직 가진 아이템이 없어요'
                                  : '준비 중인 아이템이에요',
                              style: FigmaShopTokens.body(figma.scale),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              s(16),
                              s(12),
                              s(16),
                              s(24),
                            ),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: s(12),
                              mainAxisSpacing: s(12),
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ShopItemCard(
                                figma: figma,
                                item: item,
                                owned: _profile.ownedShopItemIds
                                    .contains(item.id),
                                onTap: () => _onItemTap(item),
                              );
                            },
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

  Widget _tabLabel(FigmaScale figma, _ClosetTab tab, String label) {
    final selected = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Text(
        label,
        style: FigmaShopTokens.tab(figma.scale, selected: selected),
      ),
    );
  }
}
