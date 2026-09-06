import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/interest_categories.dart';
import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';
import '../utils/quiz_text_helper.dart';

/// Firestore `quizQuestions` + `mastered` — 출제 · 제출 · 세션 완료.
/// 개발: 클라이언트 트랜잭션. 배포: `functions/index.js` Callable로 전환 예정.
class QuizSessionRepository {
  QuizSessionRepository._();

  static final instance = QuizSessionRepository._();

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
      final categoryLabel =
          interestCategoryById(targetCategories.first)?.name ??
          _categoryLabels[targetCategories.first] ??
          targetCategories.first;
      throw QuizSessionException(
        '$categoryLabel 카테고리의 출제 가능한 문제가 부족해요. '
        '(${candidates.length}/${QuizData.dailyQuestionCount}문항)',
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

    // 웹: runTransaction 콜백 안에서 throw/reject 하면 Firestore JS SDK가
    // HTTP BodyStream을 abort → AbortError · 무한 대기. 검증은 null 반환 후 처리.
    final txError = <String>[];

    try {
      final txResult = await _firestore.runTransaction<Map<String, dynamic>?>(
        (tx) async {
        txError.clear();
        final userSnap = await tx.get(userRef);
        final sessionSnap = await tx.get(sessionRef);
        final answerSnap = await tx.get(answerRef);
        final questionSnap = await tx.get(questionRef);

        if (!userSnap.exists) {
          txError.add('유저 프로필을 찾을 수 없어요.');
          return null;
        }
        if (!sessionSnap.exists) {
          txError.add('세션을 찾을 수 없어요.');
          return null;
        }
        if (!questionSnap.exists) {
          txError.add('문제를 찾을 수 없어요.');
          return null;
        }

        final session = sessionSnap.data()!;
        if (session['status'] != 'inProgress') {
          txError.add('이미 종료된 세션이에요.');
          return null;
        }

        final questionIds = List<String>.from(
          (session['questionIds'] as List?) ?? [],
        );
        if (!questionIds.contains(questionId)) {
          txError.add('이 세션의 문제가 아니에요.');
          return null;
        }

        if (answerSnap.exists) {
          txError.add('이미 제출한 문제예요.');
          return null;
        }

        final user = userSnap.data()!;
        var energy = (user['energy'] as num?)?.toInt() ?? QuizData.maxEnergy;
        if (energy < QuizData.energyCostPerQuestion) {
          txError.add('에너지가 부족해요.');
          return null;
        }

        final q = questionSnap.data()!;
        if (q['isActive'] != true) {
          txError.add('출제되지 않은 문제예요.');
          return null;
        }

        final options = List<String>.from((q['options'] as List?) ?? []);
        if (selectedIndex < 0 || selectedIndex >= options.length) {
          txError.add('보기 번호가 올바르지 않아요.');
          return null;
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

        // 웹: 커스텀 클래스 반환은 JS interop에서 null로 깨짐 → Map만 반환.
        return {
          'isCorrect': isCorrect,
          'correctIndex': correctIndex,
          'energyRemaining': energy,
        };
      },
      );

      if (txError.isNotEmpty) {
        throw QuizSessionException(txError.first);
      }
      if (txResult == null) {
        throw QuizSessionException('답안 제출에 실패했어요.');
      }
      return _submitAnswerResultFromTx(txResult);
    } on QuizSessionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw QuizSessionException(_firebaseTxMessage(e, '답안 제출에 실패했어요.'));
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

    final txError = <String>[];

    try {
      final txResult = await _firestore.runTransaction<Map<String, dynamic>?>(
        (tx) async {
        txError.clear();
        final sessionSnap = await tx.get(sessionRef);
        if (!sessionSnap.exists) {
          txError.add('세션을 찾을 수 없어요.');
          return null;
        }

        final session = sessionSnap.data()!;
        if (session['status'] != 'inProgress') {
          txError.add('이미 완료된 세션이에요.');
          return null;
        }

        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          txError.add('유저 프로필을 찾을 수 없어요.');
          return null;
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
            txError.add(
              '아직 풀지 않은 문제가 있어요. (${answerDocs.length}/$expectedCount)',
            );
            return null;
          }
          answerDocs.add(answerSnap);
        }

        if (answerDocs.length < expectedCount) {
          txError.add(
            '아직 풀지 않은 문제가 있어요. (${answerDocs.length}/$expectedCount)',
          );
          return null;
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
        var studyGuardCount = (user['studyGuardCount'] as num?)?.toInt() ?? 0;
        final today = DateHelper.todayKey();

        if (!todayQuizCompleted) {
          todayQuizCompleted = true;
          if (lastQuizCompletedDate == null) {
            streak = 1;
          } else if (DateHelper.isYesterday(lastQuizCompletedDate)) {
            streak += 1;
          } else if (!DateHelper.isToday(lastQuizCompletedDate)) {
            final lastDate = DateTime.tryParse(lastQuizCompletedDate);
            final todayDate = DateTime.tryParse(today);
            final missedDays = lastDate == null || todayDate == null
                ? 1
                : todayDate.difference(lastDate).inDays - 1;
            // 방어권은 결석일수를 전부 못 덮으면 쓰지 않는다 — 일부만 막고
            // streak을 어차피 리셋하면 방어권만 날리고 얻는 게 없다.
            if (missedDays <= studyGuardCount) {
              studyGuardCount -= missedDays;
              streak += 1;
            } else {
              streak = 1;
            }
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
          'studyGuardCount': studyGuardCount,
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

        return {
          'answers': answerResults
              .map(
                (a) => {
                  'questionId': a.questionId,
                  'selectedIndex': a.selectedIndex,
                  'isCorrect': a.isCorrect,
                },
              )
              .toList(),
          'xpEarned': xpEarned,
          'seedsEarned': seedsEarned,
          'leveledUp': newLevel > previousLevel,
          'newLevel': newLevel,
          'previousLevel': previousLevel,
          'unlockedItems': unlocks.newly,
          'newStreak': streak,
          'energyRemaining': energyRemaining,
        };
      },
      );

      if (txError.isNotEmpty) {
        throw QuizSessionException(txError.first);
      }
      if (txResult == null) {
        throw QuizSessionException('세션 완료 처리에 실패했어요.');
      }
      return _sessionResultFromTx(txResult);
    } on QuizSessionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw QuizSessionException(_firebaseTxMessage(e, '세션 완료 처리에 실패했어요.'));
    }
  }

  SubmitAnswerResult _submitAnswerResultFromTx(Map<String, dynamic> data) {
    return SubmitAnswerResult(
      isCorrect: data['isCorrect'] as bool? ?? false,
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
      energyRemaining: (data['energyRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  QuizSessionResult _sessionResultFromTx(Map<String, dynamic> data) {
    final answersRaw = (data['answers'] as List? ?? []).cast<Map>();
    return QuizSessionResult(
      answers: answersRaw
          .map(
            (a) => QuizAnswer(
              questionId: a['questionId'] as String,
              selectedIndex: (a['selectedIndex'] as num).toInt(),
              isCorrect: a['isCorrect'] as bool? ?? false,
            ),
          )
          .toList(),
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      seedsEarned: (data['seedsEarned'] as num?)?.toInt() ?? 0,
      leveledUp: data['leveledUp'] as bool? ?? false,
      newLevel: (data['newLevel'] as num?)?.toInt() ?? 1,
      previousLevel: (data['previousLevel'] as num?)?.toInt() ?? 1,
      unlockedItems: List<String>.from(data['unlockedItems'] as List? ?? []),
      newStreak: (data['newStreak'] as num?)?.toInt() ?? 0,
      energyRemaining: (data['energyRemaining'] as num?)?.toInt(),
    );
  }

  String _firebaseTxMessage(FirebaseException e, String fallback) {
    if (e.code == 'permission-denied') {
      return firestorePermissionDeniedMessage();
    }
    final msg = e.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return '$fallback (${e.code})';
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
    final activeId = resolveActiveInterestCategoryId(profile.interestCategories);
    if (activeId == null) {
      throw QuizSessionException('학습 카테고리를 선택해 주세요.');
    }
    return [activeId];
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
        question: stripQuizMetadataPrefix(data['question'] as String? ?? ''),
        options: options,
        correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
        explanation: stripQuizMetadataPrefix(
          data['explanation'] as String? ?? '',
        ),
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
