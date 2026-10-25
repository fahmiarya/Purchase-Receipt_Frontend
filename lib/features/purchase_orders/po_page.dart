// lib/features/purchase_orders/po_page.dart
// Split-panel page for the Purchase Orders feature.
// Left: PoList (status chips + date filter + cards).
// Right: create form, detail view, or an empty placeholder.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/purchase_order.dart';
import 'po_detail.dart';
import 'po_form.dart';
import 'po_list.dart';
import 'po_provider.dart';

class PoPage extends StatefulWidget {
  const PoPage({super.key});

  @override
  State<PoPage> createState() => _PoPageState();
}

enum _PoPanel { placeholder, detail, create }

class _PoPageState extends State<PoPage> {
  final PoProvider _provider = PoProvider();
  _PoPanel _panel = _PoPanel.placeholder;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({bool keepPanel = false}) async {
    setState(() => _loadError = null);
    try {
      await _provider.load();
      setState(() {
        if (_provider.selected == null && !keepPanel) {
          _panel = _PoPanel.placeholder;
        }
      });
    } catch (e) {
      setState(() => _loadError = apiErrorMessage(e));
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(apiErrorMessage(e)), backgroundColor: Colors.red),
    );
  }

  Future<void> _onSelect(PurchaseOrder order) async {
    setState(() => _panel = _PoPanel.detail);
    try {
      await _provider.select(order.id);
      setState(() {});
    } catch (e) {
      setState(() {});
      _showError(e);
    }
  }

  void _onCreate() {
    _provider.clearSelection();
    setState(() => _panel = _PoPanel.create);
  }

  void _onStatusChanged(String? status) {
    _provider.status = status;
    _reload(keepPanel: true);
  }

  void _onRangeChanged(String? start, String? end) {
    _provider.startDate = start;
    _provider.endDate = end;
    _reload(keepPanel: true);
  }

  Future<void> _onSubmitCreate({
    required int vendorId,
    required String tglPO,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    setState(() => _submitting = true);
    try {
      final created = await _provider.create(
        vendorId: vendorId,
        tglPO: tglPO,
        notes: notes,
        items: items,
      );
      await _provider.load();
      await _provider.select(created.id);
      setState(() => _panel = _PoPanel.detail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PO dibuat: ${created.noPo ?? created.id}',
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onCancelPo() async {
    final selected = _provider.selected;
    if (selected == null) return;
    setState(() => _submitting = true);
    try {
      await _provider.cancel(selected.id);
      await _provider.load();
      await _provider.select(selected.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PO berhasil dibatalkan')));
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onCreateGrFromPo() {
    final selected = _provider.selected;
    if (selected == null) return;
    // Preselect the PO in the GR form via query parameter.
    context.go('/goods-receipts?poId=${selected.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PoList(
          orders: _provider.orders,
          loading: _provider.loading,
          selectedOrder: _provider.selected,
          status: _provider.status,
          startDate: _provider.startDate,
          endDate: _provider.endDate,
          onStatusChanged: _onStatusChanged,
          onRangeChanged: _onRangeChanged,
          onSelect: _onSelect,
          onCreate: _onCreate,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildRightPanel() {
    if (_loadError != null) {
      return _ErrorView(message: _loadError!, onRetry: () => _reload());
    }
    switch (_panel) {
      case _PoPanel.create:
        return PoForm(
          onSubmit: _onSubmitCreate,
          onCancel: () => setState(() => _panel = _PoPanel.placeholder),
          submitting: _submitting,
        );
      case _PoPanel.detail:
        if (_provider.detailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final order = _provider.selected;
        if (order == null) {
          return const _PlaceholderView();
        }
        return PoDetail(
          order: order,
          receiptStatus: _provider.receiptStatus,
          busy: _submitting,
          onCancel: _onCancelPo,
          onCreateGr: _onCreateGrFromPo,
          onRefresh: () async {
            await _provider.select(order.id);
            await _provider.load();
            setState(() {});
          },
        );
      case _PoPanel.placeholder:
        return const _PlaceholderView();
    }
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          const Text('Pilih PO di sebelah kiri, atau buat PO baru.'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
