// lib/features/purchase_orders/po_list.dart
// Left column: status filter chips, date filter, PO cards, create button.

import 'package:flutter/material.dart';

import '../../core/models/purchase_order.dart';
import '../../core/models/vendor.dart';
import '../../widgets/status_badge.dart';

class PoList extends StatelessWidget {
  final List<PurchaseOrder> orders;
  final bool loading;
  final PurchaseOrder? selectedOrder;
  final String? status;
  final String? startDate; // YYYY-MM-DD, inclusive
  final String? endDate; // YYYY-MM-DD, inclusive
  final ValueChanged<String?> onStatusChanged;
  final void Function(String? start, String? end) onRangeChanged;
  final ValueChanged<PurchaseOrder> onSelect;
  final VoidCallback onCreate;

  const PoList({
    super.key,
    required this.orders,
    required this.loading,
    required this.selectedOrder,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.onStatusChanged,
    required this.onRangeChanged,
    required this.onSelect,
    required this.onCreate,
  });

  static const List<String> statusOptions = [
    'All', 'Open', 'Partial', 'Complete', 'Cancelled',
  ];

  static DateTime _tryParseIso(String? value) {
    return DateTime.tryParse(value ?? '') ?? DateTime.now();
  }

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

  static String _iso8601(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final option in statusOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(option),
                      selected: (status ?? 'All') == option,
                      onSelected: (_) => onStatusChanged(option),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat PO'),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text('Tidak ada purchase order'))
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final selected = selectedOrder?.id == order.id;
                          final itemCount =
                              order.items.isNotEmpty ? order.items.length : null;
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.noPo ?? 'PO #${order.id}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (order.status != null)
                                    StatusBadge(status: order.status!),
                                ],
                              ),
                              subtitle: Text(
                                '${Vendor.nameOf(order.vendorId)} • ${order.tglPo}'
                                '${itemCount == null ? '' : ' • $itemCount item'}',
                              ),
                              onTap: () => onSelect(order),
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
