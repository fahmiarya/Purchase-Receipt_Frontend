// lib/core/api/gr_api.dart
// API client for Goods Receipts, matching SC3.postman_collection.json.
// Request body uses the exact Postman contract (camelCase):
//   POST { poId, tglGR, notes, items: [{ poItemId, qtyDiterima }] }
//   GET  ?po_id=&date= (or a range via startDate/endDate)
//
// Note: POST /goods-receipts/preview is NOT in the collection yet, so it is
// intentionally not implemented here (see REQUIREMENTS.md).

import 'api_client.dart';
import '../models/goods_receipt.dart';

class GoodsReceiptApi {
  final ApiClient client;
  GoodsReceiptApi(this.client);

  // List Goods Receipts with optional filters.
  // Date filter: `date` = exact day, or a range via `startDate`/`endDate`
  // (both YYYY-MM-DD, inclusive; enforced by the backend).
  Future<List<GoodsReceipt>> list({
    int? poId,
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (poId != null) query['po_id'] = poId.toString();
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    final json = await client.get('/goods-receipts', query: query);
    final List data = json['data'] as List? ?? [];
    return data
        .map((e) => GoodsReceipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get details of a specific Goods Receipt.
  Future<GoodsReceipt> get(int grId) async {
    final json = await client.get('/goods-receipts/$grId');
    return GoodsReceipt.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Create a Goods Receipt. GR is final once saved — no edit/delete endpoints.
  Future<GoodsReceipt> create({
    required int poId,
    required String tglGR,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'poId': poId,
      'tglGR': tglGR,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items,
    };
    final json = await client.post('/goods-receipts', payload);
    return GoodsReceipt.fromJson(json['data'] as Map<String, dynamic>);
  }
}
