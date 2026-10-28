import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/shop_data.dart';

class ShopCatalogService {
  ShopCatalogService._();

  static final instance = ShopCatalogService._();

  CollectionReference<Map<String, dynamic>> get _items =>
      FirebaseFirestore.instance.collection('shopItems');

  /// 한 번 불러온 카탈로그. 홈·마이페이지·옷장이 같이 쓰고, 앱을 다시 켤
  /// 때까지 Firestore를 다시 읽지 않는다. 불러오기에 실패하면 남기지 않아서
  /// 다음 호출이 다시 시도한다.
  List<ShopItem>? _cached;
  Future<List<ShopItem>>? _loading;

  /// 바로 그릴 카탈로그 — 불러온 적이 있으면 그 결과, 아니면 로컬 카탈로그.
  List<ShopItem> get cachedOrLocal => _cached ?? ShopData.items;

  Future<List<ShopItem>> getItems() async {
    final snapshot = await _items.where('isActive', isEqualTo: true).get();
    final items = snapshot.docs
        .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  Future<List<ShopItem>> getItemsOrFallback() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    // 홈과 마이페이지가 동시에 불러도 Firestore는 한 번만 읽는다.
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<List<ShopItem>> _load() async {
    try {
      final remoteItems = await getItems();
      final localIds = ShopData.items.map((item) => item.id).toSet();
      final newItems = remoteItems
          .where(
            (item) =>
                !localIds.contains(item.id) &&
                !ShopData.retiredIds.contains(item.id),
          )
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
      return _cached = [...ShopData.items, ...newItems];
    } on FirebaseException catch (error) {
      debugPrint('Shop catalog Firebase error: ${error.code} ${error.message}');
      return ShopData.items;
    }
  }
}
