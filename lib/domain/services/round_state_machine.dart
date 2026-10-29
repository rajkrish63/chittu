import '../models/enums.dart';

/// Pure-Dart state machine for Chit Round transitions.
/// Enforces:
/// 1. open: round is active, collections ongoing (paidMembers < totalMembers).
/// 2. collected: all N/N members have contributed; pot is 100% funded.
/// 3. paid_out: pot has been disbursed to the round recipient.
/// 4. Arrears tolerance: payout can occur before 100% collected (foreman advance).
///    Late contributions can still be recorded after payout without deadlock.
class RoundStateMachine {
  /// Computes the current lifecycle state from aggregate parameters.
  static RoundStatus resolveStatus({
    required int totalMembers,
    required int paidMembers,
    required bool isPaidOut,
  }) {
    if (isPaidOut) return RoundStatus.paidOut;
    if (paidMembers >= totalMembers && totalMembers > 0) return RoundStatus.collected;
    return RoundStatus.open;
  }

  /// Validates whether a pot can be disbursed.
  /// Payout is allowed even with arrears, but returns a warning count.
  static ({bool allowed, bool hasArrears, int pendingCount}) evaluatePayoutEligibility({
    required int totalMembers,
    required int paidMembers,
    required bool isPaidOut,
  }) {
    if (isPaidOut) {
      return (allowed: false, hasArrears: false, pendingCount: 0);
    }
    final pending = totalMembers - paidMembers;
    return (
      allowed: true,
      hasArrears: pending > 0,
      pendingCount: pending > 0 ? pending : 0,
    );
  }

  /// Whether a member's installment contribution can be recorded.
  /// Always allowed, even if already paid_out (solves arrears deadlock).
  static bool canRecordContribution({required bool isAlreadyPaid}) {
    return !isAlreadyPaid;
  }
}

