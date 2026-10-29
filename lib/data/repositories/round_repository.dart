import 'package:sqflite/sqflite.dart';
import '../../domain/models/enums.dart';
import '../database/database_helper.dart';
import '../models/chit_group.dart';
import '../models/chit_round.dart';

class RoundRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<ChitRound>> getForGroup(int groupId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'rounds',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'seq_no ASC',
    );
    return rows.map(ChitRound.fromMap).toList();
  }

  Future<ChitRound?> getById(int roundId) async {
    final db = await _helper.database;
    final rows = await db.query('rounds', where: 'id = ?', whereArgs: [roundId]);
    if (rows.isEmpty) return null;
    return ChitRound.fromMap(rows.first);
  }

  Future<void> setRecipient(int roundId, int membershipId) async {
    final db = await _helper.database;
    await db.update(
      'rounds',
      {'recipient_membership_id': membershipId},
      where: 'id = ?',
      whereArgs: [roundId],
    );
  }

  /// Records a contribution in the immutable append-only ledger.
  /// If late, automatically snapshots the computed late-fee transaction row.
  Future<void> markContribution({
    required ChitRound round,
    required ChitGroup group,
    required int membershipId,
    required bool isLate,
    int? lateFeePaise,
    String? note,
  }) async {
    final db = await _helper.database;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Insert contribution row
      await txn.insert('transactions', {
        'round_id': round.id,
        'membership_id': membershipId,
        'type': TransactionType.contribution.value,
        'amount_paise': group.installmentPaise,
        'is_late': isLate ? 1 : 0,
        'note': note,
        'created_at': now,
      });

      // 2. If late and fee > 0, insert separate interest transaction row
      if (isLate && lateFeePaise != null && lateFeePaise > 0) {
        await txn.insert('transactions', {
          'round_id': round.id,
          'membership_id': membershipId,
          'type': TransactionType.interest.value,
          'amount_paise': lateFeePaise,
          'is_late': 1,
          'note': 'late fee snapshot',
          'created_at': now,
        });
      }

      // 3. Check if all members in group have now paid
      final totalMembers = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT COUNT(*) FROM memberships WHERE group_id = ?',
        [group.id],
      )) ?? 0;

      final paidMembers = Sqflite.firstIntValue(await txn.rawQuery('''
        SELECT COUNT(DISTINCT membership_id) FROM transactions 
        WHERE round_id = ? AND type = 'contribution'
          AND id NOT IN (SELECT reverses_txn_id FROM transactions WHERE reverses_txn_id IS NOT NULL)
      ''', [round.id])) ?? 0;

      if (paidMembers >= totalMembers && round.status == RoundStatus.open) {
        await txn.update(
          'rounds',
          {'status': RoundStatus.collected.value},
          where: 'id = ?',
          whereArgs: [round.id],
        );
      }
    });
  }

  /// Appends a reversal transaction referencing `reverses_txn_id` (append-only ledger).
  Future<void> unmarkContribution(int roundId, int membershipId) async {
    final db = await _helper.database;

    await db.transaction((txn) async {
      // Find the active contribution transaction for this round and member
      final activeTxns = await txn.rawQuery('''
        SELECT * FROM transactions 
        WHERE round_id = ? AND membership_id = ? AND reverses_txn_id IS NULL
          AND id NOT IN (SELECT reverses_txn_id FROM transactions WHERE reverses_txn_id IS NOT NULL)
      ''', [roundId, membershipId]);

      final now = DateTime.now().toIso8601String();

      for (final t in activeTxns) {
        final originalId = t['id'] as int;
        final type = t['type'] as String;
        final amountPaise = t['amount_paise'] as int;

        // Append reversal row
        await txn.insert('transactions', {
          'round_id': roundId,
          'membership_id': membershipId,
          'type': type,
          'amount_paise': amountPaise,
          'is_late': 0,
          'reverses_txn_id': originalId,
          'note': 'reversal of txn #$originalId',
          'created_at': now,
        });
      }

      // If round was marked 'collected', revert it back to 'open'
      await txn.update(
        'rounds',
        {'status': RoundStatus.open.value},
        where: "id = ? AND status = 'collected'",
        whereArgs: [roundId],
      );
    });
  }

  /// Disburses the round pot to the winning recipient.
  /// Arrears-tolerant: Can be executed even if collections are still pending.
  Future<void> runPayout({
    required ChitRound round,
    required ChitGroup group,
    required int recipientMembershipId,
    int? customPotPaise,
  }) async {
    final db = await _helper.database;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // Total members
      final totalMembers = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT COUNT(*) FROM memberships WHERE group_id = ?',
        [group.id],
      )) ?? 1;

      final fullPotPaise = customPotPaise ?? (group.installmentPaise * totalMembers);

      // 1. Insert payout transaction
      await txn.insert('transactions', {
        'round_id': round.id,
        'membership_id': recipientMembershipId,
        'type': TransactionType.payout.value,
        'amount_paise': fullPotPaise,
        'note': 'round ${round.seqNo} pot payout',
        'created_at': now,
      });

      // 2. Mark membership as prized
      await txn.update(
        'memberships',
        {'prized': 1},
        where: 'id = ?',
        whereArgs: [recipientMembershipId],
      );

      // 3. Update round status to paid_out
      await txn.update(
        'rounds',
        {
          'recipient_membership_id': recipientMembershipId,
          'status': RoundStatus.paidOut.value,
          'paid_out_at': now,
        },
        where: 'id = ?',
        whereArgs: [round.id],
      );
    });
  }
}
