import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      ..._defaultProfileJson(),
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
      final provider = OAuthProvider('oidc.kakao')..addScope('profile_nickname');
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final profile = credential.additionalUserInfo?.profile;
      await _ensureProfileDoc(
        credential.user!,
        nickname: credential.user!.displayName ?? profile?['nickname'] as String?,
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
      ..._defaultProfileJson(),
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
        await _reserveNickname(user.uid, '$nickname${user.uid.substring(0, 4)}');
      }
    }

    final hasEmail = await _emails.where('uid', isEqualTo: user.uid).limit(1).get();
    if (hasEmail.docs.isEmpty) {
      await _reserveEmail(user.uid, nickname, user.email);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).update(_profileToJson(profile));
  }

  /// 관심 카테고리 저장.
  /// 회원가입 직후 카테고리 선택 화면에서 호출한다.
  /// (categoryIds는 QuizCategory enum의 name 문자열 목록)
  Future<void> saveInterestCategories(List<String> categoryIds) async {
    final profile = await getCurrentUser();
    if (profile == null) return;
    profile.interestCategories = List<String>.from(categoryIds);
    await saveProfile(profile);
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

  Map<String, dynamic> _defaultProfileJson() => {
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
    'seeds': 0,
    'ownedShopItemIds': <String>[],
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
      xp: data['xp'] as int? ?? 0,
      streak: streak,
      lastQuizCompletedDate: lastDate,
      todayQuizCompleted: todayCompleted,
      energy: energy.clamp(0, QuizData.maxEnergy),
      lastEnergyResetDate: lastEnergyResetDate,
      unlockedHamsterIds: List<String>.from(
        data['unlockedHamsterIds'] as List? ?? ['hamster_basic'],
      ),
      selectedHamsterId: data['selectedHamsterId'] as String? ?? 'hamster_basic',
      learningHistory: historyRaw,
      categoryStats: stats,
      interestCategories: List<String>.from(
        data['interestCategories'] as List? ?? [],
      ),
      seeds: data['seeds'] as int? ?? 0,
      ownedShopItemIds: List<String>.from(
        data['ownedShopItemIds'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> _profileToJson(UserProfile profile) => {
    'nickname': profile.nickname,
    'xp': profile.xp,
    'streak': profile.streak,
    'lastQuizCompletedDate': profile.lastQuizCompletedDate,
    'todayQuizCompleted': profile.todayQuizCompleted,
    'energy': profile.energy,
    'lastEnergyResetDate': profile.lastEnergyResetDate,
    'unlockedHamsterIds': profile.unlockedHamsterIds,
    'selectedHamsterId': profile.selectedHamsterId,
    'learningHistory': profile.learningHistory.map((e) => e.toJson()).toList(),
    'categoryStats': profile.categoryStats.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'interestCategories': profile.interestCategories,
    'seeds': profile.seeds,
    'ownedShopItemIds': profile.ownedShopItemIds,
  };
}
