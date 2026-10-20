class ChitGroup {
  final int? id;
  final String name;
  final double contributionAmount;
  final String currency;
  final String period; // weekly | monthly
  final double interestRatePct;
  final String interestMode; // late_fee | recipient_pays
  final DateTime startDate;
  final int dueDay;
  final String status; // active | closed
  final DateTime createdAt;

  const ChitGroup({
    this.id,
    required this.name,
    required this.contributionAmount,
    this.currency = '₹',
    this.period = 'monthly',
    this.interestRatePct = 0,
    this.interestMode = 'late_fee',
    required this.startDate,
    this.dueDay = 1,
    this.status = 'active',
    required this.createdAt,
  });

  factory ChitGroup.fromMap(Map<String, Object?> m) => ChitGroup(
        id: m['id'] as int?,
        name: m['name'] as String,
        contributionAmount: (m['contribution_amount'] as num).toDouble(),
        currency: m['currency'] as String? ?? '₹',
        period: m['period'] as String,
        interestRatePct: (m['interest_rate_pct'] as num?)?.toDouble() ?? 0,
        interestMode: m['interest_mode'] as String? ?? 'late_fee',
        startDate: DateTime.parse(m['start_date'] as String),
        dueDay: m['due_day'] as int? ?? 1,
        status: m['status'] as String? ?? 'active',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'contribution_amount': contributionAmount,
        'currency': currency,
        'period': period,
        'interest_rate_pct': interestRatePct,
        'interest_mode': interestMode,
        'start_date': startDate.toIso8601String(),
        'due_day': dueDay,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  ChitGroup copyWith({double? interestRatePct, String? name, int? dueDay, String? status}) =>
      ChitGroup(
        id: id,
        name: name ?? this.name,
        contributionAmount: contributionAmount,
        currency: currency,
        period: period,
        interestRatePct: interestRatePct ?? this.interestRatePct,
        interestMode: interestMode,
        startDate: startDate,
        dueDay: dueDay ?? this.dueDay,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
