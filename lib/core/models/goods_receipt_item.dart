// lib/core/models/goods_receipt_item.dart
// Model representing an item line within a Goods Receipt.
// Parsing is tolerant (camelCase / snake_case) because the Postman collection
// does not document full response shapes.

import 'json_helpers.dart';

class GoodsReceiptItem {
  final int id;
  final int grId;

  /// PO item id — this is the `poItemId` value used when creating a GR.
  final int poItemId;
  final int itemId;
  final String? itemName;
  final String? uom;
  final num qtyDiterima;
  final String? createdAt;

  GoodsReceiptItem({
    required this.id,
    required this.grId,
    required this.poItemId,
    required this.itemId,
    this.itemName,
    this.uom,
    required this.qtyDiterima,
    this.createdAt,
  });

  factory GoodsReceiptItem.fromJson(Map<String, dynamic> json) {
    final dynamic nestedItem = pick(json, ['item']);
    return GoodsReceiptItem(
      id: asInt(pick(json, ['id'])),
      grId: asInt(pick(json, ['grId', 'gr_id'])),
      poItemId: asInt(pick(json, ['poItemId', 'po_item_id'])),
      itemId: asInt(pick(json, ['itemId', 'item_id', 'itemID'])),
      itemName: pick(json, ['itemName', 'item_name', 'nama_barang'])?.toString() ??
          (nestedItem is Map<String, dynamic>
              ? pick(nestedItem, ['name', 'itemName'])?.toString()
              : null),
      uom: pick(json, ['uom', 'satuan'])?.toString() ??
          (nestedItem is Map<String, dynamic>
              ? pick(nestedItem, ['uom'])?.toString()
              : null),
      qtyDiterima: asNum(pick(json, ['qtyDiterima', 'qty_diterima', 'qtyReceived'])),
      createdAt: pick(json, ['createdAt', 'created_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grId': grId,
        'poItemId': poItemId,
        'itemId': itemId,
        if (itemName != null) 'itemName': itemName,
        if (uom != null) 'uom': uom,
        'qtyDiterima': qtyDiterima,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
