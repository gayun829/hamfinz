import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/storage_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await StorageService.instance.init();
  });

  test('FinQuiz app smoke placeholder', () {
    expect(true, isTrue);
  });
}
