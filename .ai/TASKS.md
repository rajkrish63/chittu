# Tasks

## Current Task
**Project Knowledge Initialization & Repository Analysis**
- Complete comprehensive codebase analysis (`pubspec.yaml`, `README.md`, `docs/`, `lib/`).
- Populate `.ai/` documentation suite with current architectural models, decisions, conventions, current state, known issues, and roadmap.

## Next Up
**Phase 1 — Data Layer Hardening with Unit Tests**
1. Add testing dependencies (`test`, `sqflite_common_ffi` if needed for desktop/headless unit testing).
2. Create unit tests for [`GroupRepository`](file:///d:/codebase/chit-notebook/lib/data/repositories/group_repository.dart):
   - Round pre-generation with `monthlyDueDate` clamping (February 28/29, April 30).
   - Round-robin accountable person rotation and fixed recipient sequencing.
   - Settings immutability rules (`updateSettings`).
   - Group deletion guard (`deleteIfEmpty`).
3. Create unit tests for [`RoundRepository`](file:///d:/codebase/chit-notebook/lib/data/repositories/round_repository.dart):
   - One-tap contribution marking and auto-advancing round to `collected`.
   - Late fee insertion as a separate ledger row in `late_fee` mode.
   - Unmark contribution atomic rollback (contribution + auto late interest).
   - Closed-loop dividend calculation in `recipient_pays` mode (`recipient interest == sum(dividends)`).
   - Recipient change with audit trail note.
   - Pending members query accuracy.
4. Create unit tests for [`MemberRepository`](file:///d:/codebase/chit-notebook/lib/data/repositories/member_repository.dart):
   - Dynamic `MemberBalance` computation (`contributed`, `taken`, `interestPaid`, `dividends`, `arrears`, `net`).
5. Create unit tests for [`DatabaseHelper`](file:///d:/codebase/chit-notebook/lib/data/database/database_helper.dart):
   - Full JSON database export and restore round-trip equality.

## Acceptance Criteria
- [x] All `.ai/*.md` documents accurately reflect the state and design of the repository.
- [ ] Test coverage on `lib/data/repositories/` reaches ≥ 90%.
- [ ] All unit tests pass with `flutter test`.
- [ ] No regression or compilation issues reported by `flutter analyze`.

## Verification Checklist
- [ ] `flutter test` passes without errors.
- [ ] `flutter analyze` passes with zero issues.
- [ ] Review all modified files before committing.
- [ ] Keep `.ai/CURRENT_STATE.md` and `.ai/TASKS.md` updated as features are delivered.
