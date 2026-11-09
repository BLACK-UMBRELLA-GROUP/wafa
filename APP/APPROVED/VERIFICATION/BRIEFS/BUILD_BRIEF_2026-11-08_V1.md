---
id: DOC-WAFA-0017
type: BRIEF
status: CURRENT
feature: APP: VERIFICATION
purpose: Build brief for queue line 5 - LOCK 3 optional verification, two badges
links: [DOC-WAFA-0015, DOC-WAFA-0016]
owner: WAFA chat
---

# BUILD BRIEF — VERIFICATION — LOCK 3 — 8 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 4. ROADMAP row: **"Define verification tiers"** - tick it and close its GitHub issue when this line is BUILT.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `VERIFICATION/RECORD/VERIFICATION_SPEC_CURRENT_VERSION_V1.md` (all), `VERIFICATION/RECORD/LOCK_RECORD.md`, masters `VERIFICATION/MASTERS/w17`-`w20`, `AGREEMENTS/MASTERS/w10`-`w15` (badges), today's Profile capture |
| 2 | Model | A verification level per demo person (spec §1, §5): email, phone, photo ID + selfie; level None / Basic / Verified. In memory, like the rest of the demo |
| 3 | Badge | One shared badge widget (spec §2) used everywhere spec §1 rule 3 lists |
| 4 | Profile | Spec §3 - add the parts; leave the rest of Profile as built |
| 5 | Verification page | Spec §4, with the simulated checks and their messages |
| 6 | Nothing real | No codes, camera, photo, upload or network (spec §1 rule 4) |
| 7 | Tests | Levels (email only → none, + phone → Basic, + ID → Verified), badge text and placement, optional (no agreement blocked), Profile status line for each level. `flutter analyze` clean, all tests pass |
| 8 | Render | w17-w20 and w14 into `VERIFICATION/BUILT/V1/` as `<master>__master_beside_build.png` |
| 9 | Hand back | Task note; line 5 BUILT or FAILED; tick the ROADMAP row and close its issue; commit and push (core rule 2) |
