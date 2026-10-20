# Chit Notebook — Product Requirements Document (v1)

| | |
|---|---|
| Version | 1.0 |
| Date | 2026-10-16 |
| Status | Approved for build |
| Owner | Founder / solo dev |
| Code name | chit_notebook |

---

## 1. Elevator pitch

A simple digital notebook for family & friends chit funds (ROSCA). The organizer
records collections, payouts, interest and dues; the app calculates everything
automatically and shares statements over WhatsApp. **No money ever moves through
the app.** It replaces the paper notebook and the WhatsApp maths.

> Positioning: "Family & friends chit funds-க்கு simple digital notebook."
> ❌ Not banking · ❌ Not investment · ❌ No transfers · ❌ No KYC

## 2. Problem

| Segment | Today | Pain |
|---|---|---|
| Family chit | Paper notebook / memory | "யார் எடுத்தாங்க, balance என்ன?" — only one person knows |
| Friends group | WhatsApp + calculator | Paid/pending confusion every month; awkward follow-ups |
| Small local groups | One keeper's notebook | No transparency; if the keeper is away, everything stops |

## 3. Users

- **Primary: the Organizer** — the one person who runs the chit. Only they use
  the app. Everything in v1 is designed for their weekly/monthly loop.
- **Secondary: Members** — passive. They receive WhatsApp reminders and PDF
  statements. No account, no install, no login. (Deliberate: zero onboarding
  friction for 19 of 20 people.)

## 4. Goals & success metrics

| Goal | Metric | Target (v1) |
|---|---|---|
| Replace the paper notebook | % of beta organizers completing a full chit cycle (≥5 rounds) in-app | ≥ 80% |
| Fastest possible logging | Time to mark one member paid | ≤ 5 seconds |
| Trust | Backup adoption among beta users | 100% |
| Trust | Data-loss incidents | 0 |
| Validation | Beta cohort | 20 families/friends groups |

## 5. Scope

### In scope (v1)

1. Create/edit chit groups: amount, currency, period (weekly/monthly), start
   date, due day, interest rate %, interest mode (`late_fee` | `recipient_pays`)
2. Members with phone numbers; payout order = fixed rotation (reorderable)
3. Auto-generated rounds with due dates; accountable person per round
   (round-robin suggestion, changeable)
4. Paid/pending tracking per round (one-tap mark, timestamped, late flag)
5. Automatic interest: late-fee per late contribution, or recipient-pays at payout
6. Payout recording (pot to recipient; dividends auto-split in recipient_pays mode)
7. Member ledger: net position, arrears, full transaction timeline
8. WhatsApp reminders (wa.me deep link, prefilled message — no server)
9. Monthly PDF statement (group + per member), shared via share sheet
10. One-tap JSON backup export / restore
11. Tamil-first UI with English toggle
12. Data-integrity rules: locked fields after round 1, delete-if-empty guard,
    audit note when recipient changes

### Out of scope (v1) — the fence

| Deferred | Where it goes |
|---|---|
| Auction/bidding mode + auto dividends | v1.5 |
| Real payment collection (UPI etc.) | Not before regulatory review — possibly never |
| Member accounts / logins / view links | v1.5 |
| Cloud sync between devices | v2 |
| Multi-organizer roles & permissions | v2 |
| Subscriptions / monetization | v2 (post product-market fit) |

## 6. User stories (core loop)

- **US-1** As an organizer, I open the app and in 3 taps mark "Kumar paid" for
  this month's round — so the notebook is always current.
- **US-2** As an organizer, I see at a glance who hasn't paid, and send them a
  WhatsApp reminder with the amount auto-filled.
- **US-3** As an organizer, when everyone has paid I tap "Payout", confirm the
  recipient and amount, and the app records it and closes the round.
- **US-4** As a member, I receive a clear WhatsApp/PDF statement showing what I
  paid, what I took, and what I owe — without installing anything.
- **US-5** As an organizer, I export a backup after every collection round, so a
  lost phone never means a lost chit.
- **US-6** As an organizer, late payments automatically get interest calculated
  at my group's rate, with the interest shown as a separate line.

## 7. Functional requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | Create group: name, contribution, currency, period, start date, due day | Must |
| FR-2 | Interest settings: rate %, mode radio (late_fee / recipient_pays) | Must |
| FR-3 | Add members (name, phone); set payout order via reorder list | Must |
| FR-4 | Auto-generate all rounds on create (due dates, fixed-order recipient, round-robin accountable) | Must |
| FR-5 | Edit locks: after round 1 starts only name / rate / due day / status editable | Must |
| FR-6 | Mark contribution paid (one tap, timestamped) and unmark (with confirm) | Must |
| FR-7 | Late flag → auto late-fee interest row (late_fee mode) | Must |
| FR-8 | Round paid/pending overview; pending member list with amounts | Must |
| FR-9 | WhatsApp reminder to pending members (deep link, prefilled Tamil message) | Must |
| FR-10 | Change accountable person per round | Must |
| FR-11 | Change recipient with mandatory reason note (written to ledger as audit row) | Must |
| FR-12 | Payout: record pot to recipient; auto interest + dividend rows (recipient_pays); allow payout-with-arrears | Must |
| FR-13 | Member ledger: contributed / taken / interest / arrears / net + timeline | Must |
| FR-14 | PDF statement: per group (monthly) and per member; share sheet | Must |
| FR-15 | Backup: full-database JSON export; restore with replace-all confirm | Must |
| FR-16 | Home: chit cards with status chips, this-month collection summary, backup status | Must |
| FR-17 | Close/archive chit; delete only when zero transactions | Must |
| FR-18 | Tamil + English UI strings with toggle | Must |
| FR-19 | Contacts-picker for member phone numbers | Should |
| FR-20 | This-month dashboard across all active chits (aggregate strip) | Should |
| FR-21 | Home-screen widget / notification nudge on due day | Could |

## 8. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | **Offline-first**: every feature works with zero connectivity |
| NFR-2 | **Local data only**: no server, no analytics SDK, no personal data leaves the device except user-initiated shares/backups |
| NFR-3 | All money events are append-only ledger rows; balances are derived, never stored |
| NFR-4 | All writes inside SQLite transactions (no half-written payout) |
| NFR-5 | Queries < 100 ms on a 5-year-old budget Android phone, 5 chits × 20 members |
| NFR-6 | Backup file versioned (`"version": 1`) so restores survive app upgrades |
| NFR-7 | Tamil labels reviewed by a native speaker before launch |
| NFR-8 | Font scaling support (accessibility); minimum touch target 44 dp |

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Data loss kills trust forever | Backup nudge (red dot > 7 days), JSON export on every share sheet |
| Scope creep → v1 never ships | Version fence (§5); every new idea gets parked in v1.5/v2 |
| Interest maths disputes | Interest always a separate ledger row with note ("auto late interest (2%)"); full audit trail |
| Regulatory exposure | No money movement, no custody — pure record keeping. Re-check before ever adding payments |
| Organizer phone shared with family | App-level PIN lock (v1.x quick win) |

## 10. Open questions

1. Late-fee interest: does it go to the group fund or get redistributed to
   members? (v1: group fund; add dividend rows in v1.5 if users ask.)
2. Partial early exit — a member leaves mid-cycle? (v1: manual; record via
   penalty/notes. Real feature later.)
3. Weekly vs monthly: which ships first in beta? (Build both; beta decides
   positioning.)
