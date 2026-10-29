import '../../core/money/money.dart';
import '../../domain/models/enums.dart';

/// Immutable financial ledger transaction row.
/// Never mutates rows; corrections use compensatory reversal rows linking `reversesTxnId`.
class LedgerTxn {
  final int? id;
  final int roundId;
  final int membershipId;
  final TransactionType type;
  final int amountPaise;
  final bool isLate;
  final String? receiptNo;
  final int? reversesTxnId;
  final String? note;
  final DateTime createdAt;

  const LedgerTxn({
    this.id,
    required this.roundId,
    required this.membershipId,
    required this.type,
    required this.amountPaise,
    this.isLate = false,
    this.receiptNo,
    this.reversesTxnId,
    this.note,
    required this.createdAt,
  });

  Money get amount => Money.fromPaise(amountPaise);
  bool get isReversal => reversesTxnId != null;

  factory LedgerTxn.fromMap(Map<String, Object?> m) {
    final rawAmount = m['amount_paise'] ?? m['amount'];
    final int paise = rawAmount is int
        ? rawAmount
        : ((rawAmount as num).toDouble() * 100).round();

    return LedgerTxn(
      id: m['id'] as int?,
      roundId: m['round_id'] as int,
      membershipId: m['membership_id'] as int,
      type: TransactionType.fromString(m['type'] as String),
      amountPaise: paise,
      isLate: (m['is_late'] as int? ?? 0) == 1,
      receiptNo: m['receipt_no'] as String?,
      reversesTxnId: m['reverses_txn_id'] as int?,
      note: m['note'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'round_id': roundId,
        'membership_id': membershipId,
        'type': type.value,
        'amount_paise': amountPaise,
        'is_late': isLate ? 1 : 0,
        'receipt_no': receiptNo,
        'reverses_txn_id': reversesTxnId,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  LedgerTxn copyWith({
    int? id,
    int? roundId,
    int? membershipId,
    TransactionType? type,
    int? amountPaise,
    bool? isLate,
    String? receiptNo,
    int? reversesTxnId,
    String? note,
    DateTime? createdAt,
  }) =>
      LedgerTxn(
        id: id ?? this.id,
        roundId: roundId ?? this.roundId,
        membershipId: membershipId ?? this.membershipId,
        type: type ?? this.type,
        amountPaise: amountPaise ?? this.amountPaise,
        isLate: isLate ?? this.isLate,
        receiptNo: receiptNo ?? this.receiptNo,
        reversesTxnId: reversesTxnId ?? this.reversesTxnId,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
}
