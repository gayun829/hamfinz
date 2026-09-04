import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/shop_catalog_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';
import 'item_preview_screen.dart';

enum _ClosetTab { my, skin, pattern, accessory, background }

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({
    super.key,
    required this.profile,
    this.showCatalog = false,
  });

  final UserProfile profile;
  final bool showCatalog;

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
  List<ShopItem> _catalogItems = ShopData.items;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _stagedSkinId = _profile.equippedSkinId;
    _stagedPatternId = _profile.equippedPatternId;
    _stagedBackgroundId = _profile.equippedBackgroundId;
    _stagedAccessoryIds.clear();
    _stagedAccessoryIds.addAll(_profile.equippedAccessoryIds);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final items = await ShopCatalogService.instance.getItemsOrFallback();
    if (!mounted) return;
    setState(() => _catalogItems = items);
  }

  List<ShopItem> get _visibleItems {
    if (!widget.showCatalog) {
      return _catalogItems
          .where((item) => !item.hideFromCloset && _profile.ownedShopItemIds.contains(item.id))
          .toList();
    }
    switch (_tab) {
      case _ClosetTab.my:
        return _catalogItems
            .where((item) => !item.hideFromCloset && _profile.ownedShopItemIds.contains(item.id))
            .toList();
      case _ClosetTab.skin:
        return _catalogItems.where((item) => item.category == ShopCategory.skin && !item.hideFromCloset).toList();
      case _ClosetTab.pattern:
        return _catalogItems.where((item) => item.category == ShopCategory.pattern && !item.hideFromCloset).toList();
      case _ClosetTab.accessory:
        return _catalogItems.where((item) => item.category == ShopCategory.accessory && !item.hideFromCloset).toList();
      case _ClosetTab.background:
        return _catalogItems.where((item) => item.category == ShopCategory.background && !item.hideFromCloset).toList();
    }
  }

  Future<void> _onItemTap(ShopItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemPreviewScreen(
          item: item,
          profile: _profile,
          onPurchase: () => _purchaseOrEquipFromPreview(item),
        ),
      ),
    );
    if (!mounted) return;
    final latest = await AuthService.instance.getCurrentUser();
    if (latest != null) setState(() => _profile = latest);
  }

  Future<bool> _purchaseOrEquipFromPreview(ShopItem item) async {
    final owned = _profile.ownedShopItemIds.contains(item.id);
    var skinId = _profile.equippedSkinId;
    var patternId = _profile.equippedPatternId;
    var backgroundId = _profile.equippedBackgroundId;
    var accessoryIds = List<String>.from(_profile.equippedAccessoryIds);

    switch (item.category) {
      case ShopCategory.skin:
        skinId = item.id;
      case ShopCategory.pattern:
        patternId = item.id;
      case ShopCategory.accessory:
        accessoryIds = [item.id];
      case ShopCategory.background:
        backgroundId = item.id;
    }

    if (!owned && _profile.seeds < item.price) {
      _showSnackBar(_seedShortageMessage(item.price));
      return false;
    }
    await _equipOrBuyItem(
      item,
      skinId: skinId,
      patternId: patternId,
      backgroundId: backgroundId,
      accessoryIds: accessoryIds,
    );
    return true;
  }

  Future<void> _equipOrBuyItem(
    ShopItem item, {
    required String? skinId,
    required String? patternId,
    required String? backgroundId,
    required List<String> accessoryIds,
  }) async {
    final owned = _profile.ownedShopItemIds.contains(item.id);
    if (!owned) {
      if (_profile.seeds < item.price) {
        _showSnackBar(_seedShortageMessage(item.price));
        return;
      }
      _profile.seeds -= item.price;
      _profile.ownedShopItemIds = [..._profile.ownedShopItemIds, item.id];
    }

    _profile.equippedSkinId = skinId;
    _profile.equippedPatternId = patternId;
    _profile.equippedBackgroundId = backgroundId;
    _profile.equippedAccessoryIds = accessoryIds;
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() {
      _stagedSkinId = skinId;
      _stagedPatternId = patternId;
      _stagedBackgroundId = backgroundId;
      _stagedAccessoryIds
        ..clear()
        ..addAll(accessoryIds);
    });
    _showSnackBar(owned ? '${item.name}을(를) 착용했어요.' : '${item.name}을(를) 구매하고 착용했어요.');
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

  ShopItem? _itemById(String? id) {
    if (id == null) return null;
    try {
      return _catalogItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCompositePreview(
    double width,
    double height, {
    required String? skinId,
    required String? patternId,
    required String? backgroundId,
    required List<String> accessoryIds,
  }) {
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

    final background = _itemById(backgroundId);
    final skin = _itemById(skinId);
    final pattern = _itemById(patternId);

    if (background != null) {
      layers.add(ShopHamsterSprite(column: background.spriteCol, row: background.spriteRow));
    }
    if (skin != null) {
      layers.add(ShopHamsterSprite(column: skin.spriteCol, row: skin.spriteRow));
    }
    if (pattern != null) {
      layers.add(ShopHamsterSprite(column: pattern.spriteCol, row: pattern.spriteRow));
    }
    for (final accId in accessoryIds) {
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
                    title: widget.showCatalog ? '옷 상점' : '햄핀 옷장',
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(
                    height: previewHeight,
                    child: ColoredBox(
                      color: FigmaShopTokens.previewBackground,
                      child: Center(
                        child: SizedBox(
                          width: hamsterSize,
                          height: hamsterSize,
                          child: _buildCompositePreview(
                            hamsterSize,
                            hamsterSize,
                            skinId: _profile.equippedSkinId,
                            patternId: _profile.equippedPatternId,
                            backgroundId: _profile.equippedBackgroundId,
                            accessoryIds: _profile.equippedAccessoryIds,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showCatalog)
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
                              !widget.showCatalog || _tab == _ClosetTab.my
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
                                    if (owned &&
                                      (!widget.showCatalog || _tab == _ClosetTab.my)) {
                                bool isEquipped() {
                                  return _stagedSkinId == item.id ||
                                      _stagedPatternId == item.id ||
                                      _stagedBackgroundId == item.id ||
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
                                        _stagedBackgroundId = _stagedBackgroundId == item.id ? null : item.id;
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
