# Changelog: Chit Notebook (சிட்டு நோட்புக்)

All notable changes to the Chit Notebook project will be documented in this file milestone by milestone.

---

## [0.1.0] - Milestone 1: M1 Core Financial Foundation

### Added
- **Integer-Paise Core Financial Engine (`lib/core/money/money.dart`):**
  - Zero-drift `Money` value object storing currency in integer paise ($1\text{ INR} = 100\text{ paise}$).
  - Full Indian Lakh numbering format (`₹##,##,###`).
  - Safe string parsing with prefix/comma stripping.
- **Pure-Dart Domain Services (`lib/domain/`):**
  - Zero Flutter imports in domain layer.
  - `LateFeeCalculator`: Daily prorated overdue interest with basis points (`rate_bps`), grace period, and whole-rupee rounding rule.
  - `RoundsGenerator`: Generates schedules with automatic calendar month clamping (e.g. Feb 31st -> 28th/29th).
  - `RoundStateMachine`: Formal transitions (`open` -> `collected` -> `paid_out`) with arrears-tolerant payout (avoids collection deadlock).
  - `LedgerAggregator`: Derived balance computation from append-only transaction stream with `reverses_txn_id` filtering.
- **Production SQLite Schema v2 (`lib/data/database/`):**
  - Referential safety with `PRAGMA foreign_keys = ON;` in `onConfigure`.
  - Tables: `contacts`, `groups`, `memberships`, `rounds`, `transactions`, `meta`.
  - Composite indices on `(group_id, payout_order)`, `(round_id, membership_id)`, `(reverses_txn_id)`.
  - Safe deletion enforcement: groups with posted transactions can never be deleted (`ON DELETE RESTRICT`).
- **Feature Layer (`lib/features/`):**
  - `HomeScreen`: Dashboard with required offline disclaimer banner, cash-flow summary cards (total monthly outflow, active count), and active round badges.
  - `NewChitScreen`: Creation wizard supporting custom installments, payout method, penalty mode, drag-to-reorder payout rotation, and contact selection modal.
  - `GroupDetailScreen`: Members roster with prized badges, guarantor notes, and rounds calendar.
  - `RoundDetailScreen`: Member checklist with payment indicators, dynamic late-fee modal (collect or waive), pot disbursement with arrears tolerance, and reversible unmark.
  - `MemberLedgerScreen`: Plain-language balance cards ("Paid so far", "Received so far", "Still to receive / To pay"), prized status indicator, and guarantor details.
- **Localization & Theming:**
  - Full bilingual ARB files (`en-IN` and `ta`) with plain-language financial terms.
  - Material 3 theming with dynamic dark, light, and system mode toggle.
- **Testing:**
  - 100% passing domain unit test suite covering integer arithmetic, daily late fees, state transitions, calendar clamping, reversals, and balance derivations.
  - Model serialization and accounting tests.

---

## Planned Upcoming Milestones
- **[0.2.0] Milestone 2:** Auction + Lottery Payout Methods & Dividend Distribution Engine.
- **[0.3.0] Milestone 3:** WhatsApp Deep Links & Statement/Receipt Automation.
- **[0.4.0] Milestone 4:** Encrypted JSON Database Backup, Restore & Migration.
- **[0.5.0] Milestone 5:** Biometric App Lock & PIN Security.
- **[0.6.0] Milestone 6:** Background Collection Reminders & Performance Optimization.

