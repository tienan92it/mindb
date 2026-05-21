import 'package:postgres/postgres.dart';

/// Formats a PostgreSQL cell for display and LLM tool output.
///
/// The [postgres] driver returns [UndecodedBytes] for types it does not decode
/// natively (custom ENUMs, some arrays, etc.). [Object.toString] on that type
/// is not the column value — use [UndecodedBytes.asString] instead.
String formatCellValue(Object? value) {
  if (value == null) {
    return 'NULL';
  }
  if (value is UndecodedBytes) {
    return value.asString;
  }
  return value.toString();
}

/// Converts driver values into app-friendly objects at the DB boundary.
Object? normalizeCellValue(Object? value) {
  if (value is UndecodedBytes) {
    return value.asString;
  }
  return value;
}
