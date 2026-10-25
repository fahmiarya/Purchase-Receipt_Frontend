// lib/features/goods_receipts/gr_detail.dart
// Right-column detail view for a single Goods Receipt.
// Shows the receipt table plus latest stock per received item
// (fetched via GET /items/:id/stock). GR is immutable — no edit/delete.

import 'package:flutter/material.dart';

import '../../core/models/goods_receipt.dart';
import 'gr_provider.dart';

class GrDetail extends StatelessWidget {
  final GoodsReceipt receipt;
  final GrProvider provider;
  final VoidCallback onRefresh;

  const GrDetail({
    super.key,
    required this.receipt,
    required this.provider,
    required this.onRefresh,
  });

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
              _buildItemsTable(context),
              const SizedBox(height: 16),
              Text(
                'GR bersifat final (immutable). Koreksi dilakukan melalui '
                'dokumen Goods Return di luar scope aplikasi ini.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
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
        Text(
          receipt.noGr.isEmpty ? 'GR #${receipt.id}' : receipt.noGr,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _infoRow('PO Terkait',
            '#${receipt.poId}${receipt.noPo == null ? '' : ' (${receipt.noPo})'}'),
        _infoRow('Tanggal GR', receipt.tglGr),
        if (receipt.notes != null) _infoRow('Notes', receipt.notes!),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    if (receipt.items.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Tidak ada item pada GR ini'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Barang')),
              DataColumn(label: Text('Qty Diterima'), numeric: true),
              DataColumn(label: Text('Satuan')),
              DataColumn(label: Text('Stok Terkini'), numeric: true),
            ],
            rows: [
              for (final item in receipt.items)
                DataRow(cells: [
                  DataCell(Text(item.itemName ?? 'Item #${item.itemId}')),
                  DataCell(Text('${item.qtyDiterima}')),
                  DataCell(Text(item.uom ?? '-')),
                  DataCell(Text(_stockLabel(item.itemId))),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  String _stockLabel(int itemId) {
    if (provider.stockLoading) return 'memuat...';
    final stock = provider.stockAfter[itemId];
    return stock == null ? '-' : '$stock';
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
