# Chit Notebook — v1 scaffold

Family & friends chit fund-க்கான digital notebook. **Money moves outside the app;
the app is the ledger.** Primary user: the organizer. Members get WhatsApp/PDF only.

## Status

- Data layer complete & testable: schema, models, repositories
  (interest logic, payout, arrears, backup export/import)
- UI screens: stubs with blueprint section references (`lib/features/…`)

## Setup

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
├── main.dart / app.dart
├── core/
│   ├── constants.dart            # Tamil UI labels
│   └── utils.dart                # money format, wa.me deep links, due-date math
├── data/
│   ├── database/
│   │   ├── schema.dart           # single source of truth (DDL)
│   │   └── database_helper.dart  # open/migrate + JSON backup export/import
│   ├── models/                   # ChitGroup, Member, ChitRound, LedgerTxn
│   └── repositories/             # all business logic lives here
│       ├── group_repository.dart   # createGroup pre-generates all rounds
│       ├── round_repository.dart   # markContribution, runPayout, pending
│       └── member_repository.dart  # balance() — never stored, always derived
└── features/                     # 5 screens per v1 blueprint sections 1–5
```

## Key logic (already implemented)

| Blueprint decision | Where |
|---|---|
| Fixed-order rotation, round-robin accountable | `GroupRepository.createGroup` |
| Late-fee: interest = contribution × rate% | `RoundRepository.markContribution` |
| Recipient-pays: interest = pot × rate%, split to others | `RoundRepository.runPayout` |
| Round auto-advances open → collected when all paid | `_maybeMarkCollected` |
| Paid/pending list for reminders | `RoundRepository.pendingMembers` |
| Member net position = received − paid, arrears | `MemberRepository.balance` |
| Locked fields after round 1 starts | `GroupRepository.updateSettings` |
| Delete only if zero transactions | `GroupRepository.deleteIfEmpty` |
| One-tap backup (JSON) / restore | `DatabaseHelper.exportJson/importJson` |

## Notes

- Interest is always its **own transaction row** — never folded into the pot.
- `recipient_pays` is closed-loop: interest paid by recipient = dividends received
  by others (sums to zero across the group).
- In `late_fee` mode, late interest goes to the group fund (v1: not redistributed;
  add dividend rows in `markContribution` if members should earn it).
- WhatsApp reminders: `openWhatsApp()` — wa.me deep link, zero server cost.
