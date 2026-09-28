/// Shared UUID parsing helpers for contract models.
String uuidOf(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected UUID string for $field');
}

String? uuidOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;
