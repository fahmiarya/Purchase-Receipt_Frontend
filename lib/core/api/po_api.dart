// lib/core/api/po_api.dart
// API client for Purchase Orders, matching SC3.postman_collection.json.
// Request bodies use the exact Postman contract (camelCase):
//   POST   { vendorId, tglPO, notes, items: [{ itemId, qtyPO, hargaPO }] }
//   PUT    { vendorId, notes }
//   GET    ?status=&vendor=&date=

import 'api_client.dart';
import '../models/purchase_order.dart';

class PurchaseOrderApi {
  final ApiClient client;
  PurchaseOrderApi(this.client);

  // List PO with optional filters.
  // Date filter: `date` = exact day, or a range via `startDate`/`endDate`
  // (both YYYY-MM-DD, inclusive; enforced by the backend).
  Future<List<PurchaseOrder>> list({
    String? status,
    String? vendorId,
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (vendorId != null && vendorId.isNotEmpty) query['vendor'] = vendorId;
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    final json = await client.get('/purchase-orders', query: query);
    final List data = json['data'] as List? ?? [];
    return data
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get PO detail (includes items).
  Future<PurchaseOrder> get(int poId) async {
    final json = await client.get('/purchase-orders/$poId');
    return PurchaseOrder.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Create PO. The collection does not include `no_pr`; the backend generates it.
  Future<PurchaseOrder> create({
    required int vendorId,
    required String tglPO,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'vendorId': vendorId,
      'tglPO': tglPO,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items,
    };
    final json = await client.post('/purchase-orders', payload);
    return PurchaseOrder.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Update PO (only allowed while the PO is open).
  Future<PurchaseOrder> update(int poId, {int? vendorId, String? notes}) async {
    final payload = <String, dynamic>{};
    if (vendorId != null) payload['vendorId'] = vendorId;
    if (notes != null) payload['notes'] = notes;
    final json = await client.put('/purchase-orders/$poId', payload);
    return PurchaseOrder.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Cancel PO via PATCH /cancel.
  Future<void> cancel(int poId) async {
    await client.patch('/purchase-orders/$poId/cancel');
  }

  // Get receipt status for a PO.
  Future<Map<String, dynamic>> receiptStatus(int poId) async {
    final json = await client.get('/purchase-orders/$poId/receipt-status');
    return json['data'] as Map<String, dynamic>? ?? {};
  }
}
