import '../../core/money/money.dart';
import '../models/enums.dart';
import '../models/member_balance.dart';

class RawTxnRecord {
  final int id;
  final int roundId;
  final int membershipId;
  final TransactionType type;
  final int amountPaise;
  final bool isLate;
  final int? reversesTxnId;

  const RawTxnRecord({
    required this.id,
    required this.roundId,
    required this.membershipId,
    required this.type,
    required this.amountPaise,
    this.isLate = false,
    this.reversesTxnId,
  });
}

/// Pure-Dart ledger aggregation service.
/// Derives balances dynamically from the immutable append-only transaction stream.
/// Never mutates rows; cancels out transactions referenced by `reversesTxnId`.
class LedgerAggregator {
  /// Filters out both reversed transactions and their reversal pairs to yield active records.
  static List<RawTxnRecord> getActiveTransactions(List<RawTxnRecord> allTxns) {
    final reversedIds = <int>{};
    for (final txn in allTxns) {
      if (txn.reversesTxnId != null) {
        reversedIds.add(txn.reversesTxnId!);
        reversedIds.add(txn.id);
      }
    }
    return allTxns.where((t) => !reversedIds.contains(t.id)).toList();
  }

  /// Computes a member's full financial position.
  static MemberBalance aggregateMemberBalance({
    required int membershipId,
    required int totalRounds,
    required int installmentPaise,
    required bool isPrized,
    String? guarantorNote,
    required List<RawTxnRecord> memberTxns,
    required int pastDueOrActiveRoundsCount,
  }) {
    final active = getActiveTransactions(memberTxns);

    int totalPaidPaise = 0;
    int totalReceivedPaise = 0;
    int contributionsCount = 0;

    for (final txn in active) {
      switch (txn.type) {
        case TransactionType.contribution:
        case TransactionType.interest:
          totalPaidPaise += txn.amountPaise;
          if (txn.type == TransactionType.contribution) {
            contributionsCount++;
          }
          break;
        case TransactionType.payout:
        case TransactionType.dividend:
          totalReceivedPaise += txn.amountPaise;
          break;
        case TransactionType.commission:
          // Commission is organizer-specific
          break;
      }
    }

    // Arrears = (past due rounds - contributions paid so far) * installment
    final unpaidRounds = pastDueOrActiveRoundsCount - contributionsCount;
    final arrearsPaise = unpaidRounds > 0 ? unpaidRounds * installmentPaise : 0;

    // Post-prize outstanding obligation = remaining future installments
    final remainingInstallments = totalRounds - contributionsCount;
    final postPrizePaise = isPrized && remainingInstallments > 0
        ? remainingInstallments * installmentPaise
        : 0;

    return MemberBalance(
      paidSoFar: Money.fromPaise(totalPaidPaise),
      receivedSoFar: Money.fromPaise(totalReceivedPaise),
      arrears: Money.fromPaise(arrearsPaise),
      isPrized: isPrized,
      postPrizeOutstanding: Money.fromPaise(postPrizePaise),
      guarantorNote: guarantorNote,
    );
  }
}

