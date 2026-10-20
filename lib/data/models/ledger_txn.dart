/// One money event. Never merge interest into the pot — separate rows keep the
/// ledger auditable (per design decision in the v1 blueprint).
class LedgerTxn {
  final int? id;
  final int roundId;
  final int memberId;
  final String type; // contribution | payout | interest | penalty | dividend
  final double amount;
  final bool isLate;
  final String? note;
  final DateTime createdAt;

  const LedgerTxn({
    this.id,
    required this.roundId,
    required this.memberId,
    required this.type,
    required this.amount,
    this.isLate = false,
    this.note,
    required this.createdAt,
  });

  factory LedgerTxn.fromMap(Map<String, Object?> m) => LedgerTxn(
        id: m['id'] as int?,
        roundId: m['round_id'] as int,
        memberId: m['member_id'] as int,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        isLate: (m['is_late'] as int?) == 1,
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'round_id': roundId,
        'member_id': memberId,
        'type': type,
        'amount': amount,
        'is_late': isLate ? 1 : 0,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}
