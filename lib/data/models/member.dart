class Member {
  final int? id;
  final int groupId;
  final String name;
  final String? phone;
  final int payoutOrder; // 1-based; this order IS the fixed rotation
  final String role; // admin | member
  final DateTime joinedAt;

  const Member({
    this.id,
    this.groupId = 0,
    required this.name,
    this.phone,
    required this.payoutOrder,
    this.role = 'member',
    required this.joinedAt,
  });

  factory Member.fromMap(Map<String, Object?> m) => Member(
        id: m['id'] as int?,
        groupId: m['group_id'] as int? ?? 0,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        payoutOrder: m['payout_order'] as int,
        role: m['role'] as String? ?? 'member',
        joinedAt: DateTime.parse(m['joined_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'name': name,
        'phone': phone,
        'payout_order': payoutOrder,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
      };

  Member copyWith({int? groupId, String? name, String? phone, int? payoutOrder}) => Member(
        id: id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        payoutOrder: payoutOrder ?? this.payoutOrder,
        role: role,
        joinedAt: joinedAt,
      );
}
