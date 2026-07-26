import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/user_profile.dart';
import '../utils/date_helper.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const _usersKey = 'finquiz_users';
  static const _sessionKey = 'finquiz_session';

  // 개발자가 회원가입 없이 바로 로그인해볼 수 있는 테스트 계정.
  static const testEmail = 'test@finquiz.com';
  static const testPassword = 'test1234';

  Future<String?> getCurrentEmail() async {
    return StorageService.instance.getString(_sessionKey);
  }

  Future<UserProfile?> getCurrentUser() async {
    final email = await getCurrentEmail();
    if (email == null) return null;
    return getUser(email);
  }

  Future<UserProfile?> getUser(String email) async {
    final users = _loadUsers();
    final data = users[email];
    if (data == null) return null;
    return _profileFromJson(email, data);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.length < 6) {
      return '이메일과 6자 이상 비밀번호를 입력해주세요.';
    }
    if (nickname.trim().isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    final users = _loadUsers();
    if (users.containsKey(trimmedEmail)) {
      return '이미 가입된 이메일입니다.';
    }

    final salt = _generateSalt();
    users[trimmedEmail] = {
      'passwordHash': _hashPassword(password, salt),
      'salt': salt,
      'nickname': nickname.trim(),
      'profile': _defaultProfileJson(),
    };
    await _saveUsers(users);
    await StorageService.instance.setString(_sessionKey, trimmedEmail);
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

    final users = _loadUsers();
    if (trimmedEmail == testEmail && password == testPassword) {
      await _ensureTestAccount(users);
    }

    final user = users[trimmedEmail] as Map<String, dynamic>?;
    if (user == null) {
      return '가입되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.';
    }

    final salt = user['salt'] as String?;
    final storedHash = user['passwordHash'] as String?;
    if (salt == null ||
        storedHash == null ||
        _hashPassword(password, salt) != storedHash) {
      return '이메일 또는 비밀번호가 일치하지 않습니다.';
    }

    await StorageService.instance.setString(_sessionKey, trimmedEmail);
    return null;
  }

  Future<void> logout() async {
    await StorageService.instance.remove(_sessionKey);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final users = _loadUsers();
    final user = users[profile.email];
    if (user == null) return;
    user['profile'] = _profileToJson(profile);
    await _saveUsers(users);
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

  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (newPassword.length < 6) {
      return '6자 이상 비밀번호를 입력해주세요.';
    }

    final users = _loadUsers();
    final user = users[trimmedEmail] as Map<String, dynamic>?;
    if (user == null) {
      return '가입되지 않은 이메일입니다.';
    }

    final salt = _generateSalt();
    user['salt'] = salt;
    user['passwordHash'] = _hashPassword(newPassword, salt);
    await _saveUsers(users);
    return null;
  }

  Future<void> _ensureTestAccount(Map<String, dynamic> users) async {
    if (users.containsKey(testEmail)) return;

    final salt = _generateSalt();
    users[testEmail] = {
      'passwordHash': _hashPassword(testPassword, salt),
      'salt': salt,
      'nickname': '테스트 계정',
      'profile': _defaultProfileJson(),
    };
    await _saveUsers(users);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  Map<String, dynamic> _loadUsers() {
    return Map<String, dynamic>.from(
      StorageService.instance.getJson(_usersKey) ?? {},
    );
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    await StorageService.instance.setJson(_usersKey, users);
  }

  Map<String, dynamic> _defaultProfileJson() => {
    'xp': 0,
    'streak': 0,
    'lastQuizCompletedDate': null,
    'todayQuizCompleted': false,
    'unlockedHamsterIds': ['hamster_basic'],
    'selectedHamsterId': 'hamster_basic',
    'learningHistory': <Map<String, dynamic>>[],
    'categoryStats': <String, dynamic>{},
    'interestCategories': <String>[],
  };

  UserProfile _profileFromJson(String email, Map<String, dynamic> user) {
    final profile = Map<String, dynamic>.from(user['profile'] as Map? ?? {});
    final statsRaw = Map<String, dynamic>.from(
      profile['categoryStats'] as Map? ?? {},
    );
    final stats = <String, CategoryStat>{};
    for (final entry in statsRaw.entries) {
      stats[entry.key] = CategoryStat.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    final historyRaw = (profile['learningHistory'] as List? ?? [])
        .cast<Map>()
        .map((e) => LearningRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final lastDate = profile['lastQuizCompletedDate'] as String?;
    var streak = profile['streak'] as int? ?? 0;
    var todayCompleted = profile['todayQuizCompleted'] as bool? ?? false;

    if (lastDate != null &&
        !DateHelper.isToday(lastDate) &&
        !DateHelper.isYesterday(lastDate)) {
      streak = 0;
      todayCompleted = false;
    } else if (lastDate != null && !DateHelper.isToday(lastDate)) {
      todayCompleted = false;
    }

    return UserProfile(
      email: email,
      nickname: user['nickname'] as String? ?? email,
      xp: profile['xp'] as int? ?? 0,
      streak: streak,
      lastQuizCompletedDate: lastDate,
      todayQuizCompleted: todayCompleted,
      unlockedHamsterIds: List<String>.from(
        profile['unlockedHamsterIds'] as List? ?? ['hamster_basic'],
      ),
      selectedHamsterId:
          profile['selectedHamsterId'] as String? ?? 'hamster_basic',
      learningHistory: historyRaw,
      categoryStats: stats,
      interestCategories: List<String>.from(
        profile['interestCategories'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> _profileToJson(UserProfile profile) => {
    'xp': profile.xp,
    'streak': profile.streak,
    'lastQuizCompletedDate': profile.lastQuizCompletedDate,
    'todayQuizCompleted': profile.todayQuizCompleted,
    'unlockedHamsterIds': profile.unlockedHamsterIds,
    'selectedHamsterId': profile.selectedHamsterId,
    'learningHistory': profile.learningHistory.map((e) => e.toJson()).toList(),
    'categoryStats': profile.categoryStats.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'interestCategories': profile.interestCategories,
  };
}
