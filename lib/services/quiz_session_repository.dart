import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';

/// Firestore `quizQuestions` + `mastered` 기반 세션 출제.
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
