---
id: DOC-WAFA-0011
type: BRIEF
status: CURRENT
feature: APP: DASHBOARD
purpose: Build brief for queue line 3 - Home dashboard LOCK 1
links: [DOC-WAFA-0009, DOC-WAFA-0010]
owner: WAFA chat
---

# BUILD BRIEF — HOME DASHBOARD — LOCK 1 — 8 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 1 and line 2 (use line 2's captures as "before"). ROADMAP row: **"WAFA design chat specifies the dashboard"** - tick it and close its GitHub issue when this line is BUILT.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `DASHBOARD/RECORD/DASHBOARD_SPEC_CURRENT_VERSION_V1.md` (all of it), `DASHBOARD/RECORD/LOCK_RECORD.md`, masters `DASHBOARD/MASTERS/w01`-`w07`, today's captures in `BASELINE/SCREENSHOTS/member/` |
| 2 | Check | Every component the spec calls "existing" (`BrandMark`, `DemoBadge`, `AgreementTile`, `SoftNote`, `WafaColors`, invitation flow, create flow) is in `SOURCE/lib/`. Report any that is not; do not invent one |
| 3 | Build Home | Replace `dashboard()` in `SOURCE/lib/main.dart` with spec §1 (w01, w02) and the new-member state §2 (w03). Exact words from the spec. Do **not** build Loading or Couldn't load (spec §2) |
| 4 | Build section list | New page per spec §3 (w06, w07), opened by the five tiles |
| 5 | Moves and removals | Spec §4: "A first look at Wafa" note to the top of Profile; remove the old Home parts and any code only they used |
| 6 | Must not change | Spec §5 |
| 7 | Tests | Update `test/widget_test.dart` (and any test using the old Home) for the new Home; add tests: needs-you order (invitation, overdue, awaiting, due ≤ 7 days), calm card + Next payment when empty, five tile counts, tile opens filtered list, empty list text, new-member state, greeting by hour, "1 agreement"/"n agreements". Keep keys `create-agreement` and `open-invitations`. `flutter analyze` clean, all tests pass |
| 8 | Render | Render w01, w02, w03, w06, w07 at 430 × 932 @3x into `DASHBOARD/BUILT/V1/` as `<master>__master_beside_build.png` |
| 9 | Hand back | Task note ("Built from", beside images, Disk); mark line 3 BUILT or FAILED; tick the ROADMAP row and close its issue; commit and push (core rule 2) |
