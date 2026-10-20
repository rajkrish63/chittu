class ChitRound {
  final int? id;
  final int groupId;
  final int seqNo;
  final int? accountableMemberId;
  final int? recipientMemberId;
  final DateTime dueDate;
  final String status; // open | collected | paid_out
  final DateTime? paidOutAt;

  const ChitRound({
    this.id,
    required this.groupId,
    required this.seqNo,
    this.accountableMemberId,
    this.recipientMemberId,
    required this.dueDate,
    this.status = 'open',
    this.paidOutAt,
  });

  factory ChitRound.fromMap(Map<String, Object?> m) => ChitRound(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        seqNo: m['seq_no'] as int,
        accountableMemberId: m['accountable_member_id'] as int?,
        recipientMemberId: m['recipient_member_id'] as int?,
        dueDate: DateTime.parse(m['due_date'] as String),
        status: m['status'] as String? ?? 'open',
        paidOutAt:
            m['paid_out_at'] == null ? null : DateTime.parse(m['paid_out_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'seq_no': seqNo,
        'accountable_member_id': accountableMemberId,
        'recipient_member_id': recipientMemberId,
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'paid_out_at': paidOutAt?.toIso8601String(),
      };
}
