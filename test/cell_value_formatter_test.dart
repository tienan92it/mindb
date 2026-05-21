import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/postgres/cell_value_formatter.dart';
import 'package:postgres/postgres.dart';

void main() {
  test('formatCellValue decodes UndecodedBytes as enum text', () {
    final value = UndecodedBytes(
      typeOid: 12345,
      isBinary: false,
      bytes: Uint8List.fromList(utf8.encode('active')),
      encoding: utf8,
    );

    expect(formatCellValue(value), 'active');
    expect(value.toString(), isNot(contains('active')));
  });

  test('normalizeCellValue converts UndecodedBytes to String', () {
    final value = UndecodedBytes(
      typeOid: 12345,
      isBinary: false,
      bytes: Uint8List.fromList(utf8.encode('pending')),
      encoding: utf8,
    );

    expect(normalizeCellValue(value), 'pending');
  });

  test('formatCellValue handles null and plain values', () {
    expect(formatCellValue(null), 'NULL');
    expect(formatCellValue(42), '42');
    expect(formatCellValue('ready'), 'ready');
  });
}
