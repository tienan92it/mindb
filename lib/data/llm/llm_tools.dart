import '../../domain/ports/ports.dart';

const mindbLlmTools = <LlmToolDefinition>[
  LlmToolDefinition(
    name: 'get_schema',
    description:
        'Fetch the live PostgreSQL schema (tables, columns). Required before referencing structure. Do not assume tables exist without calling this.',
    parameters: {
      'type': 'object',
      'properties': {},
    },
  ),
  LlmToolDefinition(
    name: 'execute_sql',
    description:
        'Run SQL and return real rows. You MUST call this before stating any data values, counts, or lists. If row_count is 0, report no data — never invent rows.',
    parameters: {
      'type': 'object',
      'properties': {
        'sql': {
          'type': 'string',
          'description': 'PostgreSQL SELECT (or approved write) statement.',
        },
      },
      'required': ['sql'],
    },
  ),
  LlmToolDefinition(
    name: 'explain_sql',
    description:
        'Return the EXPLAIN plan for a query. Does not return table data — do not infer row values from the plan.',
    parameters: {
      'type': 'object',
      'properties': {
        'sql': {
          'type': 'string',
          'description': 'The SQL query to explain.',
        },
      },
      'required': ['sql'],
    },
  ),
];
