# Architecture

## Overview
Chit Notebook follows a layered offline-first architecture with strict unidirectional dependencies:

```
UI Screens (features/)
       ↓
State / Providers (state/ - planned)
       ↓
Repositories (data/repositories/)
       ↓
Database Helper & Schema (data/database/)
       ↓
Local SQLite (sqflite)
```

- **Core Utilities (`lib/core/`):** Pure helper modules without dependencies on other layers.
- **Data Layer (`lib/data/`):** Contains models, database helper, schema, and repositories.
- **Presentation Layer (`lib/features/`):** UI screens organized by domain feature.

---

## Main Modules

### 1. `lib/core/`
- [`constants.dart`](file:///d:/codebase/chit-notebook/lib/core/constants.dart): Tamil UI label mappings (`Labels.txnTypes`, `Labels.roundStatuses`, `Labels.interestModes`, `Labels.periods`). Stored database values remain in English snake_case.
- [`utils.dart`](file:///d:/codebase/chit-notebook/lib/core/utils.dart):
  - `formatMoney`: Currency formatting with thousand separators and minus sign preservation.
  - `formatDate`: Standardized date presentation (`dd MMM yyyy`).
  - `waUrl` & `openWhatsApp`: External WhatsApp invocation via `wa.me` URL scheme with prefilled text.
  - `reminderMessage`: Formats Tamil reminder text referencing round number, member name, and pending amount.
  - `monthlyDueDate`: Clamps due day to target month boundary (e.g., handles February 28/29 or April 30 correctly).

### 2. `lib/data/database/`
- [`schema.dart`](file:///d:/codebase/chit-notebook/lib/data/database/schema.dart): Single source of truth for DDL. Defines four relational tables:
  - `groups`: ID, name, contribution amount, currency, period (`weekly`/`monthly`), interest rate %, interest mode (`late_fee`/`recipient_pays`), start date, due day, status (`active`/`closed`), created timestamp.
  - `members`: ID, group foreign key (CASCADE), name, phone, payout order, role (`admin`/`member`), joined timestamp.
  - `rounds`: ID, group foreign key (CASCADE), sequence number, accountable member foreign key, recipient member foreign key, due date, status (`open`/`collected`/`paid_out`), paid out timestamp.
  - `transactions`: Append-only ledger rows. ID, round foreign key (CASCADE), member foreign key, type (`contribution`, `payout`, `interest`, `penalty`, `dividend`), amount, late flag, note, created timestamp.
  - Indexes on foreign keys: `idx_members_group`, `idx_rounds_group`, `idx_txn_round`, `idx_txn_member`.
- [`database_helper.dart`](file:///d:/codebase/chit-notebook/lib/data/database/database_helper.dart):
  - Singleton database connection lifecycle (`DatabaseHelper.instance`).
  - `exportJson()`: Dumps all tables to a versioned JSON string (`"app": "chit_notebook", "version": 1`).
  - `importJson()`: Transactional full-database restore with cascade table clearing.

### 3. `lib/data/models/`
- [`chit_group.dart`](file:///d:/codebase/chit-notebook/lib/data/models/chit_group.dart): Representation of a chit group with copy and map serialization.
- [`member.dart`](file:///d:/codebase/chit-notebook/lib/data/models/member.dart): Member entity with role and payout order.
- [`chit_round.dart`](file:///d:/codebase/chit-notebook/lib/data/models/chit_round.dart): Round cycle status tracking.
- [`ledger_txn.dart`](file:///d:/codebase/chit-notebook/lib/data/models/ledger_txn.dart): Immutable transaction entity.

### 4. `lib/data/repositories/`
- [`group_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/group_repository.dart):
  - `createGroup`: Inserts group, inserts members, and pre-generates all rounds up front in a single database transaction. Recipient order follows member payout order; accountable member rotates round-robin.
  - `updateSettings`: Enforces field immutability after round 1 starts (only name, interest rate, due day, status are mutable).
  - `deleteIfEmpty`: Guard preventing deletion if any transaction exists in any round (suggests archive instead).
- [`round_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/round_repository.dart):
  - `markContribution`: Writes contribution row; if late and in `late_fee` mode, writes a separate `interest` row; checks `_maybeMarkCollected` to advance status to `collected`.
  - `unmarkContribution`: Reverses contribution and associated auto-late interest rows, reverting status to `open`.
  - `runPayout`: Executes payout in an atomic transaction; records pot payout row; in `recipient_pays` mode, records recipient interest and calculates/inserts equal `dividend` rows for all other members; marks round `paid_out`.
  - `setRecipient`: Updates recipient and records a zero-amount audit row (`type = 'penalty'`, note with reason).
  - `setAccountable`: Updates accountable member.
  - `pendingMembers`: Queries members who have not contributed to the given round.
- [`member_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/member_repository.dart):
  - `balance`: Computes dynamic `MemberBalance` (`contributed`, `taken`, `interestPaid`, `dividends`, `arrears`, `net = receivedTotal - paidTotal`) via SQL aggregate queries. Never stored.
  - `transactionsFor`: Fetches complete reverse-chronological transaction ledger for a member.

### 5. `lib/features/`
- [`home/home_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/home/home_screen.dart): Chit summary list and active status cards.
- [`group/group_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/group_detail_screen.dart): Group rounds overview, accountable member, and member list.
- [`group/new_chit_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/new_chit_screen.dart): 4-step wizard for creating or editing a chit.
- [`round/round_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/round/round_detail_screen.dart): Core collection loop (one-tap payment marking, late interest prompt, WhatsApp reminders, payout sheet).
- [`member/member_ledger_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/member/member_ledger_screen.dart): Member balance card, arrears chip, and transaction timeline.

---

## Data Flow

```
1. Create Group:
   UserInput → GroupRepository.createGroup()
             → INSERT groups
             → INSERT members (ordered by payoutOrder)
             → INSERT rounds (pre-generated seq 1..N with due dates)

2. Core Collection Loop:
   Organizer Tap → RoundRepository.markContribution()
                 → INSERT transaction (type='contribution')
                 → (if late & late_fee mode) INSERT transaction (type='interest')
                 → (if all members paid) UPDATE round status='collected'

3. Payout:
   Organizer Tap → RoundRepository.runPayout()
                 → INSERT transaction (type='payout', recipient, pot)
                 → (if recipient_pays mode)
                     - INSERT transaction (type='interest', recipient)
                     - INSERT transactions (type='dividend', share to each other member)
                 → UPDATE round status='paid_out'

4. Member Ledger & Net Position:
   Member View → MemberRepository.balance()
               → SELECT SUM(amount) GROUP BY type
               → SELECT unpaid rounds before completion (arrears)
               → Compute: net = (taken + dividends) - (contributed + interestPaid)
```

---

## External Services
- **No Remote Servers or APIs:** All computation and persistence occur locally.
- **WhatsApp Integration:** Deep link integration via `https://wa.me/<phone>?text=<encoded_message>`. Handled by the device's default application launcher.
- **System Share Sheet:** File sharing via Android/iOS native share sheets for JSON backups and exported PDF statements.

---

## Important Boundaries
1. **Repository SQL Isolation:** Widgets and screens must never access SQLite directly. All SQL statements live exclusively within repository classes.
2. **Derived Balances:** Member balances, group totals, and arrears are never stored as static columns. They are always computed dynamically from the transaction log.
3. **Atomic Operations:** Multi-row mutations (group creation, mark payment with interest, payout distribution, database restore) must run within `db.transaction(...)`.
4. **Append-Only Ledger Discipline:** Once a round is marked `paid_out`, its transactions are immutable. Corrections are made via adjusting entries or reversal notes, not silent deletions.
5. **No Flutter UI in Data Layer:** `lib/data/` must not import Flutter UI libraries (`package:flutter/material.dart`).
