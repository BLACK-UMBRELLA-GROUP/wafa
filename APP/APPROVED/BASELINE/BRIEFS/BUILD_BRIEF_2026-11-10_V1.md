---
id: DOC-WAFA-0021
type: PLAN
status: SUPERSEDED
feature: APP: BASELINE
purpose: Build brief for queue line 7 - prepare the existing local run prerequisites offline, then take the nine baseline captures (replaces line 2; answers QUESTIONS row 1)
links: [DOC-WAFA-0006, DOC-WAFA-0007, DOC-WAFA-0008]
owner: WAFA chat
---

# BUILD BRIEF — RUN PREREQUISITES + BASELINE CAPTURES — 10 NOV 2026

**Founder-named:** "Answer QUESTIONS row 1, then set lines 3–6 back to WAITING" (10 Nov 2026), on top of the 8 Nov capture line ("Start the dashboard (Recommended)"). Replaces line 2 (FAILED 8 Nov: `SOURCE/.dart_tool/package_config.json` and `SOURCE/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` missing).

**Copy exactly. Unclear or blocked → stop, file it in `APP/APPROVED/QUESTIONS.md`, set this line to QUESTION (rule 10).**

| # | Step | Detail |
|---|---|---|
| 1 | Toolchain | Use the existing Flutter 3.44.2 at the wrapper's default (`/opt/homebrew/Caskroom/flutter/3.44.2/flutter`) or `WAFA_FLUTTER_ROOT` if already set. No SDK install, upgrade, channel change or repair |
| 2 | Packages, offline only | From `SOURCE/`: `./tooling/flutter_cached.sh pub get --offline`. This only uses packages already in the local pub cache and the existing `pubspec.lock`. **If it reports any package that is not cached, stop:** write the exact package names and versions in QUESTIONS.md (that download needs the Founder's approval) and set this line to QUESTION. Do not run pub get without `--offline` |
| 3 | iOS generated files | From `SOURCE/`: `./run.sh --build-only --unsigned` (documented in `README.md`). This creates `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` and an unsigned simulator-compatible build. If Xcode or Swift Package Manager tries to download anything, or the build fails for another reason, stop and file the exact error as a question |
| 4 | Install on the simulator | Install the built `Runner.app` on the existing iPhone Pro Max simulator (`xcrun simctl install`), launch `app.wafa.preview`. Use the existing simulator; create or download none |
| 5 | Captures | Exactly as line 2: 430 × 932 points @3x (1290 × 2796 PNG) into `APP/APPROVED/BASELINE/SCREENSHOTS/member/<area>/<screen>__<state>.png` for Home (top, and scrolled to the bottom), Agreements list, one agreement detail, Payments page, Tracker, Profile, Create step 1, Invitations. If the simulator's screen size is not 430 × 932, capture at its size and record the size in INDEX.md; do not resize or redraw |
| 6 | Index | Rewrite `BASELINE/SCREENSHOTS/INDEX.md`: one row per file (path, screen, state, how reached) plus the source commit, Flutter version and simulator. Keep `RUN.json` as the line 2 history and add a `RUN_LINE7.json` beside it |
| 7 | Nothing committed from the build | `.dart_tool/`, `build/` and `ios/Flutter/ephemeral/` stay uncommitted (already ignored). Commit only the PNGs, INDEX.md and RUN_LINE7.json |
| 8 | Hand back | Task note; mark line 7 BUILT or FAILED; commit and push (core rule 2). Then carry on with line 3 (it waits for this line) |

**Superseded 10 Nov 2026 by V2 (DOC-WAFA-0022):** step 3 was wrong - `run.sh --build-only --unsigned` builds for a real iPhone, not the simulator (QUESTIONS row 2).
