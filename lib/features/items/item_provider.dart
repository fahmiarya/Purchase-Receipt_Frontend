// lib/features/items/item_provider.dart
// State holder for the Items feature (list, filters, selection, stock).
// Plain mutable state + async methods; the owning StatefulWidget calls
// setState around these methods (setState-based state management per reqs).

import '../../core/api/api_provider.dart';
import '../../core/models/item.dart';

class ItemProvider {
  final _api = ApiProvider().itemApi;

  List<Item> items = [];
  bool loading = false;

  // Filters
  String search = '';
  String? categoryCode;

  /// true → kirim `include_inactive=true` (item nonaktif ikut tampil).
  bool includeInactive = false;

  // Selection
  Item? selected;

  /// Latest stock fetched from GET /items/:id/stock.
  double? selectedStock;
  bool stockLoading = false;

  Future<void> load() async {
    loading = true;
    try {
      items = await _api.list(
        categoryCode: categoryCode,
        search: search.isEmpty ? null : search,
        includeInactive: includeInactive,
      );
    } finally {
      loading = false;
    }
  }

  Future<void> select(Item item) async {
    selected = item;
    selectedStock = null;
    stockLoading = true;
    try {
      selectedStock = await _api.stock(item.id);
    } finally {
      stockLoading = false;
    }
  }

  void clearSelection() {
    selected = null;
    selectedStock = null;
    stockLoading = false;
  }

  Future<Item> create(Map<String, dynamic> payload) => _api.create(payload);

  // Update: backend hanya menerima `name`, `brandCode`, `uom` — `stock`
  // read-only (stok hanya bergerak lewat Goods Receipt).
  Future<Item> update(int id, Map<String, dynamic> payload) =>
      _api.update(id, payload);

  /// Soft disable/enable item (TIDAK ada delete). Mengembalikan instance Item
  /// terbaru dari backend; pemanggil (page) yang me-reload list & selection.
  Future<Item> toggle(Item item, {required bool nextActive}) =>
      _api.toggleStatus(item.id, isActive: nextActive);
}
