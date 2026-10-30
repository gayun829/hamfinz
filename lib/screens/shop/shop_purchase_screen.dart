import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';

/// Supplies a result even when the OS back action or iOS swipe pops without one.
class ShopPurchaseRoute extends MaterialPageRoute<bool> {
  ShopPurchaseRoute({required super.builder, required this.isCompleted});
  final bool Function() isCompleted;

  @override
  bool get currentResult => isCompleted();
}

/// Confirmation previews the product; the receipt shows the saved outfit.
class ShopPurchaseScreen extends StatefulWidget {
  const ShopPurchaseScreen({
    super.key,
    required this.itemName,
    required this.price,
    required this.balance,
    required this.avatar,
    this.receiptAvatar,
    required this.onPurchase,
  });
  final String itemName;
  final int price;
  final int Function() balance;
  final Widget avatar;
  final Widget? receiptAvatar;
  final Future<bool> Function() onPurchase;

  @override
  State<ShopPurchaseScreen> createState() => _ShopPurchaseScreenState();
}

class _ShopPurchaseScreenState extends State<ShopPurchaseScreen> {
  bool _busy = false;
  bool _complete = false;

  Future<void> _buy() async {
    if (_busy || _complete) return;
    setState(() => _busy = true);
    try {
      final success = await widget.onPurchase();
      if (mounted && success) setState(() => _complete = true);
    } catch (error, stack) {
      debugPrint('Purchase preview error: $error\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('구매하지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DefaultTextStyle.merge(
          style: const TextStyle(height: AppTheme.figmaAutoLineHeight),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final scale = FigmaScale.ofWidth(bounds.maxWidth).clamped();
                final s = scale.s;
                return Column(
                  children: [
                    ShopHeader(
                      figma: scale,
                      title: '미리보기',
                      seeds: widget.balance(),
                      onBack: () {
                        if (!_busy) Navigator.pop(context, _complete);
                      },
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _complete
                              ? null
                              : FigmaShopTokens.purchaseBackground,
                          gradient: _complete
                              ? const RadialGradient(
                                  center: Alignment(0, -.35),
                                  radius: .95,
                                  colors: [
                                    Colors.white,
                                    FigmaShopTokens.receiptBackground,
                                  ],
                                )
                              : null,
                        ),
                        child: LayoutBuilder(
                          builder: (context, content) {
                            // Scroll only on short windows or large accessibility text.
                            final minHeight = content.maxHeight;
                            final layoutHeight = minHeight < s(650)
                                ? s(650)
                                : minHeight;
                            double h(double fraction) =>
                                layoutHeight * fraction;
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: minHeight,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    s(20),
                                    h(_complete ? .125 : .064),
                                    s(20),
                                    h(.07),
                                  ),
                                  child: _complete
                                      ? Column(
                                          children: [
                                            Text(
                                              '구매 완료',
                                              style: TextStyle(
                                                fontSize: s(
                                                  FigmaShopTokens
                                                      .receiptTitleSize,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color: FigmaShopTokens
                                                    .receiptTitle,
                                              ),
                                            ),
                                            SizedBox(height: h(.025)),
                                            SizedBox(
                                              width: s(290),
                                              height: h(.37),
                                              child:
                                                  widget.receiptAvatar ??
                                                  widget.avatar,
                                            ),
                                            SizedBox(height: h(.025)),
                                            Text(
                                              _receiptMessage,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: s(
                                                  FigmaShopTokens
                                                      .receiptMessageSize,
                                                ),
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(
                                              height: h(
                                                .226,
                                              ).clamp(s(24), double.infinity),
                                            ),
                                            // Figma 확인 버튼은 x=24, 폭 345다.
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: s(4),
                                              ),
                                              child: _button(
                                                '확인',
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                s,
                                                radius: 13,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.fromLTRB(
                                                s(16),
                                                h(.033),
                                                s(16),
                                                h(.084),
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      s(13),
                                                    ),
                                              ),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    height: h(.353),
                                                    width: s(290),
                                                    child: widget.avatar,
                                                  ),
                                                  SizedBox(height: s(20)),
                                                  Text(
                                                    widget.itemName,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: s(
                                                        FigmaShopTokens
                                                            .purchaseNameSize,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(height: s(18)),
                                                  ShopSeedChip(
                                                    figma: scale,
                                                    seeds: widget.price,
                                                    iconSize: const Size(
                                                      30,
                                                      30,
                                                    ),
                                                    amountSize: FigmaShopTokens
                                                        .purchasePriceSize,
                                                    amountColor: Colors.black,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: s(24)),
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 106,
                                                  child: _button(
                                                    '취소',
                                                    _busy
                                                        ? null
                                                        : () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                    s,
                                                    cancel: true,
                                                  ),
                                                ),
                                                SizedBox(width: s(8)),
                                                Expanded(
                                                  flex: 239,
                                                  child: _button(
                                                    _busy ? '구매 중…' : '구매하기',
                                                    _busy ? null : _buy,
                                                    s,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String get _receiptMessage {
    final last = widget.itemName.isEmpty ? 0 : widget.itemName.runes.last;
    final particle =
        last >= 0xAC00 && last <= 0xD7A3 && (last - 0xAC00) % 28 == 0
        ? '를'
        : '을';
    return '${widget.itemName}$particle 얻었어요!';
  }

  Widget _button(
    String label,
    VoidCallback? onPressed,
    double Function(double) s, {
    bool cancel = false,
    double radius = 14,
  }) => SizedBox(
    width: double.infinity,
    height: s(52),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cancel
            ? FigmaShopTokens.purchaseCancel
            : FigmaShopTokens.purchaseAction,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(radius)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: s(FigmaShopTokens.purchaseButtonSize),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
