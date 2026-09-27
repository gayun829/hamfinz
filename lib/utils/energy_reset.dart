import 'dart:math';

import '../data/quiz_data.dart';
import 'date_helper.dart';

/// 날짜가 바뀌었을 때 회복된 에너지와, 그때 같이 저장해야 하는 리셋 날짜.
typedef ResolvedEnergy = ({int energy, String lastEnergyResetDate});

/// 세션 완료 보상은 설정값과 실제 소모량 중 작은 값이다.
///
/// 오답 복습은 한 문제만 포함할 수 있으므로 고정 보상을 주면 5를 쓰고 20을
/// 돌려받는 식으로 에너지를 반복 생성할 수 있다.
int completionEnergyReward(int energySpent) =>
    energySpent.clamp(0, QuizData.sessionCompleteEnergyReward).toInt();

/// 저장된 에너지에 "날짜가 바뀌면 최대치로 회복" 규칙을 적용한다.
///
/// `AuthService._profileFromJson`은 같은 계산을 화면에만 반영하고 저장하지
/// 않는다. 그래서 에너지를 쓰는 트랜잭션이 저장값을 그대로 읽어 깎기만 하면,
/// 저장된 에너지가 날짜가 바뀌어도 회복되지 않아 화면은 100인데 제출은 막히는
/// 상태가 된다. 트랜잭션은 이 함수로 회복을 반영하고 [ResolvedEnergy.lastEnergyResetDate]까지
/// 같이 저장해야 한다.
/// 중도 종료한 세션에서 쓴 에너지를 돌려준다. 에너지는 날짜가 바뀌면 최대치로
/// 리셋되므로 오늘([today]) 시작한 세션만 돌려준다. 이전 날짜 세션에서 쓴
/// 에너지는 리셋으로 이미 사라졌어야 해서, 돌려주면 오늘 에너지 위에 어제치가
/// 얹힌다. `functions/quiz_energy.js`의 `abandonRefund`와 같은 규칙이다.
({int energyRemaining, int energyRefunded}) abandonRefund({
  required int energy,
  required int spent,
  required String? sessionDate,
  required String today,
}) {
  final refundable = sessionDate == today && spent > 0 ? spent : 0;
  // 환불이 에너지를 줄이는 일은 없게 한다.
  final energyRemaining = max(
    energy,
    min(QuizData.maxEnergy, energy + refundable),
  );
  return (
    energyRemaining: energyRemaining,
    energyRefunded: energyRemaining - energy,
  );
}

ResolvedEnergy resolveDailyEnergy({
  required int? storedEnergy,
  required String? lastEnergyResetDate,
  String? today,
}) {
  final todayKey = today ?? DateHelper.todayKey();
  if (lastEnergyResetDate != todayKey) {
    return (energy: QuizData.maxEnergy, lastEnergyResetDate: todayKey);
  }
  return (
    energy: (storedEnergy ?? QuizData.maxEnergy).clamp(0, QuizData.maxEnergy),
    lastEnergyResetDate: todayKey,
  );
}
