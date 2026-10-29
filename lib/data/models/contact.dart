class Contact {
  final int? id;
  final String name;
  final String? phone;
  final String countryCode;
  final String? note;
  final DateTime createdAt;

  const Contact({
    this.id,
    required this.name,
    this.phone,
    this.countryCode = '91',
    this.note,
    required this.createdAt,
  });

  factory Contact.fromMap(Map<String, Object?> m) => Contact(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        countryCode: m['country_code'] as String? ?? '91',
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'country_code': countryCode,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? countryCode,
    String? note,
    DateTime? createdAt,
  }) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        countryCode: countryCode ?? this.countryCode,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
}

