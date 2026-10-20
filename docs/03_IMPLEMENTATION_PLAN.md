# Chit Notebook — Implementation Plan (v1)

Assumption: solo dev, part-time (~15 h/week). Adjust by removing `Should`s if
time-boxed. Total: **~6 weeks** to beta.

## Phase 0 — Setup (Week 1, ~2 days)

- [ ] Repo, `.gitignore`, `flutter_lints`, CI (analyze + test on PR)
- [ ] Theme skeleton (Material 3, seed black per design), Tamil/English strings
      file (`AppStrings`) — no hardcoded UI text anywhere
- [ ] Wire riverpod; folder structure per `04_MODULES.md`

**Done when:** app builds, empty Home shows correct Tamil strings, CI green.

## Phase 1 — Data layer hardening (Week 1–2)

Already scaffolded: schema, models, repositories, backup. Now make it provable.

- [ ] Unit tests: `createGroup` round generation (dates incl. Feb clamp,
      round-robin accountable, fixed-order recipients)
- [ ] Unit tests: `markContribution` late-fee rows; `unmarkContribution`
      reverses exactly those rows
- [ ] Unit tests: `runPayout` closed-loop (recipient interest = Σ dividends)
- [ ] Unit tests: `balance()` nets & arrears; `deleteIfEmpty` guard;
      backup export→import round-trip

**Done when:** ≥ 90% line coverage on `repositories/`, all tests green.

## Phase 2 — Core loop UI (Week 2–4) ⭐ highest priority

- [ ] `HomeScreen`: chit cards (status chips, next payout line), month summary
      strip, backup icon w/ red-dot logic, FAB
- [ ] `GroupDetailScreen`: progress dots, current-round card (pot, accountable,
      recipient, paid x/y, CTA), member rows w/ status, history list
- [ ] `RoundDetailScreen` (core loop): member rows + paid toggle, late prompt,
      accountable chips, sticky bottom bar (pending summary, remind-all,
      payout button), payout confirm sheet
- [ ] Navigation wiring (go_router or plain Navigator — keep simple)

**Done when:** organizer can run a real collection round end-to-end on a real
phone, 3 taps to mark paid, offline.

## Phase 3 — Chit setup & edit (Week 4)

- [ ] `NewChitScreen`: 4-section form (basic / interest / members+reorder /
      round preview), create → pre-generated rounds
- [ ] Edit mode with lock display (🔒 + reason), `updateSettings`,
      archive/close, delete-if-empty guard

**Done when:** US-1…US-3 fully usable; creating a 10-member chit takes < 3 min.

## Phase 4 — Ledger & statements (Week 5)

- [ ] `MemberLedgerScreen`: net header, chips, reverse-chron timeline, running
      balance
- [ ] PDF: group monthly statement + member statement (`pdf` package), share
      via share_plus (WhatsApp first)

**Done when:** US-4 satisfied — a member with no app gets a clear statement.

## Phase 5 — Reminders & backup UX (Week 5)

- [ ] Reminder deep links per pending member + "remind all"
- [ ] Backup: export from home icon & settings; restore with confirm;
      red-dot nudge (> 7 days)

## Phase 6 — Polish & localization (Week 6)

- [ ] Tamil pass with native speaker (NFR-7); font scaling check (NFR-8)
- [ ] Empty states everywhere; error dialogs (restore failure, locked edit)
- [ ] PIN lock quick win (risk table §9) if time permits — else v1.1

## Phase 7 — Beta (Week 6+)

- [ ] 20 organizers (family + friends groups); watch the 3 core metrics (PRD §4)
- [ ] integration_test for create → 2 rounds → payout flow
- [ ] Fix loop weekly; only then cut v1.1 from the v1.5 parking lot

## Milestones

| Milestone | Contents | Acceptance |
|---|---|---|
| M1 (end wk 2) | Data layer + tests | Phase 1 checklist green |
| M2 (end wk 4) | Core loop demo | Organizer runs a real round on-device |
| M3 (end wk 6) | v1 feature complete | Phases 3–6 done; PRD `Must`s all pass |
| M4 (wk 7–10) | Beta | 20 groups, metrics tracked, v1.1 defined |

## Cut lines (if slipping)

1. Drop FR-19 (contacts picker) — type phone manually.
2. Drop FR-20 (aggregate dashboard) — per-group only.
3. Drop per-member PDF — group statement only.
Never cut: core loop speed, backup, interest correctness.
