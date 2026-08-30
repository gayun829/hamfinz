import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';

/// Firestore `quizQuestions` + `mastered` — 출제 · 제출 · 세션 완료.
/// 개발: 클라이언트 트랜잭션. 배포: `functions/index.js` Callable로 전환 예정.
class QuizSessionRepository {
  QuizSessionRepository._();

  static final instance = QuizSessionRepository._();

  static const _allCategoryIds = [
    'allowance',
    'saving',
    'stock',
    'insurance',
    'tax',
    'credit',
  ];

  /// 카테고리당 후보 풀 크기 (랜덤 셔플 후 10문항 선정).
  static const _poolPerCategory = 200;

  static const _categoryLabels = {
    'allowance': '용돈 관리',
    'saving': '저축',
    'stock': '주식 기초',
    'insurance': '보험',
    'tax': '세금',
    'credit': '신용',
  };

  final _firestore = FirebaseFirestore.instance;
  final _random = Random();

  Future<QuizSession> startSession({required UserProfile profile}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw QuizSessionException('로그인이 필요해요.');
    }

    if (profile.energy < QuizData.sessionEnergyCost) {
      throw QuizSessionException(
        '에너지가 부족해요. ${QuizData.sessionEnergyCost} 이상 필요해요.',
      );
    }

    final mastered = await _fetchMasteredIds(uid);
    final targetCategories = _targetCategories(profile);

    var candidates = await _fetchCandidates(
      categoryIds: targetCategories,
      excludeIds: mastered,
    );

    if (candidates.length < QuizData.dailyQuestionCount) {
      final extraCategories = _allCategoryIds
          .where((id) => !targetCategories.contains(id))
          .toList();
      final extra = await _fetchCandidates(
        categoryIds: extraCategories,
        excludeIds: mastered,
      );
      final seen = candidates.map((c) => c.id).toSet();
      for (final doc in extra) {
        if (seen.add(doc.id)) candidates.add(doc);
      }
    }

    if (candidates.length < QuizData.dailyQuestionCount) {
      throw QuizSessionException(
        '출제 가능한 문제가 부족해요. (${candidates.length}문항)',
      );
    }

    final selected = _selectQuestions(
      candidates,
      count: QuizData.dailyQuestionCount,
    );

    final sessionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc();

    await sessionRef.set({
      'source': 'energySession',
      'questionIds': selected.map((q) => q.id).toList(),
      'questionCount': selected.length,
      'correctCount': 0,
      'xpEarned': 0,
      'energySpent': 0,
      'seedDate': DateHelper.todayKey(),
      'status': 'inProgress',
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });

    return QuizSession(
      sessionId: sessionRef.id,
      questions: selected
          .map(
            (q) => QuizQuestionLearning(
              id: q.id,
              type: q.type,
              category: q.category,
              difficulty: q.difficulty,
              question: q.question,
              options: q.options,
              explanation: q.explanation,
            ),
          )
          .toList(),
    );
  }

  /// DB `correctIndex`로 채점 · answers · mastered · energy 차감.
  Future<SubmitAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw QuizSessionException('로그인이 필요해요.');

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = userRef.collection('sessions').doc(sessionId);
    final answerRef = sessionRef.collection('answers').doc(questionId);
    final questionRef = _firestore.collection('quizQuestions').doc(questionId);

    try {
      return await _firestore.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final sessionSnap = await tx.get(sessionRef);
        final answerSnap = await tx.get(answerRef);
        final questionSnap = await tx.get(questionRef);

        if (!userSnap.exists) {
          throw QuizSessionException('유저 프로필을 찾을 수 없어요.');
        }
        if (!sessionSnap.exists) {
          throw QuizSessionException('세션을 찾을 수 없어요.');
        }
        if (!questionSnap.exists) {
          throw QuizSessionException('문제를 찾을 수 없어요.');
        }

        final session = sessionSnap.data()!;
        if (session['status'] != 'inProgress') {
          throw QuizSessionException('이미 종료된 세션이에요.');
        }

        final questionIds = List<String>.from(
          (session['questionIds'] as List?) ?? [],
        );
        if (!questionIds.contains(questionId)) {
          throw QuizSessionException('이 세션의 문제가 아니에요.');
        }

        if (answerSnap.exists) {
          throw QuizSessionException('이미 제출한 문제예요.');
        }

        final user = userSnap.data()!;
        var energy = (user['energy'] as num?)?.toInt() ?? QuizData.maxEnergy;
        if (energy < QuizData.energyCostPerQuestion) {
          throw QuizSessionException('에너지가 부족해요.');
        }

        final q = questionSnap.data()!;
        if (q['isActive'] != true) {
          throw QuizSessionException('출제되지 않은 문제예요.');
        }

        final options = List<String>.from((q['options'] as List?) ?? []);
        if (selectedIndex < 0 || selectedIndex >= options.length) {
          throw QuizSessionException('보기 번호가 올바르지 않아요.');
        }

        final correctIndex = (q['correctIndex'] as num?)?.toInt() ?? 0;
        final isCorrect = selectedIndex == correctIndex;
        energy = (energy - QuizData.energyCostPerQuestion).clamp(
          0,
          QuizData.maxEnergy,
        );

        tx.update(userRef, {'energy': energy});

        tx.set(answerRef, {
          'selectedIndex': selectedIndex,
          'isCorrect': isCorrect,
          'categoryId': q['categoryId'] ?? 'allowance',
          'energySpent': QuizData.energyCostPerQuestion,
          'answeredAt': FieldValue.serverTimestamp(),
        });

        if (isCorrect) {
          tx.set(
            userRef.collection('mastered').doc(questionId),
            {'answeredAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
        }

        final sessionUpdate = <String, dynamic>{
          'energySpent':
              ((session['energySpent'] as num?)?.toInt() ?? 0) +
              QuizData.energyCostPerQuestion,
        };
        if (isCorrect) {
          sessionUpdate['correctCount'] =
              ((session['correctCount'] as num?)?.toInt() ?? 0) + 1;
        }
        tx.update(sessionRef, sessionUpdate);

        return SubmitAnswerResult(
          isCorrect: isCorrect,
          correctIndex: correctIndex,
          energyRemaining: energy,
        );
      });
    } on QuizSessionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw QuizSessionException(e.message ?? '답안 제출에 실패했어요.');
    }
  }

  /// answers 집계 · XP · 씨앗 · streak · categoryStats · 세션 completed.
  Future<QuizSessionResult> completeSession({
    required String sessionId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw QuizSessionException('로그인이 필요해요.');

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = userRef.collection('sessions').doc(sessionId);

    try {
      return await _firestore.runTransaction((tx) async {
        final sessionSnap = await tx.get(sessionRef);
        if (!sessionSnap.exists) {
          throw QuizSessionException('세션을 찾을 수 없어요.');
        }

        final session = sessionSnap.data()!;
        if (session['status'] != 'inProgress') {
          throw QuizSessionException('이미 완료된 세션이에요.');
        }

        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          throw QuizSessionException('유저 프로필을 찾을 수 없어요.');
        }

        final questionIds = List<String>.from(
          (session['questionIds'] as List?) ?? [],
        );
        final expectedCount =
            (session['questionCount'] as num?)?.toInt() ?? questionIds.length;

        final answerDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final qid in questionIds) {
          final answerSnap = await tx.get(
            sessionRef.collection('answers').doc(qid),
          );
          if (!answerSnap.exists) {
            throw QuizSessionException(
              '아직 풀지 않은 문제가 있어요. (${answerDocs.length}/$expectedCount)',
            );
          }
          answerDocs.add(answerSnap);
        }

        if (answerDocs.length < expectedCount) {
          throw QuizSessionException(
            '아직 풀지 않은 문제가 있어요. (${answerDocs.length}/$expectedCount)',
          );
        }

        final answers = answerDocs;

        final user = userSnap.data()!;
        final previousXp = (user['xp'] as num?)?.toInt() ?? 0;
        final previousLevel = LevelUtils.levelFromXp(previousXp);

        var xpEarned = 0;
        var correctCount = 0;
        final categoryStats = _copyCategoryStats(user['categoryStats']);
        final answerResults = <QuizAnswer>[];

        for (final doc in answers) {
          final a = doc.data()!;
          final isCorrect = a['isCorrect'] == true;
          if (isCorrect) correctCount++;
          xpEarned += isCorrect ? QuizData.correctXp : QuizData.wrongXp;

          final categoryId = a['categoryId'] as String? ?? 'allowance';
          final label = _categoryLabels[categoryId] ?? categoryId;
          categoryStats.putIfAbsent(label, CategoryStat.new);
          categoryStats[label]!.total += 1;
          if (isCorrect) categoryStats[label]!.correct += 1;

          answerResults.add(
            QuizAnswer(
              questionId: doc.id,
              selectedIndex: (a['selectedIndex'] as num).toInt(),
              isCorrect: isCorrect,
            ),
          );
        }

        final seedsEarned = correctCount * QuizData.seedsPerCorrect;
        final newXp = previousXp + xpEarned;
        final newLevel = LevelUtils.levelFromXp(newXp);

        var streak = (user['streak'] as num?)?.toInt() ?? 0;
        var lastQuizCompletedDate = user['lastQuizCompletedDate'] as String?;
        var todayQuizCompleted = user['todayQuizCompleted'] as bool? ?? false;
        final today = DateHelper.todayKey();

        if (!todayQuizCompleted) {
          todayQuizCompleted = true;
          if (lastQuizCompletedDate == null) {
            streak = 1;
          } else if (DateHelper.isYesterday(lastQuizCompletedDate)) {
            streak += 1;
          } else if (!DateHelper.isToday(lastQuizCompletedDate)) {
            streak = 1;
          }
          lastQuizCompletedDate = today;
        }

        final history = [
          LearningRecord(
            date: today,
            correctCount: correctCount,
            totalCount: answers.length,
            xpEarned: xpEarned,
          ),
          ...List<LearningRecord>.from(
            ((user['learningHistory'] as List?) ?? [])
                .cast<Map>()
                .map(
                  (e) => LearningRecord.fromJson(Map<String, dynamic>.from(e)),
                ),
          ),
        ].take(50).toList();

        final unlocks = _computeUnlocks(
          user: user,
          streak: streak,
          xp: newXp,
          historyLength: history.length,
        );

        final energyRemaining = (user['energy'] as num?)?.toInt() ?? 0;

        tx.update(userRef, {
          'xp': newXp,
          'seeds': ((user['seeds'] as num?)?.toInt() ?? 0) + seedsEarned,
          'streak': streak,
          'lastQuizCompletedDate': lastQuizCompletedDate,
          'todayQuizCompleted': todayQuizCompleted,
          'categoryStats': categoryStats.map(
            (key, value) => MapEntry(key, value.toJson()),
          ),
          'learningHistory': history.map((e) => e.toJson()).toList(),
          'unlockedHamsterIds': unlocks.all,
        });

        tx.update(sessionRef, {
          'status': 'completed',
          'correctCount': correctCount,
          'xpEarned': xpEarned,
          'energySpent':
              (session['energySpent'] as num?)?.toInt() ??
              answers.length * QuizData.energyCostPerQuestion,
          'completedAt': FieldValue.serverTimestamp(),
        });

        return QuizSessionResult(
          answers: answerResults,
          xpEarned: xpEarned,
          seedsEarned: seedsEarned,
          leveledUp: newLevel > previousLevel,
          newLevel: newLevel,
          previousLevel: previousLevel,
          unlockedItems: unlocks.newly,
          newStreak: streak,
          energyRemaining: energyRemaining,
        );
      });
    } on QuizSessionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw QuizSessionException(e.message ?? '세션 완료 처리에 실패했어요.');
    }
  }

  Map<String, CategoryStat> _copyCategoryStats(Object? raw) {
    final statsRaw = Map<String, dynamic>.from(raw as Map? ?? {});
    final stats = <String, CategoryStat>{};
    for (final entry in statsRaw.entries) {
      stats[entry.key] = CategoryStat.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return stats;
  }

  ({List<String> all, List<String> newly}) _computeUnlocks({
    required Map<String, dynamic> user,
    required int streak,
    required int xp,
    required int historyLength,
  }) {
    final unlocked = Set<String>.from(
      (user['unlockedHamsterIds'] as List?)?.cast<String>() ??
          ['hamster_basic'],
    );
    final newly = <String>[];

    void unlock(String id) {
      if (unlocked.add(id)) newly.add(id);
    }

    if (historyLength > 0) unlock('hamster_study');
    if (streak >= 3) unlock('hamster_streak');
    final level = LevelUtils.levelFromXp(xp);
    if (level >= 3) unlock('hamster_level3');
    if (level >= 5) unlock('hamster_level5');
    if (level >= 10) unlock('hamster_master');

    return (all: unlocked.toList(), newly: newly);
  }

  List<String> _targetCategories(UserProfile profile) {
    final ids = profile.interestCategories
        .where((id) => _allCategoryIds.contains(id))
        .toList();
    return ids.isEmpty ? List<String>.from(_allCategoryIds) : ids;
  }

  Future<Set<String>> _fetchMasteredIds(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('mastered')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<List<_QuestionDoc>> _fetchCandidates({
    required List<String> categoryIds,
    required Set<String> excludeIds,
  }) async {
    final results = <_QuestionDoc>[];

    for (final categoryId in categoryIds) {
      final snap = await _firestore
          .collection('quizQuestions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .limit(_poolPerCategory)
          .get();

      for (final doc in snap.docs) {
        if (excludeIds.contains(doc.id)) continue;
        final parsed = _parseQuestionDoc(doc);
        if (parsed != null) results.add(parsed);
      }
    }

    return results;
  }

  _QuestionDoc? _parseQuestionDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    try {
      final categoryId = data['categoryId'] as String? ?? '';
      final typeRaw = data['type'] as String? ?? '';
      final optionsRaw = data['options'];

      final options = optionsRaw is List
          ? optionsRaw.map((e) => e.toString()).toList()
          : <String>[];

      return _QuestionDoc(
        id: doc.id,
        type: _parseType(typeRaw),
        category: _parseCategory(categoryId),
        difficulty: (data['difficulty'] as num?)?.toInt() ?? 1,
        question: data['question'] as String? ?? '',
        options: options,
        correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
        explanation: data['explanation'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  QuizType _parseType(String raw) {
    return raw == 'multipleChoice' ? QuizType.multipleChoice : QuizType.ox;
  }

  QuizCategory _parseCategory(String categoryId) {
    for (final category in QuizCategory.values) {
      if (category.name == categoryId) return category;
    }
    return QuizCategory.allowance;
  }

  List<_QuestionDoc> _selectQuestions(
    List<_QuestionDoc> candidates, {
    required int count,
  }) {
    final pool = List<_QuestionDoc>.from(candidates)..shuffle(_random);

    // 난이도 1~10 구간에서 무작위 목표를 두고 가까운 순으로 1차 정렬 후 셔플.
    final targetDifficulty = _random.nextInt(10) + 1;
    pool.sort(
      (a, b) => (a.difficulty - targetDifficulty)
          .abs()
          .compareTo((b.difficulty - targetDifficulty).abs()),
    );

    final picked = <_QuestionDoc>[];

    for (final question in pool) {
      if (picked.length >= count) break;
      // 카테고리 다양성: 아직 적은 카테고리 우선 (최대 2개까지 같은 카테고리 연속 허용).
      final sameCategoryCount =
          picked.where((q) => q.category == question.category).length;
      if (sameCategoryCount >= 3) continue;
      picked.add(question);
    }

    if (picked.length < count) {
      for (final question in pool) {
        if (picked.length >= count) break;
        if (picked.any((q) => q.id == question.id)) continue;
        picked.add(question);
      }
    }

    picked.shuffle(_random);
    return picked.take(count).toList();
  }
}

class _QuestionDoc {
  const _QuestionDoc({
    required this.id,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final QuizType type;
  final QuizCategory category;
  final int difficulty;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}
