import 'package:flutter/material.dart';

import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';

/// 친구 추가 화면. 닉네임/이메일 검색 탭과 받은 요청 탭으로 구성된다.
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  bool _searching = false;
  List<FriendSearchResult> _results = const [];
  bool _searched = false;

  bool _loadingRequests = true;
  List<FriendRequestInfo> _requests = const [];
  String? _requestsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('문제가 발생했어요: $error')),
    );
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

  Future<void> _search() async {
    final query = _searchController.text;
    if (query.trim().isEmpty) return;
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
      await _loadRequests();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 추가'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryGreen,
          tabs: [
            const Tab(text: '검색'),
            Tab(text: '받은 요청${_requests.isEmpty ? '' : ' (${_requests.length})'}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSearchTab(), _buildRequestsTab()],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: '닉네임 또는 이메일로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _search,
              ),
            ),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : !_searched
                  ? const Center(
                      child: Text(
                        '친구의 닉네임이나 이메일을 검색해보세요.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : _results.isEmpty
                      ? const Center(
                          child: Text(
                            '검색 결과가 없어요.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _results.length,
                          itemBuilder: (context, index) =>
                              _SearchResultTile(
                            result: _results[index],
                            onAdd: () => _sendRequest(_results[index]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requestsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '받은 요청을 불러오지 못했어요.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadRequests,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          '받은 친구 요청이 없어요.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                request.nickname,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('친구 요청을 보냈어요'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _decline(request),
                    child: const Text('거절'),
                  ),
                  ElevatedButton(
                    onPressed: () => _accept(request),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('수락'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onAdd});

  final FriendSearchResult result;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          result.nickname,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildTrailing() {
    switch (result.status) {
      case FriendStatus.friends:
        return const Text(
          '친구',
          style: TextStyle(color: AppTheme.textSecondary),
        );
      case FriendStatus.requestSent:
        return const Text(
          '요청 보냄',
          style: TextStyle(color: AppTheme.textSecondary),
        );
      case FriendStatus.requestReceived:
        return const Text(
          '받은 요청 있음',
          style: TextStyle(color: AppTheme.primaryBlue),
        );
      case FriendStatus.none:
        return ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('추가'),
        );
    }
  }
}
