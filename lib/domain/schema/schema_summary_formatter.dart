import '../models/models.dart';
import 'schema_query.dart';

class SchemaIndexFormatResult {
  const SchemaIndexFormatResult({
    required this.text,
    required this.totalTables,
    required this.shownTables,
  });

  final String text;
  final int totalTables;
  final int shownTables;

  bool get isPartial => shownTables < totalTables;
}

class SchemaSummaryFormatter {
  SchemaSummaryFormatter._();

  static const systemIndexMaxChars = 48000;
  static const toolDetailMaxChars = 600000;

  /// Table index only — safe for the system prompt on large databases.
  static SchemaIndexFormatResult formatSystemIndex(
    DatabaseSchema schema, {
    int maxChars = systemIndexMaxChars,
  }) {
    if (schema.tables.isEmpty) {
      return const SchemaIndexFormatResult(
        text: 'No tables found.',
        totalTables: 0,
        shownTables: 0,
      );
    }

    final header =
        'Database has ${schema.tables.length} tables. '
        'Use get_schema with schema, table, or search for column details.\n';
    final lines = schema.tables
        .map((table) => '${table.qualifiedName} (${table.columns.length} cols)')
        .toList();

    final truncated = _truncateLines(lines, maxChars: maxChars, header: header);
    return SchemaIndexFormatResult(
      text: truncated.text,
      totalTables: schema.tables.length,
      shownTables: truncated.shown,
    );
  }

  /// Tool output — detailed when filtered or small; compact index when too large.
  static String formatForTool(
    DatabaseSchema schema, {
    SchemaQuery query = const SchemaQuery(),
    int maxChars = toolDetailMaxChars,
  }) {
    final filtered = filterTables(schema, query);

    if (filtered.isEmpty) {
      if (!query.isEmpty) {
        return 'No tables matched schema=${query.schema ?? '*'}, '
            'table=${query.table ?? '*'}, search=${query.search ?? '*'}';
      }
      return 'No tables found.';
    }

    final detailed = _formatDetailed(filtered);
    if (!query.isEmpty || detailed.length <= maxChars) {
      return _truncateText(
        detailed,
        maxChars,
        suffix:
            '\n...[schema truncated — call get_schema with schema/table/search for a smaller slice]',
      );
    }

    return _truncateLines(
      filtered
          .map((table) => '${table.qualifiedName} (${table.columns.length} cols)')
          .toList(),
      maxChars: maxChars,
      header:
          'Schema has ${schema.tables.length} tables (${filtered.length} shown). '
          'Full column details omitted — call get_schema with schema, table, or search.\n',
    ).text;
  }

  static List<SchemaTable> filterTables(
    DatabaseSchema schema,
    SchemaQuery query,
  ) {
    if (query.isEmpty) {
      return schema.tables;
    }

    final tableNeedle = query.table?.toLowerCase();
    final schemaNeedle = query.schema?.toLowerCase();
    final searchNeedle = query.search?.toLowerCase();

    return schema.tables.where((table) {
      final qualified = table.qualifiedName.toLowerCase();
      final schemaName = table.schema.toLowerCase();
      final tableName = table.name.toLowerCase();

      if (schemaNeedle != null && schemaName != schemaNeedle) {
        return false;
      }

      if (tableNeedle != null) {
        final matchesTable = tableName == tableNeedle || qualified == tableNeedle;
        final matchesSuffix = qualified.endsWith('.$tableNeedle');
        if (!matchesTable && !matchesSuffix) {
          return false;
        }
      }

      if (searchNeedle != null && !qualified.contains(searchNeedle)) {
        return false;
      }

      return true;
    }).toList();
  }

  static String _formatDetailed(List<SchemaTable> tables) {
    if (tables.isEmpty) {
      return 'No tables found.';
    }

    final buffer = StringBuffer();
    for (final table in tables) {
      buffer.writeln('${table.qualifiedName} (${table.columns.length} columns)');
      for (final column in table.columns) {
        final flags = <String>[
          if (column.isPrimaryKey) 'PK',
          if (!column.isNullable) 'NOT NULL',
        ];
        final suffix = flags.isEmpty ? '' : ' [${flags.join(', ')}]';
        buffer.writeln('  - ${column.name}: ${column.dataType}$suffix');
      }
    }
    return buffer.toString().trim();
  }

  static ({String text, int shown}) _truncateLines(
    List<String> lines, {
    required int maxChars,
    required String header,
  }) {
    final buffer = StringBuffer(header);
    var shown = 0;

    for (final line in lines) {
      final next = '$line\n';
      if (buffer.length + next.length > maxChars) {
        break;
      }
      buffer.write(next);
      shown++;
    }

    final omitted = lines.length - shown;
    if (omitted > 0) {
      buffer.writeln('... ($omitted more tables not shown)');
    }

    return (text: buffer.toString().trim(), shown: shown);
  }

  static String _truncateText(String text, int maxChars, {String? suffix}) {
    if (text.length <= maxChars) {
      return text;
    }
    final suffixText = suffix ?? '\n...[truncated]';
    final keep = maxChars - suffixText.length;
    if (keep <= 0) {
      return suffixText.trim();
    }
    return '${text.substring(0, keep)}$suffixText';
  }
}
