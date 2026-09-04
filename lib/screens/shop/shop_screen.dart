import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
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
  static const _maxStudyGuards = 3;
  static const _energyPackAmount = 20;
  static const _energyPackPrice = 123;

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _buyStudyGuard() async {
    if (_profile.studyGuardCount >= _maxStudyGuards) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방어권은 최대 3개까지 보유할 수 있어요.')),
      );
      return;
    }
    const price = 123;
    if (_profile.seeds < price) {
      _showSnackBar('씨앗이 부족해요. $price씨앗이 필요합니다.');
      return;
    }

    _profile.seeds -= price;
    _profile.studyGuardCount += 1;
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연속 학습 방어권을 1개 구매했어요.')),
    );
  }

  Future<void> _buyEnergy() async {
    if (_profile.energy >= 100) {
      _showSnackBar('에너지가 이미 가득 차 있어요.');
      return;
    }
    if (_profile.seeds < _energyPackPrice) {
      _showSnackBar('씨앗이 부족해요. $_energyPackPrice씨앗이 필요합니다.');
      return;
    }

    _profile.seeds -= _energyPackPrice;
    _profile.energy = (_profile.energy + _energyPackAmount).clamp(0, 100);
    await AuthService.instance.saveProfile(_profile, includeEnergy: true);
    if (!mounted) return;
    setState(() {});
    _showSnackBar('에너지 $_energyPackAmount을 구매했어요.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCloset() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClosetScreen(profile: _profile)),
    );
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
                    title: '상점',
                    seeds: _profile.seeds,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        s(FigmaShopTokens.pagePadding),
                        0,
                        s(FigmaShopTokens.pagePadding),
                        s(24),
                      ),
                      children: [
                        _ShopLinkCard(figma: figma, title: '햄핀 옷장', subtitle: '보유한 옷을 입혀보세요', onTap: _openCloset),
                        SizedBox(height: s(12)),
                        _ShopLinkCard(figma: figma, title: '옷 상점', subtitle: '새로운 옷을 둘러보고 구매해요', onTap: _openClothingShop),
                        SizedBox(height: s(12)),
                        Text(
                          '아이템 상점',
                          style: FigmaShopTokens.sectionTitle(figma.scale),
                        ),
                        SizedBox(height: s(8)),
                        _ItemPurchaseTile(
                          title: '연속 학습 방어권',
                          detail: '보유 ${_profile.studyGuardCount} / $_maxStudyGuards',
                          price: 123,
                          onTap: _buyStudyGuard,
                        ),
                        SizedBox(height: s(8)),
                        _ItemPurchaseTile(
                          title: '에너지 $_energyPackAmount',
                          detail: '현재 에너지 ${_profile.energy} / 100',
                          price: _energyPackPrice,
                          onTap: _buyEnergy,
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

class _ShopLinkCard extends StatelessWidget {
  const _ShopLinkCard({required this.figma, required this.title, required this.subtitle, required this.onTap});
  final FigmaScale figma;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
      child: Container(
        padding: EdgeInsets.all(s(18)),
        decoration: BoxDecoration(color: FigmaShopTokens.card, borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: FigmaShopTokens.cardTitle(figma.scale)),
            SizedBox(height: s(5)),
            Text(subtitle, style: FigmaShopTokens.body(figma.scale)),
          ])),
          Icon(Icons.chevron_right, size: s(24)),
        ]),
      ),
    );
  }
}

class _ItemPurchaseTile extends StatelessWidget {
  const _ItemPurchaseTile({required this.title, required this.detail, required this.price, required this.onTap});
  final String title;
  final String detail;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: FigmaShopTokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        subtitle: Text(detail),
        trailing: Text('$price 씨앗'),
        onTap: onTap,
      );
}

class _ClosetBanner extends StatelessWidget {
  const _ClosetBanner({required this.figma, required this.onTap});

  final FigmaScale figma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(s(16), s(14), s(12), s(14)),
        decoration: BoxDecoration(
          color: FigmaShopTokens.card,
          borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '햄핀이 꾸미러 가기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigmaShopTokens.cardEyebrow(figma.scale),
                  ),
                  SizedBox(height: s(4)),
                  Text(
                    '햄핀 옷장',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigmaShopTokens.cardTitle(figma.scale),
                  ),
                  SizedBox(height: s(6)),
                  Text(
                    '내가 가진 씨앗으로 햄핀이를 꾸며보세요!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FigmaShopTokens.body(figma.scale),
                  ),
                ],
              ),
            ),
            SizedBox(width: s(8)),
            SizedBox(
              width: s(72),
              height: s(86),
              child: FigmaPng(
                FigmaAssets.hamsterAuth,
                width: s(72),
                height: s(86),
                fit: BoxFit.contain,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: s(22),
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

