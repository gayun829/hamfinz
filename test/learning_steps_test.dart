import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/learning_steps.dart';
import 'package:testapp/models/user_profile.dart';

void main() {
  UserProfile profile({int completedSessions = 0}) {
    return UserProfile(
      email: 'step@test.dev',
      nickname: '스텝',
      interestCategories: const ['saving'],
      categoryStats: {'저축': CategoryStat(completedSessions: completedSessions)},
    );
  }

  test('zero sessions shows step 1 and upcoming 3', () {
    expect(homeMapCurrentStep(profile()), 1);
    expect(homeMapUpcomingStep(1), 3);
  });

  test('each finished session advances the map number', () {
    expect(homeMapCurrentStep(profile(completedSessions: 4)), 5);
    expect(homeMapUpcomingStep(5), 7);
  });

  test('clamps at 200', () {
    expect(homeMapCurrentStep(profile(completedSessions: 200)), 200);
    expect(homeMapUpcomingStep(199), 200);
    expect(homeMapUpcomingStep(200), 200);
  });
}
