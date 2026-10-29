import 'contact.dart';

class Membership {
  final int? id;
  final int groupId;
  final int contactId;
  final int shareNo;
  final int payoutOrder;
  final bool prized;
  final String? guarantorNote;

  /// Optional joined contact for display
  final Contact? contact;

  const Membership({
    this.id,
    required this.groupId,
    required this.contactId,
    this.shareNo = 1,
    required this.payoutOrder,
    this.prized = false,
    this.guarantorNote,
    this.contact,
  });

  factory Membership.fromMap(Map<String, Object?> m, [Contact? contact]) => Membership(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        contactId: m['contact_id'] as int,
        shareNo: m['share_no'] as int? ?? 1,
        payoutOrder: m['payout_order'] as int,
        prized: (m['prized'] as int? ?? 0) == 1,
        guarantorNote: m['guarantor_note'] as String?,
        contact: contact,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'contact_id': contactId,
        'share_no': shareNo,
        'payout_order': payoutOrder,
        'prized': prized ? 1 : 0,
        'guarantor_note': guarantorNote,
      };

  Membership copyWith({
    int? id,
    int? groupId,
    int? contactId,
    int? shareNo,
    int? payoutOrder,
    bool? prized,
    String? guarantorNote,
    Contact? contact,
  }) =>
      Membership(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        contactId: contactId ?? this.contactId,
        shareNo: shareNo ?? this.shareNo,
        payoutOrder: payoutOrder ?? this.payoutOrder,
        prized: prized ?? this.prized,
        guarantorNote: guarantorNote ?? this.guarantorNote,
        contact: contact ?? this.contact,
      );
}

