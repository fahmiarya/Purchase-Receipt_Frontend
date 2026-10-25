// lib/features/purchase_orders/po_form.dart
// Right-column form for creating a Purchase Order.
// Payload follows the Postman contract:
//   { vendorId, tglPO, notes, items: [{ itemId, qtyPO, hargaPO }] }

import 'package:flutter/material.dart';

import '../../core/api/api_provider.dart';
import '../../core/models/item.dart';
import '../../core/models/vendor.dart';

class PoLineRow {
  int? itemId;
  final TextEditingController qty = TextEditingController();
  final TextEditingController harga = TextEditingController();

  void dispose() {
    qty.dispose();
    harga.dispose();
  }
}

class PoForm extends StatefulWidget {
  final Future<void> Function({
    required int vendorId,
    required String tglPO,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) onSubmit;
  final VoidCallback onCancel;
  final bool submitting;

  const PoForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    required this.submitting,
  });

  @override
  State<PoForm> createState() => _PoFormState();
}

class _PoFormState extends State<PoForm> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  int? _vendorId;
  DateTime? _tglPo;
  List<Item> _items = [];
  bool _itemsLoading = true;
  final List<PoLineRow> _rows = [PoLineRow()];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiProvider().itemApi.list();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Errors surface at submit time if the user cannot pick an item.
    } finally {
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglPo ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _tglPo = picked);
  }

  void _addRow() => setState(() => _rows.add(PoLineRow()));

  void _removeRow(int index) {
    _rows[index].dispose();
    setState(() => _rows.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 1 baris item diperlukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await widget.onSubmit(
      vendorId: _vendorId!,
      tglPO: _tglPo!.toIso8601String().substring(0, 10),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      items: [
        for (final row in _rows)
          {
            'itemId': row.itemId!,
            'qtyPO': num.tryParse(row.qty.text.trim()) ?? 0,
            'hargaPO': num.tryParse(row.harga.text.trim()) ?? 0,
          },
      ],
    );
  }

  String? _validateQty(String? value, {bool isPrice = false}) {
    if (value == null || value.trim().isEmpty) {
      return isPrice ? 'Harga wajib diisi' : 'Qty wajib diisi';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 'Harus berupa angka';
    if (parsed <= 0) return 'Harus lebih besar dari 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Buat Purchase Order',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _vendorId,
                  decoration: const InputDecoration(
                    labelText: 'Vendor *',
                    helperText: 'Data seed lokal (belum ada endpoint vendor)',
                  ),
                  items: [
                    for (final vendor in Vendor.seedList)
                      DropdownMenuItem(
                        value: vendor.id,
                        child: Text(vendor.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _vendorId = value),
                  validator: (v) => (v == null) ? 'Vendor wajib dipilih' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_tglPo == null
                            ? 'Pilih tanggal PO *'
                            : 'tglPO: ${_tglPo!.toIso8601String().substring(0, 10)}'),
                        onPressed: _pickDate,
                      ),
                    ),
                  ],
                ),
                if (_tglPo == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Tanggal PO wajib dipilih',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Items',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Baris'),
                    ),
                  ],
                ),
                if (_itemsLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ..._buildItemRows(),
                if (_rows.isEmpty)
                  const Text('Minimal 1 baris item', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: widget.submitting ? null : _submit,
                      child: widget.submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Buat PO'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.submitting ? null : widget.onCancel,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemRows() {
    return [
      for (var i = 0; i < _rows.length; i++) ...[
        const Divider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _rows[i].itemId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Barang'),
                items: [
                  for (final item in _items)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        '${item.name} (${item.code})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _rows[i].itemId = value),
                validator: (v) =>
                    (v == null || _rows.isEmpty) ? 'Barang wajib dipilih' : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: _rows[i].qty,
                decoration: const InputDecoration(labelText: 'Qty'),
                keyboardType: TextInputType.number,
                validator: (v) => _validateQty(v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: _rows[i].harga,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validateQty(v, isPrice: true),
              ),
            ),
            IconButton(
              tooltip: 'Hapus baris',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeRow(i),
            ),
          ],
        ),
      ],
    ];
  }
}
