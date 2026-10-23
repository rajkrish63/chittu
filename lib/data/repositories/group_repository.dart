import '../../core/utils.dart';
import '../database/database_helper.dart';
import '../models/chit_group.dart';
import '../models/member.dart';

class GroupRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  /// Creates the group, inserts members, and pre-generates ALL rounds
  /// (fixed order = payout_order; accountable rotates round-robin).
  Future<int> createGroup(ChitGroup group, List<Member> members) async {
    assert(members.isNotEmpty, 'A chit needs at least 1 member');
    final db = await _helper.database;
    return db.transaction((txn) async {
      final groupId = await txn.insert('groups', group.toMap());
      final sorted = [...members]..sort((a, b) => a.payoutOrder.compareTo(b.payoutOrder));
      final memberIds = <int>[
        for (final m in sorted) await txn.insert('members', m.copyWith(groupId: groupId).toMap()),
      ];
      final n = memberIds.length;
      for (var seq = 1; seq <= n; seq++) {
        final due = group.period == 'monthly'
            ? monthlyDueDate(group.startDate, group.dueDay, seq - 1)
            : group.startDate.add(Duration(days: 7 * (seq - 1)));
        await txn.insert('rounds', {
          'group_id': groupId,
          'seq_no': seq,
          'accountable_member_id': memberIds[(seq - 1) % n], // rotation suggestion
          'recipient_member_id': memberIds[seq - 1], // fixed order
          'due_date': due.toIso8601String(),
          'status': 'open',
        });
      }
      return groupId;
    });
  }

  Future<List<ChitGroup>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('groups', orderBy: 'created_at DESC');
    return rows.map(ChitGroup.fromMap).toList();
  }

  Future<ChitGroup?> getById(int id) async {
    final db = await _helper.database;
    final rows = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : ChitGroup.fromMap(rows.first);
  }

  /// Delete allowed ONLY when the group has no transactions (blueprint section 5).
  Future<void> deleteIfEmpty(int groupId) async {
    final db = await _helper.database;
    final txn = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE round_id IN '
        '(SELECT id FROM rounds WHERE group_id = ?)', [groupId]);
    if ((txn.first['c'] as int) > 0) {
      throw StateError('Chit has transactions — archive instead of delete.');
    }
    await db.delete('groups', where: 'id = ?', whereArgs: [groupId]); // cascades
  }
}
