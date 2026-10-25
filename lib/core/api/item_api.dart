// lib/core/api/item_api.dart
// API client for Items, matching SC3.postman_collection.json.
//   POST /items  body: { code, name, itemCategoryCode, brandCode, sequence, uom, stock }
//   PUT  /items/:id  body example: { name, stock }
//   GET  /items?category_code=&search=

import 'api_client.dart';
import '../models/item.dart';
import '../models/json_helpers.dart';

class ItemApi {
  final ApiClient client;
  ItemApi(this.client);

  Future<List<Item>> list({
    String? categoryCode,
    String? search,
    bool includeInactive = false,
  }) async {
    final query = <String, String>{};

    if (categoryCode != null && categoryCode.isNotEmpty) {
      query['category_code'] = categoryCode;
    }

    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    if (includeInactive) {
      query['include_inactive'] = 'true';
    }

    final json = await client.get('/items', query: query);
    final List data = json['data'] as List? ?? [];

    return data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Item> get(int id) async {
    final json = await client.get('/items/$id');
    return Item.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Create:
  // `code`, `sequence` and `stock` are part of the running contract.
  Future<Item> create(Map<String, dynamic> payload) async {
    final json = await client.post('/items', payload);
    return Item.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Update: master data only (`name`, `uom`
  // → `brandCode`). `stock` cannot be changed — it moves only via Goods Receipt.
  Future<Item> update(int id, Map<String, dynamic> payload) async {
    final json = await client.put('/items/$id', payload);
    return Item.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Item> toggleStatus(
    int id, {
    required bool isActive,
  }) async {
    final json = await client.patch(
      '/items/$id/toggle-status',
      body: {'isActive': isActive},
    );

    return Item.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Stock must be read via the dedicated endpoint, not assumed from list data.
  Future<double> stock(int id) async {
    final json = await client.get('/items/$id/stock');
    final data = json['data'];
    final dynamic stockValue =
        data is Map<String, dynamic> ? (data['stock'] ?? data) : data;
    return asDouble(stockValue);
  }
}
