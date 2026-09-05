import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/shop_data.dart';

class ShopCatalogService {
  ShopCatalogService._();

  static final instance = ShopCatalogService._();

  CollectionReference<Map<String, dynamic>> get _items =>
      FirebaseFirestore.instance.collection('shopItems');

  Future<List<ShopItem>> getItems() async {
    final snapshot = await _items.where('isActive', isEqualTo: true).get();
    final items = snapshot.docs
        .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  Future<List<ShopItem>> getItemsOrFallback() async {
    try {
      final remoteItems = await getItems();
      final localIds = ShopData.items.map((item) => item.id).toSet();
      final newItems = remoteItems
          .where((item) => !localIds.contains(item.id))
          .toList();
      final ignoredIds = remoteItems
          .where((item) => localIds.contains(item.id))
          .map((item) => item.id)
          .toList();
      debugPrint(
        'Shop catalog: Firebase IDs=${remoteItems.map((item) => item.id).toList()}, '
        'new=${newItems.map((item) => item.id).toList()}, '
        'ignoredExisting=$ignoredIds',
      );
      return [...ShopData.items, ...newItems];
    } on FirebaseException catch (error) {
      debugPrint('Shop catalog Firebase error: ${error.code} ${error.message}');
      return ShopData.items;
    }
  }
}
