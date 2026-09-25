import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/interest_categories.dart';
import '../data/legal_documents.dart';
import '../data/learning_stages.dart';
import '../data/quiz_data.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';
import '../utils/incorrect_questions.dart';
import '../utils/learning_dates.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  final _nicknames = FirebaseFirestore.instance.collection('nicknames');
  final _emails = FirebaseFirestore.instance.collection('emails');
  final _friendships = FirebaseFirestore.instance.collection('friendships');

  Future<String?> getCurrentEmail() async => _auth.currentUser?.email;

  Future<UserProfile?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    if (data['incorrectQuestionCounts'] is! Map) {
      final counts = await ensureIncorrectQuestionCounts(user.uid);
      data['incorrectQuestionCounts'] = counts;
      data['incorrectQuestionCount'] = totalIncorrectQuestionCount(counts);
    }
    return _profileFromJson(user.email ?? '', data);
  }

  /// 예전 계정은 오답 수가 전체 합계만 있다.
  /// 카테고리별 맵이 없으면 `incorrectQuestions`를 세어 채운다.
  ///
  /// 프로덕션 규칙은 이 필드를 클라이언트 쓰기에서 막으므로, 저장이 거절되면
  /// 집계 결과만 돌려준다. 다음 제출의 Functions가 문서를 저장한다.
  Future<Map<String, int>> ensureIncorrectQuestionCounts(String uid) async {
    final userRef = _users.doc(uid);
    final doc = await userRef.get();
    final data = doc.data();
    if (data != null && data['incorrectQuestionCounts'] is Map) {
      return readIncorrectQuestionCounts(data);
    }

    final snap = await userRef.collection('incorrectQuestions').get();
    final counts = <String, int>{};
    for (final item in snap.docs) {
      final categoryId =
          item.data()['categoryId'] as String? ?? 'allowance';
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }

    try {
      await userRef.update({
        'incorrectQuestionCounts': counts,
        'incorrectQuestionCount': totalIncorrectQuestionCount(counts),
      });
    } on FirebaseException {
      // permission-denied: 프로덕션에서는 Functions가 저장한다.
    }
    return counts;
  }

  /// 회원가입 1단계: 계정을 만들고 인증 메일을 보낸다.
  /// 프로필은 아직 안 만든다 — 인증 완료 후 [completeSignUp]에서 만든다.
  Future<String?> beginSignUp({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.length < 6) {
      return '이메일과 6자 이상 비밀번호를 입력해주세요.';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      await credential.user!.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return _resumeSignUp(trimmedEmail, password);
      }
      return _authErrorMessage(e);
    }
  }

  /// 인증 단계에서 앱을 껐다가 같은 메일·비밀번호로 다시 가입을 시도한 경우.
  ///
  /// Auth 계정만 만들어지고 프로필 문서가 없는 상태라 `email-already-in-use`로
  /// 막히는데, 실제로는 본인이 이어서 가입하는 것이라 다시 로그인시켜 흐름을
  /// 이어준다. 이미 가입이 끝난 계정이면 로그인하라고 알려주고 되돌린다.
  Future<String?> _resumeSignUp(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final profile = await _users.doc(user.uid).get();
      if (profile.exists) {
        await _auth.signOut();
        return '이미 가입된 이메일입니다. 로그인해 주세요.';
      }
      if (!user.emailVerified) await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException {
      return '이미 가입된 이메일입니다. 로그인해 주세요.';
    }
  }

  /// 가입 도중 앱을 껐을 때 남는 "프로필 없는 이메일 계정"을 정리한다.
  ///
  /// 소셜 계정은 [pendingSocialSignUp]이 닉네임 화면부터 이어받지만, 이메일
  /// 가입은 비밀번호를 다시 받아야 해서 이어갈 수 없다. 로그인 상태만 어정쩡하게
  /// 남기지 말고 로그아웃시켜, 처음부터 다시 진행하게 한다
  /// (같은 메일로 다시 오면 [_resumeSignUp]이 받아준다).
  Future<void> discardIncompleteEmailSignUp() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final providerIds = user.providerData.map((p) => p.providerId).toList();
    if (providerIds.isNotEmpty && providerIds.any((id) => id != 'password')) {
      return;
    }
    final profile = await _users.doc(user.uid).get();
    if (profile.exists) return;
    await _auth.signOut();
  }

  /// 서버에서 이메일 인증 완료 여부를 다시 확인한다.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<String?> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return '로그인 정보가 없어요.';
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    }
  }

  /// 회원가입 2단계: 인증이 끝난 계정에 프로필 문서를 만든다.
  Future<String?> completeSignUp({
    required String nickname,
    bool marketingConsent = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      return '이메일 인증을 먼저 완료해주세요.';
    }
    return _createProfile(user, nickname, marketingConsent: marketingConsent);
  }

  /// 닉네임을 예약하고 프로필 문서를 만든다 — 이메일·소셜 가입의 마지막 단계.
  ///
  /// 예약과 프로필을 한 트랜잭션으로 쓴다. 따로 쓰면 중간에 끊겼을 때 예약만
  /// 남는데, 예약 문서는 Rules가 수정·삭제를 막아서 다시 시도할 때 같은 문서에
  /// `set`(= update)하면 거절된다 — 이어서 가입하려는 본인이 자기 닉네임에
  /// 막히고 그 계정은 가입을 끝낼 수 없게 된다. 그래서 이미 내 uid로 잡혀 있는
  /// 예약은 다시 쓰지 않고 넘어간다.
  Future<String?> _createProfile(
    User user,
    String nickname, {
    bool marketingConsent = false,
  }) async {
    final trimmedNickname = nickname.trim();
    final invalid = nicknameError(trimmedNickname);
    if (invalid != null) return invalid;

    final nicknameRef = _nicknames.doc(trimmedNickname.toLowerCase());
    final taken = await FirebaseFirestore.instance.runTransaction((tx) async {
      final reservation = await tx.get(nicknameRef);
      final available = nicknameAvailableFor(
        reserved: reservation.exists,
        ownerUid: reservation.data()?['uid'] as String?,
        uid: user.uid,
      );
      if (!available) return true;
      if (!reservation.exists) {
        tx.set(nicknameRef, {'uid': user.uid, 'nickname': trimmedNickname});
      }
      tx.set(_users.doc(user.uid), {
        'nickname': trimmedNickname,
        ..._defaultProfileJson(user, marketingConsent: marketingConsent),
      });
      return false;
    });
    if (taken) return '이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해주세요.';

    // 이메일 검색 인덱스는 친구 찾기용이라 가입을 막을 이유가 없다. 이미 있으면
    // (앞선 시도에서 만들어졌으면) Rules가 덮어쓰기를 거절하는데, 그대로 두면 되고
    // 빠졌으면 다음 로그인 때 [_backfillSearchIndexes]가 채운다.
    try {
      await _reserveEmail(user.uid, trimmedNickname, user.email);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    return null;
  }

  static const nicknameMinLength = 2;
  static const nicknameMaxLength = 12;
  static const nicknameLengthHint = '2자~12자 사이로 입력해 주세요';

  /// 닉네임 규칙. 이메일·소셜 가입이 같은 기준을 쓴다. 통과하면 null.
  ///
  /// 닉네임은 소문자로 바꿔 `nicknames/{닉네임}` 문서 id가 되므로, Firestore가
  /// 문서 id로 받지 않는 `/`·`..`·`__이름__`도 여기서 막는다.
  static String? nicknameError(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.length < nicknameMinLength ||
        trimmed.length > nicknameMaxLength) {
      return nicknameLengthHint;
    }
    if (trimmed.contains('/') ||
        trimmed == '..' ||
        RegExp(r'^__.*__$').hasMatch(trimmed)) {
      return '닉네임에 쓸 수 없는 문자가 들어 있어요.';
    }
    return null;
  }

  /// [uid]가 이 닉네임을 쓸 수 있는지. 예약이 없거나 내가 잡아둔 것이면 쓸 수 있다
  /// — 가입을 이어서 할 때 앞선 시도의 내 예약이 남아 있다.
  ///
  /// 중복 확인([isNicknameTaken])과 실제 예약([_createProfile])이 이 한 규칙을
  /// 같이 써야 "확인은 통과했는데 가입에서 막히는" 일이 없다.
  static bool nicknameAvailableFor({
    required bool reserved,
    required String? ownerUid,
    required String? uid,
  }) => !reserved || (uid != null && ownerUid == uid);

  /// 닉네임 중복 확인. 예약 문서가 내 uid면 내가 잡아둔 것이라 사용 가능으로 본다.
  Future<bool> isNicknameTaken(String nickname) async {
    final key = nickname.trim().toLowerCase();
    if (key.isEmpty) return false;
    final doc = await _nicknames.doc(key).get();
    return !nicknameAvailableFor(
      reserved: doc.exists,
      ownerUid: doc.data()?['uid'] as String?,
      uid: _auth.currentUser?.uid,
    );
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return '이메일과 비밀번호를 입력해주세요.';
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
        await _auth.signOut();
        return '이메일 인증 후 로그인할 수 있어요. 인증 메일을 다시 보냈어요.';
      }
      await _backfillSearchIndexes(credential.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    }
  }

  /// 구글 계정으로 로그인/가입. 처음 보는 계정이면 프로필 문서를 만들지 않고
  /// 닉네임·약관 화면이 필요하다고 알려준다.
  Future<SocialSignInResult> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      return await _resolveSocialSignIn(
        credential.user!,
        credential.user!.displayName,
      );
    } on FirebaseAuthException catch (e) {
      return SocialSignInResult.failure(_authErrorMessage(e));
    } catch (e) {
      return SocialSignInResult.failure('구글 로그인 실패: $e');
    }
  }

  /// 카카오 계정(OIDC)으로 로그인/가입. 분기는 [signInWithGoogle]과 같다.
  Future<SocialSignInResult> signInWithKakao() async {
    try {
      final provider = OAuthProvider('oidc.kakao')
        ..addScope('profile_nickname');
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final profile = credential.additionalUserInfo?.profile;
      return await _resolveSocialSignIn(
        credential.user!,
        credential.user!.displayName ?? profile?['nickname'] as String?,
      );
    } on FirebaseAuthException catch (e) {
      return SocialSignInResult.failure(_authErrorMessage(e));
    } catch (e) {
      return SocialSignInResult.failure('카카오 로그인 실패: $e');
    }
  }

  /// 소셜 로그인 직후 분기. 프로필 문서가 있으면 기존 회원이라 그대로 들어가고,
  /// 없으면 가입이 아직 안 끝난 상태다 — 이메일 가입과 똑같이 닉네임을 직접 고르고
  /// 약관에 동의해야 [completeSocialSignUp]에서 문서가 생긴다.
  Future<SocialSignInResult> _resolveSocialSignIn(
    User user,
    String? providerNickname,
  ) async {
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) {
      return SocialSignInResult.needsSetup(
        _suggestNickname(user, providerNickname),
      );
    }
    await _backfillSearchIndexes(user);
    return const SocialSignInResult.signedIn();
  }

  /// 닉네임 화면에서 앱을 꺼버린 소셜 계정을 위한 이어하기.
  /// Auth 세션은 살아 있는데 프로필 문서만 없는 상태를 찾아낸다.
  /// 이메일 계정은 회원가입 화면이 이어서 처리하므로 제외한다.
  Future<SocialSignInResult?> pendingSocialSignUp() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final providerIds = user.providerData.map((p) => p.providerId).toList();
    if (providerIds.isEmpty || providerIds.every((id) => id == 'password')) {
      return null;
    }
    return pendingProfileSetup();
  }

  /// 로그인은 됐는데 `users/{uid}` 문서가 없으면 닉네임·약관 화면이 필요하다고
  /// 알려준다. 프로필이 있으면 null.
  ///
  /// 이메일 가입자가 인증까지 마치고 약관 단계에서 그만둔 뒤 로그인 화면으로
  /// 들어온 경우도 여기에 걸린다 — 그냥 통과시키면 홈이 프로필을 못 찾아
  /// "사용자 정보를 불러올 수 없습니다"에서 멈춘다.
  Future<SocialSignInResult?> pendingProfileSetup() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return null;
    return SocialSignInResult.needsSetup(
      _suggestNickname(user, user.displayName),
    );
  }

  /// 소셜 가입 마무리. 사용자가 직접 고른 닉네임으로 프로필 문서를 만든다.
  /// 프로필 없이 로그인한 이메일 계정([pendingProfileSetup])도 여기서 마친다
  /// — 로그인이 이미 이메일 인증을 확인했다.
  Future<String?> completeSocialSignUp({required String nickname}) async {
    final user = _auth.currentUser;
    if (user == null) return '로그인 정보가 없어요. 다시 로그인해 주세요.';
    return _createProfile(user, nickname);
  }

  /// 소셜 제공자가 준 이름을 닉네임 입력칸 기본값으로 쓴다. 없으면 이메일
  /// 앞부분, 그것도 없으면 빈 값으로 두고 사용자가 직접 입력하게 한다.
  String _suggestNickname(User user, String? providerNickname) {
    final fromProvider = providerNickname?.trim() ?? '';
    if (fromProvider.isNotEmpty) return fromProvider;
    return (user.email ?? '').split('@').first;
  }

  /// 닉네임 검색 인덱스를 1회 생성 시도한다. 이미 있으면 Rules가
  /// permission-denied로 막는다 (nicknames: create만 허용, update/delete 금지).
  Future<void> _reserveNickname(String uid, String nickname) async {
    await _nicknames.doc(nickname.toLowerCase()).set({
      'uid': uid,
      'nickname': nickname,
    });
  }

  /// 이메일 검색 인덱스를 생성한다. 이메일이 없으면(익명 등) 건너뛴다.
  Future<void> _reserveEmail(String uid, String nickname, String? email) async {
    final emailLower = (email ?? '').toLowerCase();
    if (emailLower.isEmpty) return;
    await _emails.doc(emailLower).set({'uid': uid, 'nickname': nickname});
  }

  /// nicknames/emails 인덱스가 생기기 전에 가입한 기존 계정을 위한 백필.
  /// 로그인할 때마다 호출하되, 내 uid로 인덱스가 이미 있으면 아무 것도 안 해서 저렴하다.
  Future<void> _backfillSearchIndexes(User user) async {
    final profileDoc = await _users.doc(user.uid).get();
    final nickname = profileDoc.data()?['nickname'] as String?;
    if (nickname == null || nickname.isEmpty) return;

    final hasNickname = await _nicknames
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (hasNickname.docs.isEmpty) {
      try {
        await _reserveNickname(user.uid, nickname);
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // 그 닉네임이 이미 다른 uid로 예약돼 있음(기존 데이터라 흔함) — uid 뒷자리를 붙여 재시도.
        await _reserveNickname(
          user.uid,
          '$nickname${user.uid.substring(0, 4)}',
        );
      }
    }

    final hasEmail = await _emails
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (hasEmail.docs.isEmpty) {
      await _reserveEmail(user.uid, nickname, user.email);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 착용 정보만 저장해 다른 화면에서 변경한 프로필 값을 보호한다.
  Future<void> updateShopEquipment({
    required String? skinId,
    required String? patternId,
    required String? backgroundId,
    required List<String> accessoryIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인이 필요해요.');
    await _users.doc(user.uid).update({
      'equippedSkinId': skinId,
      'equippedPatternId': patternId,
      'equippedBackgroundId': backgroundId,
      'equippedAccessoryIds': accessoryIds,
    });
  }

  /// 클라이언트가 직접 고치는 필드만 쓴다.
  ///
  /// energy·streak·learningDates·categoryStats는
  /// 퀴즈 트랜잭션(`QuizSessionRepository`)·Functions만, seeds·ownedShopItemIds·
  /// studyGuardCount는 상점 구매(`ShopService`)만 쓴다. 여기서 같이 덮으면 화면이
  /// 들고 있던 오래된 프로필로 진행도·재화가 되돌아간다.
  Future<void> saveProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).update(clientOwnedJson(profile));
  }

  /// 마이페이지 한줄소개. [saveProfile]로 같이 쓰면 화면이 들고 있던 오래된
  /// 프로필이 다른 필드를 덮을 수 있어서 `bio`만 따로 쓴다.
  Future<void> updateBio(String bio) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).update({'bio': bio});
  }

  /// 회원 탈퇴. 재인증 → Firestore 개인정보 삭제 → Auth 계정 삭제 순으로 한다.
  /// 재인증을 먼저 해야 `requires-recent-login`으로 데이터만 지워지고 계정은
  /// 남는 상태가 안 생긴다.
  /// [password]는 이메일 계정에서만 필요하다 ([requiresPasswordToWithdraw]).
  Future<String?> withdraw({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return '로그인 정보가 없어요.';

    final reauthError = await _reauthenticate(user, password);
    if (reauthError != null) return reauthError;

    try {
      final profile = await _users.doc(user.uid).get();
      final nickname = (profile.data()?['nickname'] as String? ?? '')
          .toLowerCase();
      final email = (user.email ?? '').toLowerCase();

      final friendships = await _friendships
          .where('uids', arrayContains: user.uid)
          .get();
      for (final doc in friendships.docs) {
        await doc.reference.delete();
      }
      if (nickname.isNotEmpty) await _nicknames.doc(nickname).delete();
      if (email.isNotEmpty) await _emails.doc(email).delete();
      await _users.doc(user.uid).delete();

      // ponytail: sessions·mastered 서브컬렉션은 Rules가 delete를 막아 남는다.
      // 개인정보 없이 uid만 달린 고아 문서 — Functions 배포 때 재귀 삭제로 정리.
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      // 위 정리는 전부 Firestore 호출이라 FirebaseAuthException이 아니라
      // FirebaseException으로 떨어진다. 안 잡으면 화면에 아무 것도 안 뜬다.
      if (e.code == 'permission-denied') {
        return '탈퇴 권한이 없어요. Firestore 규칙 배포를 확인해주세요 '
            '(firebase deploy --only firestore:rules).';
      }
      return '탈퇴 처리에 실패했어요. (${e.code})';
    }
  }

  /// 이메일·비밀번호 계정이면 탈퇴 전에 비밀번호를 다시 받아야 한다.
  bool get requiresPasswordToWithdraw {
    final providers = _auth.currentUser?.providerData;
    return providers == null ||
        providers.isEmpty ||
        providers.first.providerId == 'password';
  }

  /// 계정 삭제 직전 재인증. Firebase가 최근 로그인을 요구한다.
  Future<String?> _reauthenticate(User user, String? password) async {
    final providerId = user.providerData.isEmpty
        ? 'password'
        : user.providerData.first.providerId;
    try {
      if (providerId == 'password') {
        if (password == null || password.isEmpty) {
          return '비밀번호를 입력해주세요.';
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password,
          ),
        );
      } else {
        final provider = providerId == 'google.com'
            ? GoogleAuthProvider()
            : OAuthProvider(providerId);
        if (kIsWeb) {
          await user.reauthenticateWithPopup(provider);
        } else {
          await user.reauthenticateWithProvider(provider);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    }
  }

  /// 학습과정 저장 (1~10). 실패 시 사용자용 메시지, 성공 시 null.
  Future<String?> saveLearningStage(int stage) async {
    final user = _auth.currentUser;
    if (user == null) return '로그인 정보가 없어요.';

    final normalized = normalizeLearningStage(stage);

    try {
      await _users.doc(user.uid).update({'learningStage': normalized});
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return '학습과정 저장 권한이 없어요. Firestore 규칙 배포를 확인해 주세요.';
      }
      if (e.code == 'not-found') {
        return '프로필을 찾을 수 없어요. 다시 로그인해 주세요.';
      }
      return '학습과정 저장에 실패했어요. (${e.code})';
    } catch (e) {
      return '학습과정 저장에 실패했어요. (${e.runtimeType})';
    }
  }

  /// 학습 카테고리 저장 (6개 중 1개). 실패 시 사용자용 메시지, 성공 시 null.
  Future<String?> saveInterestCategories(List<String> categoryIds) async {
    final user = _auth.currentUser;
    if (user == null) return '로그인 정보가 없어요.';

    final activeId = resolveActiveInterestCategoryId(categoryIds);
    if (activeId == null) return '유효한 카테고리를 선택해 주세요.';

    try {
      await _users.doc(user.uid).update({
        'interestCategories': [activeId],
      });
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return '카테고리 저장 권한이 없어요. Firestore 규칙 배포를 확인해 주세요.';
      }
      if (e.code == 'not-found') {
        return '프로필을 찾을 수 없어요. 다시 로그인해 주세요.';
      }
      return '카테고리 저장에 실패했어요. (${e.code})';
    }
  }

  /// 비밀번호 재설정 이메일을 보낸다. Firebase Auth는 클라이언트에서 임의로
  /// 비밀번호를 바꿀 수 없어서, 링크가 담긴 메일을 보내는 방식으로 동작한다.
  Future<String?> resetPassword({required String email}) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다.';
      case 'user-not-found':
        return '가입되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.';
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 일치하지 않습니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'weak-password':
        return '6자 이상 비밀번호를 입력해주세요.';
      default:
        return e.message ?? '알 수 없는 오류가 발생했어요.';
    }
  }

  /// 프로필 문서 초기값. 가입 시 1회만 쓴다.
  ///
  /// `consents`는 약관·개인정보 동의 기록이다. 이메일 가입 화면과 소셜 가입
  /// 화면 모두 필수 두 항목 동의를 강제하므로, 문서를 만드는 시점 = 동의 시점으로
  /// 남긴다. 마케팅 수신만 선택이라 실제 선택값을 그대로 적는다.
  /// 본문이 개정되면 [LegalDocuments.version]을 올려 재동의 대상을 가려낸다.
  Map<String, dynamic> _defaultProfileJson(
    User user, {
    bool marketingConsent = false,
  }) => {
    'streak': 0,
    'lastQuizCompletedDate': null,
    'todayQuizCompleted': false,
    'energy': QuizData.maxEnergy,
    'lastEnergyResetDate': DateHelper.todayKey(),
    'selectedHamsterId': 'hamster_basic',
    'learningDates': <String>[],
    'categoryStats': <String, dynamic>{},
    'interestCategories': <String>[],
    'learningStage': kMinLearningStage,
    'incorrectQuestionCounts': <String, int>{},
    'incorrectQuestionCount': 0,
    'seeds': 0,
    'ownedShopItemIds': <String>[],
    'consents': {
      'termsVersion': LegalDocuments.version,
      'privacyVersion': LegalDocuments.version,
      'agreedAt': FieldValue.serverTimestamp(),
      // 선택 항목 — 가입 화면의 "광고성 정보, 마케팅 활용 동의(선택)".
      'marketing': marketingConsent,
    },
    'providers': user.providerData.isEmpty
        ? ['password']
        : user.providerData.map((p) => p.providerId).toList(),
    'createdAt': FieldValue.serverTimestamp(),
  };

  UserProfile _profileFromJson(String email, Map<String, dynamic> data) {
    final statsRaw = Map<String, dynamic>.from(
      data['categoryStats'] as Map? ?? {},
    );
    final stats = <String, CategoryStat>{};
    for (final entry in statsRaw.entries) {
      stats[entry.key] = CategoryStat.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    final lastDate = data['lastQuizCompletedDate'] as String?;
    var streak = data['streak'] as int? ?? 0;
    var todayCompleted = data['todayQuizCompleted'] as bool? ?? false;

    if (lastDate != null &&
        !DateHelper.isToday(lastDate) &&
        !DateHelper.isYesterday(lastDate)) {
      streak = 0;
      todayCompleted = false;
    } else if (lastDate != null && !DateHelper.isToday(lastDate)) {
      todayCompleted = false;
    }

    final today = DateHelper.todayKey();
    var energy = data['energy'] as int? ?? QuizData.maxEnergy;
    var lastEnergyResetDate = data['lastEnergyResetDate'] as String?;
    // 날짜가 바뀌면 에너지를 최대로 회복한다.
    if (lastEnergyResetDate != today) {
      energy = QuizData.maxEnergy;
      lastEnergyResetDate = today;
    }

    return UserProfile(
      email: email,
      nickname: data['nickname'] as String? ?? email,
      bio: data['bio'] as String? ?? '',
      streak: streak,
      lastQuizCompletedDate: lastDate,
      todayQuizCompleted: todayCompleted,
      energy: energy.clamp(0, QuizData.maxEnergy),
      lastEnergyResetDate: lastEnergyResetDate,

      selectedHamsterId:
          data['selectedHamsterId'] as String? ?? 'hamster_basic',
      learningDates: LearningDates.fromUser(data, today: today),
      categoryStats: stats,
      interestCategories: List<String>.from(
        data['interestCategories'] as List? ?? [],
      ),
      learningStage: normalizeLearningStage(
        readLearningStageField(data['learningStage']),
      ),
      incorrectQuestionCounts: readIncorrectQuestionCounts(data),
      incorrectQuestionCount:
          (data['incorrectQuestionCount'] as num?)?.toInt() ?? 0,
      reviewArrivals: readReviewArrivals(data),
      seeds: data['seeds'] as int? ?? 0,
      ownedShopItemIds: List<String>.from(
        data['ownedShopItemIds'] as List? ?? [],
      ),
      studyGuardCount: data['studyGuardCount'] as int? ?? 0,
      equippedSkinId: data['equippedSkinId'] as String?,
      equippedPatternId: data['equippedPatternId'] as String?,
      equippedBackgroundId: data['equippedBackgroundId'] as String?,
      equippedAccessoryIds: List<String>.from(
        data['equippedAccessoryIds'] as List? ?? [],
      ),
    );
  }

  // seeds·ownedShopItemIds·studyGuardCount·energy는 `ShopService.purchaseItem`
  // (트랜잭션/Functions)만 쓴다. equipped*는 재화와 무관한 순수 착용 상태라
  // 여기서 계속 클라이언트가 쓴다.
  static Map<String, dynamic> clientOwnedJson(UserProfile profile) => {
    'nickname': profile.nickname,
    'selectedHamsterId': profile.selectedHamsterId,
    'interestCategories': profile.interestCategories,
    'learningStage': normalizeLearningStage(profile.learningStage),
    'equippedSkinId': profile.equippedSkinId,
    'equippedPatternId': profile.equippedPatternId,
    'equippedBackgroundId': profile.equippedBackgroundId,
    'equippedAccessoryIds': profile.equippedAccessoryIds,
  };
}

/// 소셜 로그인 결과.
///
/// [needsProfileSetup]이면 Auth 로그인은 끝났지만 `users/{uid}` 문서가 아직
/// 없는 상태다 — 닉네임·약관 화면을 거쳐야 가입이 완료된다.
class SocialSignInResult {
  const SocialSignInResult.failure(String this.error)
    : needsProfileSetup = false,
      suggestedNickname = '';

  const SocialSignInResult.signedIn()
    : error = null,
      needsProfileSetup = false,
      suggestedNickname = '';

  const SocialSignInResult.needsSetup(this.suggestedNickname)
    : error = null,
      needsProfileSetup = true;

  final String? error;
  final bool needsProfileSetup;
  final String suggestedNickname;
}
