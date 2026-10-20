# Architecture and Engineering Decisions

## Decision Log

### 1. Offline-First Local SQLite Architecture (No Backend)
- **Date:** 2026-10-16
- **Context:** Chit funds in India are subject to strict regulatory oversight if funds or user accounts are held/managed online. Furthermore, internet connectivity among organizers and members can be intermittent, and running backend infrastructure introduces maintenance and server costs.
- **Decision:** Build Chit Notebook as a 100% offline-first application using Flutter and local SQLite (`sqflite`). No user accounts, no cloud sync in v1, and no network requests for data persistence.
- **Alternatives:** Firebase / Supabase cloud backend; React Native with WatermelonDB.
- **Tradeoffs:** Zero hosting cost, zero privacy/regulatory exposure, instant response times. However, multi-device synchronization is deferred to later versions, and phone loss requires user-managed backups.

---

### 2. Derived Balances from Append-Only Ledger (Never Store Balances)
- **Date:** 2026-10-16
- **Context:** Financial calculations (contributions, interest, penalties, dividends, and arrears) easily drift and become corrupt if balances are cached as mutable columns in database tables.
- **Decision:** Every financial occurrence is an append-only row in the `transactions` table. Member net positions, balances, and arrears are always derived dynamically via SQL queries (`MemberRepository.balance`).
- **Alternatives:** Maintaining `current_balance` columns on `members` or `groups`.
- **Tradeoffs:** Eliminates balance synchronization bugs and simplifies auditability. Requires index optimization on `transactions(member_id)` and `transactions(round_id)` to keep query performance under 100ms.

---

### 3. Interest Recorded as Separate Ledger Rows
- **Date:** 2026-10-16
- **Context:** In informal chit funds, interest and penalties often cause disputes if they are quietly blended into contribution or pot totals.
- **Decision:** Interest is never folded into the pot or contribution amount. Late interest and recipient interest are always inserted as distinct rows with `type = 'interest'` and explanatory audit notes.
- **Alternatives:** Adjusting the `amount` column of the contribution or payout transaction.
- **Tradeoffs:** Transparent, dispute-free audit trail for members. Slightly more rows inserted per round.

---

### 4. Closed-Loop Recipient-Pays Interest Model
- **Date:** 2026-10-16
- **Context:** When a chit group uses the `recipient_pays` mode, the member taking the pot pays interest, which is divided among the other members as an incentive / dividend.
- **Decision:** Calculate recipient interest as `pot * interestRatePct / 100`. Insert one `interest` row for the recipient and `N - 1` equal `dividend` rows for the remaining members. Across the group, the net interest change sums to zero (`interest == sum(dividends)`).
- **Alternatives:** Pooling interest into a group kitty without redistribution.
- **Tradeoffs:** Perfect mathematical fairness; matches traditional informal ROSCA rules.

---

### 5. Passive Member Engagement (WhatsApp / PDF Statements Only)
- **Date:** 2026-10-16
- **Context:** Getting 10 to 20 group members to install a specialized app and create accounts creates immense friction and blocks adoption.
- **Decision:** Only the organizer installs and uses the app. Group members interact passively by receiving pre-filled WhatsApp reminder messages via `wa.me` deep links and exported PDF statements.
- **Alternatives:** Requiring all members to download the app and register via OTP.
- **Tradeoffs:** Zero onboarding friction for 95% of participants. Members cannot independently inspect the live ledger without requesting an export from the organizer.

---

### 6. Pre-generation of All Rounds upon Chit Creation
- **Date:** 2026-10-16
- **Context:** Organizers need full visibility into the entire lifecycle of the chit, including future due dates, scheduled recipients, and rotating accountable coordinators.
- **Decision:** Upon creating a chit group, all `N` rounds (where `N` is the number of members) are immediately generated in a single database transaction, with due dates computed and clamped for month-end variations.
- **Alternatives:** Lazily creating rounds one-by-one as previous rounds conclude.
- **Tradeoffs:** Enables instant round schedule preview and member order verification. Requires explicit guard logic to prevent destructive modifications once transactions commence.

---

### 7. Strict Immutability of Financial Terms Post-Start
- **Date:** 2026-10-16
- **Context:** Altering member counts, payout rotation, or core contribution amounts after money has moved invalidates prior accounting.
- **Decision:** Once round 1 has started, financial parameters (contribution amount, period, members, rotation) are locked. Only cosmetic or forward-looking settings (group name, interest rate for future rounds, due day, and active/closed status) can be updated via `updateSettings`. Non-empty groups cannot be deleted (`deleteIfEmpty` throws `StateError`).
- **Alternatives:** Allowing arbitrary edits with retroactive transaction recalculation.
- **Tradeoffs:** Prevents accidental accounting corruption. Requires members to complete or archive a chit rather than arbitrarily resizing it mid-cycle.

---

### 8. Full-Database JSON Backup & Restore with Versioning
- **Date:** 2026-10-16
- **Context:** Because there is no central server, phone replacement or damage could result in total data loss.
- **Decision:** Provide a one-tap JSON backup (`exportJson()`) that dumps all tables into an indented, human-readable JSON payload with schema version metadata (`"version": 1`). Backups can be shared via standard share sheets to Google Drive, WhatsApp, or local storage. Restores run inside a single database transaction.
- **Alternatives:** Binary SQLite file copying; CSV exports.
- **Tradeoffs:** High portability across Android and iOS; easy to inspect. Requires full-database replacement warning during restore.
