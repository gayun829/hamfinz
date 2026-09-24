import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/interest_categories.dart';
import '../data/learning_stages.dart';
import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../utils/date_helper.dart';
import '../utils/energy_reset.dart';
import '../utils/incorrect_questions.dart';
import '../utils/learning_dates.dart';
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
    final categoryId = targetCategories.first;
    final categoryLabel =
        interestCategoryById(categoryId)?.name ??
        _categoryLabels[categoryId] ??
        categoryId;

    final resolved = await _resolveStageCandidates(
      profile: profile,
      uid: uid,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      mastered: mastered,
    );

    final candidates = resolved.candidates;
    final sessionCount = candidates.length < QuizData.dailyQuestionCount
        ? candidates.length
        : QuizData.dailyQuestionCount;

    if (sessionCount == 0) {
      throw QuizSessionException(
        '$categoryLabel ${resolved.stage}단계의 출제 가능한 문제가 없어요.',
      );
    }

    final selected = _selectQuestions(candidates, count: sessionCount);

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
      'energySpent': 0,
      'seedDate': DateHelper.todayKey(),
      'status': 'inProgress',
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });

    return _learningSession(sessionId: sessionRef.id, selected: selected);
  }

  /// 활성 카테고리의 오답에서 최대 10문항을 다시 출제한다.
  Future<QuizSession> startReviewSession({required UserProfile profile}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw QuizSessionException('로그인이 필요해요.');
    }

    if (profile.energy < QuizData.sessionEnergyCost) {
      throw QuizSessionException(
        '에너지가 부족해요. ${QuizData.sessionEnergyCost} 이상 필요해요.',
      );
    }

    final categoryId = _targetCategories(profile).first;
    final userRef = _firestore.collection('users').doc(uid);
    final incorrectIds = await _fetchIncorrectQuestionIds(
      userRef: userRef,
      categoryId: categoryId,
    );
    incorrectIds.shuffle(_random);

    if (incorrectIds.isEmpty) {
      throw QuizSessionException('이 카테고리에서 복습할 오답이 없어요.');
    }

    final selected = <_QuestionDoc>[];
    for (var i = 0; i < incorrectIds.length; i += 10) {
      if (selected.length >= QuizData.dailyQuestionCount) break;
      final chunk = incorrectIds.skip(i).take(10);
      final docs = await Future.wait(
        chunk.map((id) => _firestore.collection('quizQuestions').doc(id).get()),
      );
      for (final doc in docs) {
        if (selected.length >= QuizData.dailyQuestionCount) break;
        if (doc.data()?['isActive'] != true) continue;
        final parsed = _parseQuestionDoc(doc);
        if (parsed == null || parsed.category.name != categoryId) continue;
        selected.add(parsed);
      }
    }

    if (selected.isEmpty) {
      throw QuizSessionException('복습할 문제를 불러오지 못했어요.');
    }

    final sessionRef = userRef.collection('sessions').doc();
    await sessionRef.set({
      'source': QuizSession.reviewSessionSource,
      'categoryId': categoryId,
      'questionIds': selected.map((q) => q.id).toList(),
      'questionCount': selected.length,
      'correctCount': 0,
      'energySpent': 0,
      'seedDate': DateHelper.todayKey(),
      'status': 'inProgress',
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });

    return _learningSession(
      sessionId: sessionRef.id,
      selected: selected,
      source: QuizSession.reviewSessionSource,
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

    // 모바일 SDK 트랜잭션은 컬렉션을 조회할 수 없어서 맵은 그 전에 맞춘다.
    // 이 세션에서 맵을 확인한 계정은 추가로 읽지 않는다.
    await AuthService.instance.ensureIncorrectQuestionCounts(uid);

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = userRef.collection('sessions').doc(sessionId);
    final answerRef = sessionRef.collection('answers').doc(questionId);
    final questionRef = _firestore.collection('quizQuestions').doc(questionId);
    final incorrectRef = userRef
        .collection('incorrectQuestions')
        .doc(questionId);

    // 웹: runTransaction 콜백 안에서 throw/reject 하면 Firestore JS SDK가
    // HTTP BodyStream을 abort → AbortError · 무한 대기. 검증은 null 반환 후 처리.
    final txError = <String>[];

    try {
      final txResult = await _firestore.runTransaction<Map<String, dynamic>?>((
        tx,
      ) async {
        txError.clear();
        final userSnap = await tx.get(userRef);
        final sessionSnap = await tx.get(sessionRef);
        final answerSnap = await tx.get(answerRef);
        final questionSnap = await tx.get(questionRef);
        final incorrectSnap = await tx.get(incorrectRef);

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
        final resolvedEnergy = _userEnergy(user);
        var energy = resolvedEnergy.energy;
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

        final categoryId = q['categoryId'] as String? ?? 'allowance';
        final counts = readIncorrectQuestionCounts(user);
        final nextCounts = nextIncorrectQuestionCounts(
          counts: counts,
          categoryId: categoryId,
          isCorrect: isCorrect,
          alreadyTracked: incorrectSnap.exists,
        );
        final nextTotal = totalIncorrectQuestionCount(nextCounts);
        final currentTotal =
            (user['incorrectQuestionCount'] as num?)?.toInt() ?? 0;
        final userUpdate = <String, dynamic>{
          'energy': energy,
          'lastEnergyResetDate': resolvedEnergy.lastEnergyResetDate,
        };
        if (nextTotal != currentTotal ||
            !sameIncorrectQuestionCounts(counts, nextCounts)) {
          userUpdate['incorrectQuestionCounts'] = nextCounts;
          userUpdate['incorrectQuestionCount'] = nextTotal;
        }
        tx.update(userRef, userUpdate);

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
          if (incorrectSnap.exists) {
            tx.delete(incorrectRef);
          }
        } else {
          final previousWrongCount =
              (incorrectSnap.data()?['wrongCount'] as num?)?.toInt() ?? 0;
          final incorrectUpdate = <String, dynamic>{
            'questionId': questionId,
            'categoryId': q['categoryId'] ?? 'allowance',
            'difficulty': (q['difficulty'] as num?)?.toInt() ?? 1,
            'wrongCount': previousWrongCount + 1,
            'lastSelectedIndex': selectedIndex,
            'lastSessionId': sessionId,
            'lastWrongAt': FieldValue.serverTimestamp(),
          };
          if (!incorrectSnap.exists) {
            incorrectUpdate['firstWrongAt'] = FieldValue.serverTimestamp();
          }
          tx.set(incorrectRef, incorrectUpdate, SetOptions(merge: true));
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
      });

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

  /// answers 집계 · 씨앗 · streak · categoryStats · 세션 completed.
  Future<QuizSessionResult> completeSession({required String sessionId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw QuizSessionException('로그인이 필요해요.');

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = userRef.collection('sessions').doc(sessionId);

    final txError = <String>[];

    try {
      final txResult = await _firestore.runTransaction<Map<String, dynamic>?>((
        tx,
      ) async {
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

        var correctCount = 0;
        final categoryStats = _copyCategoryStats(user['categoryStats']);
        final answerResults = <QuizAnswer>[];

        for (final doc in answers) {
          final a = doc.data()!;
          final isCorrect = a['isCorrect'] == true;
          if (isCorrect) correctCount++;

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

        final sessionSource =
            session['source'] as String? ?? QuizSession.energySessionSource;
        if (sessionSource != QuizSession.reviewSessionSource &&
            answerResults.isNotEmpty) {
          final firstCategoryId =
              answers.first.data()?['categoryId'] as String? ?? 'allowance';
          final sessionLabel =
              _categoryLabels[firstCategoryId] ?? firstCategoryId;
          categoryStats.putIfAbsent(sessionLabel, CategoryStat.new);
          categoryStats[sessionLabel]!.completedSessions += 1;
        }

        final seedsEarned = correctCount * QuizData.seedsPerCorrect;

        var streak = (user['streak'] as num?)?.toInt() ?? 0;
        var lastQuizCompletedDate = user['lastQuizCompletedDate'] as String?;
        var todayQuizCompleted = DateHelper.isToday(lastQuizCompletedDate);
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

        final learningDates = LearningDates.fromUser(
          user,
          today: today,
          markToday: true,
        );

        // 짧은 복습 세션이 에너지 생성 수단이 되지 않도록 실제 소모량까지만
        // 돌려준다.
        final energySpent =
            (session['energySpent'] as num?)?.toInt() ??
            answers.length * QuizData.energyCostPerQuestion;
        final rewardCap = completionEnergyReward(energySpent);
        final resolvedEnergy = _userEnergy(user);
        final energyBefore = resolvedEnergy.energy;
        final energyRemaining = (energyBefore + rewardCap).clamp(
          0,
          QuizData.maxEnergy,
        );
        final energyEarned = energyRemaining - energyBefore;

        tx.update(userRef, {
          'energy': energyRemaining,
          'lastEnergyResetDate': resolvedEnergy.lastEnergyResetDate,
          'seeds': ((user['seeds'] as num?)?.toInt() ?? 0) + seedsEarned,
          'streak': streak,
          'lastQuizCompletedDate': lastQuizCompletedDate,
          'todayQuizCompleted': todayQuizCompleted,
          'studyGuardCount': studyGuardCount,
          'categoryStats': categoryStats.map(
            (key, value) => MapEntry(key, value.toJson()),
          ),
          'learningDates': learningDates,
        });

        tx.update(sessionRef, {
          'status': 'completed',
          'correctCount': correctCount,
          'energySpent': energySpent,
          'energyEarned': energyEarned,
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
          'seedsEarned': seedsEarned,
          'newStreak': streak,
          'energyRemaining': energyRemaining,
          'energyEarned': energyEarned,
        };
      });

      if (txError.isNotEmpty) {
        throw QuizSessionException(txError.first);
      }
      if (txResult == null) {
        throw QuizSessionException('세션 완료 처리에 실패했어요.');
      }
      var result = _sessionResultFromTx(txResult);

      final userData = (await userRef.get()).data() ?? {};
      final categoryId = resolveActiveInterestCategoryId(
        List<String>.from(userData['interestCategories'] as List? ?? []),
      );
      if (categoryId != null) {
        final currentStage = normalizeLearningStage(
          readLearningStageField(userData['learningStage']),
        );
        final masteredAfter = await _fetchMasteredIds(uid);
        final advancedStage = await _advanceStageIfComplete(
          categoryId: categoryId,
          currentStage: currentStage,
          mastered: masteredAfter,
        );
        if (advancedStage != null) {
          result = QuizSessionResult(
            answers: result.answers,
            seedsEarned: result.seedsEarned,
            newStreak: result.newStreak,
            energyRemaining: result.energyRemaining,
            energyEarned: result.energyEarned,
            advancedLearningStage: advancedStage,
          );
        }
      }

      return result;
    } on QuizSessionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw QuizSessionException(_firebaseTxMessage(e, '세션 완료 처리에 실패했어요.'));
    }
  }

  ResolvedEnergy _userEnergy(Map<String, dynamic> user) => resolveDailyEnergy(
    storedEnergy: (user['energy'] as num?)?.toInt(),
    lastEnergyResetDate: user['lastEnergyResetDate'] as String?,
  );

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
      seedsEarned: (data['seedsEarned'] as num?)?.toInt() ?? 0,
      newStreak: (data['newStreak'] as num?)?.toInt() ?? 0,
      energyRemaining: (data['energyRemaining'] as num?)?.toInt(),
      energyEarned: (data['energyEarned'] as num?)?.toInt() ?? 0,
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

  List<String> _targetCategories(UserProfile profile) {
    final activeId = resolveActiveInterestCategoryId(
      profile.interestCategories,
    );
    if (activeId == null) {
      throw QuizSessionException('학습 카테고리를 선택해 주세요.');
    }
    return [activeId];
  }

  /// 활성 카테고리의 오답 id. `categoryId`가 없는 예전 문서는 용돈 관리로
  /// 보므로, 그 카테고리만 컬렉션 전체를 읽어 거른다.
  Future<List<String>> _fetchIncorrectQuestionIds({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String categoryId,
  }) async {
    final collection = userRef.collection('incorrectQuestions');
    final snap = categoryId == legacyIncorrectQuestionCategoryId
        ? await collection.get()
        : await collection.where('categoryId', isEqualTo: categoryId).get();
    return snap.docs
        .where((doc) => incorrectQuestionCategoryId(doc.data()) == categoryId)
        .map((doc) => doc.id)
        .toList();
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
    required int difficulty,
  }) async {
    final results = <_QuestionDoc>[];

    for (final categoryId in categoryIds) {
      final snap = await _firestore
          .collection('quizQuestions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .where('difficulty', isEqualTo: difficulty)
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

  Future<List<String>> _fetchStageQuestionIds({
    required String categoryId,
    required int difficulty,
  }) async {
    final snap = await _firestore
        .collection('quizQuestions')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .where('difficulty', isEqualTo: difficulty)
        .get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  Future<({int stage, List<_QuestionDoc> candidates})> _resolveStageCandidates({
    required UserProfile profile,
    required String uid,
    required String categoryId,
    required String categoryLabel,
    required Set<String> mastered,
  }) async {
    var stage = normalizeLearningStage(profile.learningStage);

    // 현재 단계 문제를 전부 풀었으면 프로필 학습과정을 다음 단계로 올린다.
    while (stage <= kMaxLearningStage) {
      final stageQuestionIds = await _fetchStageQuestionIds(
        categoryId: categoryId,
        difficulty: stage,
      );

      if (stageQuestionIds.isEmpty) {
        throw QuizSessionException(
          '$categoryLabel ${learningStageLabel(stage)} 문제가 아직 준비되지 않았어요.',
        );
      }

      final hasRemaining = stageQuestionIds.any((id) => !mastered.contains(id));

      if (hasRemaining) break;

      if (stage >= kMaxLearningStage) {
        throw QuizSessionException(
          '$categoryLabel의 모든 학습과정(1~10단계) 문제를 완료했어요!',
        );
      }

      final nextStage = stage + 1;
      final error = await AuthService.instance.saveLearningStage(nextStage);
      if (error != null) {
        throw QuizSessionException(error);
      }
      profile.learningStage = nextStage;
      stage = nextStage;
    }

    final targetCount = QuizData.dailyQuestionCount;
    final collected = <_QuestionDoc>[];
    final pickedIds = <String>{...mastered};
    var fetchStage = stage;

    while (collected.length < targetCount && fetchStage <= kMaxLearningStage) {
      final batch = await _fetchCandidates(
        categoryIds: [categoryId],
        excludeIds: pickedIds,
        difficulty: fetchStage,
      );
      batch.shuffle(_random);

      for (final question in batch) {
        if (collected.length >= targetCount) break;
        if (pickedIds.add(question.id)) {
          collected.add(question);
        }
      }

      // 10단계는 다음 단계가 없으므로 남은 만큼만 출제한다.
      if (fetchStage >= kMaxLearningStage) break;

      if (collected.length < targetCount) {
        fetchStage++;
      }
    }

    if (collected.isEmpty) {
      throw QuizSessionException(
        '$categoryLabel ${learningStageLabel(stage)}의 출제 가능한 문제가 없어요.',
      );
    }

    return (stage: stage, candidates: collected);
  }

  Future<int?> _advanceStageIfComplete({
    required String categoryId,
    required int currentStage,
    required Set<String> mastered,
  }) async {
    final stageQuestionIds = await _fetchStageQuestionIds(
      categoryId: categoryId,
      difficulty: currentStage,
    );
    if (stageQuestionIds.isEmpty) return null;
    if (!stageQuestionIds.every(mastered.contains)) return null;
    if (currentStage >= kMaxLearningStage) return null;

    final nextStage = currentStage + 1;
    final error = await AuthService.instance.saveLearningStage(nextStage);
    if (error != null) return null;
    return nextStage;
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
    return pool.take(count).toList();
  }

  QuizSession _learningSession({
    required String sessionId,
    required List<_QuestionDoc> selected,
    String source = QuizSession.energySessionSource,
  }) {
    return QuizSession(
      sessionId: sessionId,
      source: source,
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
