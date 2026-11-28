---
id: DOC-WAFA-0030
type: PLAN
status: CURRENT
feature: APP: BASELINE
purpose: Build brief for queue line 11 - render every built LOCK screen beside its master so the WAFA chat can do the build check (core rule 8)
links: [DOC-WAFA-0007, DOC-WAFA-0009, DOC-WAFA-0012, DOC-WAFA-0015, DOC-WAFA-0018, DOC-WAFA-0024, DOC-WAFA-0027]
owner: WAFA chat
---

# BUILD BRIEF — BUILD-CHECK RENDERS — 13 NOV 2026

**Capture only. No change to the app. Unclear or a step fails → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10). Do not add tooling, downloads or wrappers that this brief does not name.**

Founder, 13 Nov 2026 (audit action A-06): "A-06 Build check (Recommended)". The Mac simulator does not work (line 7 report), so this brief renders the screens **inside `flutter test`**, which needs no simulator and no device.

| # | Step | Detail |
|---|---|---|
| 1 | Read | This brief; the MASTERS list below; `SOURCE/test/demo_test_helpers.dart` and the existing tests that already reach each state |
| 2 | Where | New folder `SOURCE/test_screens/` only (outside `test/`, so the normal test run is unchanged). One file, `build_check_renders_test.dart`. No change to `lib/`, `test/`, `pubspec.yaml`, `run.sh` or `tooling/` |
| 3 | Size | Phone surface 430 × 932 logical points at device pixel ratio 3, so each PNG is **1290 × 2796** like the masters |
| 4 | Font | Load the Roboto font that already ships in the cached Flutter SDK (material fonts in its `bin/cache`) with `FontLoader`, so text renders as text. No download. If the font is not in the cache, render with the default test font and say so in the task note |
| 5 | Render | For each master below, put the app in that state (same demo data, same person signed in, same clock as the tests) and save the screen with `RepaintBoundary.toImage(pixelRatio: 3)` to `APP/APPROVED/<FEATURE>/BUILT/<master file name>` - the **same file name as the master** |
| 6 | Run | `SOURCE/tooling/flutter_cached.sh test test_screens/` (allowed by the wrapper). Then the normal `flutter_cached.sh test` and `flutter_cached.sh analyze` must still pass unchanged |
| 7 | Hand back | Task note: "Built from: this brief"; the list of PNGs written; any state you could not reach (and why). Line 11 BUILT or FAILED; commit and push (core rule 2); public checks A-F |

## Masters to render

| Feature | Masters (render each) | Skip (and why) |
|---|---|---|
| DASHBOARD | w01 needs you · w02 nothing needs you · w03 new member · w06 section list · w07 section empty | w04 loading, w05 couldn't load - not built, by Founder decision ("Wait") |
| AGREEMENTS | w08 type · w09 type scrolled · w10 details equal · w11 details set · w12 details error · w13 review · w14 agreement many people · w16 custom warning | w15 who paid - superseded by VERIFICATION w31 (QUESTIONS 7, 8); Who paid? is rendered once, as w31 |
| VERIFICATION | w17 profile · w18 email only · w19 basic · w20 verified · w31 who paid | - |
| TRACK_RECORD | w21 mine shared · w22 mine private · w23 other person | - |
| EVIDENCE | w24 list signed · w25 add · w26 empty · w27 draft removable | - |
| BRAND | w30 in-app mark home top - render the full Home screen in w01's state, then crop x 60-1229, y 186-305 px (390 × 40 pt at x 20, y 62) and save only the crop (QUESTIONS 8) | w28 home-screen icon, w29 launch screen - already checked by the WAFA chat from the asset files (13 Nov: icon matches, launch mark identical) |

The renders are working files for the WAFA chat's comparison; the Founder is not shown PNGs (Founder rule, 8 Nov).
