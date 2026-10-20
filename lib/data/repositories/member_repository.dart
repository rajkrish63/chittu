import '../database/database_helper.dart';
import '../models/ledger_txn.dart';
import '../models/member.dart';

/// Everything the member ledger screen (blueprint section 4) needs, derived
/// from transactions — never stored, always computed. Single source of truth.
class MemberBalance {
  final double contributed; // type = contribution
  final double taken; // type = payout
  final double interestPaid; // interest + penalty paid BY this member
  final double dividends; // received shares (recipient_pays mode)
  final double arrears; // unpaid contributions in unfinished rounds
  final double net; // received - paid

  const MemberBalance({
    required this.contributed,
    required this.taken,
    required this.interestPaid,
    required this.dividends,
    required this.arrears,
    required this.net,
  });
}

class MemberRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Member>> getForGroup(int groupId) async {
    final db = await _helper.database;
    final rows = await db
        .query('members', where: 'group_id = ?', whereArgs: [groupId], orderBy: 'payout_order');
    return rows.map(Member.fromMap).toList();
  }

  Future<List<LedgerTxn>> transactionsFor(int memberId) async {
    final db = await _helper.database;
    final rows = await db.query('transactions',
        where: 'member_id = ?', whereArgs: [memberId], orderBy: 'created_at DESC');
    return rows.map(LedgerTxn.fromMap).toList();
  }

  Future<MemberBalance> balance(int groupId, int memberId) async {
    final db = await _helper.database;
    final sums = await db.rawQuery(
      'SELECT type, SUM(amount) AS s FROM transactions WHERE member_id = ? GROUP BY type',
      [memberId],
    );
    double sumOf(String type) {
      final rows = sums.where((r) => r['type'] == type);
      return rows.isEmpty ? 0.0 : (rows.first['s'] as num).toDouble();
    }

    final contributed = sumOf('contribution');
    final taken = sumOf('payout');
    final interestPaid = sumOf('interest') + sumOf('penalty');
    final dividends = sumOf('dividend');

    // Arrears: rounds not yet paid_out where this member has no contribution row.
    final arrearsRows = await db.rawQuery(
      'SELECT g.contribution_amount AS amt FROM rounds r '
      'JOIN groups g ON g.id = r.group_id '
      'WHERE r.group_id = ? AND r.status != ? AND NOT EXISTS '
      '(SELECT 1 FROM transactions t WHERE t.round_id = r.id AND t.member_id = ? AND t.type = ?)',
      [groupId, 'paid_out', memberId, 'contribution'],
    );
    final arrears =
        arrearsRows.fold<double>(0.0, (acc, r) => acc + (r['amt'] as num).toDouble());

    final paidTotal = contributed + interestPaid;
    final receivedTotal = taken + dividends;
    return MemberBalance(
      contributed: contributed,
      taken: taken,
      interestPaid: interestPaid,
      dividends: dividends,
      arrears: arrears,
      net: receivedTotal - paidTotal,
    );
  }
}
