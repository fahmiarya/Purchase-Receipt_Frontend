// lib/core/models/purchase_order_item.dart
// Model representing an item line within a Purchase Order.
// Parsing is tolerant (camelCase / snake_case) because the Postman collection
// does not document full response shapes.

import 'json_helpers.dart';

class PurchaseOrderItem {
  /// PO item id — used as `poItemId` when creating a Goods Receipt.
  final int id;

  /// Master item id — used as `itemId` when creating a Purchase Order.
  final int itemId;
  final String? itemName;
  final String? uom;
  final num qtyPo;
  final num? qtyReceived; // from PO detail; null when not provided
  final num hargaPo;

  PurchaseOrderItem({
    required this.id,
    required this.itemId,
    this.itemName,
    this.uom,
    required this.qtyPo,
    this.qtyReceived,
    required this.hargaPo,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    final dynamic nestedItem = pick(json, ['item']);
    return PurchaseOrderItem(
      id: asInt(pick(json, ['id', 'poItemId', 'po_item_id'])),
      itemId: asInt(pick(json, ['itemId', 'item_id'])),
      itemName: pick(json, ['itemName', 'item_name', 'nama_barang'])?.toString() ??
          (nestedItem is Map<String, dynamic>
              ? pick(nestedItem, ['name', 'itemName'])?.toString()
              : null),
      uom: pick(json, ['uom', 'satuan'])?.toString() ??
          (nestedItem is Map<String, dynamic>
              ? pick(nestedItem, ['uom'])?.toString()
              : null),
      // Backend serializes Prisma Decimal as strings (e.g. "100") — must be
      // parsed with asNum, not cast directly (implicit downcast fails on web).
      qtyPo: asNum(pick(json, ['qtyPO', 'qty_po', 'qtyPo'])),
      qtyReceived: _numOrNull(pick(
        json,
        ['qtyReceived', 'qtyDiterima', 'qty_received', 'qty_diterima'],
      )),
      hargaPo: asNum(pick(json, ['hargaPO', 'harga_po', 'hargaPo'])),
    );
  }

  static num? _numOrNull(dynamic value) {
    if (value == null) return null;
    return asNum(value);
  }

  /// Remaining quantity that can still be received.
  num get sisa {
    final received = qtyReceived;
    if (received == null) return qtyPo;
    final value = qtyPo - received;
    return value < 0 ? 0 : value;
  }

  // Payload for POST /purchase-orders items — exact Postman contract.
  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'qtyPO': qtyPo,
        'hargaPO': hargaPo,
      };
}
