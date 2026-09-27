import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/friend_service.dart';

void main() {
  const today = '2026-09-28';
  const yesterday = '2026-09-27';

  List<(String, int, int)> rank(List<FriendStreak> people) => [
    for (final e in rankFriendStreaks(
      people,
      today: today,
      yesterday: yesterday,
    ))
      (e.nickname, e.rank, e.streak),
  ];

  test(
    'a streak counts only while the last study day is today or yesterday',
    () {
      expect(
        rank(const [
          FriendStreak(nickname: '오늘', streak: 5, lastQuizCompletedDate: today),
          FriendStreak(
            nickname: '어제',
            streak: 6,
            lastQuizCompletedDate: yesterday,
          ),
          FriendStreak(
            nickname: '끊김',
            streak: 9,
            lastQuizCompletedDate: '2026-09-25',
          ),
          FriendStreak(nickname: '없음', streak: 0, lastQuizCompletedDate: null),
        ]),
        [('어제', 1, 6), ('오늘', 2, 5), ('끊김', 3, 0), ('없음', 4, 0)],
      );
    },
  );

  test('ties go to whoever studied today, then by nickname', () {
    expect(
      rank(const [
        FriendStreak(
          nickname: '다람',
          streak: 3,
          lastQuizCompletedDate: yesterday,
        ),
        FriendStreak(nickname: '나비', streak: 3, lastQuizCompletedDate: today),
        FriendStreak(
          nickname: '가람',
          streak: 3,
          lastQuizCompletedDate: yesterday,
        ),
      ]),
      [('나비', 1, 3), ('가람', 2, 3), ('다람', 3, 3)],
    );
  });

  test('keeps who is me', () {
    final ranked = rankFriendStreaks(
      const [
        FriendStreak(nickname: '친구', streak: 1, lastQuizCompletedDate: today),
        FriendStreak(
          nickname: '나',
          streak: 2,
          lastQuizCompletedDate: today,
          isMe: true,
        ),
      ],
      today: today,
      yesterday: yesterday,
    );
    expect(ranked.map((e) => e.isMe), [true, false]);
  });
}
