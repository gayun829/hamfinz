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
    test('쓴 에너지를 한도 없이 그대로 돌려준다', () {
      final refund = abandonRefund(energy: 190, spent: 25);
      expect(refund.energyRemaining, 215);
      expect(refund.energyRefunded, 25);
    });

    test('쓴 에너지가 없으면 그대로 둔다', () {
      final refund = abandonRefund(energy: 40, spent: 0);
      expect(refund.energyRemaining, 40);
      expect(refund.energyRefunded, 0);
    });
  });

  group('매일 첫 접속 지급', () {
    test('날짜가 바뀌면 남은 에너지에 100을 더한다', () {
      final resolved = resolveDailyEnergy(
        storedEnergy: 35,
        lastEnergyResetDate: '2026-09-12',
        today: '2026-09-13',
      );

      expect(resolved.energy, 35 + QuizData.dailyEnergyGrant);
      expect(resolved.lastEnergyResetDate, '2026-09-13');
    });

    test('며칠 접속하지 않아도 한 번만 지급한다', () {
      final resolved = resolveDailyEnergy(
        storedEnergy: 10,
        lastEnergyResetDate: '2026-09-01',
        today: '2026-09-13',
      );

      expect(resolved.energy, 10 + QuizData.dailyEnergyGrant);
    });

    test('오늘 이미 받았으면 저장된 값을 그대로 쓴다', () {
      final resolved = resolveDailyEnergy(
        storedEnergy: 35,
        lastEnergyResetDate: '2026-09-13',
        today: '2026-09-13',
      );

      expect(resolved.energy, 35);
      expect(resolved.lastEnergyResetDate, '2026-09-13');
    });

    test('한도가 없어 100을 넘는 에너지도 그대로 둔다', () {
      expect(
        resolveDailyEnergy(
          storedEnergy: 999,
          lastEnergyResetDate: '2026-09-13',
          today: '2026-09-13',
        ).energy,
        999,
      );
    });

    test('지급 기록이 없는 문서도 첫 지급을 받는다', () {
      final resolved = resolveDailyEnergy(
        storedEnergy: null,
        lastEnergyResetDate: null,
        today: '2026-09-13',
      );

      expect(resolved.energy, QuizData.dailyEnergyGrant);
    });

    test('음수 저장값은 0으로 본다', () {
      expect(
        resolveDailyEnergy(
          storedEnergy: -10,
          lastEnergyResetDate: '2026-09-13',
          today: '2026-09-13',
        ).energy,
        0,
      );
    });
  });
}
