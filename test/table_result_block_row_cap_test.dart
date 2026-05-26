import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/table_result_block.dart';

void main() {
  testWidgets('shows row-cap footer when cap applied', (tester) async {
    const result = QueryResult(
      columns: ['id'],
      rows: [
        [1],
        [2],
        [3],
      ],
      duration: Duration.zero,
      rowCapApplied: true,
      appliedRowCap: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableResultBlock(result: result),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(result.rowCapNoticeText!), findsOneWidget);
  });

  testWidgets('hides row-cap footer when cap not applied', (tester) async {
    const result = QueryResult(
      columns: ['id'],
      rows: [
        [1],
      ],
      duration: Duration.zero,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TableResultBlock(result: result),
        ),
      ),
    );

    expect(find.textContaining('Row cap'), findsNothing);
  });
}
