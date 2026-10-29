import '../../core/money/money.dart';

/// Calculation result for overdue installments.
class LateFeeResult {
  final Money baseInstallment;
  final int daysOverdue;
  final Money lateFee;
  final Money flatFee;
  final Money totalDue;
  final bool isOverdue;

  const LateFeeResult({
    required this.baseInstallment,
    required this.daysOverdue,
    required this.lateFee,
    required this.flatFee,
    required this.totalDue,
    required this.isOverdue,
  });
}

/// Pure-Dart late-fee calculation service.
/// Zero Flutter imports.
/// Formula:
///   Late Fee (paise) = (Installment * (Rate_bps / 10000) / 30) * Overdue_Days + Flat_Fee
/// Stated rounding rule: rounded to the nearest whole Rupee (100 paise) for clean community collections.
class LateFeeCalculator {
  static LateFeeResult compute({
    required int installmentPaise,
    required int rateBps, // e.g. 200 bps = 2.0% per month
    required DateTime dueDate,
    int graceDays = 0,
    int flatFeePaise = 0,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final rawDays = today.difference(due).inDays;
    final overdueDays = rawDays > graceDays ? rawDays : 0;

    if (overdueDays <= 0 || (rateBps <= 0 && flatFeePaise <= 0)) {
      return LateFeeResult(
        baseInstallment: Money.fromPaise(installmentPaise),
        daysOverdue: 0,
        lateFee: Money.zero,
        flatFee: Money.zero,
        totalDue: Money.fromPaise(installmentPaise),
        isOverdue: false,
      );
    }

    // Daily rate = rateBps / (10000 * 30) = rateBps / 300,000
    // Unrounded raw fee in paise
    final rawFee = (installmentPaise * rateBps * overdueDays) / 300000.0;

    // Stated rounding rule: round to nearest whole Rupee (100 paise)
    final feePaise = ((rawFee / 100).round() * 100) + flatFeePaise;

    return LateFeeResult(
      baseInstallment: Money.fromPaise(installmentPaise),
      daysOverdue: overdueDays,
      lateFee: Money.fromPaise(feePaise),
      flatFee: Money.fromPaise(flatFeePaise),
      totalDue: Money.fromPaise(installmentPaise + feePaise),
      isOverdue: true,
    );
  }
}

