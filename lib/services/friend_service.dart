import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FriendStatus { none, requestSent, requestReceived, friends }

class FriendSearchResult {
  const FriendSearchResult({
    required this.uid,
    required this.nickname,
    required this.status,
  });

  final String uid;
  final String nickname;
  final FriendStatus status;
}

class FriendRequestInfo {
  const FriendRequestInfo({
    required this.friendshipId,
    required this.uid,
    required this.nickname,
  });

  final String friendshipId;
  final String uid;
  final String nickname;
}

/// 친구 관계는 `friendships/{uidA}_{uidB}` (정렬된 uid 쌍) 문서 하나로 관리한다.
/// 어느 한쪽 유저 문서도 건드리지 않아 Firestore 보안 규칙이 단순해진다.
class FriendService {
  FriendService._();
  static final instance = FriendService._();

  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  final _friendships = FirebaseFirestore.instance.collection('friendships');

  String get _myUid => _auth.currentUser!.uid;

  String _friendshipId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// 닉네임(접두어 일치) 또는 이메일(정확히 일치)로 사용자를 검색한다. 나 자신은 제외한다.
  Future<List<FriendSearchResult>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final myUid = _myUid;
    final nicknames = <String, String>{};

    final byNickname = await _users
        .orderBy('nickname')
        .startAt([trimmed])
        .endAt(['$trimmed'])
        .limit(20)
        .get();
    for (final doc in byNickname.docs) {
      nicknames[doc.id] = doc.data()['nickname'] as String? ?? '';
    }

    if (trimmed.contains('@')) {
      final byEmail = await _users
          .where('email', isEqualTo: trimmed.toLowerCase())
          .limit(5)
          .get();
      for (final doc in byEmail.docs) {
        nicknames[doc.id] = doc.data()['nickname'] as String? ?? '';
      }
    }

    nicknames.remove(myUid);
    if (nicknames.isEmpty) return [];

    final statuses = await _statusesFor(nicknames.keys, myUid);

    return nicknames.entries
        .map(
          (e) => FriendSearchResult(
            uid: e.key,
            nickname: e.value.isEmpty ? '(닉네임 없음)' : e.value,
            status: statuses[e.key] ?? FriendStatus.none,
          ),
        )
        .toList();
  }

  Future<Map<String, FriendStatus>> _statusesFor(
    Iterable<String> uids,
    String myUid,
  ) async {
    final map = <String, FriendStatus>{};
    await Future.wait(
      uids.map((uid) async {
        final doc = await _friendships.doc(_friendshipId(myUid, uid)).get();
        if (!doc.exists) {
          map[uid] = FriendStatus.none;
          return;
        }
        final data = doc.data()!;
        if (data['status'] == 'accepted') {
          map[uid] = FriendStatus.friends;
        } else {
          map[uid] = data['requestedBy'] == myUid
              ? FriendStatus.requestSent
              : FriendStatus.requestReceived;
        }
      }),
    );
    return map;
  }

  /// 친구 요청을 보낸다. 이미 요청/친구 관계가 있으면 아무 것도 하지 않는다.
  Future<void> sendFriendRequest(String targetUid) async {
    final myUid = _myUid;
    if (targetUid == myUid) return;
    final ref = _friendships.doc(_friendshipId(myUid, targetUid));
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'uids': [myUid, targetUid],
      'requestedBy': myUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 내가 받은(상대가 보낸) 대기 중인 친구 요청 목록.
  Future<List<FriendRequestInfo>> getIncomingRequests() async {
    final myUid = _myUid;
    final snap = await _friendships
        .where('uids', arrayContains: myUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final incoming = snap.docs.where((d) => d.data()['requestedBy'] != myUid);

    final result = <FriendRequestInfo>[];
    for (final doc in incoming) {
      final uids = List<String>.from(doc.data()['uids'] as List);
      final otherUid = uids.firstWhere((u) => u != myUid, orElse: () => '');
      if (otherUid.isEmpty) continue;
      final userDoc = await _users.doc(otherUid).get();
      result.add(
        FriendRequestInfo(
          friendshipId: doc.id,
          uid: otherUid,
          nickname: userDoc.data()?['nickname'] as String? ?? '알 수 없음',
        ),
      );
    }
    return result;
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).update({'status': 'accepted'});
  }

  Future<void> declineFriendRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }
}
