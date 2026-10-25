// lib/core/models/vendor.dart
// Vendor model. No dedicated vendor endpoint exists in the Postman collection,
// so vendors are seeded locally (per REQUIREMENTS.md). Update the seed list
// when the backend exposes a vendor master endpoint.

class Vendor {
  final int id;
  final String name;

  const Vendor({required this.id, required this.name});

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
      );

  /// Seed data — keep in sync with the backend seed.
  static const List<Vendor> seedList = [
    Vendor(id: 1, name: 'PT Maju Jaya'),
    Vendor(id: 2, name: 'CV Sumber Makmur'),
    Vendor(id: 3, name: 'PT Indo Plastik'),
    Vendor(id: 4, name: 'CV Berkah Abadi'),
  ];

  /// Display label for a vendor id, falling back to `Vendor #<id>`.
  static String nameOf(int id) {
    for (final vendor in seedList) {
      if (vendor.id == id) return vendor.name;
    }
    return 'Vendor #$id';
  }
}
