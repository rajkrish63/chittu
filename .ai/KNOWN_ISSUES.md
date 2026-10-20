# Known Issues

Record confirmed defects, reproduction steps, workarounds, and status.

## Current Known Issues & Constraints

### 1. Feature Screens are Placeholder Stubs
- **Status:** Open (Planned for Phases 2–4)
- **Impact:** App cannot currently be used interactively via GUI; launching the app displays static placeholder text.
- **Affected Files:**
  - [`lib/features/home/home_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/home/home_screen.dart)
  - [`lib/features/group/group_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/group_detail_screen.dart)
  - [`lib/features/group/new_chit_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/group/new_chit_screen.dart)
  - [`lib/features/round/round_detail_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/round/round_detail_screen.dart)
  - [`lib/features/member/member_ledger_screen.dart`](file:///d:/codebase/chit-notebook/lib/features/member/member_ledger_screen.dart)
- **Workaround:** Build UI screens according to the blueprint specifications and wire them to repositories.

---

### 2. Missing Automated Test Suite in `test/`
- **Status:** Open (Phase 1 Target)
- **Impact:** Business logic (interest math, month clamping, dividend distribution, arrears tracking, JSON backup) lacks regression tests.
- **Affected Files:** `test/` directory is currently empty.
- **Workaround:** Implement Phase 1 unit tests with SQLite test fixtures.

---

### 3. Missing Dependencies in `pubspec.yaml`
- **Status:** Open (Prerequisite for Phase 0 & Phase 4)
- **Impact:** The architectural documents specify `flutter_riverpod` (`^2.5`) for state management and `pdf` (`^3.11`) for statement generation, but they are not yet declared in [`pubspec.yaml`](file:///d:/codebase/chit-notebook/pubspec.yaml).
- **Workaround:** Add `flutter_riverpod` and `pdf` to `pubspec.yaml` before implementing state providers and PDF statement generation.

---

### 4. Group Deletion Blocked When Transactions Exist
- **Status:** By Design / Working as Intended
- **Impact:** Calling `GroupRepository.deleteIfEmpty` on a group with existing transaction rows throws `StateError('Chit has transactions — archive instead of delete.')`.
- **Workaround:** The UI must hide the delete action for non-empty chits or prompt the user to archive the chit by setting status to `closed`.

---

### 5. Late-Fee Interest Pools into Group Fund (Not Redistributed in v1)
- **Status:** By Design for v1 (Documented in PRD §10)
- **Impact:** In `late_fee` mode, late fees are recorded against the delinquent member but are not split as dividends to on-time members.
- **Workaround:** Expected behavior for v1. Redistribution logic can be added in v1.5 if demanded by beta users.
