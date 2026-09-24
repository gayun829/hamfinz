enum ShopCategory { skin, pattern, accessory, background }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.spriteCol,
    required this.spriteRow,
    this.featured = false,
    this.hideFromCloset = false,
    this.imageUrl,
    this.assetPath,
    this.included = false,
    this.sharedCanvas = false,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final ShopCategory category;
  final int spriteCol;
  final int spriteRow;
  final bool featured;
  final bool hideFromCloset;
  final String? imageUrl;
  final String? assetPath;
  final bool included;
  final bool sharedCanvas;
  bool get usesSharedCanvas => assetPath != null || sharedCanvas;

  factory ShopItem.fromFirestore(String id, Map<String, dynamic> data) {
    final categoryName = data['category'] as String? ?? 'accessory';
    final category = ShopCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => ShopCategory.accessory,
    );

    return ShopItem(
      id: id,
      name: data['name'] as String? ?? id,
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      category: category,
      spriteCol: (data['spriteCol'] as num?)?.toInt() ?? 0,
      spriteRow: (data['spriteRow'] as num?)?.toInt() ?? 0,
      featured: data['featured'] as bool? ?? false,
      hideFromCloset: data['hideFromCloset'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      sharedCanvas:
          data['sharedCanvas'] as bool? ??
          (category == ShopCategory.skin || category == ShopCategory.accessory),
    );
  }
}

abstract final class ShopData {
  static const retiredIds = {
    'headband',
    'cap',
    'hoodie',
    'glasses',
    'bow',
    'coconut',
  };

  /// [items]의 id·price는 `functions/index.js`의 `SHOP_CATALOG`와 값을 맞춰야
  /// 한다 — 배포(cloudFunctions) 모드에서는 Functions가 이 두 카탈로그 중
  /// 하나가 갱신 안 됐을 때 (`SHOP_CATALOG`에 없는 id는 `kind: 'cosmetic'`으로
  /// 조용히 처리하므로) 가격·종류가 어긋난 채로 구매가 성사될 수 있다.
  static const items = <ShopItem>[
    ShopItem(
      id: 'skin_default',
      name: '기본 햄핀',
      description: '기본 햄핀으로 햄핀을 꾸며보세요.',
      price: 0,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_default.svg',
      included: true,
    ),
    ShopItem(
      id: 'skin_bearded_cream',
      name: '수염 햄핀',
      description: '수염 햄핀으로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_bearded_cream.svg',
      included: false,
    ),
    ShopItem(
      id: 'skin_bearded_gray',
      name: '회색 수염 햄핀',
      description: '회색 수염 햄핀으로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_bearded_gray.svg',
      included: false,
    ),
    ShopItem(
      id: 'skin_caveman',
      name: '원시인 햄핀',
      description: '원시인 햄핀으로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_caveman.png',
      included: false,
    ),
    ShopItem(
      id: 'skin_caveman_bearded',
      name: '수염 원시인 햄핀',
      description: '수염 원시인 햄핀으로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_caveman_bearded.svg',
      included: false,
    ),
    ShopItem(
      id: 'skin_bee',
      name: '꿀벌 햄핀',
      description: '귀여운 날개와 줄무늬를 가진 꿀벌 햄핀이에요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_bee.svg',
    ),
    ShopItem(
      id: 'skin_bee_duckbill',
      name: '오리입 꿀벌 햄핀',
      description: '오리입이 매력적인 꿀벌 햄핀이에요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_bee_duckbill.svg',
    ),
    ShopItem(
      id: 'skin_black',
      name: '검정 햄핀',
      description: '검정 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_black.svg',
    ),
    ShopItem(
      id: 'skin_dinosaur',
      name: '공룡 햄핀',
      description: '공룡 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_dinosaur.svg',
    ),
    ShopItem(
      id: 'skin_ninja',
      name: '닌자 햄핀',
      description: '닌자 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_ninja.svg',
    ),
    ShopItem(
      id: 'skin_pirate',
      name: '안대 햄핀',
      description: '안대 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_pirate.svg',
    ),
    ShopItem(
      id: 'skin_genie_blue',
      name: '파란 지니 햄핀',
      description: '파란 지니 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_genie_blue.svg',
    ),
    ShopItem(
      id: 'skin_genie_tail',
      name: '지니 꼬리 햄핀',
      description: '지니 꼬리 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_genie_tail.svg',
    ),
    ShopItem(
      id: 'skin_crewcut',
      name: '군필 햄핀',
      description: '군필 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_crewcut.svg',
    ),
    ShopItem(
      id: 'skin_grandma',
      name: '할머니 햄핀',
      description: '할머니 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_grandma.svg',
    ),
    ShopItem(
      id: 'skin_kindergarten',
      name: '유치원생 햄핀',
      description: '유치원생 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_kindergarten.svg',
    ),
    ShopItem(
      id: 'skin_perm',
      name: '파마 햄핀',
      description: '파마 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_perm.svg',
    ),
    ShopItem(
      id: 'skin_genie',
      name: '지니 햄핀',
      description: '지니 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_genie.svg',
    ),
    ShopItem(
      id: 'skin_business',
      name: '넥타이 햄핀',
      description: '넥타이 햄핀 스킨으로 꾸며보세요.',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/skins/skin_business.svg',
    ),
    ShopItem(
      id: 'accessory_grandma',
      name: '할머니 장식',
      description: '할머니 장식으로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_grandma.png',
      included: false,
    ),
    ShopItem(
      id: 'accessory_painter_set',
      name: '화가 세트',
      description: '베레모와 앞치마를 함께 착용해요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_painter_set.png',
      included: false,
    ),
    ShopItem(
      id: 'accessory_perm',
      name: '파마 머리',
      description: '동글동글한 파마 머리로 꾸며보세요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_perm.png',
    ),
    ShopItem(
      id: 'accessory_kindergarten_hair',
      name: '유치원생 세트 (머리 있음)',
      description: '머리카락이 있는 모자와 유치원복 세트예요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath:
          'assets/figma/shop/accessories/accessory_kindergarten_hair.png',
    ),
    ShopItem(
      id: 'accessory_kindergarten',
      name: '유치원생 세트 (머리 없음)',
      description: '모자와 유치원복을 함께 착용해요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_kindergarten.png',
    ),
    ShopItem(
      id: 'accessory_propeller_hat',
      name: '헬리콥터 모자',
      description: '프로펠러 모자로 햄핀을 꾸며보세요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_propeller_hat.png',
    ),
    ShopItem(
      id: 'accessory_genie_set',
      name: '요술지니 세트',
      description: '지니 머리와 수염, 장식을 함께 착용해요.',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 0,
      spriteRow: 0,
      assetPath: 'assets/figma/shop/accessories/accessory_genie_set.png',
    ),
    ShopItem(
      id: 'study_guard',
      name: '연속 학습 방어권',
      description: '연속 학습을 지켜주는 보호 아이템',
      price: 123,
      category: ShopCategory.accessory,
      spriteCol: 4,
      spriteRow: 2,
      hideFromCloset: true,
    ),
    ShopItem(
      id: 'energy_pack',
      name: '에너지 20',
      description: '에너지를 20 회복하는 아이템',
      price: 123,
      category: ShopCategory.accessory,
      spriteCol: 4,
      spriteRow: 2,
      hideFromCloset: true,
    ),
  ];

  static ShopItem get featured =>
      items.firstWhere((item) => item.featured, orElse: () => items.first);

  static List<ShopItem> catalogWithoutFeatured() =>
      items.where((item) => !item.featured).toList();

  static List<ShopItem> byCategory(ShopCategory category) => items
      .where((item) => item.category == category && !item.hideFromCloset)
      .toList();
}
