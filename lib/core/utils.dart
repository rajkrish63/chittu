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
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return 'https://wa.me/$digits?text=${Uri.encodeComponent(message)}';
}

Future<void> openWhatsApp(String phone, String message) async {
  final uri = Uri.parse(waUrl(phone, message));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Reminder message per v1 blueprint: "Anna, Nov சீட் ₹1,000 pending — round 4 pot waiting"
String reminderMessage({
  required String memberName,
  required int roundNo,
  required double amount,
  required String currency,
}) =>
    '$memberName, $roundNo-வது ரவுண்டு சீட்டுக்கு ${formatMoney(currency, amount)} இன்னும் pending. '
    'தயவுசெய்து செலுத்துங்கள் — pot காத்திருக்கு 🙏';

/// Monthly due date: clamp due_day to the month's length (e.g. 31 -> 28 in Feb).
DateTime monthlyDueDate(DateTime start, int dueDay, int monthsAfter) {
  final y = start.year;
  final m = start.month + monthsAfter;
  final firstOfTarget = DateTime(y, m, 1);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, dueDay.clamp(1, lastDay));
}
