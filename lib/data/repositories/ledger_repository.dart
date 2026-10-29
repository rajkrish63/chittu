import 'package:sqflite/sqflite.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/member_balance.dart';
import '../../domain/services/ledger_aggregator.dart';
import '../database/database_helper.dart';
import '../models/ledger_txn.dart';

class LedgerRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<LedgerTxn>> getTransactionsForRound(int roundId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'transactions',
      where: 'round_id = ?',
      whereArgs: [roundId],
      orderBy: 'created_at ASC',
    );
    return rows.map(LedgerTxn.fromMap).toList();
  }

  Future<List<LedgerTxn>> getTransactionsForMembership(int membershipId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'transactions',
      where: 'membership_id = ?',
      whereArgs: [membershipId],
      orderBy: 'created_at DESC',
    );
    return rows.map(LedgerTxn.fromMap).toList();
  }

  Future<Set<int>> getPaidMembershipIdsForRound(int roundId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT membership_id FROM transactions
      WHERE round_id = ? AND type = 'contribution'
        AND id NOT IN (SELECT reverses_txn_id FROM transactions WHERE reverses_txn_id IS NOT NULL)
        AND reverses_txn_id IS NULL
    ''', [roundId]);

    return rows.map((r) => r['membership_id'] as int).toSet();
  }

  Future<MemberBalance> getMemberBalance({
    required int groupId,
    required int membershipId,
  }) async {
    final db = await _helper.database;

    // 1. Get Group info
    final groupRows = await db.query('groups', where: 'id = ?', whereArgs: [groupId]);
    if (groupRows.isEmpty) {
      throw StateError('Group #$groupId not found');
    }
    final installmentPaise = groupRows.first['installment_paise'] as int;

    // 2. Total rounds count
    final totalRounds = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM rounds WHERE group_id = ?',
      [groupId],
    )) ?? 1;

    // 3. Past due or active rounds count
    final nowIso = DateTime.now().toIso8601String();
    final pastDueOrActiveRounds = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM rounds
      WHERE group_id = ? AND (due_date <= ? OR status != 'open')
    ''', [groupId, nowIso])) ?? 1;

    // 4. Membership info
    final membershipRows = await db.query('memberships', where: 'id = ?', whereArgs: [membershipId]);
    if (membershipRows.isEmpty) {
      throw StateError('Membership #$membershipId not found');
    }
    final isPrized = (membershipRows.first['prized'] as int? ?? 0) == 1;
    final guarantorNote = membershipRows.first['guarantor_note'] as String?;

    // 5. Raw transactions for membership
    final txnRows = await db.query('transactions', where: 'membership_id = ?', whereArgs: [membershipId]);

    final rawTxns = txnRows.map((r) => RawTxnRecord(
      id: r['id'] as int,
      roundId: r['round_id'] as int,
      membershipId: r['membership_id'] as int,
      type: TransactionType.fromString(r['type'] as String),
      amountPaise: r['amount_paise'] as int,
      isLate: (r['is_late'] as int? ?? 0) == 1,
      reversesTxnId: r['reverses_txn_id'] as int?,
    )).toList();

    return LedgerAggregator.aggregateMemberBalance(
      membershipId: membershipId,
      totalRounds: totalRounds,
      installmentPaise: installmentPaise,
      isPrized: isPrized,
      guarantorNote: guarantorNote,
      memberTxns: rawTxns,
      pastDueOrActiveRoundsCount: pastDueOrActiveRounds > 0 ? pastDueOrActiveRounds : 1,
    );
  }
}

