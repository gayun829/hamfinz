import 'package:flutter/material.dart';

import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/shop_catalog_service.dart';
import '../../services/shop_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';
import '../../widgets/shop/closet_stage.dart';

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
  _ClosetTab _tab = _ClosetTab.skin;
  bool _saving = false;
  ShopItem? _selectedItem;
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

  bool _owns(ShopItem item) =>
      item.included || _profile.ownedShopItemIds.contains(item.id);

  List<ShopItem> get _visibleItems {
    final items = _filteredItems;
    if (!widget.showCatalog) return items;
    return [...items.where((item) => !_owns(item)), ...items.where(_owns)];
  }

  List<ShopItem> get _filteredItems {
    final category = switch (_tab) {
      _ClosetTab.skin => ShopCategory.skin,
      _ClosetTab.pattern => ShopCategory.pattern,
      _ClosetTab.accessory => ShopCategory.accessory,
      _ClosetTab.background => ShopCategory.background,
      _ClosetTab.my => null,
    };
    return _catalogItems
        .where(
          (item) =>
              !item.hideFromCloset &&
              (widget.showCatalog || _owns(item)) &&
              (category == null || item.category == category),
        )
        .toList();
  }

  String? _normalizedSkin(String? id) => id == 'skin_default' ? null : id;

  bool get _hasChanges =>
      _normalizedSkin(_stagedSkinId) !=
          _normalizedSkin(_profile.equippedSkinId) ||
      _stagedPatternId != _profile.equippedPatternId ||
      _stagedBackgroundId != _profile.equippedBackgroundId ||
      _stagedAccessoryIds.length != _profile.equippedAccessoryIds.length ||
      !_stagedAccessoryIds.every(_profile.equippedAccessoryIds.contains);

  bool _isEquipped(ShopItem item) =>
      (item.included && _normalizedSkin(_stagedSkinId) == null) ||
      _stagedSkinId == item.id ||
      _stagedPatternId == item.id ||
      _stagedBackgroundId == item.id ||
      _stagedAccessoryIds.contains(item.id);

  void _stageItem(ShopItem item) {
    if (_saving || !_owns(item)) return;
    final removing = _isEquipped(item);
    setState(() {
      switch (item.category) {
        case ShopCategory.skin:
          _stagedSkinId = removing ? null : item.id;
        case ShopCategory.pattern:
          _stagedPatternId = removing ? null : item.id;
        case ShopCategory.background:
          _stagedBackgroundId = removing ? null : item.id;
        case ShopCategory.accessory:
          _stagedAccessoryIds
            ..clear()
            ..addAll(removing ? <String>[] : [item.id]);
      }
    });
  }

  Future<void> _saveOutfit() async {
    if (_saving || !_hasChanges) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateShopEquipment(
        skinId: _stagedSkinId,
        patternId: _stagedPatternId,
        backgroundId: _stagedBackgroundId,
        accessoryIds: List.of(_stagedAccessoryIds),
      );
      if (!mounted) return;
      setState(() {
        _profile.equippedSkinId = _stagedSkinId;
        _profile.equippedPatternId = _stagedPatternId;
        _profile.equippedBackgroundId = _stagedBackgroundId;
        _profile.equippedAccessoryIds = List.of(_stagedAccessoryIds);
      });
      _showSnackBar('착용 정보를 저장했어요.');
    } catch (_) {
      _showSnackBar('저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onItemTap(ShopItem item) {
    if (_saving) return;
    if (!widget.showCatalog) {
      _stageItem(item);
      return;
    }
    setState(() {
      _selectedItem = item;
      _stagedSkinId = item.category == ShopCategory.skin
          ? item.id
          : _profile.equippedSkinId;
      _stagedPatternId = item.category == ShopCategory.pattern
          ? item.id
          : _profile.equippedPatternId;
      _stagedBackgroundId = item.category == ShopCategory.background
          ? item.id
          : _profile.equippedBackgroundId;
      _stagedAccessoryIds
        ..clear()
        ..addAll(
          item.category == ShopCategory.accessory
              ? [item.id]
              : _profile.equippedAccessoryIds,
        );
    });
  }

  Future<void> _confirmSelection() async {
    final item = _selectedItem;
    if (item == null || _saving) return;
    final owned = _owns(item);
    if (!owned) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${item.name}을 구매할까요?'),
          content: Text('${item.price}씨앗이 필요해요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('구매하기'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final success = await _purchaseOrEquipFromPreview(item);
    if (success && mounted) {
      setState(() => _selectedItem = null);
      _showSnackBar(owned ? '착용했어요.' : '구매하고 착용했어요.');
    }
  }

  Future<bool> _purchaseOrEquipFromPreview(ShopItem item) async {
    final owned =
        (item.included || _profile.ownedShopItemIds.contains(item.id));
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
    return _equipOrBuyItem(
      item,
      skinId: skinId,
      patternId: patternId,
      backgroundId: backgroundId,
      accessoryIds: accessoryIds,
    );
  }

  Future<bool> _equipOrBuyItem(
    ShopItem item, {
    required String? skinId,
    required String? patternId,
    required String? backgroundId,
    required List<String> accessoryIds,
  }) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final owned =
          item.included || _profile.ownedShopItemIds.contains(item.id);
      if (!owned) {
        final result = await ShopService.instance.purchaseItem(
          profile: _profile,
          itemId: item.id,
        );
        if (!mounted) return false;
        if (!result.isSuccess) {
          _showSnackBar(result.message ?? '구매에 실패했어요.');
          return false;
        }
      }
      await AuthService.instance.updateShopEquipment(
        skinId: skinId,
        patternId: patternId,
        backgroundId: backgroundId,
        accessoryIds: accessoryIds,
      );
      if (!mounted) return false;
      setState(() {
        _profile.equippedSkinId = _stagedSkinId = skinId;
        _profile.equippedPatternId = _stagedPatternId = patternId;
        _profile.equippedBackgroundId = _stagedBackgroundId = backgroundId;
        _profile.equippedAccessoryIds = List.of(accessoryIds);
        _stagedAccessoryIds
          ..clear()
          ..addAll(accessoryIds);
      });
      return true;
    } catch (_) {
      _showSnackBar('착용을 저장하지 못했어요. 구매한 아이템은 옷장에서 다시 착용할 수 있어요.');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return Scaffold(
      backgroundColor: FigmaShopTokens.background,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(1).clamp(0.9, 1.1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final figma = FigmaScale.ofLayout(
                constraints,
                designWidth: FigmaShopTokens.designWidth,
              );
              final s = figma.s;
              final previewHeight = (constraints.maxHeight * .36).clamp(
                140.0,
                s(280),
              );
              final showAction = widget.showCatalog
                  ? _selectedItem != null
                  : _hasChanges;
              return Column(
                children: [
                  ShopHeader(
                    figma: figma,
                    title: widget.showCatalog ? '햄핀이 옷 상점' : '햄핀이 옷장',
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  ClosetStage(
                    height: previewHeight,
                    avatar: ShopAvatar(
                      catalogItems: _catalogItems,
                      skinId: _stagedSkinId,
                      patternId: _stagedPatternId,
                      backgroundId: _stagedBackgroundId,
                      accessoryIds: _stagedAccessoryIds,
                    ),
                  ),
                  Container(
                    height: s(56),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE3E3E3), width: 2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: s(20)),
                      child: Row(
                        children: [
                          _tabLabel(figma, _ClosetTab.skin, '스킨'),
                          _tabLabel(figma, _ClosetTab.pattern, '무늬'),
                          _tabLabel(figma, _ClosetTab.accessory, '악세서리'),
                          _tabLabel(figma, _ClosetTab.background, '배경'),
                          _tabLabel(figma, _ClosetTab.my, '전체'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (items.isEmpty)
                          Center(
                            child: Text(
                              widget.showCatalog
                                  ? '준비 중인 아이템이에요'
                                  : '아직 가진 아이템이 없어요',
                              style: FigmaShopTokens.body(figma.scale),
                            ),
                          )
                        else
                          GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              s(20),
                              s(23),
                              s(20),
                              showAction ? s(92) : s(24),
                            ),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: s(10),
                                  mainAxisSpacing: s(16),
                                  childAspectRatio: 111 / 145,
                                ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ShopItemCard(
                                key: ValueKey('shop-item-${item.id}'),
                                figma: figma,
                                item: item,
                                owned: _owns(item),
                                actionLabel: widget.showCatalog
                                    ? null
                                    : (_isEquipped(item) ? '착용 중' : '착용하기'),
                                selected: widget.showCatalog
                                    ? _selectedItem?.id == item.id
                                    : _isEquipped(item),
                                onTap: () => _onItemTap(item),
                              );
                            },
                          ),
                        if (showAction)
                          Positioned(
                            left: s(23),
                            right: s(23),
                            bottom: s(16),
                            child: SizedBox(
                              height: s(52),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF38C5F5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(s(14)),
                                  ),
                                  textStyle: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: _saving
                                    ? null
                                    : (widget.showCatalog
                                          ? _confirmSelection
                                          : _saveOutfit),
                                child: Text(
                                  _saving
                                      ? '저장 중…'
                                      : widget.showCatalog
                                      ? (_owns(_selectedItem!)
                                            ? '착용하기'
                                            : '구매하기')
                                      : '저장',
                                ),
                              ),
                            ),
                          ),
                      ],
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
    return InkWell(
      onTap: _saving
          ? null
          : () => setState(() {
              _tab = tab;
              if (widget.showCatalog) {
                _selectedItem = null;
                _stagedSkinId = _profile.equippedSkinId;
                _stagedPatternId = _profile.equippedPatternId;
                _stagedBackgroundId = _profile.equippedBackgroundId;
                _stagedAccessoryIds
                  ..clear()
                  ..addAll(_profile.equippedAccessoryIds);
              }
            }),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: figma.s(12)),
        child: Text(
          label,
          style: FigmaShopTokens.tab(figma.scale, selected: _tab == tab),
        ),
      ),
    );
  }
}
