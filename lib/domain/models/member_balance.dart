import '../../core/money/money.dart';

/// Pure-Dart financial balance model for a member in a chit group.
/// Derived dynamically from immutable ledger transactions.
class MemberBalance {
  /// Total cash paid by member: contributions + interest/late fees.
  final Money paidSoFar;

  /// Total cash received by member: pot payouts + dividends.
  final Money receivedSoFar;

  /// Unpaid installments from past and active rounds.
  final Money arrears;

  /// Whether this membership has won/taken the pot.
  final bool isPrized;

  /// Post-prize outstanding obligation (Total group commitment - total contributed so far).
  final Money postPrizeOutstanding;

  /// Optional guarantor or security note.
  final String? guarantorNote;

  const MemberBalance({
    required this.paidSoFar,
    required this.receivedSoFar,
    required this.arrears,
    this.isPrized = false,
    required this.postPrizeOutstanding,
    this.guarantorNote,
  });

  /// Net balance in plain language:
  /// If positive: Received more than paid (borrower/winner position).
  /// If negative: Contributed more than received (saver position).
  Money get netBalance => receivedSoFar - paidSoFar;

  bool get hasArrears => arrears.isPositive;
}

