// lib/core/models/purchase_order.dart
// Model representing a Purchase Order.
// Parsing is tolerant (camelCase / snake_case) because the Postman collection
// does not document full response shapes.

import 'json_helpers.dart';
import 'purchase_order_item.dart';

class PurchaseOrder {
  final int id;
  final String? noPo;

  /// PO number; different backends use different keys, resolved in [fromJson].
  final int vendorId;
  final String? vendorName;
  final String tglPo; // YYYY-MM-DD format
  final String? notes;
  final String? status; // open | partial | complete | cancelled
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    required this.id,
    this.noPo,
    required this.vendorId,
    this.vendorName,
    required this.tglPo,
    this.notes,
    this.status,
    required this.items,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final dynamic itemsJson = pick(json, ['items', 'poItems', 'po_items']) ?? [];
    final dynamic vendor = pick(json, ['vendor']);
    return PurchaseOrder(
      id: asInt(pick(json, ['id', 'poId', 'po_id'])),
      noPo: pick(json, ['no_po', 'noPO', 'noPr', 'no_pr'])?.toString(),
      vendorId: asInt(pick(json, ['vendorId', 'vendor_id'])),
      vendorName: pick(json, ['vendorName', 'vendor_name'])?.toString() ??
          (vendor is Map<String, dynamic>
              ? (pick(vendor, ['name', 'vendorName', 'vendor_name'])?.toString())
              : (vendor is String ? vendor : null)),
      // Normalized to YYYY-MM-DD (backend sends full ISO timestamps).
      tglPo: asDateString(pick(json, ['tglPO', 'tgl_po', 'tglPo'])),
      notes: pick(json, ['notes'])?.toString(),
      status: pick(json, ['status', 'poStatus', 'po_status'])?.toString(),
      items: (itemsJson is List)
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map((e) => PurchaseOrderItem.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (noPo != null) 'no_po': noPo,
        'vendorId': vendorId,
        if (vendorName != null) 'vendorName': vendorName,
        'tglPO': tglPo,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
