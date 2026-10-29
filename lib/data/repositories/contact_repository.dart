import '../database/database_helper.dart';
import '../models/contact.dart';

class ContactRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Contact>> getAllContacts() async {
    final db = await _helper.database;
    final rows = await db.query('contacts', orderBy: 'name ASC');
    return rows.map(Contact.fromMap).toList();
  }

  Future<Contact?> getById(int id) async {
    final db = await _helper.database;
    final rows = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Contact.fromMap(rows.first);
  }

  Future<Contact> getOrCreateContact({
    required String name,
    String? phone,
    String? note,
  }) async {
    final db = await _helper.database;
    final trimmedName = name.trim();
    final trimmedPhone = phone?.trim();

    // Check by phone first if provided
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      final rows = await db.query(
        'contacts',
        where: 'phone = ?',
        whereArgs: [trimmedPhone],
      );
      if (rows.isNotEmpty) {
        return Contact.fromMap(rows.first);
      }
    }

    // Check by exact name match
    final nameRows = await db.query(
      'contacts',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmedName.toLowerCase()],
    );
    if (nameRows.isNotEmpty) {
      return Contact.fromMap(nameRows.first);
    }

    // Insert new contact
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('contacts', {
      'name': trimmedName,
      'phone': trimmedPhone,
      'country_code': '91',
      'note': note,
      'created_at': now,
    });

    return Contact(
      id: id,
      name: trimmedName,
      phone: trimmedPhone,
      countryCode: '91',
      note: note,
      createdAt: DateTime.parse(now),
    );
  }
}
