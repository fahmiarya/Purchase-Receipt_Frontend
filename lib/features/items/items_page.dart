// lib/features/items/items_page.dart
// Split-panel page for the Items feature.
// Left: ItemList (search + category chips + cards).
// Right: detail (+ edit) or create form, or an empty placeholder.

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/models/item.dart';
import '../../widgets/confirm_dialog.dart';
import 'item_form.dart';
import 'item_list.dart';
import 'item_provider.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

enum _ItemsPanel { placeholder, detail, edit, create }

class _ItemsPageState extends State<ItemsPage> {
  final ItemProvider _provider = ItemProvider();
  _ItemsPanel _panel = _ItemsPanel.placeholder;
  bool _submitting = false;
  String? _loadError;
  int? _togglingItemId;

  @override
  void initState() {
    super.initState();
    _reload(keepPanel: true);
  }

  Future<void> _reload({bool keepPanel = false}) async {
    setState(() => _loadError = null);
    try {
      await _provider.load();
      setState(() {
        if (!keepPanel && _provider.selected == null) _panel = _ItemsPanel.placeholder;
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

  Future<void> _onSelect(Item item) async {
    setState(() => _panel = _ItemsPanel.detail);
    try {
      await _provider.select(item);
      setState(() {});
    } catch (e) {
      // Stock fetch failure should not block the detail view.
      setState(() {});
      _showError(e);
    }
  }

  void _onCreate() {
    _provider.clearSelection();
    setState(() => _panel = _ItemsPanel.create);
  }

  void _onCategoryChanged(String? categoryCode) {
    _provider.categoryCode = categoryCode;
    _reload(keepPanel: true);
  }

  void _onSearchChanged(String search) {
    _provider.search = search;
    _reload(keepPanel: true);
  }

  void _onShowInactiveChanged(bool value) {
    _provider.includeInactive = value;
    _reload(keepPanel: true);
  }

  Future<void> _onToggleItem(Item item, bool nextActive) async {
    final confirmed = await showConfirmDialog(
      context,
      title: nextActive ? 'Aktifkan Item' : 'Nonaktifkan Item',
      content: nextActive
          ? 'Aktifkan kembali item "${item.name}" (${item.code})? Item aktif bisa dipilih untuk PO.'
          : 'Nonaktifkan item "${item.name}" (${item.code})? Item ini tidak akan muncul di dropdown PO, tapi datanya tetap ada.',
      confirmLabel: nextActive ? 'Aktifkan' : 'Nonaktifkan',
      confirmColor: nextActive ? Colors.green : Colors.red,
    );
    if (!confirmed) return;
    setState(() => _togglingItemId = item.id);
    try {
      final updated = await _provider.toggle(item, nextActive: nextActive);
      await _provider.load();
      if (_provider.selected?.id == item.id) {
        _provider.selected = updated; // sync panel detail dengan status baru
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updated.isActive ? 'Item diaktifkan' : 'Item dinonaktifkan')),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _togglingItemId = null);
    }
  }

  Future<void> _onSubmit(Map<String, dynamic> payload) async {
    setState(() => _submitting = true);
    try {
      final isEdit = _panel == _ItemsPanel.edit;
      final saved = isEdit
          ? await _provider.update(_provider.selected!.id, payload)
          : await _provider.create(payload);
      await _provider.load();
      await _provider.select(saved);
      setState(() => _panel = _ItemsPanel.detail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Item berhasil diupdate' : 'Item berhasil ditambahkan'),
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
    return Row(
      children: [
        ItemList(
          items: _provider.items,
          loading: _provider.loading,
          selectedItem: _provider.selected,
          search: _provider.search,
          categoryCode: _provider.categoryCode,
          showInactive: _provider.includeInactive,
          onShowInactiveChanged: _onShowInactiveChanged,
          onToggleItem: _onToggleItem,
          togglingItemId: _togglingItemId,
          onSearchChanged: _onSearchChanged,
          onCategoryChanged: _onCategoryChanged,
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
      case _ItemsPanel.create:
        return ItemForm(
          item: null,
          onSubmit: _onSubmit,
          onCancel: () => setState(() => _panel = _ItemsPanel.placeholder),
          submitting: _submitting,
        );
      case _ItemsPanel.edit:
        return ItemForm(
          item: _provider.selected,
          onSubmit: _onSubmit,
          onCancel: () => setState(() => _panel = _ItemsPanel.detail),
          submitting: _submitting,
        );
      case _ItemsPanel.detail:
        return _ItemDetailView(
          provider: _provider,
          submitting: _submitting,
          toggling: _togglingItemId != null,
          onEdit: () => setState(() => _panel = _ItemsPanel.edit),
          onToggle: () => _onToggleItem(_provider.selected!, !_provider.selected!.isActive),
        );
      case _ItemsPanel.placeholder:
        return const _PlaceholderView();
    }
  }
}

class _ItemDetailView extends StatelessWidget {
  final ItemProvider provider;
  final bool submitting;
  final bool toggling;
  final VoidCallback onEdit;

  /// Toggle aktif/nonaktif (target dihitung dari status item sekarang).
  final VoidCallback onToggle;

  const _ItemDetailView({
    required this.provider,
    required this.submitting,
    required this.toggling,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final item = provider.selected;
    if (item == null) return const _PlaceholderView();

    Widget stockInfo;
    if (provider.stockLoading) {
      stockInfo = const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      stockInfo = Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.warehouse, size: 20),
            const SizedBox(width: 8),
            Text(
              'Stok terkini (GET /items/:id/stock): ${provider.selectedStock ?? item.stock} ${item.uom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final rows = <(String, String)>[
      ('Kode', item.code),
      ('Nama', item.name),
      ('Kategori', ItemCategory.nameOf(item.itemCategoryCode)),
      ('Kode kategori', item.itemCategoryCode ?? '-'),
      ('Brand code', item.brandCode),
      ('Sequence', '${item.sequence}'),
      ('Satuan', item.uom),
      ('Stok (dari data item)', '${item.stock}'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(item.name, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (!item.isActive) ...[
                    const SizedBox(width: 8),
                    const InactiveBadge(),
                  ],
                ],
              ),
              Text(item.code, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              stockInfo,
              const SizedBox(height: 12),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 180,
                        child: Text(label,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Text(value)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: submitting ? null : onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Ubah'),
                  ),
                  item.isActive
                      ? OutlinedButton.icon(
                          style:
                              OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: toggling ? null : onToggle,
                          icon: toggling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.visibility_off),
                          label: const Text('Nonaktifkan'),
                        )
                      : OutlinedButton.icon(
                          style:
                              OutlinedButton.styleFrom(foregroundColor: Colors.green),
                          onPressed: toggling ? null : onToggle,
                          icon: toggling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.visibility),
                          label: const Text('Aktifkan kembali'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          Icon(Icons.inventory_2_outlined,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          const Text('Pilih item di sebelah kiri, atau tambah item baru.'),
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
