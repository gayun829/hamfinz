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
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _buy(ShopItem item) async {
    if (_profile.ownedShopItemIds.contains(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name}은(는) 이미 가지고 있어요.')),
      );
      return;
    }
    if (_profile.seeds < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '씨앗이 부족해요. ${item.name}은(는) ${item.price}씨앗이 필요해요. '
            '(현재 ${_profile.seeds})',
          ),
        ),
      );
      return;
    }

    _profile.seeds -= item.price;
    _profile.ownedShopItemIds = [..._profile.ownedShopItemIds, item.id];
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name}을(를) 구매했어요!')),
    );
  }

  Future<void> _buyStudyGuard() async {
    const maxCount = 3;
    if (_profile.studyGuardCount >= maxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방어권은 최대 3개까지 보유할 수 있어요.')),
      );
      return;
    }

    _profile.studyGuardCount += 1;
    await AuthService.instance.saveProfile(_profile);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연속 학습 방어권을 1개 구매했어요.')),
    );
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

  @override
  Widget build(BuildContext context) {
    final learningItem = ShopData.items.firstWhere(
      (item) => item.id == 'study_guard',
      orElse: () => ShopData.items.first,
    );
    final currentGuardCount = _profile.studyGuardCount;
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
                        0,
                        s(FigmaShopTokens.pagePadding),
                        s(24),
                      ),
                      children: [
                        _ClosetBanner(figma: figma, onTap: _openCloset),
                        SizedBox(height: s(16)),
                        Text(
                          '학습 아이템',
                          style: FigmaShopTokens.sectionTitle(figma.scale),
                        ),
                        SizedBox(height: s(8)),
                        GestureDetector(
                          onTap: currentGuardCount >= 3 ? null : _buyStudyGuard,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(s(16), s(16), s(12), s(14)),
                            decoration: BoxDecoration(
                              color: FigmaShopTokens.card,
                              borderRadius: BorderRadius.circular(s(FigmaShopTokens.cardRadius)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        learningItem.name,
                                        style: FigmaShopTokens.cardTitle(figma.scale),
                                      ),
                                      SizedBox(height: s(4)),
                                      Text(
                                        learningItem.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: FigmaShopTokens.body(figma.scale),
                                      ),
                                      SizedBox(height: s(8)),
                                      Text(
                                        '현재 보유: $currentGuardCount / 3',
                                        style: FigmaShopTokens.body(figma.scale),
                                      ),
                                      SizedBox(height: s(8)),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
                                        decoration: BoxDecoration(
                                          color: currentGuardCount >= 3 ? Colors.grey.shade300 : FigmaShopTokens.chip,
                                          borderRadius: BorderRadius.circular(s(8)),
                                        ),
                                        child: Text(
                                          currentGuardCount >= 3 ? '최대 보유' : '구매하기',
                                          style: FigmaShopTokens.sectionTitle(figma.scale),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: s(8)),
                                SizedBox(
                                  width: s(96),
                                  height: s(112),
                                  child: ShopHamsterSprite(
                                    column: learningItem.spriteCol,
                                    row: learningItem.spriteRow,
                                  ),
                                ),
                              ],
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

