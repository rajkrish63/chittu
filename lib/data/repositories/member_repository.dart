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

  /// Single source of truth: net is always received minus paid.
  double get net => (taken + dividends) - (contributed + interestPaid);

  const MemberBalance({
    required this.contributed,
    required this.taken,
    required this.interestPaid,
    required this.dividends,
    required this.arrears,
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

    // Arrears: rounds that are closed (paid_out) or whose due date has passed, where this member has no contribution.
    final nowIso = DateTime.now().toIso8601String();
    final arrearsRows = await db.rawQuery(
      'SELECT g.contribution_amount AS amt FROM rounds r '
      'JOIN groups g ON g.id = r.group_id '
      'WHERE r.group_id = ? AND (r.status = ? OR r.due_date <= ?) AND NOT EXISTS '
      '(SELECT 1 FROM transactions t WHERE t.round_id = r.id AND t.member_id = ? AND t.type = ?)',
      [groupId, 'paid_out', nowIso, memberId, 'contribution'],
    );
    final arrears =
        arrearsRows.fold<double>(0.0, (acc, r) => acc + (r['amt'] as num).toDouble());

    return MemberBalance(
      contributed: contributed,
      taken: taken,
      interestPaid: interestPaid,
      dividends: dividends,
      arrears: arrears,
    );
  }
}
