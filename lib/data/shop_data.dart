enum ShopCategory {
  skin,
  pattern,
  accessory,
  background,
}

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
}

abstract final class ShopData {
  /// Figma `image 64` 스프라이트 — 6열 × 5행.
  static const spriteColumns = 6;
  static const spriteRows = 5;

  static const items = <ShopItem>[
    ShopItem(
      id: 'headband',
      name: '머리띠',
      description: '머리띠를 쓰면 용감한 햄핀이',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 5,
      spriteRow: 0,
      featured: true,
    ),
    ShopItem(
      id: 'cap',
      name: '모자',
      description: '모자를 쓰면 멋진 햄핀이',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 2,
      spriteRow: 0,
    ),
    ShopItem(
      id: 'hoodie',
      name: '후드티',
      description: '후드티를 입으면 포근한 햄핀이',
      price: 579,
      category: ShopCategory.skin,
      spriteCol: 3,
      spriteRow: 0,
    ),
    ShopItem(
      id: 'glasses',
      name: '안경',
      description: '안경을 쓰면 똑똑한 햄핀이',
      price: 579,
      category: ShopCategory.accessory,
      spriteCol: 1,
      spriteRow: 0,
    ),
    ShopItem(
      id: 'bow',
      name: '리본',
      description: '리본을 달면 사랑스러운 햄핀이',
      price: 579,
      category: ShopCategory.pattern,
      spriteCol: 1,
      spriteRow: 1,
    ),
    ShopItem(
      id: 'coconut',
      name: '코코넛 하우스',
      description: '코코넛 집에서 쉬는 햄핀이',
      price: 579,
      category: ShopCategory.background,
      spriteCol: 0,
      spriteRow: 0,
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
  ];

  static ShopItem get featured =>
      items.firstWhere((item) => item.featured, orElse: () => items.first);

  static List<ShopItem> catalogWithoutFeatured() =>
      items.where((item) => !item.featured).toList();

  static List<ShopItem> byCategory(ShopCategory category) =>
      items.where((item) => item.category == category && !item.hideFromCloset).toList();
}
