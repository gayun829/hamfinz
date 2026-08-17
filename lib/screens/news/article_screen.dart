import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/app_theme.dart';

/// 기사를 앱 안에서 그대로 보여주는 화면.
///
/// 외부 브라우저로 넘기면 앱을 나가버려서, 기사 위에 퀴즈 진입점을 붙일 수가 없다.
/// 그래서 WebView로 앱이 기사 화면을 직접 소유한다.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    super.key,
    required this.url,
    required this.title,
    this.onStartQuiz,
  });

  final Uri url;
  final String title;

  /// 넘기면 하단에 '이 기사로 퀴즈 풀기' 버튼이 붙는다.
  /// 뉴스 기반 퀴즈가 준비되기 전까지는 비워두면 버튼도 안 보인다.
  final void Function(Uri url, String title)? onStartQuiz;

  /// WebView 플러그인이 있는 플랫폼인지. Web·Windows에는 구현체가 없어서
  /// 그쪽에서는 기존처럼 외부 브라우저로 넘겨야 한다.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    // 구글뉴스 링크는 자바스크립트로 언론사 페이지에 넘겨주므로 JS를 켜둬야 한다.
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => _update(() => _progress = progress),
          onPageStarted: (_) => _update(() {
            _progress = 0;
            _failed = false;
          }),
          onPageFinished: (_) {
            _update(() => _progress = 100);
            _syncCanGoBack();
          },
          onWebResourceError: (error) {
            // 광고·이미지 같은 하위 리소스 실패까지 잡으면 멀쩡한 기사도 실패로 보인다.
            if (error.isForMainFrame == false) return;
            _update(() => _failed = true);
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  void _update(VoidCallback change) {
    if (!mounted) return;
    setState(change);
  }

  Future<void> _syncCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    _update(() => _canGoBack = canGoBack);
  }

  Future<void> _openExternally() async {
    final ok = await launchUrl(widget.url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열지 못했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onStartQuiz = widget.onStartQuiz;

    return PopScope(
      // 기사 안에서 링크를 타고 들어갔으면 뒤로가기는 앱이 아니라 WebView 히스토리를 되짚는다.
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          await _syncCanGoBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.figmaHomeBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.card,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: '브라우저로 열기',
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new, size: 20),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _progress >= 100
                ? const SizedBox(height: 2)
                : LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    backgroundColor: AppTheme.figmaMintLight,
                    color: AppTheme.figmaTeal,
                  ),
          ),
        ),
        body: _failed ? _buildError() : WebViewWidget(controller: _controller),
        bottomNavigationBar: onStartQuiz == null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => onStartQuiz(widget.url, widget.title),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.figmaTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '이 기사로 퀴즈 풀기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '기사를 불러오지 못했어요.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '언론사 쪽에서 앱 안 보기를 막았을 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _update(() => _failed = false);
                    _controller.loadRequest(widget.url);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.figmaTeal,
                  ),
                  child: const Text('다시 시도'),
                ),
                FilledButton(
                  onPressed: _openExternally,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.figmaTeal,
                  ),
                  child: const Text('브라우저로 열기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
