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
