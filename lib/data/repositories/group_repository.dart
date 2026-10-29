import 'package:sqflite/sqflite.dart';
import '../../domain/services/rounds_generator.dart';
import '../database/database_helper.dart';
import '../models/chit_group.dart';
import '../models/contact.dart';
import '../models/membership.dart';

class GroupRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<ChitGroup>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('groups', orderBy: 'created_at DESC');
    return rows.map(ChitGroup.fromMap).toList();
  }

  Future<ChitGroup?> getById(int id) async {
    final db = await _helper.database;
    final rows = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ChitGroup.fromMap(rows.first);
  }

  Future<List<Membership>> getMemberships(int groupId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT m.*, c.name as contact_name, c.phone as contact_phone, 
             c.country_code as contact_country_code, c.note as contact_note,
             c.created_at as contact_created_at
      FROM memberships m
      JOIN contacts c ON m.contact_id = c.id
      WHERE m.group_id = ?
      ORDER BY m.payout_order ASC
    ''', [groupId]);

    return rows.map((r) {
      final contact = Contact(
        id: r['contact_id'] as int,
        name: r['contact_name'] as String,
        phone: r['contact_phone'] as String?,
        countryCode: r['contact_country_code'] as String? ?? '91',
        note: r['contact_note'] as String?,
        createdAt: DateTime.parse(r['contact_created_at'] as String),
      );
      return Membership.fromMap(r, contact);
    }).toList();
  }

  /// Atomically creates a chit group, its contacts/memberships, and its generated rounds schedule.
  Future<int> createGroupWithMembershipsAndRounds({
    required ChitGroup group,
    required List<Contact> contacts,
    required DateTime startDate,
    required int dueDay,
    List<String?>? guarantorNotes,
  }) async {
    final db = await _helper.database;

    return await db.transaction<int>((txn) async {
      // 1. Insert Group
      final groupId = await txn.insert('groups', group.toMap());

      // 2. Insert or find Contacts and create Memberships
      final orderToMembershipId = <int, int>{};

      for (var i = 0; i < contacts.length; i++) {
        final c = contacts[i];
        int contactId;

        if (c.id != null) {
          contactId = c.id!;
        } else {
          // Check by phone or name
          final existing = await txn.query(
            'contacts',
            where: 'name = ?',
            whereArgs: [c.name.trim()],
          );
          if (existing.isNotEmpty) {
            contactId = existing.first['id'] as int;
          } else {
            contactId = await txn.insert('contacts', {
              'name': c.name.trim(),
              'phone': c.phone?.trim(),
              'country_code': c.countryCode,
              'note': c.note,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }

        final payoutOrder = i + 1;
        final guarantorNote = guarantorNotes != null && i < guarantorNotes.length
            ? guarantorNotes[i]
            : null;

        final membershipId = await txn.insert('memberships', {
          'group_id': groupId,
          'contact_id': contactId,
          'share_no': 1,
          'payout_order': payoutOrder,
          'prized': 0,
          'guarantor_note': guarantorNote,
        });

        orderToMembershipId[payoutOrder] = membershipId;
      }

      // 3. Generate and insert Rounds
      final rounds = RoundsGenerator.generateSchedule(
        startDate: startDate,
        dueDay: dueDay,
        totalMembers: contacts.length,
        period: group.period,
        payoutMethod: group.payoutMethod,
        payoutOrderToMembershipId: orderToMembershipId,
      );

      for (final r in rounds) {
        await txn.insert('rounds', {
          'group_id': groupId,
          'seq_no': r.seqNo,
          'recipient_membership_id': r.recipientMembershipId,
          'due_date': r.dueDate.toIso8601String(),
          'status': r.status.value,
          'auction_discount_paise': 0,
        });
      }

      return groupId;
    });
  }

  /// Safe deletion: Enforces the rule that groups with financial transactions can NEVER be deleted.
  Future<void> deleteIfEmpty(int groupId) async {
    final db = await _helper.database;

    final txnCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM transactions t
      JOIN rounds r ON t.round_id = r.id
      WHERE r.group_id = ?
    ''', [groupId])) ?? 0;

    if (txnCount > 0) {
      throw StateError(
        'Cannot delete chit: $txnCount financial transaction(s) are recorded. '
        'Financial records are immutable.',
      );
    }

    await db.transaction((txn) async {
      await txn.delete('rounds', where: 'group_id = ?', whereArgs: [groupId]);
      await txn.delete('memberships', where: 'group_id = ?', whereArgs: [groupId]);
      await txn.delete('groups', where: 'id = ?', whereArgs: [groupId]);
    });
  }
}
