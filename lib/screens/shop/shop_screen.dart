import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/shop_catalog_service.dart';
import '../../services/shop_service.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
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
      backgroundColor: const Color(0xFFFBFBFB),
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
                  _ItemShopHeader(
                    figma: figma,
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        s(FigmaShopTokens.pagePadding),
                        s(27),
                        s(FigmaShopTokens.pagePadding),
                        s(24),
                      ),
                      children: [
                        _ClosetBanner(figma: figma, onTap: _openCloset),
                        SizedBox(height: s(23)),
                        _ClothingShopBanner(
                          figma: figma,
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

/// Figma `675:454` 아이템 상점창 상단 바 (상태바 아래 57px).
class _ItemShopHeader extends StatelessWidget {
  const _ItemShopHeader({
    required this.figma,
    required this.seeds,
    required this.onBack,
  });
  final FigmaScale figma;
  final int seeds;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Container(
      height: s(57),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '아이템 상점',
            style: TextStyle(
              fontSize: 22 * figma.scale,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Positioned(
            left: s(10),
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
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: s(14),
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

/// 상점 배너 공통 카드: 그림자, 둥근 모서리, 바닥 나무판, 오른쪽 화살표.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.figma,
    required this.height,
    required this.decoration,
    required this.chevronAsset,
    required this.chevronTop,
    required this.onTap,
    required this.children,
  });
  final FigmaScale figma;
  final double height;
  final BoxDecoration decoration;
  final String chevronAsset;
  final double chevronTop;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final radius = BorderRadius.circular(s(13));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: s(height),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE5E5E5), blurRadius: 12.2),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: decoration,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: s(-4),
                  top: s(height - 46),
                  width: s(361),
                  height: s(46),
                  child: Image.asset(
                    FigmaAssets.shopBannerFloor,
                    fit: BoxFit.fill,
                  ),
                ),
                ...children,
                Positioned(
                  left: s(326),
                  top: s(chevronTop),
                  child: Transform.flip(
                    flipX: true,
                    child: FigmaSvg(
                      chevronAsset,
                      width: s(10.644),
                      height: s(21.069),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `675:479` 햄핀이 옷장 배너.
class _ClosetBanner extends StatelessWidget {
  const _ClosetBanner({required this.figma, required this.onTap});
  final FigmaScale figma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return _BannerCard(
      figma: figma,
      height: 164,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC7EE97), Color(0xFFFFF8EA)],
          stops: [0, 0.95],
        ),
      ),
      chevronAsset: FigmaAssets.shopBannerChevronGreen,
      chevronTop: 72,
      onTap: onTap,
      children: [
        Positioned(
          left: s(188),
          top: s(15),
          width: s(110.7),
          height: s(127.7),
          child: Image.asset(FigmaAssets.shopBannerCloset, fit: BoxFit.fill),
        ),
        Positioned(
          left: s(19),
          top: s(33),
          child: Text('햄핀이 옷장', style: _bannerTitle(figma.scale)),
        ),
        Positioned(
          left: s(20),
          top: s(77),
          child: Text('햄핀이 꾸미러 가기', style: _bannerBody(figma.scale, 17)),
        ),
      ],
    );
  }
}

/// Figma `675:491` 햄핀이 옷 상점 배너.
class _ClothingShopBanner extends StatelessWidget {
  const _ClothingShopBanner({required this.figma, required this.onTap});
  final FigmaScale figma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return _BannerCard(
      figma: figma,
      height: 204,
      decoration: const BoxDecoration(color: Color(0xFFFFF8D3)),
      chevronAsset: FigmaAssets.shopBannerChevronWood,
      chevronTop: 99,
      onTap: onTap,
      children: [
        Positioned(
          left: s(32),
          top: s(28),
          width: s(292),
          height: s(148),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: s(50),
              sigmaY: s(50),
              tileMode: TileMode.decal,
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.elliptical(146, 74)),
              ),
            ),
          ),
        ),
        Positioned(
          left: s(160),
          top: s(119),
          width: s(177),
          height: s(106.3),
          child: Image.asset(FigmaAssets.shopBannerStump, fit: BoxFit.fill),
        ),
        Positioned(
          left: s(175),
          top: s(12),
          width: s(97.7),
          height: s(116.3),
          child: Image.asset(FigmaAssets.shopBannerPhotoPink, fit: BoxFit.fill),
        ),
        Positioned(
          left: s(212),
          top: s(47),
          width: s(94.7),
          height: s(114),
          child: Image.asset(FigmaAssets.shopBannerPhotoBlue, fit: BoxFit.fill),
        ),
        Positioned(
          left: s(19),
          top: s(33),
          child: Text('새로운 옷을 만나보세요!', style: _bannerBody(figma.scale, 14)),
        ),
        Positioned(
          left: s(18),
          top: s(52),
          child: Text('햄핀이 옷 상점', style: _bannerTitle(figma.scale)),
        ),
        Positioned(
          left: s(18),
          top: s(103),
          child: Text(
            '보유한 옷과 구매 가능한\n옷을 한눈에 볼 수 있어요!',
            style: _bannerBody(figma.scale, 12.7),
          ),
        ),
      ],
    );
  }
}

TextStyle _bannerTitle(double scale) => TextStyle(
  fontSize: 26 * scale,
  fontWeight: FontWeight.w600,
  color: const Color(0xFF1C1C1E),
  height: 1.19,
);

TextStyle _bannerBody(double scale, double size) => TextStyle(
  fontSize: size * scale,
  fontWeight: FontWeight.w500,
  color: const Color(0xFF1C1C1E),
  height: 1.19,
);

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
