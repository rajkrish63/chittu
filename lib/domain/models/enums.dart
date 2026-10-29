/// Domain enums for Chit Notebook (ROSCA).
/// Pure Dart — zero Flutter dependencies.
library;

enum PayoutMethod {
  fixedOrder('fixed_order'),
  lottery('lottery'),
  auction('auction');

  final String value;
  const PayoutMethod(this.value);

  factory PayoutMethod.fromString(String val) {
    return PayoutMethod.values.firstWhere(
      (e) => e.value == val,
      orElse: () => PayoutMethod.fixedOrder,
    );
  }
}

enum PenaltyMode {
  none('none'),
  lateFee('late_fee'),
  recipientPays('recipient_pays');

  final String value;
  const PenaltyMode(this.value);

  factory PenaltyMode.fromString(String val) {
    return PenaltyMode.values.firstWhere(
      (e) => e.value == val,
      orElse: () => PenaltyMode.lateFee,
    );
  }
}

enum RoundStatus {
  open('open'),
  collected('collected'),
  paidOut('paid_out');

  final String value;
  const RoundStatus(this.value);

  factory RoundStatus.fromString(String val) {
    return RoundStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RoundStatus.open,
    );
  }

  bool get isOpen => this == RoundStatus.open;
  bool get isCollected => this == RoundStatus.collected;
  bool get isPaidOut => this == RoundStatus.paidOut;
}

enum TransactionType {
  contribution('contribution'),
  payout('payout'),
  interest('interest'),
  dividend('dividend'),
  commission('commission');

  final String value;
  const TransactionType(this.value);

  factory TransactionType.fromString(String val) {
    return TransactionType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TransactionType.contribution,
    );
  }
}
