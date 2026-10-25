// lib/features/items/item_list.dart
// Left column: search bar, cascading category dropdowns (L1 → L2 → L3),
// item cards, add button.

import 'package:flutter/material.dart';

import '../../core/models/item.dart';

class ItemList extends StatefulWidget {
  final List<Item> items;
  final bool loading;
  final Item? selectedItem;
  final String search;

  /// Currently applied category filter — may be any level code (L1/L2/L3).
  final String? categoryCode;

  /// true → list sedang menampilkan item aktif + nonaktif.
  final bool showInactive;

  /// Dipanggil saat switch "Tampilkan nonaktif" diganti.
  final ValueChanged<bool> onShowInactiveChanged;

  /// Toggle item dari kartu list: [item] + status target.
  final Future<void> Function(Item item, bool nextActive) onToggleItem;

  /// Item yang sedang dalam proses toggle (untuk spinner tombol).
  final int? togglingItemId;

  final ValueChanged<String> onSearchChanged;

  /// Receives the deepest selected level code, or null to clear the filter.
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<Item> onSelect;
  final VoidCallback onCreate;

  const ItemList({
    super.key,
    required this.items,
    required this.loading,
    required this.selectedItem,
    required this.search,
    required this.categoryCode,
    required this.showInactive,
    required this.onShowInactiveChanged,
    required this.onToggleItem,
    required this.togglingItemId,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  String? _l1Code;
  String? _l2Code;
  String? _l3Code;

  @override
  void initState() {
    super.initState();
    _syncFromFilter();
  }

  @override
  void didUpdateWidget(covariant ItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryCode != widget.categoryCode) {
      _syncFromFilter();
    }
  }

  void _syncFromFilter() {
    final chain = ItemCategory.chainOf(widget.categoryCode);
    _l1Code = chain.isNotEmpty ? chain[0].code : null;
    _l2Code = chain.length > 1 ? chain[1].code : null;
    _l3Code = chain.length > 2 ? chain[2].code : null;
  }

  void _apply() {
    widget.onCategoryChanged(_l3Code ?? _l2Code ?? _l1Code);
  }

  void _clearFilter() {
    setState(() {
      _l1Code = _l2Code = _l3Code = null;
    });
    widget.onCategoryChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: TextEditingController(text: widget.search),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari nama atau kode barang...',
                suffixIcon: widget.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => widget.onSearchChanged(''),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: widget.onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLevelDropdown(
                  label: 'Level 1',
                  value: _l1Code,
                  options: ItemCategory.childrenOf(null),
                  onChanged: (code) {
                    setState(() {
                      _l1Code = code;
                      _l2Code = null;
                      _l3Code = null;
                    });
                    if (code == null) {
                      widget.onCategoryChanged(null);
                    } else {
                      _apply();
                    }
                  },
                ),
                if (_l1Code != null)
                  _buildLevelDropdown(
                    label: 'Level 2',
                    value: _l2Code,
                    options: ItemCategory.childrenOf(_l1Code),
                    onChanged: (code) {
                      setState(() {
                        _l2Code = code;
                        _l3Code = null;
                      });
                      _apply();
                    },
                  ),
                if (_l2Code != null)
                  _buildLevelDropdown(
                    label: 'Level 3',
                    value: _l3Code,
                    options: ItemCategory.childrenOf(_l2Code),
                    onChanged: (code) {
                      setState(() => _l3Code = code);
                      _apply();
                    },
                  ),
                if (_l1Code != null || widget.search.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: TextButton.icon(
                      onPressed: _clearFilter,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Hapus filter kategori'),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton.icon(
              onPressed: widget.onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Item'),
            ),
          ),
          ToggleInactiveRow(
            value: widget.showInactive,
            onChanged: widget.onShowInactiveChanged,
          ),
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator())
                : widget.items.isEmpty
                    ? const Center(child: Text('Tidak ada item'))
                    : ListView.separated(
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final selected = widget.selectedItem?.id == item.id;
                          final busy = widget.togglingItemId == item.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : null,
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: item.isActive
                                          ? null
                                          : TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline),
                                    ),
                                  ),
                                  if (!item.isActive) const InactiveBadge(),
                                ],
                              ),
                              subtitle: Text(
                                '${item.code} • ${ItemCategory.nameOf(item.itemCategoryCode)}',
                              ),
                              leading: item.isActive
                                  ? null
                                  : Icon(Icons.inventory_2_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${item.stock}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(item.uom,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          tooltip: item.isActive
                                              ? 'Nonaktifkan'
                                              : 'Aktifkan',
                                          icon: Icon(
                                            item.isActive
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            size: 20,
                                            color: item.isActive
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                          ),
                                          onPressed: () =>
                                              widget.onToggleItem(item, !item.isActive),
                                        ),
                                ],
                              ),
                              onTap: () => widget.onSelect(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDropdown({
    required String label,
    required String? value,
    required List<ItemCategory> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('(semua)', overflow: TextOverflow.ellipsis),
          ),
          for (final category in options)
            DropdownMenuItem<String>(
              value: category.code,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Badge "Nonaktif" kecil (dipakai di kartu list & panel detail).
class InactiveBadge extends StatelessWidget {
  const InactiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}

/// Switch "Tampilkan nonaktif" di bawah tombol Tambah Item.
class ToggleInactiveRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleInactiveRow({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Row(
        children: [
          Switch(value: value, onChanged: onChanged),
          Text('Tampilkan nonaktif', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
