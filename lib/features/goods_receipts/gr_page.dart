// lib/features/goods_receipts/gr_page.dart
// Split-panel page for the Goods Receipts feature.
// Left: GrList (po/date filters + cards).
// Right: create form, detail view, or an empty placeholder.
// Supports ?poId=<id> query (from "Buat GR dari PO ini" on the PO page).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/goods_receipt.dart';
import 'gr_detail.dart';
import 'gr_form.dart';
import 'gr_list.dart';
import 'gr_provider.dart';

class GrPage extends StatefulWidget {
  const GrPage({super.key});

  @override
  State<GrPage> createState() => _GrPageState();
}

enum _GrPanel { placeholder, detail, create }

class _GrPageState extends State<GrPage> {
  final GrProvider _provider = GrProvider();
  _GrPanel _panel = _GrPanel.placeholder;
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
          _panel = _GrPanel.placeholder;
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

  Future<void> _onSelect(GoodsReceipt gr) async {
    setState(() => _panel = _GrPanel.detail);
    try {
      await _provider.select(gr.id);
      setState(() {});
    } catch (e) {
      setState(() {});
      _showError(e);
    }
  }

  void _onCreate() {
    _provider.clearSelection();
    setState(() => _panel = _GrPanel.create);
  }

  void _onRangeChanged(String? start, String? end) {
    _provider.startDate = start;
    _provider.endDate = end;
    _reload(keepPanel: true);
  }

  void _onPoSearchChanged(String poSearch) {
    _provider.poSearch = poSearch;
    _reload(keepPanel: true);
  }

  Future<void> _onSubmitCreate({
    required int poId,
    required String tglGR,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    setState(() => _submitting = true);
    try {
      final created = await _provider.create(
        poId: poId,
        tglGR: tglGR,
        notes: notes,
        items: items,
      );
      await _provider.load();
      await _provider.select(created.id);
      setState(() => _panel = _GrPanel.detail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GR tersimpan: ${created.noGr.isEmpty ? created.id : created.noGr}',
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

  @override
  Widget build(BuildContext context) {
    // ?poId=... preselects a PO inside the create form.
    final poIdParam =
        GoRouterState.of(context).uri.queryParameters['poId'];
    final initialPoId = int.tryParse(poIdParam ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (initialPoId != null && _panel != _GrPanel.create)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.tonal(
              onPressed: _onCreate,
              child: const Text('Buat GR untuk PO ini'),
            ),
          ),
        Expanded(
          child: Row(
            children: [
              GrList(
                receipts: _provider.receipts,
                loading: _provider.loading,
                selectedReceipt: _provider.selected,
                startDate: _provider.startDate,
                endDate: _provider.endDate,
                poSearch: _provider.poSearch,
                onRangeChanged: _onRangeChanged,
                onPoSearchChanged: _onPoSearchChanged,
                onSelect: _onSelect,
                onCreate: _onCreate,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildRightPanel(initialPoId)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(int? initialPoId) {
    if (_loadError != null) {
      return _ErrorView(message: _loadError!, onRetry: () => _reload());
    }
    switch (_panel) {
      case _GrPanel.create:
        return GrForm(
          provider: _provider,
          initialPoId: initialPoId,
          onSubmit: _onSubmitCreate,
          onCancel: () => setState(() => _panel = _GrPanel.placeholder),
          submitting: _submitting,
        );
      case _GrPanel.detail:
        if (_provider.detailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final gr = _provider.selected;
        if (gr == null) return const _PlaceholderView();
        return GrDetail(
          receipt: gr,
          provider: _provider,
          onRefresh: () async {
            await _provider.select(gr.id);
            await _provider.load();
            setState(() {});
          },
        );
      case _GrPanel.placeholder:
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
          Icon(Icons.local_shipping_outlined,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          const Text('Pilih GR di sebelah kiri, atau buat GR baru.'),
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
