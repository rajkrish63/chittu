# Current State

Last reviewed: 2026-10-20

## Implemented
- **Data & Database Layer:**
  - [`schema.dart`](file:///d:/codebase/chit-notebook/lib/data/database/schema.dart): Complete SQLite DDL with 4 relational tables (`groups`, `members`, `rounds`, `transactions`), foreign key constraints with cascade deletes, check constraints on enum fields, and query indexes.
  - [`database_helper.dart`](file:///d:/codebase/chit-notebook/lib/data/database/database_helper.dart): Singleton database instance management, database creation execution, versioned JSON backup export (`exportJson()`), and atomic JSON backup restore (`importJson()`).
- **Data Models:**
  - [`chit_group.dart`](file:///d:/codebase/chit-notebook/lib/data/models/chit_group.dart): Group entity with period, interest configuration, and status.
  - [`member.dart`](file:///d:/codebase/chit-notebook/lib/data/models/member.dart): Member entity with payout order and role.
  - [`chit_round.dart`](file:///d:/codebase/chit-notebook/lib/data/models/chit_round.dart): Round cycle tracking seq_no, due date, accountable person, recipient, and status.
  - [`ledger_txn.dart`](file:///d:/codebase/chit-notebook/lib/data/models/ledger_txn.dart): Append-only transaction entry entity.
- **Repository Business Logic:**
  - [`group_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/group_repository.dart): `createGroup` (auto-generates all rounds up-front with round-robin accountable assignment and fixed-order recipient assignment), `updateSettings` (immutability enforcement for locked fields after start), and `deleteIfEmpty` (safe deletion guard).
  - [`round_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/round_repository.dart): `markContribution` (with late-fee calculation), `unmarkContribution` (atomic reversal), `_maybeMarkCollected` (auto-advance round status to 'collected'), `runPayout` (atomic pot distribution and closed-loop dividend calculation in recipient-pays mode), `setRecipient` (audit transaction creation), and `pendingMembers` (filter for unpaid members).
  - [`member_repository.dart`](file:///d:/codebase/chit-notebook/lib/data/repositories/member_repository.dart): On-the-fly `MemberBalance` calculation (`contributed`, `taken`, `interestPaid`, `dividends`, `arrears`, and `net`), and transaction log retrieval.
- **Core Utilities & Constants:**
  - [`constants.dart`](file:///d:/codebase/chit-notebook/lib/core/constants.dart): Tamil UI string mappings for transaction types, round statuses, and interest modes.
  - [`utils.dart`](file:///d:/codebase/chit-notebook/lib/core/utils.dart): Currency and date formatters, WhatsApp URL link generation, Tamil reminder message formatter, and month-clamping due date calculation.
- **Application Shell & UI Stubs:**
  - [`main.dart`](file:///d:/codebase/chit-notebook/lib/main.dart) and [`app.dart`](file:///d:/codebase/chit-notebook/lib/app.dart): Flutter app entry point with Material 3 theming.
  - Feature screen stubs annotated with blueprint section references: [`home_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/home/home_screen.dart), [`group_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/group_detail_screen.dart), [`new_chit_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/new_chit_screen.dart), [`round_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/round/round_detail_screen.dart), and [`member_ledger_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/member/member_ledger_screen.dart).

## In Progress
- **Phase 0 (Setup & Polish):**
  - Centralized string table (`lib/core/strings.dart`) for bi-lingual Tamil/English support.
  - Riverpod dependency setup and state providers in `lib/state/`.
- **Phase 1 (Data Layer Hardening):**
  - Unit test suite to validate business logic and repository calculations.
- **Phase 2 (Core Loop UI):**
  - Implementing full interactive screens for `HomeScreen`, `GroupDetailScreen`, and `RoundDetailScreen`.

## Known Broken Behavior
- **Screens Are Placeholder Stubs:** Feature screens in `lib/features/` currently render static placeholder text and do not interact with repositories.
- **Missing Test Coverage:** No tests exist in `test/` yet.
- **Pending Dependencies:** `flutter_riverpod` and `pdf` packages are specified in the architecture documentation but are not yet added to [`pubspec.yaml`](file:///d:/codebase/chit-notebook/pubspec.yaml).

## Verification Performed
- Inspected all documentation files in `docs/` (`00_PRD.md`, `01_APP_FLOW.md`, `02_TECH_STACK.md`, `03_IMPLEMENTATION_PLAN.md`, `04_MODULES.md`).
- Inspected all Dart implementation files in `lib/`.
- Successfully initialized `.ai/` documentation structure via PowerShell script.

## Next Recommended Task
- **Phase 1 Data Hardening:** Write comprehensive unit tests in `test/` for `GroupRepository`, `RoundRepository`, `MemberRepository`, and `DatabaseHelper` to prove round generation, late fee calculation, closed-loop dividends, arrears tracking, and JSON backup integrity.
