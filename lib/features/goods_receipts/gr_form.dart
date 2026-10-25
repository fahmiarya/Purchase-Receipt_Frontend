// lib/features/goods_receipts/gr_form.dart
// Right-column form for creating a Goods Receipt from an existing PO.
// Step 1: pick a PO with status `open` / `partial` only.
// Step 2: fill receipt date, notes, and qty per PO line (max = sisa).
// Payload follows the Postman contract:
//   { poId, tglGR, notes, items: [{ poItemId, qtyDiterima }] }
//
// POST /goods-receipts/preview is intentionally NOT implemented because the
// endpoint is not in the Postman collection yet (see REQUIREMENTS.md).

import 'package:flutter/material.dart';

import '../../core/models/purchase_order.dart' show PurchaseOrder;
import '../../core/models/purchase_order_item.dart' show PurchaseOrderItem;
import 'gr_provider.dart';

class GrForm extends StatefulWidget {
  final GrProvider provider;

  /// Optional PO to preselect (from "Buat GR dari PO ini" on the PO page).
  final int? initialPoId;
  final VoidCallback onCancel;
  final bool submitting;
  final Future<void> Function({
    required int poId,
    required String tglGR,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) onSubmit;

  const GrForm({
    super.key,
    required this.provider,
    required this.onCancel,
    required this.submitting,
    required this.onSubmit,
    this.initialPoId,
  });

  @override
  State<GrForm> createState() => _GrFormState();
}

class _GrFormState extends State<GrForm> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final Map<int, TextEditingController> _qtyControllers = {};

  DateTime? _tglGr = DateTime.now();
  int? _poId;
  bool _loadingPoOptions = true;
  bool _loadingPoItems = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.provider.loadOpenPos();
    if (!mounted) return;
    setState(() => _loadingPoOptions = false);
    final initial = widget.initialPoId;
    if (initial != null &&
        widget.provider.openPos.any((po) => po.id == initial)) {
      await _onPoChanged(initial);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onPoChanged(int? poId) async {
    _clearQtyControllers();
    if (poId == null) {
      setState(() {
        _poId = null;
        widget.provider.selectedPo = null;
      });
      return;
    }
    setState(() {
      _poId = poId;
      _loadingPoItems = true;
    });
    try {
      await widget.provider.selectPo(poId);
      // A GR cannot precede its PO — the date picker lower bound follows the
      // selected PO's tglPO, so previously chosen dates are clamped here.
      final po = widget.provider.selectedPo;
      final poDate = DateTime.tryParse(po?.tglPo ?? '');
      if (poDate != null && _tglGr != null && _tglGr!.isBefore(poDate)) {
        if (mounted) setState(() => _tglGr = poDate);
      }
    } finally {
      if (mounted) setState(() => _loadingPoItems = false);
    }
  }

  void _clearQtyControllers() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    _qtyControllers.clear();
  }

  // The PO chosen for the receipt constrains the date picker: the earliest
  // selectable GR date is the PO's tglPO (backend also rejects earlier dates).
  DateTime _dateLowerBound() {
    final poDate = DateTime.tryParse(widget.provider.selectedPo?.tglPo ?? '');
    final firstDate = DateTime(DateTime.now().year - 5);
    return (poDate != null && poDate.isAfter(firstDate)) ? poDate : firstDate;
  }

  Future<void> _pickDate() async {
    final lower = _dateLowerBound();
    final now = DateTime.now();
    var initial = _tglGr ?? now;
    if (initial.isBefore(lower)) initial = lower;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: lower,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _tglGr = picked);
  }

  /// Validates one receipt qty input: 0 < qty <= sisa.
  String? _validateQty(String? value, num sisa) {
    if (value == null || value.trim().isEmpty) return null; // skip empty rows
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 'Harus berupa angka';
    if (parsed <= 0) return 'Qty harus lebih besar dari 0';
    if (parsed > sisa) return 'Qty melebihi sisa ($sisa)';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tglGr == null || _poId == null) return;

    final po = widget.provider.selectedPo!;
    // Final client-side guard (the backend also rejects this with 422).
    final poDate = DateTime.tryParse(po.tglPo);
    if (poDate != null && _tglGr!.isBefore(poDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tanggal GR tidak boleh mendahului tanggal PO (${po.tglPo})',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final poItem in po.items) {
      final controller = _qtyControllers[poItem.id];
      if (controller == null) continue;
      final parsed = num.tryParse(controller.text.trim());
      if (parsed == null || parsed <= 0) continue;
      items.add({'poItemId': poItem.id, 'qtyDiterima': parsed});
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 1 baris penerimaan harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await widget.onSubmit(
      poId: _poId!,
      tglGR: _tglGr!.toIso8601String().substring(0, 10),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final po = provider.selectedPo;

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
                Text('Buat Goods Receipt',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Step 1 — pilih PO yang masih dapat menerima barang '
                  '(status open/partial)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_loadingPoOptions)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<int>(
                    value: _poId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Order *',
                    ),
                    items: [
                      for (final option in provider.openPos)
                        DropdownMenuItem(
                          value: option.id,
                          child: Text(
                            '${option.noPo ?? 'PO #${option.id}'} — '
                            '${option.tglPo} (${option.status})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => _onPoChanged(value),
                    validator: (v) =>
                        (v == null) ? 'PO wajib dipilih' : null,
                  ),
                const SizedBox(height: 16),

                if (_loadingPoItems)
                  const Center(child: CircularProgressIndicator())
                else if (po != null) ...[
                  Text('Step 2 — isi penerimaan',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(_tglGr == null
                              ? 'Pilih tanggal GR *'
                              : 'tglGR: ${_tglGr!.toIso8601String().substring(0, 10)}'),
                          onPressed: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tanggal GR tidak boleh mendahului tanggal PO '
                      '(${po.tglPo}).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (_tglGr == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Tanggal GR wajib dipilih',
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
                  _buildPoItemsTable(context, po),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: widget.submitting ? null : _submit,
                        child: widget.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Simpan GR'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: widget.submitting ? null : widget.onCancel,
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoItemsTable(BuildContext context, PurchaseOrder po) {
    if (po.items.isEmpty) {
      return const Text('PO ini tidak memiliki item');
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Barang')),
              DataColumn(label: Text('Qty PO'), numeric: true),
              DataColumn(label: Text('Sudah Diterima'), numeric: true),
              DataColumn(label: Text('Sisa'), numeric: true),
              DataColumn(label: Text('Qty Diterima *'), numeric: true),
            ],
            rows: [
              for (final poItem in po.items) _buildRow(context, poItem),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, PurchaseOrderItem poItem) {
    final sisa = poItem.sisa;
    final disabled = sisa <= 0;
    final controller = _qtyControllers.putIfAbsent(
      poItem.id,
      () => TextEditingController(),
    );
    return DataRow(cells: [
      DataCell(Text(poItem.itemName ?? 'Item #${poItem.itemId}')),
      DataCell(Text('${poItem.qtyPo}')),
      DataCell(Text('${poItem.qtyReceived ?? 0}')),
      DataCell(Text('$sisa')),
      DataCell(
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: controller,
            enabled: !disabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              hintText: disabled ? '-' : '0',
            ),
            validator: (v) => _validateQty(v, sisa),
          ),
        ),
      ),
    ]);
  }
}
