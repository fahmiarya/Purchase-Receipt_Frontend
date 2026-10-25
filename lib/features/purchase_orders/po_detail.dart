// lib/features/purchase_orders/po_detail.dart
// Right-column detail view for a single Purchase Order.
// Shows items table with receipt progress, receipt status info from
// GET /purchase-orders/:id/receipt-status, and action buttons whose
// visibility follows backend business rules:
//   - Cancel PO     → visible only while status is `open`
//   - Buat GR       → visible only while status is `open` or `partial`

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/purchase_order.dart';
import '../../core/models/vendor.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';

final _numberFormat = NumberFormat('#,###');

class PoDetail extends StatelessWidget {
  final PurchaseOrder order;
  final Map<String, dynamic> receiptStatus;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onCreateGr;
  final VoidCallback onRefresh;

  const PoDetail({
    super.key,
    required this.order,
    required this.receiptStatus,
    required this.busy,
    required this.onCancel,
    required this.onCreateGr,
    required this.onRefresh,
  });

  String? get _status => order.status?.toLowerCase();

  bool get _canCancel => _status == 'open';
  bool get _canCreateGr => _status == 'open' || _status == 'partial';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildReceiptStatusInfo(context),
              const SizedBox(height: 16),
              _buildItemsTable(context),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (_canCreateGr)
                    FilledButton.icon(
                      onPressed: busy ? null : onCreateGr,
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Buat GR dari PO ini'),
                    ),
                  if (_canCancel)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: busy ? null : () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Cancel PO',
                          content: 'Yakin ingin membatalkan PO ${order.noPo ?? order.id}?',
                          confirmLabel: 'Cancel PO',
                        );
                        if (confirmed) onCancel();
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel PO'),
                    ),
                  TextButton.icon(
                    onPressed: busy ? null : onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.noPo ?? 'PO #${order.id}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (order.status != null) StatusBadge(status: order.status!),
          ],
        ),
        const SizedBox(height: 8),
        _infoRow('Vendor', Vendor.nameOf(order.vendorId)),
        _infoRow('Tanggal PO', order.tglPo),
        if (order.notes != null) _infoRow('Notes', order.notes!),
      ],
    );
  }

  Widget _buildReceiptStatusInfo(BuildContext context) {
    if (receiptStatus.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Status penerimaan belum tersedia'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Penerimaan (GET /purchase-orders/:id/receipt-status)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (receiptStatus['status'] != null)
            StatusBadge(status: receiptStatus['status'].toString()),
          for (final entry in receiptStatus.entries)
            if (entry.key != 'status' && (entry.value is num || entry.value is String))
              _infoRow(entry.key, entry.value.toString()),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    if (order.items.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Tidak ada item pada PO ini'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: Text('Barang')),
                  DataColumn(label: Text('Qty PO'), numeric: true),
                  DataColumn(label: Text('Qty Diterima'), numeric: true),
                  DataColumn(label: Text('Sisa'), numeric: true),
                  DataColumn(label: Text('Harga'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: [
                  for (final item in order.items)
                    DataRow(cells: [
                      DataCell(Text(item.itemName ?? 'Item #${item.itemId}')),
                      DataCell(Text(_numberFormat.format(item.qtyPo))),
                      DataCell(Text(_numberFormat.format(item.qtyReceived ?? 0))),
                      DataCell(Text(_numberFormat.format(item.sisa))),
                      DataCell(Text(_numberFormat.format(item.hargaPo))),
                      DataCell(
                          Text(_numberFormat.format(item.qtyPo * item.hargaPo))),
                    ]),
                ],
              ),
              // Progress bar per item: qty diterima / qty PO.
              ...buildProgressRows(),
            ],
          ),
        ),
      ),
    );
  }

  // Progress bars render under the table so narrow screens stay readable.
  // NOTE: this Column lives inside a horizontally scrollable view, so rows
  // must shrink-wrap — no Expanded (unbounded width) allowed here.
  List<Widget> buildProgressRows() {
    return [
      for (final item in order.items)
        if (item.qtyPo > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    item.itemName ?? 'Item #${item.itemId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: ((item.qtyReceived ?? 0) / item.qtyPo)
                        .clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.qtyReceived ?? 0}/${item.qtyPo}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
    ];
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
