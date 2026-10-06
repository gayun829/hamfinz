import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/date_helper.dart';

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

/// 캘린더 "이번 달 친구와의 경쟁"의 한 사람(나 포함).
class FriendRankEntry {
  const FriendRankEntry({
    required this.rank,
    required this.nickname,
    required this.streak,
    required this.isMe,
  });

  final int rank;
  final String nickname;
  final int streak;
  final bool isMe;
}

class FriendsRanking {
  const FriendsRanking({required this.friendCount, required this.participants});

  static const empty = FriendsRanking(friendCount: 0, participants: []);

  final int friendCount;

  /// 연속학습 순으로 정렬된 나와 친구들.
  final List<FriendRankEntry> participants;
}

/// 순위를 매기기 전의 한 사람. [streak]은 저장된 값 그대로다.
class FriendStreak {
  const FriendStreak({
    required this.nickname,
    required this.streak,
    required this.lastQuizCompletedDate,
    this.isMe = false,
  });

  final String nickname;
  final int streak;
  final String? lastQuizCompletedDate;
  final bool isMe;
}

/// 마지막 학습일이 오늘·어제가 아니면 연속학습은 이미 끊긴 것이라 0으로 보고
/// (`AuthService._profileFromJson`과 같은 규칙), 연속학습이 긴 순으로 줄 세운다.
/// 같으면 오늘 이미 학습한 사람, 그다음 닉네임 순.
List<FriendRankEntry> rankFriendStreaks(
  List<FriendStreak> people, {
  required String today,
  required String yesterday,
}) {
  int effective(FriendStreak p) =>
      p.lastQuizCompletedDate == today || p.lastQuizCompletedDate == yesterday
      ? p.streak.clamp(0, 1 << 30)
      : 0;
  final sorted = [...people]
    ..sort((a, b) {
      final byStreak = effective(b).compareTo(effective(a));
      if (byStreak != 0) return byStreak;
      final aToday = a.lastQuizCompletedDate == today ? 1 : 0;
      final bToday = b.lastQuizCompletedDate == today ? 1 : 0;
      if (aToday != bToday) return bToday - aToday;
      return a.nickname.compareTo(b.nickname);
    });
  return [
    for (var i = 0; i < sorted.length; i++)
      FriendRankEntry(
        rank: i + 1,
        nickname: sorted[i].nickname,
        streak: effective(sorted[i]),
        isMe: sorted[i].isMe,
      ),
  ];
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
  final _streaks = FirebaseFirestore.instance.collection('streaks');

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

      final nickname =
          data['requestedByNickname'] as String? ??
          await _lookupNicknameByUid(otherUid);

      result.add(
        FriendRequestInfo(
          friendshipId: doc.id,
          uid: otherUid,
          nickname: nickname,
        ),
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

  /// 나와 친구들의 연속학습 순위. 친구의 `users` 문서는 못 읽으니 친구만 읽을 수
  /// 있는 `streaks/{uid}` 인덱스에서 연속학습을 가져온다. 인덱스가 아직 없는
  /// 친구(업데이트 후 로그인·학습 전)는 연속학습 0으로 둔다.
  Future<FriendsRanking> getFriendsRanking() async {
    final myUid = _myUid;
    final friends = await getFriends();
    final me = (await _users.doc(myUid).get()).data() ?? const {};
    final friendStreaks = await Future.wait(
      friends.map((f) => _streaks.doc(f.uid).get()),
    );
    final people = [
      FriendStreak(
        nickname: me['nickname'] as String? ?? '',
        streak: (me['streak'] as num?)?.toInt() ?? 0,
        lastQuizCompletedDate: me['lastQuizCompletedDate'] as String?,
        isMe: true,
      ),
      for (var i = 0; i < friends.length; i++)
        FriendStreak(
          nickname: friends[i].nickname,
          streak: (friendStreaks[i].data()?['streak'] as num?)?.toInt() ?? 0,
          lastQuizCompletedDate:
              friendStreaks[i].data()?['lastQuizCompletedDate'] as String?,
        ),
    ];
    return FriendsRanking(
      friendCount: friends.length,
      participants: rankFriendStreaks(
        people,
        today: DateHelper.todayKey(),
        yesterday: DateHelper.yesterdayKey(),
      ),
    );
  }

  /// 내 `users` 문서의 연속학습을 친구 공개용 `streaks/{uid}`에 옮겨 적는다.
  /// Rules가 users 문서와 값이 같을 때만 쓰기를 허용해서, users의 streak이
  /// Functions 전용인 프로덕션에서도 여기 값을 부풀릴 수 없다.
  Future<void> publishMyStreak() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final user = (await _users.doc(uid).get()).data();
    if (user == null) return;
    await _streaks.doc(uid).set({
      'streak': (user['streak'] as num?)?.toInt() ?? 0,
      'lastQuizCompletedDate': user['lastQuizCompletedDate'] as String?,
    });
  }

  /// 친구 관계를 끊는다. `friendships` 문서 삭제만으로 처리한다(이력은 안 남김).
  Future<void> removeFriend(String friendshipId) async {
    await _friendships.doc(friendshipId).delete();
  }
}
