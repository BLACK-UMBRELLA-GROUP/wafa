---
id: DOC-WAFA-0014
type: PLAN
status: CURRENT
feature: APP: AGREEMENTS
purpose: Build brief for queue line 4 - LOCK 2 launch types and many people on one agreement
links: [DOC-WAFA-0012, DOC-WAFA-0013]
owner: WAFA chat
---

# BUILD BRIEF — LAUNCH TYPES + MANY PEOPLE — LOCK 2 — 8 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 3. ROADMAP row: **"Define MVP contract types"** - tick it and close its GitHub issue when this line is BUILT.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `AGREEMENTS/RECORD/AGREEMENTS_SPEC_CURRENT_VERSION_V1.md` (all), `AGREEMENTS/RECORD/LOCK_RECORD.md`, masters `AGREEMENTS/MASTERS/w08`-`w16`, `BASELINE/SCREENSHOTS/member/` (Create, Payments, detail) |
| 2 | Check | The existing pieces the spec reuses: saved contacts / Wafa ID person-finding and invitations (`demo_connections.dart`, `participants_screen.dart`), payment form (`payments_screen.dart`), `ParticipantRole`. If roles Owes a share / Is owed cannot sit on the existing Party role without breaking invitations, file a question; do not invent |
| 3 | Types | Spec §1: `ContractKind` gets Item lending, Item rental (replaces Rental; migrate example records), Family agreement, Custom agreement; labels, descriptions, icons and order exactly; the "Later" line |
| 4 | Details | Spec §2 (people list, roles, split, errors, Custom warning) replacing "Who is this with?" |
| 5 | Review + save | Spec §3, including invitations prepared per person |
| 6 | Agreement page | Spec §4 for three or more people |
| 7 | Who paid? | Spec §5 before the existing payment form |
| 8 | Signing | Spec §6: only the review line - build no signing |
| 9 | Example records | Spec §7 |
| 10 | Remove | The old single-counterparty field and any code only it used (no dead code) |
| 11 | Tests | Types list (7, order), equal split with pennies, set amounts total, each error message and its order, Custom warning only for Custom, save creates people and invitations, Who paid? caps at the share, two-person agreement still shows the counterparty, Item rental replaces Rental in example records. `flutter analyze` clean, all tests pass |
| 12 | Render | w08, w10, w11, w12, w13, w14, w15, w16 into `AGREEMENTS/BUILT/V1/` as `<master>__master_beside_build.png`; re-render LOCK 1 `DASHBOARD/BUILT/V1/w01` with the new records |
| 13 | Hand back | Task note ("Built from", beside images, Disk); line 4 BUILT or FAILED; tick the ROADMAP row and close its issue; commit and push (core rule 2) |
