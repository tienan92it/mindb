import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/schema/schema_service.dart';

void main() {
  test('columns schema SQL qualifies joined column names', () {
    expect(
      SchemaService.columnsSql,
      contains('SELECT c.table_schema, c.table_name, c.column_name'),
    );
    expect(SchemaService.columnsSql, isNot(contains('\nSELECT table_schema,')));
  });
}
