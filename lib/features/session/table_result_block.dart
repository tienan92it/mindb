import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/postgres/cell_value_formatter.dart';
import '../../domain/models/models.dart';
import '../connections/connections_screen.dart';

class TableResultBlock extends StatelessWidget {
  const TableResultBlock({super.key, required this.result});

  final QueryResult result;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12);

    if (!result.isSelect) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: ConnectionsScreen.muted.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'OK (${result.rowsAffected ?? 0} rows affected, ${result.duration.inMilliseconds}ms)',
          style: mono.copyWith(color: ConnectionsScreen.accent),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ConnectionsScreen.muted.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A1A)),
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          columns: result.columns
              .map(
                (column) => DataColumn(
                  label: Text(
                    column,
                    style: mono.copyWith(
                      color: ConnectionsScreen.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: result.rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (value) => DataCell(
                          Text(
                            formatCellValue(value),
                            style: mono.copyWith(color: Colors.white70),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
