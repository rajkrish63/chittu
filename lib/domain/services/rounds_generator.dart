import '../models/enums.dart';

class GeneratedRoundData {
  final int seqNo;
  final DateTime dueDate;
  final int? recipientMembershipId;
  final RoundStatus status;

  const GeneratedRoundData({
    required this.seqNo,
    required this.dueDate,
    this.recipientMembershipId,
    this.status = RoundStatus.open,
  });
}

/// Pure-Dart rounds generation service.
/// Zero Flutter dependencies.
class RoundsGenerator {
  /// Generates the schedule of rounds for a newly created chit group.
  static List<GeneratedRoundData> generateSchedule({
    required DateTime startDate,
    required int dueDay,
    required int totalMembers,
    required String period, // 'monthly' | 'weekly'
    required PayoutMethod payoutMethod,
    Map<int, int>? payoutOrderToMembershipId, // payoutOrder -> membershipId
  }) {
    final list = <GeneratedRoundData>[];

    for (var seq = 1; seq <= totalMembers; seq++) {
      final dueDate = period == 'weekly'
          ? _weeklyDueDate(startDate, seq - 1)
          : _monthlyDueDate(startDate, dueDay, seq - 1);

      int? recipientId;
      if (payoutMethod == PayoutMethod.fixedOrder && payoutOrderToMembershipId != null) {
        recipientId = payoutOrderToMembershipId[seq];
      }

      list.add(GeneratedRoundData(
        seqNo: seq,
        dueDate: dueDate,
        recipientMembershipId: recipientId,
        status: RoundStatus.open,
      ));
    }

    return list;
  }

  /// Clamps dueDay to the length of the target month (e.g., 31st -> 28th/29th in Feb).
  static DateTime _monthlyDueDate(DateTime start, int dueDay, int monthsOffset) {
    final year = start.year + ((start.month - 1 + monthsOffset) ~/ 12);
    final month = ((start.month - 1 + monthsOffset) % 12) + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = dueDay.clamp(1, lastDayOfMonth);
    return DateTime(year, month, clampedDay);
  }

  static DateTime _weeklyDueDate(DateTime start, int weeksOffset) {
    return start.add(Duration(days: 7 * weeksOffset));
  }
}

