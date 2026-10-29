/// Production SQLite DDL Schema for Chit Notebook.
/// - Integer-Centric Accounting: All monetary values are stored in paise (1 INR = 100 paise).
/// - Referential Safety: ON DELETE RESTRICT prevents accidental ledger deletion.
/// - Immutable Append-Only Ledger: Reversals reference `reverses_txn_id`.
class Schema {
  static const int currentVersion = 2;

  static const createStatements = [
    // 1. Contacts
    '''
    CREATE TABLE contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      country_code TEXT NOT NULL DEFAULT '91',
      note TEXT,
      created_at TEXT NOT NULL
    );
    ''',

    // 2. Groups
    '''
    CREATE TABLE groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      installment_paise INTEGER NOT NULL CHECK (installment_paise > 0),
      currency TEXT NOT NULL DEFAULT '₹',
      period TEXT NOT NULL CHECK (period IN ('weekly', 'monthly')),
      payout_method TEXT NOT NULL DEFAULT 'fixed_order' 
        CHECK (payout_method IN ('fixed_order', 'lottery', 'auction')),
      penalty_mode TEXT NOT NULL DEFAULT 'late_fee' 
        CHECK (penalty_mode IN ('none', 'late_fee', 'recipient_pays')),
      rate_bps INTEGER NOT NULL DEFAULT 0 CHECK (rate_bps >= 0),
      grace_days INTEGER NOT NULL DEFAULT 0 CHECK (grace_days >= 0),
      commission_bps INTEGER NOT NULL DEFAULT 0 CHECK (commission_bps >= 0),
      status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
      created_at TEXT NOT NULL
    );
    ''',

    // 3. Memberships (Links Contact to Group with Share & Order)
    '''
    CREATE TABLE memberships (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE RESTRICT,
      contact_id INTEGER NOT NULL REFERENCES contacts(id) ON DELETE RESTRICT,
      share_no INTEGER NOT NULL DEFAULT 1 CHECK (share_no > 0),
      payout_order INTEGER NOT NULL CHECK (payout_order > 0),
      prized INTEGER NOT NULL DEFAULT 0 CHECK (prized IN (0, 1)),
      guarantor_note TEXT,
      UNIQUE (group_id, payout_order)
    );
    ''',

    // 4. Rounds
    '''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE RESTRICT,
      seq_no INTEGER NOT NULL CHECK (seq_no > 0),
      recipient_membership_id INTEGER REFERENCES memberships(id) ON DELETE SET NULL,
      due_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'collected', 'paid_out')),
      auction_discount_paise INTEGER NOT NULL DEFAULT 0 CHECK (auction_discount_paise >= 0),
      paid_out_at TEXT,
      UNIQUE (group_id, seq_no)
    );
    ''',

    // 5. Append-Only Transactions Ledger
    '''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      round_id INTEGER NOT NULL REFERENCES rounds(id) ON DELETE RESTRICT,
      membership_id INTEGER NOT NULL REFERENCES memberships(id) ON DELETE RESTRICT,
      type TEXT NOT NULL 
        CHECK (type IN ('contribution', 'payout', 'interest', 'dividend', 'commission')),
      amount_paise INTEGER NOT NULL CHECK (amount_paise > 0),
      is_late INTEGER NOT NULL DEFAULT 0 CHECK (is_late IN (0, 1)),
      receipt_no TEXT,
      reverses_txn_id INTEGER REFERENCES transactions(id),
      note TEXT,
      created_at TEXT NOT NULL
    );
    ''',

    // 6. Metadata Table
    '''
    CREATE TABLE meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
    ''',

    // Performance Composite Indices
    'CREATE INDEX idx_contacts_name ON contacts(name);',
    'CREATE INDEX idx_memberships_group ON memberships(group_id, payout_order);',
    'CREATE INDEX idx_memberships_contact ON memberships(contact_id);',
    'CREATE INDEX idx_rounds_group ON rounds(group_id, seq_no);',
    'CREATE INDEX idx_rounds_status ON rounds(status);',
    'CREATE INDEX idx_txn_round_member ON transactions(round_id, membership_id);',
    'CREATE INDEX idx_txn_member_type ON transactions(membership_id, type);',
    'CREATE INDEX idx_txn_reverses ON transactions(reverses_txn_id);',
  ];

  static const tables = ['contacts', 'groups', 'memberships', 'rounds', 'transactions', 'meta'];
}
