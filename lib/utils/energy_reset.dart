import 'dart:math';

import '../data/quiz_data.dart';
import 'date_helper.dart';

/// 그날 첫 지급을 반영한 에너지와, 그때 같이 저장해야 하는 지급 날짜.
typedef ResolvedEnergy = ({int energy, String lastEnergyResetDate});

/// 세션 완료 보상은 설정값과 실제 소모량 중 작은 값이다.
///
/// 오답 복습은 한 문제만 포함할 수 있으므로 고정 보상을 주면 5를 쓰고 20을
/// 돌려받는 식으로 에너지를 반복 생성할 수 있다.
int completionEnergyReward(int energySpent) =>
    energySpent.clamp(0, QuizData.sessionCompleteEnergyReward).toInt();

/// 중도 종료한 세션에서 쓴 에너지를 그대로 돌려준다. 에너지는 날이 바뀌어도
/// 사라지지 않으므로 세션을 시작한 날과 상관없다.
/// `functions/quiz_energy.js`의 `abandonRefund`와 같은 규칙이다.
({int energyRemaining, int energyRefunded}) abandonRefund({
  required int energy,
  required int spent,
}) {
  final refunded = max(0, spent);
  return (energyRemaining: energy + refunded, energyRefunded: refunded);
}

/// 저장된 에너지에 "그날 처음이면 [QuizData.dailyEnergyGrant] 지급" 규칙을
/// 적용한다. 한도는 없다.
///
/// 지급은 접속할 때 [AuthService]가 저장하지만, 그게 실패해도 에너지를 쓰는
/// 트랜잭션이 이 함수로 같은 지급을 반영하고 [ResolvedEnergy.lastEnergyResetDate]까지
/// 저장해 한 날에 두 번 지급되지 않게 한다.
ResolvedEnergy resolveDailyEnergy({
  required int? storedEnergy,
  required String? lastEnergyResetDate,
  String? today,
}) {
  final todayKey = today ?? DateHelper.todayKey();
  final energy = max(0, storedEnergy ?? 0);
  if (lastEnergyResetDate != todayKey) {
    return (
      energy: energy + QuizData.dailyEnergyGrant,
      lastEnergyResetDate: todayKey,
    );
  }
  return (energy: energy, lastEnergyResetDate: todayKey);
}
