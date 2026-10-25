// lib/features/purchase_orders/po_provider.dart
// State holder for the Purchase Orders feature (list, filters, selection,
// receipt status). Plain mutable state + async methods; the owning
// StatefulWidget calls setState around these methods.

import '../../core/api/api_provider.dart';
import '../../core/models/purchase_order.dart';

class PoProvider {
  final _api = ApiProvider().poApi;

  List<PurchaseOrder> orders = [];
  bool loading = false;

  // Filters
  String? status; // null means All
  String? startDate; // YYYY-MM-DD (inclusive)
  String? endDate; // YYYY-MM-DD (inclusive)

  // Selection
  PurchaseOrder? selected;
  Map<String, dynamic> receiptStatus = {};
  bool detailLoading = false;

  Future<void> load() async {
    loading = true;
    try {
      orders = await _api.list(
        status: (status == null || status == 'All') ? null : status,
        startDate: startDate,
        endDate: endDate,
      );
    } finally {
      loading = false;
    }
  }

  Future<void> select(int poId) async {
    detailLoading = true;
    selected = null;
    receiptStatus = {};
    try {
      selected = await _api.get(poId);
    } finally {
      detailLoading = false;
    }
    receiptStatus = await _api.receiptStatus(poId);
  }

  void clearSelection() {
    selected = null;
    receiptStatus = {};
    detailLoading = false;
  }

  Future<PurchaseOrder> create({
    required int vendorId,
    required String tglPO,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) =>
      _api.create(vendorId: vendorId, tglPO: tglPO, notes: notes, items: items);

  Future<void> cancel(int poId) => _api.cancel(poId);
}
