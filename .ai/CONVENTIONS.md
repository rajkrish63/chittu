# Project Conventions

## Naming and Formatting
- **Dart & Flutter Code:**
  - Files and directories: `snake_case` (e.g. `group_repository.dart`, `round_detail_screen.dart`).
  - Classes and typedefs: `PascalCase` (e.g. `ChitGroup`, `RoundRepository`, `MemberBalance`).
  - Functions, methods, and variables: `camelCase` (e.g. `markContribution`, `payoutOrder`, `monthlyDueDate`).
  - Constant identifiers: `camelCase` or `UPPER_SNAKE_CASE` (e.g. `Labels.txnTypes`).
- **Database & Data Serialization:**
  - Table names and column names: `snake_case` (e.g. `group_id`, `payout_order`, `is_late`, `interest_rate_pct`).
  - Stored status and enum values: English `snake_case` strings (e.g., `open`, `collected`, `paid_out`, `late_fee`, `recipient_pays`, `contribution`, `payout`, `interest`, `penalty`, `dividend`).
- **Localization & UI Strings:**
  - UI labels are **Tamil-first** by default, accessed via [`Labels`](file:///d:/codebase/chit-notebook/lib/core/constants.dart) or localized string maps.
  - Hardcoded English text in user-facing UI widgets is discouraged.

## Error Handling
- **Database Transaction Guarantees:**
  - Any operation involving more than one database write (e.g., creating a group with members and rounds, marking payment with interest, running payouts with dividends, restoring backups) **must** run inside `db.transaction(...)`.
- **Domain Invariants & Guard Checks:**
  - Use `assert` for internal preconditions (e.g., `assert(members.isNotEmpty)`).
  - Throw explicit `StateError` for domain rule violations (e.g., attempting to delete a group that has transactions: `throw StateError('Chit has transactions — archive instead of delete.')`).
  - Payout prerequisites: Recipient must be set prior to executing `runPayout`.

## State Management
- **Riverpod Architecture (`flutter_riverpod`):**
  - Providers live in `lib/state/` and wrap repositories.
  - Screens must consume providers and avoid calling SQLite or repositories directly.
- **Single Source of Truth:**
  - Balances (`MemberBalance`), arrears, and pending member lists are never cached in persistent mutable state. They are always queried and derived from the underlying ledger tables.

## Testing
- **Unit Testing Strategy:**
  - Use `flutter_test` with in-memory SQLite fixtures (`sqflite_common_ffi` or mock databases where appropriate).
  - High-priority test cases:
    - Round generation date calculations (including month-end clamping for February and 30-day months).
    - Interest calculation accuracy for `late_fee` mode.
    - Zero-sum closed-loop validation for `recipient_pays` mode (`recipient interest == sum(member dividends)`).
    - Arrears tracking when a round is paid out with unpaid members.
    - Full round-trip backup export and import verification.
- **Widget Testing:**
  - Test core loop interactions: toggling member paid state, late fee prompt presentation, WhatsApp share intent triggers.

## Dependency Policy
- **Offline-First Non-Negotiable:**
  - No remote server dependencies, cloud synchronizers, or analytics trackers in v1.
  - All communication outside the device relies strictly on OS intent mechanisms (`url_launcher` for `wa.me`, `share_plus` for system share sheets).
- **Package Addition Rules:**
  - Keep the dependency footprint minimal. Any new package must be evaluated for offline compatibility, maintenance status, and impact on application bundle size.
