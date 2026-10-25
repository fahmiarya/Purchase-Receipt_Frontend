// lib/core/models/item.dart
// Model representing a master Item.
// Parsing is tolerant (camelCase / snake_case) because the Postman collection
// does not document full response shapes.

import 'json_helpers.dart';

class Item {
  final int id;
  final String code;
  final String name;
  final String? itemCategoryCode;
  final String brandCode;
  final int sequence;
  final String uom;
  final double stock;
  final String? createdAt;
  final String? updatedAt;

  Item({
    required this.id,
    required this.code,
    required this.name,
    this.itemCategoryCode,
    required this.brandCode,
    required this.sequence,
    required this.uom,
    required this.stock,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: asInt(pick(json, ['id', 'itemId', 'item_id'])),
      code: asString(pick(json, ['code'])),
      name: asString(pick(json, ['name'])),
      itemCategoryCode: pick(json, ['itemCategoryCode', 'item_category_code', 'category_code'])
          ?.toString(),
      brandCode: asString(pick(json, ['brandCode', 'brand_code'])),
      sequence: asInt(pick(json, ['sequence'])),
      uom: asString(pick(json, ['uom', 'uomCode', 'unit'])),
      stock: asDouble(pick(json, ['stock', 'stok'])),
      createdAt: pick(json, ['createdAt', 'created_at'])?.toString(),
      updatedAt: pick(json, ['updatedAt', 'updated_at'])?.toString(),
    );
  }

}

class ItemCategory {
  final String code;
  final String name;

  /// Code of the parent category (null for top level).
  final String? parentCode;

  const ItemCategory({
    required this.code,
    required this.name,
    this.parentCode,
  });

  /// Seed data — mirrors the backend seed hierarchy (3 levels):
  ///   L1: Raw Material / Packaging / Spare Part & Consumable
  ///   L2: Plastik & Resin, Additive & Chemical, ...
  ///   L3 (daun): PPR, PER, PVC, ABS, MBT, STB, PLZ, WPC, ACP, PKP, KRD, STR
  /// Item `code` dibangun backend dari gabungan: {L1}-{L2}-{L3}-{brandCode}-{sequence}
  static const List<ItemCategory> seedList = [
    // Level 1
    ItemCategory(code: 'A', name: 'Raw Material'),
    ItemCategory(code: 'B', name: 'Packaging'),
    ItemCategory(code: 'C', name: 'Spare Part & Consumable'),
    // Level 2
    ItemCategory(code: 'AA', name: 'Plastik & Resin', parentCode: 'A'),
    ItemCategory(code: 'AB', name: 'Additive & Chemical', parentCode: 'A'),
    ItemCategory(code: 'AC', name: 'Komposit', parentCode: 'A'),
    ItemCategory(code: 'BA', name: 'Packaging Primer', parentCode: 'B'),
    ItemCategory(code: 'BB', name: 'Packaging Sekunder', parentCode: 'B'),
    ItemCategory(code: 'CA', name: 'Spare Part Mesin', parentCode: 'C'),
    ItemCategory(code: 'CB', name: 'Consumable Produksi', parentCode: 'C'),
    // Level 3
    ItemCategory(code: 'PPR', name: 'Polypropylene (PP)', parentCode: 'AA'),
    ItemCategory(code: 'PER', name: 'Polyethylene (PE)', parentCode: 'AA'),
    ItemCategory(code: 'PVC', name: 'PVC Resin', parentCode: 'AA'),
    ItemCategory(code: 'ABS', name: 'ABS Resin', parentCode: 'AA'),
    ItemCategory(code: 'MBT', name: 'Masterbatch', parentCode: 'AB'),
    ItemCategory(code: 'STB', name: 'Stabilizer', parentCode: 'AB'),
    ItemCategory(code: 'PLZ', name: 'Plasticizer', parentCode: 'AB'),
    ItemCategory(code: 'WPC', name: 'Wood Plastic Composite', parentCode: 'AC'),
    ItemCategory(code: 'ACP', name: 'Aluminum Composite Panel', parentCode: 'AC'),
    ItemCategory(code: 'PKP', name: 'Plastik Wrapping', parentCode: 'BA'),
    ItemCategory(code: 'KRD', name: 'Kardus / Karton Box', parentCode: 'BB'),
    ItemCategory(code: 'STR', name: 'Strapping Band', parentCode: 'BB'),
  ];

  /// Direct children of [parentCode]; use null for top-level categories.
  static List<ItemCategory> childrenOf(String? parentCode) => seedList
      .where((category) => category.parentCode == parentCode)
      .toList();

  /// Hierarchical path (L1 → L2 → L3) for a category code, e.g. PPR → [A, AA, PPR].
  static List<ItemCategory> chainOf(String? code) {
    if (code == null) return const [];
    for (final category in seedList) {
      if (category.code == code) {
        return [...chainOf(category.parentCode), category];
      }
    }
    return const [];
  }

  static String nameOf(String? code) {
    if (code == null) return '-';
    for (final category in seedList) {
      if (category.code == code) return category.name;
    }
    return code;
  }
}

/// Satuan mengikuti enum `Uom` di prisma/schema.prisma backend.
const itemUomOptions = <String>[
  'pcs', 'kg', 'gram', 'm', 'cm', 'liter', 'ml', 'set', 'unit', 'lembar', 'batang', 'roll',
];
