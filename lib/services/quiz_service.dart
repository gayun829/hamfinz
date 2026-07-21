import '../data/hamster_data.dart';
import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/user_profile.dart';
import '../utils/date_helper.dart';
import 'auth_service.dart';

class QuizService {
  QuizService._();
  static final instance = QuizService._();

  List<QuizQuestion> getTodayQuestions() => QuizData.dailyQuestions();

  Future<QuizSessionResult> completeSession({
    required UserProfile profile,
    required List<QuizAnswer> answers,
  }) async {
    final previousLevel = profile.level;
    var xpEarned = 0;

    for (final answer in answers) {
      xpEarned += answer.isCorrect ? QuizData.correctXp : QuizData.wrongXp;
    }

    profile.xp += xpEarned;

    for (final answer in answers) {
      final question = QuizData.allQuestions.firstWhere(
        (q) => q.id == answer.questionId,
      );
      final key = question.category.label;
      profile.categoryStats.putIfAbsent(key, CategoryStat.new);
      profile.categoryStats[key]!.total += 1;
      if (answer.isCorrect) {
        profile.categoryStats[key]!.correct += 1;
      }
    }

    final correctCount = answers.where((a) => a.isCorrect).length;
    profile.learningHistory.insert(
      0,
      LearningRecord(
        date: DateHelper.todayKey(),
        correctCount: correctCount,
        totalCount: answers.length,
        xpEarned: xpEarned,
      ),
    );

    if (!profile.todayQuizCompleted) {
      profile.todayQuizCompleted = true;
      final lastDate = profile.lastQuizCompletedDate;
      if (lastDate == null) {
        profile.streak = 1;
      } else if (DateHelper.isYesterday(lastDate)) {
        profile.streak += 1;
      } else if (!DateHelper.isToday(lastDate)) {
        profile.streak = 1;
      }
      profile.lastQuizCompletedDate = DateHelper.todayKey();
    }

    final unlockedItems = _unlockItems(profile);
    await AuthService.instance.saveProfile(profile);

    return QuizSessionResult(
      answers: answers,
      xpEarned: xpEarned,
      leveledUp: profile.level > previousLevel,
      newLevel: profile.level,
      previousLevel: previousLevel,
      unlockedItems: unlockedItems,
      newStreak: profile.streak,
    );
  }

  List<String> _unlockItems(UserProfile profile) {
    final unlocked = <String>[];
    void unlock(String id) {
      if (!profile.unlockedHamsterIds.contains(id)) {
        profile.unlockedHamsterIds.add(id);
        unlocked.add(id);
      }
    }

    if (profile.learningHistory.isNotEmpty) {
      unlock('hamster_study');
    }
    if (profile.streak >= 3) {
      unlock('hamster_streak');
    }
    if (profile.level >= 3) {
      unlock('hamster_level3');
    }
    if (profile.level >= 5) {
      unlock('hamster_level5');
    }
    if (profile.level >= 10) {
      unlock('hamster_master');
    }

    for (final id in unlocked) {
      HamsterData.findById(id);
    }

    return unlocked;
  }
}
