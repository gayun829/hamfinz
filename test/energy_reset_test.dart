import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/quiz_data.dart';
import 'package:testapp/utils/energy_reset.dart';

void main() {
  test('완료 보상은 실제로 쓴 에너지를 넘지 않는다', () {
    expect(completionEnergyReward(5), 5);
    expect(completionEnergyReward(50), QuizData.sessionCompleteEnergyReward);
    expect(completionEnergyReward(0), 0);
    expect(completionEnergyReward(-5), 0);
  });

  group('중도 종료 환불', () {
    const today = '2026-09-27';

    test('오늘 시작한 세션은 쓴 에너지를 돌려준다', () {
      final refund = abandonRefund(
        energy: 60,
        spent: 25,
        sessionDate: today,
        today: today,
      );
      expect(refund.energyRemaining, 85);
      expect(refund.energyRefunded, 25);
    });

    test('최대치를 넘겨 돌려주지 않는다', () {
      final refund = abandonRefund(
        energy: 90,
        spent: 25,
        sessionDate: today,
        today: today,
      );
      expect(refund.energyRemaining, QuizData.maxEnergy);
      expect(refund.energyRefunded, QuizData.maxEnergy - 90);
    });

    test('이전 날짜에 시작한 세션은 환불 없이 닫는다', () {
      // 어제 쓴 에너지는 오늘 리셋으로 이미 사라졌다.
      final refund = abandonRefund(
        energy: QuizData.maxEnergy,
        spent: 25,
        sessionDate: '2026-09-26',
        today: today,
      );
      expect(refund.energyRemaining, QuizData.maxEnergy);
      expect(refund.energyRefunded, 0);
    });

    test('시작한 날을 모르면 돌려주지 않는다', () {
      final refund = abandonRefund(
        energy: 40,
        spent: 25,
        sessionDate: null,
        today: today,
      );
      expect(refund.energyRemaining, 40);
      expect(refund.energyRefunded, 0);
    });
  });

  test('날짜가 바뀌면 저장값과 무관하게 최대치로 회복한다', () {
    final resolved = resolveDailyEnergy(
      storedEnergy: 0,
      lastEnergyResetDate: '2026-09-12',
      today: '2026-09-13',
    );

    expect(resolved.energy, QuizData.maxEnergy);
    expect(resolved.lastEnergyResetDate, '2026-09-13');
  });

  test('오늘 이미 리셋했으면 저장된 값을 그대로 쓴다', () {
    final resolved = resolveDailyEnergy(
      storedEnergy: 35,
      lastEnergyResetDate: '2026-09-13',
      today: '2026-09-13',
    );

    expect(resolved.energy, 35);
    expect(resolved.lastEnergyResetDate, '2026-09-13');
  });

  test('리셋 날짜가 없으면 (신규·구버전 문서) 회복으로 본다', () {
    final resolved = resolveDailyEnergy(
      storedEnergy: 5,
      lastEnergyResetDate: null,
      today: '2026-09-13',
    );

    expect(resolved.energy, QuizData.maxEnergy);
  });

  test('energy 필드가 없으면 0이 아니라 최대치로 본다', () {
    final resolved = resolveDailyEnergy(
      storedEnergy: null,
      lastEnergyResetDate: '2026-09-13',
      today: '2026-09-13',
    );

    expect(resolved.energy, QuizData.maxEnergy);
  });

  test('저장값이 범위를 벗어나도 0~최대치로 맞춘다', () {
    expect(
      resolveDailyEnergy(
        storedEnergy: 999,
        lastEnergyResetDate: '2026-09-13',
        today: '2026-09-13',
      ).energy,
      QuizData.maxEnergy,
    );
    expect(
      resolveDailyEnergy(
        storedEnergy: -10,
        lastEnergyResetDate: '2026-09-13',
        today: '2026-09-13',
      ).energy,
      0,
    );
  });
}
