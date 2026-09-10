import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../services/auth_service.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_friends_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';

/// 친구 화면 (Figma `270:9` 마이>친구탭 수정). 탭이 아니라 친구 추가·받은 요청·
/// 친구 목록이 한 화면에 카드로 쌓인 구조다.
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();

  String _nickname = '';

  bool _searching = false;
  List<FriendSearchResult> _results = const [];
  bool _searched = false;

  bool _loadingRequests = true;
  List<FriendRequestInfo> _requests = const [];
  String? _requestsError;

  bool _loadingFriends = true;
  List<Friend> _friends = const [];
  String? _friendsError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRequests();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('문제가 발생했어요: $error')),
    );
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentUser();
      if (!mounted || profile == null) return;
      setState(() => _nickname = profile.nickname);
    } catch (_) {
      // 히어로에 닉네임만 못 뜰 뿐 화면 나머지는 정상 동작해야 하니 조용히 무시한다.
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestsError = null;
    });
    try {
      final requests = await FriendService.instance.getIncomingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _requestsError = '$e';
        _loadingRequests = false;
      });
    }
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loadingFriends = true;
      _friendsError = null;
    });
    try {
      final friends = await FriendService.instance.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _loadingFriends = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _friendsError = '$e';
        _loadingFriends = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadRequests(), _loadFriends()]);
  }

  Future<void> _search() async {
    final query = _searchController.text;
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searched = true;
    });
    try {
      final results = await FriendService.instance.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
      });
      _showError(e);
    }
  }

  Future<void> _sendRequest(FriendSearchResult result) async {
    try {
      await FriendService.instance.sendFriendRequest(result.uid);
      if (!mounted) return;
      setState(() {
        _results = _results
            .map(
              (r) => r.uid == result.uid
                  ? FriendSearchResult(
                      uid: r.uid,
                      nickname: r.nickname,
                      status: FriendStatus.requestSent,
                    )
                  : r,
            )
            .toList();
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _accept(FriendRequestInfo request) async {
    try {
      await FriendService.instance.acceptFriendRequest(request.friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.nickname}님과 친구가 되었어요.')),
      );
      await _refreshAll();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _decline(FriendRequestInfo request) async {
    try {
      await FriendService.instance.declineFriendRequest(request.friendshipId);
      await _loadRequests();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 끊기'),
        content: Text('${friend.nickname}님과 친구를 끊을까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('끊기', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FriendService.instance.removeFriend(friend.friendshipId);
      await _loadFriends();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaFriendsTokens.background,
      appBar: AppBar(
        backgroundColor: FigmaFriendsTokens.appBar,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const FigmaSvg(
            FigmaAssets.friendsBackChevron,
            width: 14,
            height: 24,
          ),
        ),
        title: const Text(
          '친구',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(nickname: _nickname),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchCard(),
                  const SizedBox(height: 16),
                  _buildRequestsCard(),
                  const SizedBox(height: 16),
                  _buildFriendsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return _FriendsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '친구 추가하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 39,
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '닉네임 또는 이메일을 입력하세요',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: FigmaFriendsTokens.placeholder,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(14),
                          child: FigmaSvg(FigmaAssets.friendsSearchIcon),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.5),
                          borderSide: const BorderSide(
                            color: FigmaFriendsTokens.outlineBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.5),
                          borderSide: const BorderSide(
                            color: FigmaFriendsTokens.outlineBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _FilledPillButton(label: '검색', onPressed: _search),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else if (_searched) ...[
              const SizedBox(height: 12),
              if (_results.isEmpty)
                const Text(
                  '검색 결과가 없어요.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < _results.length; i++) ...[
                      if (i > 0) const _RowDivider(),
                      _PersonRow(
                        nickname: _results[i].nickname,
                        trailing: _searchResultTrailing(_results[i]),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _searchResultTrailing(FriendSearchResult result) {
    switch (result.status) {
      case FriendStatus.friends:
        return const Text('친구', style: TextStyle(color: AppTheme.textSecondary));
      case FriendStatus.requestSent:
        return const Text('요청 보냄', style: TextStyle(color: AppTheme.textSecondary));
      case FriendStatus.requestReceived:
        return const Text(
          '받은 요청 있음',
          style: TextStyle(color: FigmaFriendsTokens.appBar),
        );
      case FriendStatus.none:
        return _FilledPillButton(
          label: '추가',
          onPressed: () => _sendRequest(result),
        );
    }
  }

  Widget _buildRequestsCard() {
    return _FriendsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '받은 요청',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (_requests.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${_requests.length}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FigmaFriendsTokens.badge,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingRequests)
              const Center(child: CircularProgressIndicator())
            else if (_requestsError != null)
              _ErrorRetry(
                message: '받은 요청을 불러오지 못했어요.',
                onRetry: _loadRequests,
              )
            else if (_requests.isEmpty)
              const Text(
                '받은 친구 요청이 없어요.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < _requests.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    _PersonRow(
                      nickname: _requests[i].nickname,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OutlinePillButton(
                            label: '거절',
                            onPressed: () => _decline(_requests[i]),
                          ),
                          const SizedBox(width: 8),
                          _FilledPillButton(
                            label: '수락',
                            onPressed: () => _accept(_requests[i]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsCard() {
    return _FriendsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '친구 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_loadingFriends)
              const Center(child: CircularProgressIndicator())
            else if (_friendsError != null)
              _ErrorRetry(
                message: '친구 목록을 불러오지 못했어요.',
                onRetry: _loadFriends,
              )
            else if (_friends.isEmpty)
              const Text(
                '아직 친구가 없어요. 위에서 검색해 추가해보세요.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < _friends.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    _PersonRow(
                      nickname: _friends[i].nickname,
                      trailing: _OutlinePillButton(
                        label: '삭제',
                        onPressed: () => _removeFriend(_friends[i]),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.nickname});

  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [
            FigmaFriendsTokens.heroGradientStart,
            FigmaFriendsTokens.heroGradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nickname.isEmpty ? ' ' : nickname,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Center(
              child: FigmaSvg(
                FigmaAssets.friendsHeroHamster,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FigmaFriendsTokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: FigmaFriendsTokens.cardShadow.withValues(alpha: 0.6),
            blurRadius: FigmaFriendsTokens.cardShadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.nickname, required this.trailing});

  final String nickname;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: FigmaFriendsTokens.avatarBackground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: FigmaFriendsTokens.divider);
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

class _FilledPillButton extends StatelessWidget {
  const _FilledPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: FigmaFriendsTokens.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.5),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: FigmaFriendsTokens.outlineBorder),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.5),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}
