import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/shop_data.dart';

class ShopCatalogService {
  ShopCatalogService._();

  static final instance = ShopCatalogService._();

  final _items = FirebaseFirestore.instance.collection('shopItems');

  Future<List<ShopItem>> getItems() async {
    final snapshot = await _items.get();
    final items = snapshot.docs
        .where((doc) => doc.data()['isActive'] as bool? ?? true)
        .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  Future<List<ShopItem>> getItemsOrFallback() async {
    try {
      final items = await getItems();
      return items.isEmpty ? ShopData.items : items;
    } on FirebaseException {
      return ShopData.items;
    }
  }
}