import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/shop_catalog_service.dart';
import '../../services/shop_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';
import 'closet_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _maxStudyGuards = 4;
  static const _energyPackAmount = 20;

  late UserProfile _profile;
  List<ShopItem> _catalogItems = ShopData.items;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final items = await ShopCatalogService.instance.getItemsOrFallback();
    if (!mounted) return;
    setState(() => _catalogItems = items);
  }

  ShopItem _catalogItem(String id) => _catalogItems.firstWhere(
    (item) => item.id == id,
    orElse: () => ShopData.items.firstWhere((item) => item.id == id),
  );

  Future<void> _buyStudyGuard() async {
    if (_profile.studyGuardCount >= _maxStudyGuards) {
      _showSnackBar('방어권은 최대 4개까지 보유할 수 있어요.');
      return;
    }
    final price = _catalogItem('study_guard').price;
    if (_profile.seeds < price) {
      _showSnackBar('씨앗이 부족해요. $price씨앗이 필요합니다.');
      return;
    }

    final result = await ShopService.instance.purchaseItem(
      profile: _profile,
      itemId: 'study_guard',
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      _showSnackBar(result.message ?? '구매에 실패했어요.');
      return;
    }
    setState(() {});
    _showSnackBar('연속 학습 방어권을 1개 구매했어요.');
  }

  Future<void> _buyEnergy() async {
    if (_profile.energy >= 100) {
      _showSnackBar('에너지가 이미 가득 차 있어요.');
      return;
    }
    final price = _catalogItem('energy_pack').price;
    if (_profile.seeds < price) {
      _showSnackBar('씨앗이 부족해요. $price씨앗이 필요합니다.');
      return;
    }

    final result = await ShopService.instance.purchaseItem(
      profile: _profile,
      itemId: 'energy_pack',
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      _showSnackBar(result.message ?? '구매에 실패했어요.');
      return;
    }
    setState(() {});
    _showSnackBar('에너지 $_energyPackAmount을 구매했어요.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCloset() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ClosetScreen(profile: _profile)));
    if (!mounted) return;
    final latest = await AuthService.instance.getCurrentUser();
    if (!mounted || latest == null) return;
    setState(() => _profile = latest);
  }

  Future<void> _openClothingShop() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClosetScreen(profile: _profile, showCatalog: true),
      ),
    );
    await _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    if (!mounted) return;
    final latest = await AuthService.instance.getCurrentUser();
    if (!mounted || latest == null) return;
    setState(() => _profile = latest);
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final clampedScaler = TextScaler.linear(
      textScaler.scale(1).clamp(0.9, 1.1),
    );

    return Scaffold(
      backgroundColor: FigmaShopTokens.background,
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
                    title: '아이템 상점',
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        s(FigmaShopTokens.pagePadding),
                        s(26),
                        s(FigmaShopTokens.pagePadding),
                        s(24),
                      ),
                      children: [
                        _ShopBanner(
                          figma: figma,
                          title: '햄핀이 옷장',
                          eyebrow: '햄핀이 꾸미러 가기',
                          subtitle: '내가 가진 아이템으로\n햄핀을 꾸며보세요!',
                          color: const Color(0xFFCCEF96),
                          asset: FigmaAssets.shopClosetBanner,
                          fallbackAsset: FigmaAssets.hamsterAuth,
                          onTap: _openCloset,
                        ),
                        SizedBox(height: s(23)),
                        _ShopBanner(
                          figma: figma,
                          title: '햄핀이 옷 상점',
                          eyebrow: '새로운 옷을 만나보세요!',
                          subtitle: '보유한 옷과 구매 가능한\n옷을 한눈에 볼 수 있어요!',
                          color: const Color(0xFFCAF5FF),
                          bottomColor: const Color(0xFFF2C796),
                          asset: FigmaAssets.shopClothingBanner,
                          fallbackAsset: FigmaAssets.hamsterAuth,
                          onTap: _openClothingShop,
                        ),
                        SizedBox(height: s(23)),
                        SizedBox(height: s(14)),
                        Text(
                          '아이템 목록',
                          style: FigmaShopTokens.sectionTitle(figma.scale),
                        ),
                        SizedBox(height: s(8)),
                        Row(
                          children: [
                            Expanded(
                              child: _ItemPurchaseTile(
                                figma: figma,
                                title: '방어햄',
                                price: _catalogItem('study_guard').price,
                                item: _catalogItem('study_guard'),
                                onTap: _buyStudyGuard,
                              ),
                            ),
                            SizedBox(width: s(8)),
                            Expanded(
                              child: _ItemPurchaseTile(
                                figma: figma,
                                title: '에너지햄',
                                price: _catalogItem('energy_pack').price,
                                item: _catalogItem('energy_pack'),
                                onTap: _buyEnergy,
                              ),
                            ),
                          ],
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
}

class _ShopBanner extends StatelessWidget {
  const _ShopBanner({
    required this.figma,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.color,
    this.bottomColor,
    required this.asset,
    required this.fallbackAsset,
    required this.onTap,
  });
  final FigmaScale figma;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color color;
  final Color? bottomColor;
  final String asset;
  final String fallbackAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: s(bottomColor == null ? 164 : 220),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
        ),
        child: Stack(
          children: [
            if (bottomColor != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: s(55),
                child: ColoredBox(color: bottomColor!),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                s(19),
                s(bottomColor == null ? 32 : 36),
                s(145),
                s(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: FigmaShopTokens.body(
                      figma.scale,
                    ).copyWith(fontSize: 13 * figma.scale),
                  ),
                  SizedBox(height: s(3)),
                  Text(
                    title,
                    style: FigmaShopTokens.cardTitle(
                      figma.scale,
                    ).copyWith(fontSize: 24 * figma.scale),
                  ),
                  SizedBox(height: s(20)),
                  Text(
                    subtitle,
                    style: FigmaShopTokens.body(
                      figma.scale,
                    ).copyWith(fontSize: 13 * figma.scale),
                  ),
                ],
              ),
            ),
            Positioned(
              right: s(34),
              bottom: s(bottomColor == null ? 12 : 35),
              width: s(bottomColor == null ? 158 : 130),
              height: s(bottomColor == null ? 140 : 145),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(fallbackAsset, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              right: s(10),
              top: s(bottomColor == null ? 65 : 92),
              child: Icon(
                Icons.chevron_right,
                size: s(34),
                color: bottomColor == null
                    ? const Color(0xFFB1D981)
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPurchaseTile extends StatelessWidget {
  const _ItemPurchaseTile({
    required this.figma,
    required this.title,
    required this.price,
    required this.item,
    required this.onTap,
  });
  final FigmaScale figma;
  final String title;
  final int price;
  final ShopItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(12)),
      child: Container(
        height: s(200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s(12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: FigmaShopTokens.previewBackground,
                child: Center(child: ShopItemImage(item: item)),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: s(8)),
              child: Text(
                title,
                style: FigmaShopTokens.body(figma.scale).copyWith(
                  fontSize: 14 * figma.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: s(8)),
              child: ShopSeedChip(
                figma: figma,
                seeds: price,
                iconSize: FigmaShopTokens.seedIconList,
                amountSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
