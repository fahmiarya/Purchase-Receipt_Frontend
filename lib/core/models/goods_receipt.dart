// lib/core/models/goods_receipt.dart
// Model representing a Goods Receipt.
// Parsing is tolerant (camelCase / snake_case) because the Postman collection
// does not document full response shapes.

import 'json_helpers.dart';
import 'goods_receipt_item.dart';

class GoodsReceipt {
  final int id;
  final String noGr;
  final int poId;
  final String? noPo; // displayed as "PO terkait" when the backend includes it
  final String tglGr; // YYYY-MM-DD format
  final String? notes;
  final String? createdAt;
  final List<GoodsReceiptItem> items;

  GoodsReceipt({
    required this.id,
    required this.noGr,
    required this.poId,
    this.noPo,
    required this.tglGr,
    this.notes,
    this.createdAt,
    required this.items,
  });

  factory GoodsReceipt.fromJson(Map<String, dynamic> json) {
    final List itemsJson = pick(json, ['items', 'grItems', 'gr_items']) as List? ?? [];
    return GoodsReceipt(
      id: asInt(pick(json, ['id', 'grId', 'gr_id'])),
      noGr: asString(pick(json, ['noGR', 'no_gr', 'noGr'])),
      poId: asInt(pick(json, ['poId', 'po_id'])),
      noPo: pick(json, ['noPO', 'no_po', 'noPo'])?.toString(),
      // Normalized to YYYY-MM-DD (backend sends full ISO timestamps).
      tglGr: asDateString(pick(json, ['tglGR', 'tgl_gr', 'tglGr'])),
      notes: pick(json, ['notes'])?.toString(),
      createdAt: pick(json, ['createdAt', 'created_at'])?.toString(),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => GoodsReceiptItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noGR': noGr,
        'poId': poId,
        if (noPo != null) 'no_po': noPo,
        'tglGR': tglGr,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
