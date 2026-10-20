# Chit Notebook — Module Map (files ↔ responsibilities)

## Tree

```
lib/
├── main.dart                        # entry
├── app.dart                         # MaterialApp, theme, routing
├── core/
│   ├── constants.dart               # ✅ Tamil UI labels (txn types, statuses, modes)
│   ├── strings.dart                 # ⬜ all UI strings (ta/en) — Phase 0
│   └── utils.dart                   # ✅ money/date format, wa.me links, due-date math
├── data/
│   ├── database/
│   │   ├── schema.dart              # ✅ DDL (single source of truth)
│   │   └── database_helper.dart     # ✅ open/migrate + JSON export/import
│   ├── models/
│   │   ├── chit_group.dart          # ✅
│   │   ├── member.dart              # ✅
│   │   ├── chit_round.dart          # ✅
│   │   └── ledger_txn.dart          # ✅
│   └── repositories/
│       ├── group_repository.dart    # ✅ createGroup (round gen), settings+locks, delete guard
│       ├── round_repository.dart    # ✅ mark/unmark, payout, pending, accountable/recipient
│       └── member_repository.dart   # ✅ balance() derived ledger, timeline
├── state/                           # ⬜ riverpod providers (Phase 0/2)
│   ├── group_providers.dart
│   └── round_providers.dart
├── services/
│   ├── reminder_service.dart        # ⬜ WhatsApp deep links + message builder (wraps utils)
│   ├── pdf_service.dart             # ⬜ group & member statements (pdf pkg)
│   └── backup_service.dart          # ⬜ export/import UX glue + red-dot status calc
└── features/
    ├── home/home_screen.dart                    # ⬜ stub → Phase 2
    ├── group/group_detail_screen.dart           # ⬜ stub → Phase 2
    ├── group/new_chit_screen.dart               # ⬜ stub → Phase 3
    ├── round/round_detail_screen.dart           # ⬜ stub → Phase 2 (CORE)
    └── member/member_ledger_screen.dart         # ⬜ stub → Phase 4
```

Legend: ✅ complete (scaffold) · ⬜ stub or not started

## Module contracts

### core
- `utils.dart`: `formatMoney`, `formatDate`, `waUrl/openWhatsApp`,
  `reminderMessage`, `monthlyDueDate`. Pure functions — no Flutter imports
  except url_launcher.

### data
- **database_helper**: `database` getter; `exportJson() → String`;
  `importJson(String)` (replace-all, transactional). Nobody else touches sqflite.
- **group_repository**: `createGroup(group, members) → id` (pre-generates
  rounds); `getAll/getById`; `updateSettings` (locked-field enforcement by
  exposing only safe fields); `deleteIfEmpty` (throws if transactions exist).
- **round_repository**: `getForGroup/getById`; `setAccountable`;
  `setRecipient(reason)` (audit row); `markContribution(round, group,
  memberId, isLate)` (late_fee interest row inside txn); `unmarkContribution`;
  `runPayout(round, group)` (pot + interest + dividends, one txn);
  `pendingMembers(roundId)`.
- **member_repository**: `getForGroup`; `transactionsFor`; `balance(groupId,
  memberId) → MemberBalance {contributed, taken, interestPaid, dividends,
  arrears, net}`.

### state (Phase 0/2)
- Riverpod providers mirror repositories 1:1, plus `AsyncNotifier`s for the
  core loop (round detail state = members × paid flags).

### services
- **reminder_service**: builds per-member prefilled messages (Tamil), launches
  wa.me. Zero network.
- **pdf_service**: statement layout = header (group, period) + per-member rows
  (paid/pending/net) + footer (interest notes). File → share_plus.
- **backup_service**: last-backup timestamp storage, red-dot rule (> 7 days),
  restore confirm + error mapping.

### features (screens)
Each screen consumes providers only — no SQL, no direct repository calls in
widgets. Stubs already carry blueprint section references.

## Dependency rules

```
features → state → repositories → database
services → (utils, repositories)
core     → (nothing)
```

No arrow may point backwards. `data/` never imports Flutter UI.

## Testing map

| Module | Tests |
|---|---|
| group_repository | round generation, Feb clamp, locks, delete guard |
| round_repository | late-fee maths, unmark reversal, payout closed-loop, pending list |
| member_repository | net position, arrears with payout-with-arrears case |
| database_helper | export→import round-trip equals input |
| features (widget) | mark-paid flow, late prompt, payout sheet gating |
