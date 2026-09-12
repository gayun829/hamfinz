import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/interest_categories.dart';
import '../data/legal_documents.dart';
import '../data/learning_stages.dart';
import '../data/quiz_data.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';

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
    if (!doc.exists) return null;
    return _profileFromJson(user.email ?? '', doc.data()!);
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
      return _authErrorMessage(e);
    }
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
  Future<String?> completeSignUp({required String nickname}) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      return '이메일 인증을 먼저 완료해주세요.';
    }
    final trimmedNickname = nickname.trim();
    if (trimmedNickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    try {
      await _reserveNickname(user.uid, trimmedNickname);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return '이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해주세요.';
      }
      rethrow;
    }
    await _reserveEmail(user.uid, trimmedNickname, user.email);

    await _users.doc(user.uid).set({
      'nickname': trimmedNickname,
      ..._defaultProfileJson(user),
    });
    return null;
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

  /// 구글 계정으로 로그인/가입. 처음 로그인하는 계정이면 프로필 문서를 새로 만든다.
  Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      await _ensureProfileDoc(
        credential.user!,
        nickname: credential.user!.displayName,
      );
      await _backfillSearchIndexes(credential.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (e) {
      return '구글 로그인 실패: $e';
    }
  }

  /// 카카오 계정(OIDC)으로 로그인/가입. 처음 로그인하는 계정이면 프로필 문서를 새로 만든다.
  Future<String?> signInWithKakao() async {
    try {
      final provider = OAuthProvider('oidc.kakao')
        ..addScope('profile_nickname');
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final profile = credential.additionalUserInfo?.profile;
      await _ensureProfileDoc(
        credential.user!,
        nickname:
            credential.user!.displayName ?? profile?['nickname'] as String?,
      );
      await _backfillSearchIndexes(credential.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (e) {
      return '카카오 로그인 실패: $e';
    }
  }

  /// 소셜 로그인 첫 진입 시 프로필 문서가 없으면 만들어준다.
  Future<void> _ensureProfileDoc(User user, {String? nickname}) async {
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return;
    final fallback = (user.email ?? '').split('@').first;
    var resolvedNickname = (nickname == null || nickname.isEmpty)
        ? (fallback.isEmpty ? '사용자' : fallback)
        : nickname;

    try {
      await _reserveNickname(user.uid, resolvedNickname);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // 소셜 로그인은 닉네임을 직접 고르지 않으니, 충돌하면 uid 뒷자리를 붙여 재시도한다.
      resolvedNickname = '$resolvedNickname${user.uid.substring(0, 4)}';
      await _reserveNickname(user.uid, resolvedNickname);
    }
    await _reserveEmail(user.uid, resolvedNickname, user.email);

    await _users.doc(user.uid).set({
      'nickname': resolvedNickname,
      ..._defaultProfileJson(user),
    });
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

  /// 클라이언트가 직접 고치는 필드만 쓴다.
  ///
  /// xp·energy·streak·learningHistory·categoryStats·unlockedHamsterIds는
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
  /// `consents`는 약관·개인정보 동의 기록이다. 가입 화면이 두 항목 동의를
  /// 강제하므로(소셜 로그인도 같은 약관 아래 진입), 문서를 만드는 시점 =
  /// 동의 시점으로 남긴다. 본문이 개정되면 [LegalDocuments.version]을 올려
  /// 재동의 대상을 가려낸다.
  Map<String, dynamic> _defaultProfileJson(User user) => {
    'xp': 0,
    'streak': 0,
    'lastQuizCompletedDate': null,
    'todayQuizCompleted': false,
    'energy': QuizData.maxEnergy,
    'lastEnergyResetDate': DateHelper.todayKey(),
    'unlockedHamsterIds': ['hamster_basic'],
    'selectedHamsterId': 'hamster_basic',
    'learningHistory': <Map<String, dynamic>>[],
    'categoryStats': <String, dynamic>{},
    'interestCategories': <String>[],
    'learningStage': kMinLearningStage,
    'incorrectQuestionCount': 0,
    'seeds': 0,
    'ownedShopItemIds': <String>[],
    'consents': {
      'termsVersion': LegalDocuments.version,
      'privacyVersion': LegalDocuments.version,
      'agreedAt': FieldValue.serverTimestamp(),
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

    final historyRaw = (data['learningHistory'] as List? ?? [])
        .cast<Map>()
        .map((e) => LearningRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();

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
      xp: data['xp'] as int? ?? 0,
      streak: streak,
      lastQuizCompletedDate: lastDate,
      todayQuizCompleted: todayCompleted,
      energy: energy.clamp(0, QuizData.maxEnergy),
      lastEnergyResetDate: lastEnergyResetDate,
      unlockedHamsterIds: List<String>.from(
        data['unlockedHamsterIds'] as List? ?? ['hamster_basic'],
      ),
      selectedHamsterId:
          data['selectedHamsterId'] as String? ?? 'hamster_basic',
      learningHistory: historyRaw,
      categoryStats: stats,
      interestCategories: List<String>.from(
        data['interestCategories'] as List? ?? [],
      ),
      learningStage: normalizeLearningStage(
        readLearningStageField(data['learningStage']),
      ),
      incorrectQuestionCount:
          (data['incorrectQuestionCount'] as num?)?.toInt() ?? 0,
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
