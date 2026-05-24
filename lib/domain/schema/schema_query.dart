class SchemaQuery {
  const SchemaQuery({this.schema, this.table, this.search});

  final String? schema;
  final String? table;
  final String? search;

  bool get isEmpty =>
      (schema == null || schema!.isEmpty) &&
      (table == null || table!.isEmpty) &&
      (search == null || search!.isEmpty);

  factory SchemaQuery.fromArguments(Map<String, dynamic> arguments) {
    String? read(String key) {
      final value = arguments[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    }

    return SchemaQuery(
      schema: read('schema'),
      table: read('table'),
      search: read('search'),
    );
  }
}
