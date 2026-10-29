import '../../core/money/money.dart';
import '../../domain/models/enums.dart';

class ChitGroup {
  final int? id;
  final String name;
  final int installmentPaise;
  final String currency;
  final String period; // 'weekly' | 'monthly'
  final PayoutMethod payoutMethod;
  final PenaltyMode penaltyMode;
  final int rateBps; // 100 bps = 1.0%
  final int graceDays;
  final int commissionBps;
  final String status; // 'active' | 'closed'
  final DateTime createdAt;

  const ChitGroup({
    this.id,
    required this.name,
    required this.installmentPaise,
    this.currency = '₹',
    this.period = 'monthly',
    this.payoutMethod = PayoutMethod.fixedOrder,
    this.penaltyMode = PenaltyMode.lateFee,
    this.rateBps = 0,
    this.graceDays = 0,
    this.commissionBps = 0,
    this.status = 'active',
    required this.createdAt,
  });

  Money get installment => Money.fromPaise(installmentPaise);
  double get ratePct => rateBps / 100.0;
  double get commissionPct => commissionBps / 100.0;
  bool get isActive => status == 'active';

  factory ChitGroup.fromMap(Map<String, Object?> m) {
    final rawAmount = m['installment_paise'] ?? m['contribution_amount'];
    final int paise = rawAmount is int
        ? rawAmount
        : ((rawAmount as num).toDouble() * 100).round();

    final rawRate = m['rate_bps'] ?? m['interest_rate_pct'];
    final int bps = rawRate is int
        ? rawRate
        : ((rawRate as num? ?? 0.0).toDouble() * 100).round();

    return ChitGroup(
      id: m['id'] as int?,
      name: m['name'] as String,
      installmentPaise: paise,
      currency: m['currency'] as String? ?? '₹',
      period: m['period'] as String? ?? 'monthly',
      payoutMethod: PayoutMethod.fromString(m['payout_method'] as String? ?? 'fixed_order'),
      penaltyMode: PenaltyMode.fromString(m['penalty_mode'] as String? ?? m['interest_mode'] as String? ?? 'late_fee'),
      rateBps: bps,
      graceDays: m['grace_days'] as int? ?? 0,
      commissionBps: m['commission_bps'] as int? ?? 0,
      status: m['status'] as String? ?? 'active',
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'installment_paise': installmentPaise,
        'currency': currency,
        'period': period,
        'payout_method': payoutMethod.value,
        'penalty_mode': penaltyMode.value,
        'rate_bps': rateBps,
        'grace_days': graceDays,
        'commission_bps': commissionBps,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  ChitGroup copyWith({
    int? id,
    String? name,
    int? installmentPaise,
    String? currency,
    String? period,
    PayoutMethod? payoutMethod,
    PenaltyMode? penaltyMode,
    int? rateBps,
    int? graceDays,
    int? commissionBps,
    String? status,
    DateTime? createdAt,
  }) =>
      ChitGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        installmentPaise: installmentPaise ?? this.installmentPaise,
        currency: currency ?? this.currency,
        period: period ?? this.period,
        payoutMethod: payoutMethod ?? this.payoutMethod,
        penaltyMode: penaltyMode ?? this.penaltyMode,
        rateBps: rateBps ?? this.rateBps,
        graceDays: graceDays ?? this.graceDays,
        commissionBps: commissionBps ?? this.commissionBps,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
