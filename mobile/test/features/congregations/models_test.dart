import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/congregations/models.dart';

void main() {
  test('Congregation.fromJson parses a null description', () {
    final congregation = Congregation.fromJson({
      'id': '1',
      'name': 'English Service',
      'description': null,
      'created_at': '2026-08-24T09:00:00Z',
    });

    expect(congregation.name, 'English Service');
    expect(congregation.description, isNull);
  });
}
