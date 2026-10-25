// lib/features/items/item_form.dart
// Right-column form for creating/editing an Item.
//
// Yang diisi manual: nama, kategori (3 level kaskade), dan satuan.
// Stok read-only — hanya bergerak melalui penerimaan (Goods Receipt).
// `code`, `brandCode`, dan `stock`/`sequence` TIDAK dikirim — backend membangun
// kode item dari gabungan layer kategori: {L1}-{L2}-{L3}-{brandCode}-{sequence}
// (brandCode default "000", sequence = urutan berikutnya untuk kombinasi
// kategori + brand yang sama, stok awal 0).
//
// Edit memakai field yang diizinkan backend (updateItemSchema): name, uom.

import 'package:flutter/material.dart';

import '../../core/models/item.dart';

class ItemForm extends StatefulWidget {
  /// Null → create mode; non-null → edit mode (pre-filled).
  final Item? item;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final VoidCallback onCancel;
  final bool submitting;

  const ItemForm({
    super.key,
    required this.item,
    required this.onSubmit,
    required this.onCancel,
    required this.submitting,
  });

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brandCode;
  late String? _uom;
  String? _l1Code;
  String? _l2Code;
  String? _l3Code;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _brandCode = TextEditingController(text: item?.brandCode ?? '000');
    _uom = item?.uom.isNotEmpty == true ? item!.uom : null;
    final chain = ItemCategory.chainOf(item?.itemCategoryCode);
    if (chain.isNotEmpty) {
      _l1Code = chain[0].code;
      if (chain.length > 1) _l2Code = chain[1].code;
      if (chain.length > 2) _l3Code = chain[2].code;
    } else if (item?.itemCategoryCode != null) {
      // Category unknown to the seed (e.g. placeholder created by backend) —
      // show it directly on level 3.
      _l3Code = item!.itemCategoryCode;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brandCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'uom': _uom,
    };
    if (!_isEdit) {
      payload
        ..['itemCategoryCode'] = _l3Code
        ..['brandCode'] = _brandCode.text.trim();
    }
    await widget.onSubmit(payload);
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
                Text(_isEdit ? 'Edit Item' : 'Tambah Item',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                if (_isEdit) ...[
                  Text(
                    'Kode item dibuat otomatis backend. Stok hanya bergerak '
                    'melalui penerimaan (GR) — di sini hanya nama dan satuan '
                    'yang dapat diubah.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Kode',
                    widget.item!.code.isEmpty ? '-' : widget.item!.code,
                  ),
                  _infoRow('Kategori',
                      ItemCategory.nameOf(widget.item!.itemCategoryCode)),
                  _infoRow('Stok',
                      '${widget.item!.stock} ${widget.item!.uom} (read-only)'),
                  const SizedBox(height: 12),
                ] else
                  Text(
                    'Kode item dibuat otomatis: {L1}-{L2}-{L3}-{brandCode}-{sequence}. '
                    'Sequence mengikuti kombinasi kategori + brand, stok awal 0 '
                    '(bergerak lewat Goods Receipt).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                if (!_isEdit) ...[
                  Text('Kategori *', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  ..._buildCategoryDropdowns(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _brandCode,
                    decoration: const InputDecoration(
                      labelText: 'Brand code (brandCode) *',
                      helperText: 'Layer 4 kode item; default "000"',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Brand code wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  value: _uom,
                  decoration: const InputDecoration(labelText: 'Satuan (uom) *'),
                  items: [
                    for (final uom in itemUomOptions)
                      DropdownMenuItem(value: uom, child: Text(uom)),
                  ],
                  onChanged: (value) => setState(() => _uom = value),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Satuan wajib dipilih' : null,
                ),
                const SizedBox(height: 20),
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
                          : const Text('Simpan'),
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

  List<Widget> _buildCategoryDropdowns() {
    return [
      _categoryField(
        label: 'Level 1',
        value: _l1Code,
        options: ItemCategory.childrenOf(null),
        onChanged: (code) => setState(() {
          _l1Code = code;
          _l2Code = null;
          _l3Code = null;
        }),
        validator: (v) => (v == null) ? 'Level 1 wajib dipilih' : null,
      ),
      if (_l1Code != null)
        _categoryField(
          label: 'Level 2',
          value: _l2Code,
          options: ItemCategory.childrenOf(_l1Code),
          onChanged: (code) => setState(() {
            _l2Code = code;
            _l3Code = null;
          }),
          validator: (v) => (v == null) ? 'Level 2 wajib dipilih' : null,
        ),
      if (_l2Code != null)
        _categoryField(
          label: 'Level 3',
          value: _l3Code,
          options: ItemCategory.childrenOf(_l2Code),
          onChanged: (code) => setState(() => _l3Code = code),
          validator: (v) => (v == null) ? 'Level 3 wajib dipilih' : null,
        ),
    ];
  }

  Widget _categoryField({
    required String label,
    required String? value,
    required List<ItemCategory> options,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final category in options)
            DropdownMenuItem(
              value: category.code,
              child: Text(
                '${category.name} (${category.code})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      );
}
