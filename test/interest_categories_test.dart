import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/interest_categories.dart';

void main() {
  group('needsInterestCategorySelection', () {
    test('카테고리 화면에서 앱을 꺼 빈 목록으로 남은 계정은 다시 고르게 한다', () {
      expect(needsInterestCategorySelection(const []), isTrue);
    });

    test('목록에서 빠진 카테고리만 남아 있어도 다시 고르게 한다', () {
      expect(needsInterestCategorySelection(const ['retired_category']), isTrue);
    });

    test('유효한 카테고리가 하나라도 있으면 그대로 홈으로 보낸다', () {
      expect(needsInterestCategorySelection(const ['saving']), isFalse);
      expect(
        needsInterestCategorySelection(const ['retired_category', 'stock']),
        isFalse,
      );
    });
  });
}
