import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';

enum _ClosetTab { my, skin, pattern, accessory, background }

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({
    super.key,
    required this.profile,
    this.initialPreview,
  });

  final UserProfile profile;
  final ShopItem? initialPreview;

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  late UserProfile _profile;
  _ClosetTab _tab = _ClosetTab.accessory;
  String? _stagedSkinId;
  String? _stagedPatternId;
  String? _stagedBackgroundId;
  final List<String> _stagedAccessoryIds = [];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _stagedSkinId = _profile.equippedSkinId;
    _stagedPatternId = _profile.equippedPatternId;
    _stagedBackgroundId = _profile.equippedBackgroundId;
    _stagedAccessoryIds.clear();
    _stagedAccessoryIds.addAll(_profile.equippedAccessoryIds);
  }

  List<ShopItem> get _visibleItems {
    switch (_tab) {
      case _ClosetTab.my:
        return ShopData.items
            .where((item) => !item.hideFromCloset && _profile.ownedShopItemIds.contains(item.id))
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
    setState(() {
      switch (item.category) {
        case ShopCategory.skin:
          _stagedSkinId = _stagedSkinId == item.id ? null : item.id;
          break;
        case ShopCategory.pattern:
          _stagedPatternId = _stagedPatternId == item.id ? null : item.id;
          break;
        case ShopCategory.accessory:
          if (_stagedAccessoryIds.contains(item.id)) {
            _stagedAccessoryIds.remove(item.id);
          } else {
            _stagedAccessoryIds.add(item.id);
          }
          break;
        case ShopCategory.background:
          _stagedBackgroundId = _stagedBackgroundId == item.id ? null : item.id;
          break;
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _seedShortageMessage(int total) {
    return '씨앗이 부족해요. 총 $total씨앗이 필요합니다. (현재 $_profile.seeds)';
  }

  Future<void> _purchasePreview() async {
    final stagedIds = <String>[];
    if (_stagedSkinId != null) stagedIds.add(_stagedSkinId!);
    if (_stagedPatternId != null) stagedIds.add(_stagedPatternId!);
    if (_stagedBackgroundId != null) stagedIds.add(_stagedBackgroundId!);
    stagedIds.addAll(_stagedAccessoryIds);

    // 구매 대상만 필터링
    final toBuy = stagedIds.where((id) => !_profile.ownedShopItemIds.contains(id)).toList();
    if (toBuy.isEmpty) {
      _showSnackBar('구매할 새 아이템이 없습니다.');
      return;
    }

    final itemsToBuy = toBuy.map((id) => ShopData.items.firstWhere((i) => i.id == id)).toList();
    final total = itemsToBuy.fold<int>(0, (s, it) => s + it.price);

    if (_profile.seeds < total) {
      _showSnackBar(_seedShortageMessage(total));
      return;
    }

    _profile.seeds -= total;
    _profile.ownedShopItemIds = [..._profile.ownedShopItemIds, ...toBuy];
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() {});
    _showSnackBar('아이템 ${toBuy.length}개를 구매했습니다.');
  }

  ShopItem? _itemById(String? id) {
    if (id == null) return null;
    try {
      return ShopData.items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  int get _stagedTotalPrice {
    final ids = <String>[];
    if (_stagedSkinId != null) ids.add(_stagedSkinId!);
    if (_stagedPatternId != null) ids.add(_stagedPatternId!);
    ids.addAll(_stagedAccessoryIds);
    final toBuy = ids.where((id) => !_profile.ownedShopItemIds.contains(id)).toList();
    return toBuy.map((id) => ShopData.items.firstWhere((i) => i.id == id).price).fold<int>(0, (s, p) => s + p);
  }

  Widget _buildCompositePreview(double width, double height) {
    // Order: base hamster -> background -> skin -> pattern -> accessories
    final List<Widget> layers = [];

    // base
    layers.add(Image.asset(
      FigmaAssets.hamsterAuth,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => const SizedBox.shrink(),
    ));

    final background = _itemById(_stagedPatternId);
    final skin = _itemById(_stagedSkinId);
    final pattern = _itemById(_stagedPatternId);

    if (background != null) {
      layers.add(ShopHamsterSprite(column: background.spriteCol, row: background.spriteRow));
    }
    if (skin != null) {
      layers.add(ShopHamsterSprite(column: skin.spriteCol, row: skin.spriteRow));
    }
    if (pattern != null) {
      layers.add(ShopHamsterSprite(column: pattern.spriteCol, row: pattern.spriteRow));
    }
    for (final accId in _stagedAccessoryIds) {
      final acc = _itemById(accId);
      if (acc != null) {
        layers.add(ShopHamsterSprite(column: acc.spriteCol, row: acc.spriteRow));
      }
    }

    return Stack(children: layers.map((w) => SizedBox(width: width, height: height, child: w)).toList());
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
                            child: _buildCompositePreview(hamsterSize, hamsterSize),
                          ),
                        ),
                        Positioned(
                          right: s(14),
                          bottom: s(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  _stagedSkinId = _profile.equippedSkinId;
                                  _stagedPatternId = _profile.equippedPatternId;
                                  _stagedBackgroundId = _profile.equippedBackgroundId;
                                  _stagedAccessoryIds.clear();
                                  _stagedAccessoryIds.addAll(_profile.equippedAccessoryIds);
                                }),
                                child: Container(
                                  width: s(44).clamp(40, 48),
                                  height: s(44).clamp(40, 48),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '↺',
                                    style: TextStyle(
                                      fontSize: s(18),
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: s(8)),
                              GestureDetector(
                                onTap: () async {
                                  final ids = <String>[];
                                  if (_stagedSkinId != null) ids.add(_stagedSkinId!);
                                  if (_stagedPatternId != null) ids.add(_stagedPatternId!);
                                  if (_stagedBackgroundId != null) ids.add(_stagedBackgroundId!);
                                  ids.addAll(_stagedAccessoryIds);
                                  final toBuy = ids.where((id) => !_profile.ownedShopItemIds.contains(id)).toList();

                                  if (toBuy.isNotEmpty) {
                                    final itemsToBuy = toBuy.map((id) => ShopData.items.firstWhere((i) => i.id == id)).toList();
                                    final total = itemsToBuy.fold<int>(0, (s, it) => s + it.price);
                                    if (_profile.seeds < total) {
                                      _showSnackBar(_seedShortageMessage(total));
                                      return;
                                    }
                                    _profile.seeds -= total;
                                    _profile.ownedShopItemIds = [..._profile.ownedShopItemIds, ...toBuy];
                                  }

                                  _profile.equippedSkinId = _stagedSkinId;
                                  _profile.equippedPatternId = _stagedPatternId;
                                  _profile.equippedBackgroundId = _stagedBackgroundId;
                                  _profile.equippedAccessoryIds = List<String>.from(_stagedAccessoryIds);

                                  await AuthService.instance.saveProfile(_profile);
                                  if (!mounted) return;
                                  _showSnackBar('저장되었습니다.');
                                },
                                child: Container(
                                  width: s(44).clamp(40, 48),
                                  height: s(44).clamp(40, 48),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '저장',
                                    style: TextStyle(
                                      fontSize: s(10),
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 구매 버튼: staged 총 가격을 보여주고 구매 실행
                        if ((_stagedSkinId != null || _stagedPatternId != null || _stagedAccessoryIds.isNotEmpty))
                          Positioned(
                            left: s(14),
                            bottom: s(16),
                            child: GestureDetector(
                              onTap: _purchasePreview,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: s(12)),
                                constraints: BoxConstraints(minHeight: s(40)),
                                decoration: BoxDecoration(
                                  color: FigmaShopTokens.chip,
                                  borderRadius: BorderRadius.circular(s(8)),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '구매',
                                      style: FigmaShopTokens.sectionTitle(figma.scale),
                                    ),
                                    SizedBox(width: s(8)),
                                    ShopSeedChip(
                                      figma: figma,
                                      seeds: _stagedTotalPrice,
                                      iconSize: const Size(16, 16),
                                    ),
                                  ],
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
                              final owned = _profile.ownedShopItemIds.contains(item.id);
                              Widget card = ShopItemCard(
                                figma: figma,
                                item: item,
                                owned: owned,
                                onTap: () => _onItemTap(item),
                              );

                              // MY 탭에서는 소유한 아이템에 대해 '장착' 토글 버튼을 보여줍니다.
                              if (_tab == _ClosetTab.my && owned) {
                                bool isEquipped() {
                                  return _stagedSkinId == item.id ||
                                      _stagedPatternId == item.id ||
                                      _stagedAccessoryIds.contains(item.id);
                                }

                                void toggleEquip() {
                                  setState(() {
                                    switch (item.category) {
                                      case ShopCategory.skin:
                                        _stagedSkinId = _stagedSkinId == item.id ? null : item.id;
                                        break;
                                      case ShopCategory.pattern:
                                        _stagedPatternId = _stagedPatternId == item.id ? null : item.id;
                                        break;
                                      case ShopCategory.accessory:
                                        if (_stagedAccessoryIds.contains(item.id)) {
                                          _stagedAccessoryIds.remove(item.id);
                                        } else {
                                          _stagedAccessoryIds.add(item.id);
                                        }
                                        break;
                                      case ShopCategory.background:
                                        _stagedPatternId = _stagedPatternId == item.id ? null : item.id;
                                        break;
                                    }
                                  });
                                }

                                return Column(
                                  children: [
                                    card,
                                    SizedBox(height: s(8)),
                                    GestureDetector(
                                      onTap: toggleEquip,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
                                        decoration: BoxDecoration(
                                          color: isEquipped() ? Colors.green.shade600 : FigmaShopTokens.chip,
                                          borderRadius: BorderRadius.circular(s(8)),
                                        ),
                                        child: Text(
                                          isEquipped() ? '장착 해제' : '장착',
                                          style: FigmaShopTokens.sectionTitle(figma.scale),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return card;
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
