import '../../core/money/money.dart';
import '../../domain/models/enums.dart';

class ChitRound {
  final int? id;
  final int groupId;
  final int seqNo;
  final int? recipientMembershipId;
  final DateTime dueDate;
  final RoundStatus status;
  final int auctionDiscountPaise;
  final DateTime? paidOutAt;

  const ChitRound({
    this.id,
    required this.groupId,
    required this.seqNo,
    this.recipientMembershipId,
    required this.dueDate,
    this.status = RoundStatus.open,
    this.auctionDiscountPaise = 0,
    this.paidOutAt,
  });

  Money get auctionDiscount => Money.fromPaise(auctionDiscountPaise);
  bool get isOpen => status == RoundStatus.open;
  bool get isCollected => status == RoundStatus.collected;
  bool get isPaidOut => status == RoundStatus.paidOut;

  factory ChitRound.fromMap(Map<String, Object?> m) => ChitRound(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        seqNo: m['seq_no'] as int,
        recipientMembershipId: m['recipient_membership_id'] as int?,
        dueDate: DateTime.parse(m['due_date'] as String),
        status: RoundStatus.fromString(m['status'] as String? ?? 'open'),
        auctionDiscountPaise: m['auction_discount_paise'] as int? ?? 0,
        paidOutAt: m['paid_out_at'] == null
            ? null
            : DateTime.parse(m['paid_out_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'seq_no': seqNo,
        'recipient_membership_id': recipientMembershipId,
        'due_date': dueDate.toIso8601String(),
        'status': status.value,
        'auction_discount_paise': auctionDiscountPaise,
        'paid_out_at': paidOutAt?.toIso8601String(),
      };

  ChitRound copyWith({
    int? id,
    int? groupId,
    int? seqNo,
    int? recipientMembershipId,
    DateTime? dueDate,
    RoundStatus? status,
    int? auctionDiscountPaise,
    DateTime? paidOutAt,
  }) =>
      ChitRound(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        seqNo: seqNo ?? this.seqNo,
        recipientMembershipId: recipientMembershipId ?? this.recipientMembershipId,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        auctionDiscountPaise: auctionDiscountPaise ?? this.auctionDiscountPaise,
        paidOutAt: paidOutAt ?? this.paidOutAt,
      );
}
