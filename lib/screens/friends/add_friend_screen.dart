import 'package:flutter/material.dart';

import '../../data/friend_mock_data.dart';
import '../../theme/app_theme.dart';

/// 친구 추가 화면. 닉네임 검색 탭과 받은 요청 탭으로 구성된다.
/// DB 연동 전 화면 확인용 — [FriendMockData] 목업으로 동작한다.
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  List<FriendMockCandidate> _candidates = List.of(FriendMockData.candidates);
  List<FriendMockRequest> _requests = List.of(FriendMockData.incomingRequests);

  bool _searched = false;
  List<FriendMockCandidate> _results = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searched = true;
      _results =
          _candidates.where((c) => c.nickname.contains(query)).toList();
    });
  }

  void _sendRequest(FriendMockCandidate candidate) {
    FriendMockCandidate markSent(FriendMockCandidate c) => c.uid == candidate.uid
        ? c.copyWith(status: FriendMockStatus.requestSent)
        : c;
    setState(() {
      _candidates = _candidates.map(markSent).toList();
      _results = _results.map(markSent).toList();
    });
  }

  void _accept(FriendMockRequest request) {
    setState(() => _requests = _requests.where((r) => r.uid != request.uid).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${request.nickname}님과 친구가 되었어요.')),
    );
  }

  void _decline(FriendMockRequest request) {
    setState(() => _requests = _requests.where((r) => r.uid != request.uid).toList());
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
              hintText: '닉네임으로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _search,
              ),
            ),
          ),
        ),
        Expanded(
          child: !_searched
              ? const Center(
                  child: Text(
                    '친구의 닉네임을 검색해보세요.',
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
                      itemBuilder: (context, index) => _SearchResultTile(
                        candidate: _results[index],
                        onAdd: () => _sendRequest(_results[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          '받은 친구 요청이 없어요.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
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
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.candidate, required this.onAdd});

  final FriendMockCandidate candidate;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          candidate.nickname,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildTrailing() {
    switch (candidate.status) {
      case FriendMockStatus.friends:
        return const Text(
          '친구',
          style: TextStyle(color: AppTheme.textSecondary),
        );
      case FriendMockStatus.requestSent:
        return const Text(
          '요청 보냄',
          style: TextStyle(color: AppTheme.textSecondary),
        );
      case FriendMockStatus.none:
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
