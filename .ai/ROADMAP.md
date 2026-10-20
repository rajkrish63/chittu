# Roadmap

## Current Priorities (v1 — Target: 6 Weeks to Beta)

### Phase 0 — Setup & Localization Foundation
- [ ] Centralize Tamil and English UI strings in `lib/core/strings.dart` (avoid hardcoded strings in widgets).
- [ ] Add `flutter_riverpod` to `pubspec.yaml` and configure provider container.
- [ ] Finalize Material 3 theme skeleton with seed black palette.

### Phase 1 — Data Layer Hardening
- [ ] Add unit test suite in `test/repositories/` covering:
  - Round generation date logic (including month-end clamping for February and 30-day months).
  - Round-robin accountable and fixed-order recipient assignments.
  - Late-fee calculation and atomic reversal in `markContribution` / `unmarkContribution`.
  - Recipient-pays closed-loop invariant (`recipient interest == sum(member dividends)`).
  - Derived `MemberBalance` calculation with arrears.
  - `updateSettings` locked-field enforcement and `deleteIfEmpty` transactional guard.
  - Full-database JSON backup export and import round-trip.

### Phase 2 — Core Collection Loop UI (Highest Priority ⭐)
- [ ] `HomeScreen`: Chit cards with active status chips, this-month collection summary strip, backup status indicator with red-dot logic, and FAB.
- [ ] `GroupDetailScreen`: Progress indicators, active round card (pot amount, accountable member, recipient, collection progress), member rows, and round history.
- [ ] `RoundDetailScreen`: Fast 3-tap payment marking, late fee prompt dialog, accountable member chip selection, sticky action bar (pending summary, WhatsApp remind-all button, payout confirmation sheet).
- [ ] Navigation setup between Home, Group Detail, and Round Detail.

### Phase 3 — Chit Setup & Management
- [ ] `NewChitScreen`: 4-section creation wizard (basic details, interest mode selection, member list with drag-and-drop payout reordering, auto-generated round preview).
- [ ] Edit mode with lock indicators (🔒 icon and explanatory badges for locked fields).
- [ ] Archive and close chit functionality.

### Phase 4 — Ledger & Statements
- [ ] `MemberLedgerScreen`: Net balance header (+green / −red), category breakdown chips (contributed, taken, interest, arrears), and reverse-chronological transaction timeline.
- [ ] Add `pdf` package to `pubspec.yaml` and implement on-device PDF statement generation (`pdf_service.dart`):
  - Group monthly statement.
  - Individual member statement.
  - Share via `share_plus` to WhatsApp and email.

### Phase 5 — Reminders & Backup UX
- [ ] Implement `reminder_service.dart`: WhatsApp deep links for individual pending members and bulk reminder generation.
- [ ] Backup management in settings: Export JSON via share sheet, import/restore with full-replace confirmation, and red-dot badge when last backup > 7 days old.

### Phase 6 — Polish & Accessibility
- [ ] Native Tamil speaker review of all UI labels and messages.
- [ ] Accessibility pass: verify 44 dp minimum touch targets and dynamic font scaling.
- [ ] Edge-case handling and friendly empty states across all screens.

### Phase 7 — Beta Deployment
- [ ] Pilot with 20 real family and friend chit groups.
- [ ] Track primary success metrics: ≥ 80% completion rate for full chit cycles, ≤ 5s logging time per payment, 100% backup adoption, 0 data-loss incidents.

---

## Planned Work (v1.5)
- **Auction / Bidding Chit Mode:** Support auction-style chits with automated dividend calculations based on the winning discount bid.
- **Redistribution of Late Fees:** Option to distribute collected late fees to non-delinquent members as dividends.
- **Contacts Picker:** Phone contacts integration (`flutter_contacts`) for quick member addition.
- **Member View Links:** Generate read-only web view links or static summaries for members.
- **Organizer PIN Lock:** In-app biometric or PIN lock to protect data on shared devices.

---

## Deferred Ideas (v2 & Future)
- **Multi-Device Cloud Sync:** End-to-end encrypted backup sync across devices.
- **Multi-Organizer Roles:** Co-organizer access with granular permissions.
- **Monetization & Subscriptions:** Premium features for professional organizers.
- **Direct UPI / Payment Collection:** Deferred indefinitely due to regulatory and banking compliance requirements.
