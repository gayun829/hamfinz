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

class Friend {
  const Friend({
    required this.friendshipId,
    required this.uid,
    required this.nickname,
  });

  final String friendshipId;
  final String uid;
  final String nickname;
}

/// 친구 검색은 `nicknames`/`emails` 공개 인덱스로, 관계는 `friendships/{uidA}_{uidB}`
/// 문서 하나로 관리한다. `users/{uid}`는 본인만 read라 다른 유저의 `users` 문서는
/// 이 서비스 어디에서도 읽지 않는다 — 필요한 닉네임은 인덱스/요청 문서에 있는 걸 쓴다.
class FriendService {
  FriendService._();
  static final instance = FriendService._();

  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  final _nicknames = FirebaseFirestore.instance.collection('nicknames');
  final _emails = FirebaseFirestore.instance.collection('emails');
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
    final normalized = trimmed.toLowerCase();

    final myUid = _myUid;
    final found = <String, String>{}; // uid -> nickname

    final byNickname = await _nicknames
        .orderBy(FieldPath.documentId)
        .startAt([normalized])
        .endAt(['$normalized'])
        .limit(20)
        .get();
    for (final doc in byNickname.docs) {
      final uid = doc.data()['uid'] as String?;
      final nickname = doc.data()['nickname'] as String?;
      if (uid != null && nickname != null) found[uid] = nickname;
    }

    if (trimmed.contains('@')) {
      final emailDoc = await _emails.doc(normalized).get();
      final uid = emailDoc.data()?['uid'] as String?;
      final nickname = emailDoc.data()?['nickname'] as String?;
      if (uid != null && nickname != null) found[uid] = nickname;
    }

    found.remove(myUid);
    if (found.isEmpty) return [];

    final statuses = await _statusesFor(found.keys, myUid);

    return found.entries
        .map(
          (e) => FriendSearchResult(
            uid: e.key,
            nickname: e.value,
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

    final myDoc = await _users.doc(myUid).get();
    final myNickname = myDoc.data()?['nickname'] as String? ?? '';

    await ref.set({
      'uids': [myUid, targetUid],
      'requestedBy': myUid,
      'requestedByNickname': myNickname,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// `nicknames` 공개 인덱스에서 uid로 현재 닉네임을 찾는다. `friendships` 문서에
  /// 스냅샷이 없는 옛날 데이터(필드 추가 전에 만들어진 문서)를 위한 fallback이다.
  Future<String> _lookupNicknameByUid(String uid) async {
    final snap = await _nicknames.where('uid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return '알 수 없음';
    return snap.docs.first.data()['nickname'] as String? ?? '알 수 없음';
  }

  /// 내가 받은(상대가 보낸) 대기 중인 친구 요청 목록.
  /// 상대 닉네임은 요청 문서에 스냅샷된 `requestedByNickname`을 우선 쓰고(상대 `users`
  /// 문서는 못 읽음), 스냅샷이 없는 옛날 문서면 `nicknames` 인덱스에서 찾는다.
  Future<List<FriendRequestInfo>> getIncomingRequests() async {
    final myUid = _myUid;
    final snap = await _friendships
        .where('uids', arrayContains: myUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final result = <FriendRequestInfo>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['requestedBy'] == myUid) continue;
      final uids = List<String>.from(data['uids'] as List);
      final otherUid = uids.firstWhere((u) => u != myUid, orElse: () => '');
      if (otherUid.isEmpty) continue;

      final nickname = data['requestedByNickname'] as String? ??
          await _lookupNicknameByUid(otherUid);

      result.add(
        FriendRequestInfo(friendshipId: doc.id, uid: otherUid, nickname: nickname),
      );
    }
    return result;
  }

  /// 요청을 수락한다. 내 닉네임을 `accepterNickname`으로 같이 남겨서, 나중에
  /// 친구 목록을 보여줄 때 상대 `users` 문서를 안 열어도 상대 닉네임을 알 수 있게 한다.
  Future<void> acceptFriendRequest(String friendshipId) async {
    final myUid = _myUid;
    final myDoc = await _users.doc(myUid).get();
    final myNickname = myDoc.data()?['nickname'] as String? ?? '';

    await _friendships.doc(friendshipId).update({
      'status': 'accepted',
      'accepterNickname': myNickname,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineFriendRequest(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }

  /// 내 친구 목록. 상대 닉네임은 그쪽이 requestedBy냐 아니냐에 따라
  /// `requestedByNickname`/`accepterNickname` 중 맞는 걸 우선 쓴다 — `users` 문서는
  /// 안 읽는다. 스냅샷이 없는 옛날 문서(이 필드들 추가 전에 수락된 친구)는
  /// `nicknames` 인덱스에서 uid로 현재 닉네임을 찾아온다.
  Future<List<Friend>> getFriends() async {
    final myUid = _myUid;
    final snap = await _friendships
        .where('uids', arrayContains: myUid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final result = <Friend>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final uids = List<String>.from(data['uids'] as List);
      final otherUid = uids.firstWhere((u) => u != myUid, orElse: () => '');
      if (otherUid.isEmpty) continue;

      final snapshotNickname = data['requestedBy'] == myUid
          ? data['accepterNickname'] as String?
          : data['requestedByNickname'] as String?;
      final nickname = snapshotNickname ?? await _lookupNicknameByUid(otherUid);

      result.add(
        Friend(friendshipId: doc.id, uid: otherUid, nickname: nickname),
      );
    }
    return result;
  }

  /// 친구 관계를 끊는다. `friendships` 문서 삭제만으로 처리한다(이력은 안 남김).
  Future<void> removeFriend(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }
}
