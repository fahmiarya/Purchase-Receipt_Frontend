// lib/features/goods_receipts/gr_provider.dart
// State holder for the Goods Receipts feature (list, filters, selection,
// PO options for the create form, post-receipt stock info).

import '../../core/api/api_provider.dart';
import '../../core/models/goods_receipt.dart';
import '../../core/models/purchase_order.dart';

class GrProvider {
  final _grApi = ApiProvider().grApi;
  final _poApi = ApiProvider().poApi;
  final _itemApi = ApiProvider().itemApi;

  List<GoodsReceipt> receipts = [];
  bool loading = false;

  // Filters
  String? startDate; // YYYY-MM-DD (inclusive)
  String? endDate; // YYYY-MM-DD (inclusive)

  /// Text filter for the related PO. Query `po_id` only accepts a numeric
  /// id, so non-numeric text is filtered client-side on the displayed fields.
  String poSearch = '';

  // Selection
  GoodsReceipt? selected;

  /// Latest stock per item id, fetched via GET /items/:id/stock after
  /// opening a GR detail ("Info stok terkini per barang setelah penerimaan").
  Map<int, double> stockAfter = {};
  bool detailLoading = false;
  bool stockLoading = false;

  // Create form state
  List<PurchaseOrder> openPos = [];
  bool openPosLoading = false;
  PurchaseOrder? selectedPo;

  Future<void> load() async {
    loading = true;
    try {
      receipts = await _grApi.list(startDate: startDate, endDate: endDate);
      final search = poSearch.trim();
      if (search.isNotEmpty) {
        final poId = int.tryParse(search);
        if (poId != null) {
          // Refetch using the supported `po_id` query when input is numeric.
          receipts =
              await _grApi.list(poId: poId, startDate: startDate, endDate: endDate);
        } else {
          receipts = receipts.where((gr) {
            final noGr = gr.noGr.toLowerCase();
            final noPo = (gr.noPo ?? '').toLowerCase();
            return noGr.contains(search.toLowerCase()) ||
                noPo.contains(search.toLowerCase()) ||
                '${gr.poId}'.contains(search);
          }).toList();
        }
      }
    } finally {
      loading = false;
    }
  }

  /// Loads POs eligible for receiving goods: only `open` or `partial`.
  Future<void> loadOpenPos() async {
    openPosLoading = true;
    try {
      final open = await _poApi.list(status: 'open');
      final partial = await _poApi.list(status: 'partial');
      final combined = [...open, ...partial];
      final seen = <int>{};
      openPos = combined.where((po) => seen.add(po.id)).toList();
    } finally {
      openPosLoading = false;
    }
  }

  /// Loads the items (with remaining qty) of a PO chosen in the GR form.
  Future<void> selectPo(int poId) async {
    selectedPo = await _poApi.get(poId);
  }

  Future<void> select(int grId) async {
    detailLoading = true;
    selected = null;
    stockAfter = {};
    try {
      selected = await _grApi.get(grId);
    } finally {
      detailLoading = false;
    }
    await _fetchStockAfter();
  }

  Future<void> _fetchStockAfter() async {
    final gr = selected;
    if (gr == null) return;
    stockLoading = true;
    try {
      final result = <int, double>{};
      for (final item in gr.items) {
        try {
          result[item.itemId] = await _itemApi.stock(item.itemId);
        } catch (_) {
          // Stock for a single item failing must not break the whole view.
        }
      }
      if (selected != null && selected!.id == gr.id) stockAfter = result;
    } finally {
      stockLoading = false;
    }
  }

  void clearSelection() {
    selected = null;
    stockAfter = {};
    detailLoading = false;
    stockLoading = false;
  }

  Future<GoodsReceipt> create({
    required int poId,
    required String tglGR,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) =>
      _grApi.create(poId: poId, tglGR: tglGR, notes: notes, items: items);
}
