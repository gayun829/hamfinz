enum ShopCategory { skin, clothing, bundle, pattern, accessory, background }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.componentIds = const [],
    this.featured = false,
    this.hideFromCloset = false,
    this.assetPath,
    this.imageLayers = const [],
    this.included = false,
    this.sharedCanvas = false,
  });

  final List<String> componentIds;
  final String id;
  final String name;
  final String description;
  final int price;
  final ShopCategory category;
  final bool featured;
  final bool hideFromCloset;
  final String? assetPath;
  final List<String> imageLayers;
  final bool included;
  final bool sharedCanvas;
  bool get usesSharedCanvas =>
      assetPath != null || imageLayers.isNotEmpty || sharedCanvas;
}

abstract final class ShopData {
  /// 아무것도 사지 않은 기본 햄핀이 스킨.
  static const defaultSkinId = 'skin_default';

  static const retiredIds = {
    'headband',
    'cap',
    'hoodie',
    'glasses',
    'bow',
    'coconut',
  };
  static const legacyComponents = <String, List<String>>{
    'skin_perm': ['accessory_perm_glasses'],
    'accessory_perm': ['accessory_perm_glasses'],
    'accessory_red_glasses': ['accessory_perm_glasses'],
    'accessory_kindergarten': [
      'clothing_kindergarten',
      'accessory_kindergarten_hat',
    ],
    'accessory_kindergarten_hair': [
      'clothing_kindergarten',
      'accessory_kindergarten_hat',
    ],
    'accessory_genie_set': ['clothing_genie', 'accessory_genie_hair'],
    'skin_grandma': ['accessory_grandma'],
  };
  static const items = <ShopItem>[
    ShopItem(
      id: defaultSkinId,
      name: '기본 햄핀',
      description: '기본 햄핀으로 햄핀을 꾸며보세요.',
      price: 0,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_default.svg',
      included: true,
    ),
    ShopItem(
      id: 'skin_bearded_cream',
      name: '수염 햄핀',
      description: '수염 햄핀으로 햄핀을 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_bearded_cream.svg',
    ),
    ShopItem(
      id: 'skin_bearded_gray',
      name: '회색 수염 햄핀',
      description: '회색 수염 햄핀으로 햄핀을 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_bearded_gray.svg',
    ),
    ShopItem(
      id: 'skin_caveman',
      name: '원시인 햄핀',
      description: '원시인 햄핀으로 햄핀을 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_caveman.png',
    ),
    ShopItem(
      id: 'skin_caveman_bearded',
      name: '수염 원시인 햄핀',
      description: '수염 원시인 햄핀으로 햄핀을 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_caveman_bearded.svg',
    ),
    ShopItem(
      id: 'skin_bee',
      name: '꿀벌 햄핀',
      description: '귀여운 날개와 줄무늬를 가진 꿀벌 햄핀이에요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_bee.svg',
    ),
    ShopItem(
      id: 'skin_bee_duckbill',
      name: '오리입 꿀벌 햄핀',
      description: '오리입이 매력적인 꿀벌 햄핀이에요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_bee_duckbill.svg',
    ),
    ShopItem(
      id: 'skin_black',
      name: '검정 햄핀',
      description: '검정 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_black.svg',
    ),
    ShopItem(
      id: 'skin_dinosaur',
      name: '공룡 햄핀',
      description: '공룡 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_dinosaur.svg',
    ),
    ShopItem(
      id: 'skin_ninja',
      name: '닌자 햄핀 세트',
      description: '닌자 햄핀 스킨으로 꾸며보세요.',
      price: 200,
      category: ShopCategory.bundle,
      assetPath: 'assets/figma/shop/skins/skin_ninja.svg',
      componentIds: ['clothing_ninja', 'accessory_ninja'],
    ),
    ShopItem(
      id: 'skin_pirate',
      name: '안대 햄핀',
      description: '안대 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_pirate.svg',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'skin_genie_blue',
      name: '파란 지니 햄핀',
      description: '파란 지니 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_genie_blue.svg',
    ),
    ShopItem(
      id: 'skin_genie_tail',
      name: '지니 꼬리 햄핀',
      description: '지니 꼬리 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_genie_tail.svg',
    ),
    ShopItem(
      id: 'skin_crewcut',
      name: '군필 햄핀',
      description: '군필 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_crewcut.svg',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'skin_grandma',
      name: '할머니 햄핀',
      description: '할머니 햄핀 스킨으로 꾸며보세요.',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_grandma.svg',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'skin_kindergarten',
      name: '유치원생 햄핀 세트',
      description: '유치원생 햄핀 스킨으로 꾸며보세요.',
      price: 200,
      category: ShopCategory.bundle,
      assetPath: 'assets/figma/shop/skins/skin_kindergarten.svg',
      componentIds: ['clothing_kindergarten', 'accessory_kindergarten_hat'],
    ),
    ShopItem(
      id: 'skin_perm',
      name: '파마 햄핀 세트',
      description: '파마 햄핀 스킨으로 꾸며보세요.',
      price: 160,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_perm.svg',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'skin_genie',
      name: '지니 햄핀 세트',
      description: '지니 햄핀 스킨으로 꾸며보세요.',
      price: 200,
      category: ShopCategory.bundle,
      assetPath: 'assets/figma/shop/skins/skin_genie.svg',
      componentIds: ['clothing_genie', 'accessory_genie_hair'],
    ),
    ShopItem(
      id: 'skin_business',
      name: '넥타이 햄핀 세트',
      description: '넥타이 햄핀 스킨으로 꾸며보세요.',
      price: 560,
      category: ShopCategory.bundle,
      assetPath: 'assets/figma/shop/skins/skin_business.svg',
      componentIds: ['skin_business_base', 'accessory_tie'],
    ),
    ShopItem(
      id: 'accessory_grandma',
      name: '할머니 장식',
      description: '할머니 장식으로 햄핀을 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_grandma.png',
    ),
    ShopItem(
      id: 'accessory_painter_set',
      name: '화가 세트',
      description: '베레모와 앞치마를 함께 착용해요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_painter_set.png',
    ),
    ShopItem(
      id: 'accessory_perm',
      name: '파마 머리',
      description: '동글동글한 파마 머리로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_perm.png',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'accessory_kindergarten_hair',
      name: '유치원생 세트 (머리 있음)',
      description: '머리카락이 있는 모자와 유치원복 세트예요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath:
          'assets/figma/shop/accessories/accessory_kindergarten_hair.png',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'accessory_kindergarten',
      name: '유치원생 세트 (머리 없음)',
      description: '모자와 유치원복을 함께 착용해요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_kindergarten.png',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'accessory_propeller_hat',
      name: '헬리콥터 모자',
      description: '프로펠러 모자로 햄핀을 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_propeller_hat.png',
    ),
    ShopItem(
      id: 'accessory_genie_set',
      name: '요술지니 세트',
      description: '지니 머리와 수염, 장식을 함께 착용해요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_genie_set.png',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'study_guard',
      name: '연속 학습 방어권',
      description: '연속 학습을 지켜주는 보호 아이템',
      price: 300,
      category: ShopCategory.accessory,
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'energy_pack',
      name: '에너지 20',
      description: '에너지를 20 회복하는 아이템',
      price: 60,
      category: ShopCategory.accessory,
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'clothing_ninja',
      name: '닌자 옷',
      description: '닌자 옷으로 꾸며보세요.',
      price: 150,
      category: ShopCategory.clothing,
      assetPath: 'assets/figma/shop/accessories/clothing_ninja.png',
    ),
    ShopItem(
      id: 'accessory_ninja',
      name: '닌자 머리 장식',
      description: '닌자 머리 장식으로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_ninja.png',
    ),
    ShopItem(
      id: 'clothing_kindergarten',
      name: '유치원복',
      description: '유치원복으로 꾸며보세요.',
      price: 150,
      category: ShopCategory.clothing,
      assetPath: 'assets/figma/shop/accessories/clothing_kindergarten.png',
    ),
    ShopItem(
      id: 'accessory_kindergarten_hat',
      name: '유치원 모자',
      description: '유치원 모자으로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_kindergarten_hat.png',
    ),
    ShopItem(
      id: 'clothing_genie',
      name: '지니 옷',
      description: '지니 옷으로 꾸며보세요.',
      price: 150,
      category: ShopCategory.clothing,
      assetPath: 'assets/figma/shop/accessories/clothing_genie.png',
    ),
    ShopItem(
      id: 'accessory_genie_hair',
      name: '지니 머리와 수염',
      description: '지니 머리와 수염으로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_genie_hair.png',
    ),
    ShopItem(
      id: 'accessory_tie',
      name: '넥타이',
      description: '넥타이으로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_tie.png',
    ),
    ShopItem(
      id: 'accessory_red_glasses',
      name: '빨간 안경',
      description: '빨간 안경으로 꾸며보세요.',
      price: 100,
      category: ShopCategory.accessory,
      assetPath: 'assets/figma/shop/accessories/accessory_red_glasses.png',
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'skin_business_base',
      name: '회색 햄핀',
      description: '넥타이 세트의 회색 몸 스킨',
      price: 600,
      category: ShopCategory.skin,
      assetPath: 'assets/figma/shop/skins/skin_business_base.svg',
    ),
    ShopItem(
      id: 'accessory_perm_glasses',
      name: '파마 머리와 빨간 안경',
      description: '머리와 안경을 함께 착용해요.',
      price: 100,
      category: ShopCategory.accessory,
      imageLayers: [
        'assets/figma/shop/accessories/accessory_perm.png',
        'assets/figma/shop/accessories/accessory_red_glasses.png',
      ],
    ),
  ];
  static ShopItem? find(String? id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  static Set<String> expandedOwned(Iterable<String> owned) {
    final result = owned.toSet();
    for (final id in owned) {
      result.addAll(find(id)?.componentIds ?? []);
      result.addAll(legacyComponents[id] ?? []);
    }
    return result;
  }

  static bool owns(ShopItem item, Iterable<String> owned) {
    final ids = expandedOwned(owned);
    return item.included ||
        ids.contains(item.id) ||
        (item.componentIds.isNotEmpty && item.componentIds.every(ids.contains));
  }

  static int purchasePrice(ShopItem item, Iterable<String> owned) {
    if (owns(item, owned)) return 0;
    if (item.componentIds.isEmpty) return item.price;
    final ids = expandedOwned(owned);
    final total = item.componentIds
        .where((id) => !ids.contains(id))
        .fold<int>(0, (sum, id) => sum + (find(id)?.price ?? 0));
    return (total * 80 + 99) ~/ 100;
  }

  static ShopItem get featured =>
      items.firstWhere((i) => i.featured, orElse: () => items.first);
  static List<ShopItem> catalogWithoutFeatured() =>
      items.where((i) => !i.featured).toList();
  static List<ShopItem> byCategory(ShopCategory category) =>
      items.where((i) => i.category == category && !i.hideFromCloset).toList();
}
