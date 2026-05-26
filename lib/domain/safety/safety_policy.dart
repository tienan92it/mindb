import '../models/models.dart';

class SafetyPolicy {
  const SafetyPolicy({this.readOnlyMode = false});

  final bool readOnlyMode;

  static final _writePattern = RegExp(
    r'\b(INSERT|UPDATE|DELETE|MERGE|UPSERT)\b',
    caseSensitive: false,
  );

  static final _destructivePattern = RegExp(
    r'\b(DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|COMMENT)\b',
    caseSensitive: false,
  );

  static final _selectPattern = RegExp(
    r'^\s*(WITH\b.*?SELECT|SELECT)\b',
    caseSensitive: false,
    dotAll: true,
  );

  static final _limitPattern = RegExp(r'\bLIMIT\s+\d+\b', caseSensitive: false);

  static final _ddlPattern = RegExp(
    r'\b(CREATE|ALTER|DROP)\b',
    caseSensitive: false,
  );

  bool affectsSchemaStructure(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) return false;
    if (RegExp(r'^\s*EXPLAIN\b', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }
    return _ddlPattern.hasMatch(trimmed);
  }

  SqlClassification classify(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      return SqlClassification.safe;
    }

    if (_destructivePattern.hasMatch(trimmed)) {
      return SqlClassification.destructive;
    }

    if (_writePattern.hasMatch(trimmed)) {
      return SqlClassification.write;
    }

    return SqlClassification.safe;
  }

  bool isReadOnlyAllowed(String sql) {
    if (!readOnlyMode) {
      return true;
    }
    final classification = classify(sql);
    return classification == SqlClassification.safe;
  }

  bool requiresConfirmation(String sql) {
    final classification = classify(sql);
    return classification == SqlClassification.destructive ||
        classification == SqlClassification.write;
  }

  String injectLimit(String sql, int maxRows) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty || !_selectPattern.hasMatch(trimmed)) {
      return sql;
    }

    if (_limitPattern.hasMatch(trimmed)) {
      return sql;
    }

    final withoutSemicolon = trimmed.endsWith(';')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    return '$withoutSemicolon LIMIT $maxRows;';
  }
}
