// lib/core/models/json_helpers.dart
// Tolerant JSON helpers. The Postman collection only documents request bodies,
// not complete response shapes, so models accept both camelCase and snake_case
// variants of every field, as required by REQUIREMENTS.md
// ("Cocokkan model Flutter dengan response aktual backend").

/// Returns the first non-null value found among [keys].
dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    return double.tryParse(value.trim())?.toInt() ?? fallback;
  }
  return fallback;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

/// For Decimals the backend serializes numbers as strings (e.g. "100.00").
/// Returns an int when the value has no fractional part, otherwise a double.
num asNum(dynamic value, [num fallback = 0]) {
  if (value is num) return value;
  if (value is String) {
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed) ?? (int.tryParse(trimmed) ?? fallback);
    // Prisma Decimal(15,2) — "100" is a whole qty; prefer int so UI shows 100
    // instead of 100.0.
    if (parsed.toInt() == parsed) return parsed.toInt();
    return parsed;
  }
  return fallback;
}

/// Booleans may arrive as bool, number (1/0) or string ("true"/"false").
bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

String asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  if (value is num) return value.toString();
  return fallback;
}

/// Backend date-only fields (tglPO / tglGR) arrive as full ISO timestamps
/// ("2026-10-26T00:00:00.000Z"); the UI displays and compares plain
/// YYYY-MM-DD. Extracts the date part and leaves other formats untouched.
String asDateString(dynamic value, [String fallback = '']) {
  final s = asString(value, fallback).trim();
  if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    return s.substring(0, 10);
  }
  return s;
}
