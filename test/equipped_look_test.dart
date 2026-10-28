import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/shop_data.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  UserProfile profile({
    String? skin,
    String? pattern,
    List<String> accessories = const [],
  }) => UserProfile(
    email: 'look@test.dev',
    nickname: '옷',
    equippedSkinId: skin,
    equippedPatternId: pattern,
    equippedAccessoryIds: accessories,
  );

  EquippedLook look(UserProfile p) => EquippedLook.of(p, ShopData.items);

  test('nothing equipped is the default look', () {
    expect(look(profile()).isCustom, isFalse);
  });

  test('the default skin alone is not custom', () {
    expect(look(profile(skin: ShopData.defaultSkinId)).isCustom, isFalse);
  });

  test('another skin is custom', () {
    final result = look(profile(skin: 'skin_ninja'));
    expect(result.isCustom, isTrue);
    expect(result.skinId, 'skin_ninja');
  });

  test('a drawable accessory on the default skin is custom', () {
    final result = look(profile(accessories: ['accessory_propeller_hat']));
    expect(result.isCustom, isTrue);
    expect(result.accessoryIds, ['accessory_propeller_hat']);
  });

  test('consumables are not worn', () {
    final result = look(profile(accessories: ['study_guard', 'energy_pack']));
    expect(result.accessoryIds, isEmpty);
    expect(result.isCustom, isFalse);
  });

  test('ids missing from the catalog are treated as not worn', () {
    final result = look(
      profile(
        skin: 'skin_from_firestore',
        pattern: 'pattern_from_firestore',
        accessories: ['accessory_from_firestore'],
      ),
    );
    expect(result.skinId, isNull);
    expect(result.patternId, isNull);
    expect(result.accessoryIds, isEmpty);
    expect(result.isCustom, isFalse);
  });

  test('an item appears once the catalog that has it is loaded', () {
    const remote = ShopItem(
      id: 'skin_from_firestore',
      name: '원격 스킨',
      description: '',
      price: 0,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      imageUrl: 'https://example.com/skin.png',
    );
    final result = EquippedLook.of(profile(skin: remote.id), [
      ...ShopData.items,
      remote,
    ]);
    expect(result.skinId, remote.id);
    expect(result.isCustom, isTrue);
  });
}
