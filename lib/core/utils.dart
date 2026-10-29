import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String formatMoney(String currency, double amount) {
  final f = NumberFormat('#,##0');
  final sign = amount < 0 ? '-' : '';
  return '$sign$currency${f.format(amount.abs())}';
}

String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

/// Build a wa.me deep link — no server, no SMS cost. Members need no app install.
String waUrl(String phone, String message) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    digits = '91$digits';
  }
  return 'https://wa.me/$digits?text=${Uri.encodeComponent(message)}';
}

Future<void> openWhatsApp(String phone, String message) async {
  final uri = Uri.parse(waUrl(phone, message));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Dynamic late-fee calculation data model
class LateFeeCalculation {
  final double baseAmount;
  final int daysOverdue;
  final double dailyRatePct;
  final double lateFee;
  final double totalDue;
  final bool isOverdue;

  const LateFeeCalculation({
    required this.baseAmount,
    required this.daysOverdue,
    required this.dailyRatePct,
    required this.lateFee,
    required this.totalDue,
    required this.isOverdue,
  });

  /// Factory computing late fee based on overdue calendar days:
  /// daily rate = (monthlyRatePct / 100) / 30
  /// fee = baseAmount * dailyRate * daysOverdue
  factory LateFeeCalculation.compute({
    required double baseAmount,
    required DateTime dueDate,
    required double monthlyRatePct,
    int gracePeriodDays = 0,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final diff = today.difference(due).inDays;
    final overdueDays = diff > gracePeriodDays ? diff : 0;

    if (overdueDays <= 0 || monthlyRatePct <= 0) {
      return LateFeeCalculation(
        baseAmount: baseAmount,
        daysOverdue: 0,
        dailyRatePct: 0,
        lateFee: 0,
        totalDue: baseAmount,
        isOverdue: false,
      );
    }

    final dailyRate = (monthlyRatePct / 100) / 30;
    final fee = (baseAmount * dailyRate * overdueDays).roundToDouble();

    return LateFeeCalculation(
      baseAmount: baseAmount,
      daysOverdue: overdueDays,
      dailyRatePct: dailyRate * 100,
      lateFee: fee,
      totalDue: baseAmount + fee,
      isOverdue: true,
    );
  }
}

/// Reminder message with optional overdue details
String reminderMessage({
  required String memberName,
  required int roundNo,
  required double amount,
  required String currency,
  DateTime? dueDate,
  LateFeeCalculation? lateFeeCalc,
}) {
  if (lateFeeCalc != null && lateFeeCalc.isOverdue && lateFeeCalc.lateFee > 0) {
    return '$memberName, payment for Round $roundNo is overdue by ${lateFeeCalc.daysOverdue} days.\n'
        '• Installment: ${formatMoney(currency, amount)}\n'
        '• Late Fee: ${formatMoney(currency, lateFeeCalc.lateFee)}\n'
        '• Total Due: ${formatMoney(currency, lateFeeCalc.totalDue)}\n'
        'Please pay at your earliest convenience — pot is waiting 🙏';
  }

  final dueStr = dueDate != null ? ' (due: ${formatDate(dueDate)})' : '';
  return '$memberName, payment for Round $roundNo (${formatMoney(currency, amount)})$dueStr is pending. '
      'Please pay at your earliest convenience — pot is waiting 🙏';
}

/// Monthly due date: clamp due_day to the month's length (e.g. 31 -> 28 in Feb).
DateTime monthlyDueDate(DateTime start, int dueDay, int monthsAfter) {
  final y = start.year;
  final m = start.month + monthsAfter;
  final firstOfTarget = DateTime(y, m, 1);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, dueDay.clamp(1, lastDay));
}

/// Recipient-pays interest: pot * rate%, split as dividends across other members.
({double interest, double dividend}) calculateRecipientPays({
  required double pot,
  required double interestRatePct,
  required int totalMembers,
}) {
  if (interestRatePct <= 0 || totalMembers <= 1) {
    return (interest: 0.0, dividend: 0.0);
  }
  final interest = pot * interestRatePct / 100;
  final dividend = interest / (totalMembers - 1);
  return (interest: interest, dividend: dividend);
}
