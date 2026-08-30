/// 친구 추가 화면 프론트 목업. 백엔드(Firebase) 연동 전 화면 확인용.
abstract final class FriendMockData {
  static const candidates = <FriendMockCandidate>[
    FriendMockCandidate(
      uid: 'mock_1',
      nickname: '김기니니',
      status: FriendMockStatus.none,
    ),
    FriendMockCandidate(
      uid: 'mock_2',
      nickname: '햄스터왕',
      status: FriendMockStatus.none,
    ),
    FriendMockCandidate(
      uid: 'mock_3',
      nickname: '저축요정',
      status: FriendMockStatus.friends,
    ),
    FriendMockCandidate(
      uid: 'mock_4',
      nickname: '용돈관리생',
      status: FriendMockStatus.requestSent,
    ),
    FriendMockCandidate(
      uid: 'mock_5',
      nickname: '금융탐험가',
      status: FriendMockStatus.none,
    ),
  ];

  static const incomingRequests = <FriendMockRequest>[
    FriendMockRequest(uid: 'mock_6', nickname: '재테크학습자'),
  ];
}

enum FriendMockStatus { none, requestSent, friends }

class FriendMockCandidate {
  const FriendMockCandidate({
    required this.uid,
    required this.nickname,
    required this.status,
  });

  final String uid;
  final String nickname;
  final FriendMockStatus status;

  FriendMockCandidate copyWith({FriendMockStatus? status}) =>
      FriendMockCandidate(
        uid: uid,
        nickname: nickname,
        status: status ?? this.status,
      );
}

class FriendMockRequest {
  const FriendMockRequest({required this.uid, required this.nickname});

  final String uid;
  final String nickname;
}
