// Data models for the Giving feature: what kind of gift, its status, a
// past transaction record, and the result of starting a new one.

/// The category of gift being given (chosen by the member in the form).
enum GivingType { tithe, offering, special, other }

/// Parses the backend's giving-type string into a [GivingType]; falls
/// back to [GivingType.other] for anything unrecognized.
GivingType givingTypeFromString(String value) => switch (value) {
      'tithe' => GivingType.tithe,
      'offering' => GivingType.offering,
      'special' => GivingType.special,
      _ => GivingType.other,
    };

extension GivingTypeLabel on GivingType {
  /// Text shown in the giving-type dropdown and history list.
  String get label => switch (this) {
        GivingType.tithe => 'Tithe',
        GivingType.offering => 'Offering',
        GivingType.special => 'Special gift',
        GivingType.other => 'Other',
      };

  /// Wire value sent to the backend — same as the enum's own name.
  String get apiValue => name;
}

/// Where a giving transaction is in its Paystack payment lifecycle.
enum GivingStatus { pending, success, failed }

/// Parses the backend's status string; unrecognized/missing values are
/// treated as [GivingStatus.pending] (payment not yet confirmed).
GivingStatus givingStatusFromString(String value) => switch (value) {
      'success' => GivingStatus.success,
      'failed' => GivingStatus.failed,
      _ => GivingStatus.pending,
    };

/// One past (or in-progress) giving transaction, as shown in the "Recent
/// giving" history list.
class GivingTransaction {
  final String id;
  /// Amount as a string (not a number) to avoid floating-point rounding
  /// issues with currency — displayed as-is, not parsed for math.
  final String amount;
  final String currency;
  final GivingType givingType;
  /// Optional note the giver attached; null if none was left.
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

  /// Builds a [GivingTransaction] from the JSON object the backend returns.
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

/// Response from starting a new giving transaction: the pending
/// transaction's id plus the Paystack URL to open to complete payment.
class GivingInitializeResult {
  final String transactionId;
  /// Paystack checkout page URL — opened in an external browser/app so
  /// the user can complete payment.
  final String authorizationUrl;
  /// Paystack's reference for this transaction, used to reconcile the
  /// payment webhook back to `transactionId` on the backend.
  final String reference;

  const GivingInitializeResult({
    required this.transactionId,
    required this.authorizationUrl,
    required this.reference,
  });

  /// Builds a [GivingInitializeResult] from the JSON object the backend
  /// returns.
  factory GivingInitializeResult.fromJson(Map<String, dynamic> json) => GivingInitializeResult(
        transactionId: json['transaction_id'] as String,
        authorizationUrl: json['authorization_url'] as String,
        reference: json['reference'] as String,
      );
}
