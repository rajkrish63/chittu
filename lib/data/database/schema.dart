/// Full v1 schema. One source of truth — DatabaseHelper executes this on create.
/// Every money event is a row here; screens are just views over this table.
class Schema {
  static const createStatements = [
    '''
    CREATE TABLE groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      contribution_amount REAL NOT NULL,
      currency TEXT NOT NULL DEFAULT '₹',
      period TEXT NOT NULL CHECK (period IN ('weekly','monthly')),
      interest_rate_pct REAL NOT NULL DEFAULT 0,
      interest_mode TEXT NOT NULL DEFAULT 'late_fee'
        CHECK (interest_mode IN ('late_fee','recipient_pays')),
      start_date TEXT NOT NULL,
      due_day INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed')),
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      phone TEXT,
      payout_order INTEGER NOT NULL,
      role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin','member')),
      joined_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
      seq_no INTEGER NOT NULL,
      accountable_member_id INTEGER REFERENCES members(id),
      recipient_member_id INTEGER REFERENCES members(id),
      due_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','collected','paid_out')),
      paid_out_at TEXT
    )
    ''',
    '''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      round_id INTEGER NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
      member_id INTEGER NOT NULL REFERENCES members(id),
      type TEXT NOT NULL
        CHECK (type IN ('contribution','payout','interest','penalty','dividend')),
      amount REAL NOT NULL,
      is_late INTEGER NOT NULL DEFAULT 0,
      note TEXT,
      created_at TEXT NOT NULL
    )
    ''',
    'CREATE INDEX idx_members_group ON members(group_id)',
    'CREATE INDEX idx_rounds_group ON rounds(group_id, seq_no)',
    'CREATE INDEX idx_txn_round ON transactions(round_id)',
    'CREATE INDEX idx_txn_member ON transactions(member_id)',
  ];

  static const tables = ['groups', 'members', 'rounds', 'transactions'];
}
