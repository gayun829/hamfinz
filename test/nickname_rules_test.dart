import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/auth_service.dart';

void main() {
  group('nicknameError — 이메일·소셜 가입 공통 규칙', () {
    test('2~12자만 통과한다', () {
      expect(AuthService.nicknameError('햄'), AuthService.nicknameLengthHint);
      expect(AuthService.nicknameError('햄핀'), isNull);
      expect(AuthService.nicknameError('가' * 12), isNull);
      expect(
        AuthService.nicknameError('가' * 13),
        AuthService.nicknameLengthHint,
      );
    });

    test('앞뒤 공백은 길이에 세지 않는다', () {
      expect(
        AuthService.nicknameError('  햄  '),
        AuthService.nicknameLengthHint,
      );
      expect(AuthService.nicknameError('  햄핀  '), isNull);
    });

    test('Firestore 문서 id로 못 쓰는 닉네임은 막는다', () {
      // 닉네임이 그대로 `nicknames/{닉네임}` 문서 id가 된다.
      for (final nickname in ['a/b', '햄/핀', '..', '__햄핀__']) {
        expect(
          AuthService.nicknameError(nickname),
          isNotNull,
          reason: nickname,
        );
        expect(
          AuthService.nicknameError(nickname),
          isNot(AuthService.nicknameLengthHint),
          reason: nickname,
        );
      }
    });
  });

  group('nicknameAvailableFor — 중복 확인과 예약이 같이 쓰는 규칙', () {
    test('예약이 없으면 누구든 쓸 수 있다', () {
      expect(
        AuthService.nicknameAvailableFor(
          reserved: false,
          ownerUid: null,
          uid: 'me',
        ),
        isTrue,
      );
      expect(
        AuthService.nicknameAvailableFor(
          reserved: false,
          ownerUid: null,
          uid: null,
        ),
        isTrue,
      );
    });

    test('앞선 시도에서 내가 잡아둔 예약은 이어서 쓸 수 있다', () {
      // 가입 도중 끊긴 계정이 같은 닉네임으로 다시 오는 경우. 예전에는
      // 확인은 통과시키고 예약에서 막아 그 계정이 가입을 끝낼 수 없었다.
      expect(
        AuthService.nicknameAvailableFor(
          reserved: true,
          ownerUid: 'me',
          uid: 'me',
        ),
        isTrue,
      );
    });

    test('남의 예약이면 못 쓴다', () {
      expect(
        AuthService.nicknameAvailableFor(
          reserved: true,
          ownerUid: 'other',
          uid: 'me',
        ),
        isFalse,
      );
    });

    test('로그인 전이거나 주인을 모르는 예약은 사용 중으로 본다', () {
      expect(
        AuthService.nicknameAvailableFor(
          reserved: true,
          ownerUid: 'other',
          uid: null,
        ),
        isFalse,
      );
      expect(
        AuthService.nicknameAvailableFor(
          reserved: true,
          ownerUid: null,
          uid: null,
        ),
        isFalse,
      );
      expect(
        AuthService.nicknameAvailableFor(
          reserved: true,
          ownerUid: null,
          uid: 'me',
        ),
        isFalse,
      );
    });
  });
}
