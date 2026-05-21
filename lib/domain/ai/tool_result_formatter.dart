import '../models/models.dart';
import '../../data/postgres/cell_value_formatter.dart';

/// Formats tool output so the model treats it as authoritative evidence.
class ToolResultFormatter {
  const ToolResultFormatter._();

  static String schema(String summary) {
    if (summary.trim().isEmpty || summary.trim() == 'No tables found.') {
      return '''
source: get_schema
status: success
no_data: true
schema: (empty)
instruction: Do not invent tables. Report schema as empty or unknown.
'''.trim();
    }

    return '''
source: get_schema
status: success
no_data: false
schema:
$summary
instruction: Only reference tables and columns listed above.
'''.trim();
  }

  static String sqlError(String error) {
    return '''
source: execute_sql
status: error
no_data: true
error: $error
instruction: Do not invent a result. Report the error or answer Unknown.
'''.trim();
  }

  static String sqlResult(QueryResult result) {
    if (!result.isSelect) {
      return '''
source: execute_sql
status: success
no_data: false
rows_affected: ${result.rowsAffected ?? 0}
instruction: Report only the rows_affected value above.
'''.trim();
    }

    if (result.rows.isEmpty) {
      return '''
source: execute_sql
status: success
no_data: true
row_count: 0
columns: ${result.columns.join(', ')}
rows: (none)
instruction: Answer "No matching records" or Unknown. Do not invent rows.
'''.trim();
    }

    final buffer = StringBuffer()
      ..writeln('source: execute_sql')
      ..writeln('status: success')
      ..writeln('no_data: false')
      ..writeln('row_count: ${result.rows.length}')
      ..writeln('columns: ${result.columns.join(', ')}');

    if (result.rows.length > 20) {
      buffer.writeln('truncated: true');
      buffer.writeln('shown_rows: 20');
    }

    buffer.writeln('rows:');
    for (final row in result.rows.take(20)) {
      buffer.writeln(
        row.map((value) => formatCellValue(value)).join(' | '),
      );
    }

    if (result.rows.length > 20) {
      buffer.writeln('... (${result.rows.length - 20} more rows not shown)');
    }

    buffer.writeln(
      'instruction: Report ONLY values from rows above. Do not add or infer data.',
    );

    return buffer.toString().trim();
  }

  static String explainResult(List<String> lines) {
    if (lines.isEmpty) {
      return '''
source: explain_sql
status: success
no_data: true
plan: (empty)
instruction: Do not invent an execution plan.
'''.trim();
    }

    return '''
source: explain_sql
status: success
no_data: false
plan:
${lines.join('\n')}
instruction: Describe only this plan. Do not infer row counts or data values.
'''.trim();
  }
}
