// lib/features/goods_receipts/gr_list.dart
// Left column: PO/date filters, GR cards, create button.

import 'package:flutter/material.dart';

import '../../core/models/goods_receipt.dart';

class GrList extends StatelessWidget {
  final List<GoodsReceipt> receipts;
  final bool loading;
  final GoodsReceipt? selectedReceipt;
  final String? startDate; // YYYY-MM-DD, inclusive
  final String? endDate; // YYYY-MM-DD, inclusive
  final String poSearch;
  final void Function(String? start, String? end) onRangeChanged;
  final ValueChanged<String> onPoSearchChanged;
  final ValueChanged<GoodsReceipt> onSelect;
  final VoidCallback onCreate;

  const GrList({
    super.key,
    required this.receipts,
    required this.loading,
    required this.selectedReceipt,
    required this.startDate,
    required this.endDate,
    required this.poSearch,
    required this.onRangeChanged,
    required this.onPoSearchChanged,
    required this.onSelect,
    required this.onCreate,
  });

  static DateTime _tryParseIso(String? value) {
    return DateTime.tryParse(value ?? '') ?? DateTime.now();
  }

  static String _iso8601(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _pickStart(BuildContext context) async {
    final end = _tryParseIso(endDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate != null
          ? _tryParseIso(startDate)
          : endDate != null
              ? end
              : DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      // Keep start <= end (backend rejects an inverted range).
      lastDate: endDate != null ? end : DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    onRangeChanged(_iso8601(picked), endDate);
  }

  Future<void> _pickEnd(BuildContext context) async {
    final start = _tryParseIso(startDate);
    final now = DateTime.now();
    final lower = start.isAfter(DateTime(now.year - 5)) ? start : DateTime(now.year - 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate != null
          ? _tryParseIso(endDate)
          : (lower.isAfter(now) ? lower : now),
      firstDate: lower,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    onRangeChanged(startDate, _iso8601(picked));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: TextEditingController(text: poSearch),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Filter no_po / id PO...',
                suffixIcon: poSearch.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => onPoSearchChanged(''),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: onPoSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      startDate == null
                          ? 'Dari: semua'
                          : 'Dari: $startDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _pickStart(context),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      endDate == null ? 'Sampai: semua' : 'Sampai: $endDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _pickEnd(context),
                  ),
                ),
                if (startDate != null || endDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hapus filter tanggal',
                    icon: const Icon(Icons.clear),
                    onPressed: () => onRangeChanged(null, null),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat GR'),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : receipts.isEmpty
                    ? const Center(child: Text('Tidak ada goods receipt'))
                    : ListView.separated(
                        itemCount: receipts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final gr = receipts[index];
                          final selected = selectedReceipt?.id == gr.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : null,
                            child: ListTile(
                              title: Text(gr.noGr.isEmpty
                                  ? 'GR #${gr.id}'
                                  : gr.noGr),
                              subtitle: Text(
                                'PO #${gr.poId}'
                                '${gr.noPo == null ? '' : ' ($gr.noPo)'}'
                                ' • ${gr.tglGr} • ${gr.items.length} item',
                              ),
                              onTap: () => onSelect(gr),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
