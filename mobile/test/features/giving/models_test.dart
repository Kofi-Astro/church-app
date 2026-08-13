import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/giving/models.dart';

void main() {
  test('GivingTransaction.fromJson parses a pending tithe', () {
    final transaction = GivingTransaction.fromJson({
      'id': '1',
      'amount': '100.50',
      'currency': 'GHS',
      'giving_type': 'tithe',
      'note': 'For the building fund',
      'status': 'pending',
      'created_at': '2026-08-12T23:00:00Z',
    });

    expect(transaction.amount, '100.50');
    expect(transaction.givingType, GivingType.tithe);
    expect(transaction.status, GivingStatus.pending);
  });

  test('GivingInitializeResult.fromJson parses the authorization url', () {
    final result = GivingInitializeResult.fromJson({
      'transaction_id': 't1',
      'authorization_url': 'https://paystack.test/pay/abc123',
      'reference': 'church-app-abc123',
    });

    expect(result.authorizationUrl, 'https://paystack.test/pay/abc123');
  });

  test('givingTypeFromString round-trips apiValue', () {
    for (final type in GivingType.values) {
      expect(givingTypeFromString(type.apiValue), type);
    }
  });
}
