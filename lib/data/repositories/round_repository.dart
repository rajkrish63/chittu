import 'package:sqflite/sqflite.dart';
import '../../core/utils.dart';
import '../database/database_helper.dart';
import '../models/chit_group.dart';
import '../models/chit_round.dart';

class RoundRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<ChitRound>> getForGroup(int groupId) async {
    final db = await _helper.database;
    final rows =
        await db.query('rounds', where: 'group_id = ?', whereArgs: [groupId], orderBy: 'seq_no');
    return rows.map(ChitRound.fromMap).toList();
  }

  Future<ChitRound?> getById(int roundId) async {
    final db = await _helper.database;
    final rows = await db.query('rounds', where: 'id = ?', whereArgs: [roundId]);
    return rows.isEmpty ? null : ChitRound.fromMap(rows.first);
  }

  /// Change recipient away from fixed order.
  Future<void> setRecipient(int roundId, int memberId, {String? reason}) async {
    final db = await _helper.database;
    await db.update('rounds', {'recipient_member_id': memberId},
        where: 'id = ?', whereArgs: [roundId]);
  }

  /// Core-loop tap: mark a member's contribution paid. If late and the group is
  /// in late_fee mode, interest = contribution * rate% is written as its OWN row.
  Future<void> markContribution({
    required ChitRound round,
    required ChitGroup group,
    required int memberId,
    required bool isLate,
  }) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.insert('transactions', {
        'round_id': round.id,
        'member_id': memberId,
        'type': 'contribution',
        'amount': group.contributionAmount,
        'is_late': isLate ? 1 : 0,
        'created_at': now,
      });
      if (isLate && group.interestMode == 'late_fee' && group.interestRatePct > 0) {
        final interest = group.contributionAmount * group.interestRatePct / 100;
        await txn.insert('transactions', {
          'round_id': round.id,
          'member_id': memberId,
          'type': 'interest',
          'amount': interest,
          'is_late': 1,
          'note': 'auto late interest (${group.interestRatePct}%)',
          'created_at': now,
        });
      }
      await _maybeMarkCollected(txn, round.id!, group.id!);
    });
  }

  /// Unmark: removes the contribution row and any auto late-interest from the
  /// same marking session (identified by the 'auto late' note prefix).
  Future<void> unmarkContribution(int roundId, int memberId) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions',
          where: "round_id = ? AND member_id = ? AND type = 'contribution'",
          whereArgs: [roundId, memberId]);
      await txn.delete('transactions',
          where: "round_id = ? AND member_id = ? AND type = 'interest' AND note LIKE 'auto late%'",
          whereArgs: [roundId, memberId]);
      await txn.update('rounds', {'status': 'open'},
          where: 'id = ? AND status = ?', whereArgs: [roundId, 'collected']);
    });
  }

  Future<void> _maybeMarkCollected(Transaction txn, int roundId, int groupId) async {
    final total = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM members WHERE group_id = ?', [groupId]))!;
    final paid = Sqflite.firstIntValue(await txn.rawQuery(
        "SELECT COUNT(DISTINCT member_id) FROM transactions WHERE round_id = ? AND type = 'contribution'",
        [roundId]))!;
    if (paid >= total) {
      await txn.update('rounds', {'status': 'collected'},
          where: 'id = ? AND status = ?', whereArgs: [roundId, 'open']);
    }
  }

  /// Payout: writes the pot to the recipient. In recipient_pays mode, interest =
  /// pot * rate% is paid by the recipient and split as dividends among the
  /// OTHERS (closed loop — sums to zero, per the interest design decision).
  Future<void> runPayout({required ChitRound round, required ChitGroup group}) async {
    assert(round.recipientMemberId != null, 'Recipient must be set before payout');
    final db = await _helper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final memberRows =
          await txn.query('members', where: 'group_id = ?', whereArgs: [group.id]);
      final memberIds = [for (final m in memberRows) m['id'] as int];
      final pot = group.contributionAmount * memberIds.length;

      await txn.insert('transactions', {
        'round_id': round.id,
        'member_id': round.recipientMemberId,
        'type': 'payout',
        'amount': pot,
        'note': 'round ${round.seqNo} pot',
        'created_at': now,
      });

      if (group.interestMode == 'recipient_pays') {
        final calc = calculateRecipientPays(
          pot: pot,
          interestRatePct: group.interestRatePct,
          totalMembers: memberIds.length,
        );
        if (calc.interest > 0) {
          await txn.insert('transactions', {
            'round_id': round.id,
            'member_id': round.recipientMemberId,
            'type': 'interest',
            'amount': calc.interest,
            'note': 'recipient interest (${group.interestRatePct}%)',
            'created_at': now,
          });
          final others = memberIds.where((id) => id != round.recipientMemberId).toList();
          for (final id in others) {
            await txn.insert('transactions', {
              'round_id': round.id,
              'member_id': id,
              'type': 'dividend',
              'amount': calc.dividend,
              'note': 'interest share, round ${round.seqNo}',
              'created_at': now,
            });
          }
        }
      }

      await txn.update('rounds', {'status': 'paid_out', 'paid_out_at': now},
          where: 'id = ?', whereArgs: [round.id]);
    });
  }
}
