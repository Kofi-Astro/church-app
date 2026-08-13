enum GivingType { tithe, offering, special, other }

GivingType givingTypeFromString(String value) => switch (value) {
      'tithe' => GivingType.tithe,
      'offering' => GivingType.offering,
      'special' => GivingType.special,
      _ => GivingType.other,
    };

extension GivingTypeLabel on GivingType {
  String get label => switch (this) {
        GivingType.tithe => 'Tithe',
        GivingType.offering => 'Offering',
        GivingType.special => 'Special gift',
        GivingType.other => 'Other',
      };

  String get apiValue => name;
}

enum GivingStatus { pending, success, failed }

GivingStatus givingStatusFromString(String value) => switch (value) {
      'success' => GivingStatus.success,
      'failed' => GivingStatus.failed,
      _ => GivingStatus.pending,
    };

class GivingTransaction {
  final String id;
  final String amount;
  final String currency;
  final GivingType givingType;
  final String? note;
  final GivingStatus status;
  final DateTime createdAt;

  const GivingTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.givingType,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory GivingTransaction.fromJson(Map<String, dynamic> json) => GivingTransaction(
        id: json['id'] as String,
        amount: json['amount'] as String,
        currency: json['currency'] as String,
        givingType: givingTypeFromString(json['giving_type'] as String),
        note: json['note'] as String?,
        status: givingStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class GivingInitializeResult {
  final String transactionId;
  final String authorizationUrl;
  final String reference;

  const GivingInitializeResult({
    required this.transactionId,
    required this.authorizationUrl,
    required this.reference,
  });

  factory GivingInitializeResult.fromJson(Map<String, dynamic> json) => GivingInitializeResult(
        transactionId: json['transaction_id'] as String,
        authorizationUrl: json['authorization_url'] as String,
        reference: json['reference'] as String,
      );
}
