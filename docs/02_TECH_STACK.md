# Chit Notebook — Technical Stack (v1)

## Decision summary

**Flutter + local SQLite, no backend.** The app is a notebook; the phone is the
notebook. This removes servers, accounts, costs and compliance surface from v1.

## Stack table

| Layer | Choice | Version | Why |
|---|---|---|---|
| Framework | Flutter (Dart) | stable, SDK ≥ 3.0 | One codebase → Android + iOS; excellent offline story; small install size |
| Local DB | sqflite (SQLite) | ^2.3.0 | Mature, transactional, ships with Android/iOS; supports our FK + CHECK schema |
| Paths | path + path_provider | ^1.8 / ^2.1 | DB file + backup file locations |
| State mgmt | flutter_riverpod | ^2.5 | Lightweight, testable, no boilerplate explosion; scoped per screen |
| Dates/money | intl | ^0.19.0 | NumberFormat for ₹ grouping, Tamil locale dates |
| Reminders | url_launcher | ^6.2.2 | wa.me deep links → WhatsApp, zero server/SMS cost |
| Sharing | share_plus | ^10.0.0 | Share PDF statements + JSON backups to WhatsApp/Drive/Files |
| PDF | pdf (dart_pdf) | ^3.11 | Generate statements on-device (no network) |
| Contacts (FR-19) | flutter_contacts or `flutter contact picker` | latest optional | Optional dependency; feature degrades gracefully if absent |
| Linting | flutter_lints | ^4.0.0 | Consistency |

## Architecture

```
UI (features/)  →  State (riverpod providers)  →  Repositories  →  sqflite
```

Rules that keep this healthy:

1. **Repositories own ALL SQL.** Widgets never see `db`.
2. **Balances are derived** (`MemberRepository.balance`), never stored columns.
3. **Every multi-write operation is a DB transaction** (payout, mark+interest,
   restore) — partial writes are impossible by construction.
4. **Schema changes only via `onUpgrade`** — never edit `schema.dart` in place.
5. One source of truth for DDL: `lib/data/database/schema.dart`.

## Data & sync posture

- All data lives in `chit_notebook.db` on-device.
- Backup = versioned JSON (`{"app": "chit_notebook", "version": 1, ...}`) via
  `DatabaseHelper.exportJson/importJson`; user shares it wherever they like.
- No analytics SDK. No crash reporter in v1 (add opt-in later if needed).
- No accounts, no phone-number verification, no permissions beyond storage +
  (optional) contacts.

## Alternatives considered

| Alternative | Verdict |
|---|---|
| React Native + WatermelonDB | Fine, but team fluency + SQLite maturity favored Flutter |
| Backend + login (Firebase) | Kills v1's zero-friction promise; adds privacy/compliance burden. Revisit for v2 sync |
| Hive/Isar (NoSQL) | Loses transactions + ad-hoc queries the ledger needs |
| CSV backup instead of JSON | JSON is self-describing + versioned; CSV reserved as an export format later |

## Tooling

- Flutter SDK stable, Dart ≥ 3.0
- VS Code / Android Studio + Dart-Code
- git + GitHub; CI optional: GitHub Actions running `flutter analyze` + tests on PR
- Test devices: one budget Android (≤ 2 GB RAM) + one mid-range — performance
  target NFR-5 is validated on the cheap phone

## Testing strategy

| Level | Tool | Covers |
|---|---|---|
| Unit | flutter_test | Repositories: interest maths, payout closed-loop, arrears, lock guards, backup round-trip |
| Widget | flutter_test | Core loop: mark paid → status change → reminder button state |
| Integration | integration_test (Phase 7) | Full flow: create chit → 2 rounds → payout → statement |
| Golden | n/a v1 | — |
