import '../../domain/ports/ports.dart';

const mindbLlmTools = <LlmToolDefinition>[
  LlmToolDefinition(
    name: 'get_schema',
    description:
        'Fetch PostgreSQL schema. On large databases, pass schema/table/search to get column details for a subset. Unfiltered calls return a table index when full details would exceed context limits.',
    parameters: {
      'type': 'object',
      'properties': {
        'schema': {
          'type': 'string',
          'description': 'PostgreSQL schema name (e.g. public).',
        },
        'table': {
          'type': 'string',
          'description':
              'Table name, optionally schema-qualified (e.g. users or public.users).',
        },
        'search': {
          'type': 'string',
          'description':
              'Case-insensitive substring filter on qualified table names.',
        },
      },
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
