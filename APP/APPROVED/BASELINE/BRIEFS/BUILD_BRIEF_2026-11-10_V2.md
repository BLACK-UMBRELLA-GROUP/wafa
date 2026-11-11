---
id: DOC-WAFA-0022
type: PLAN
status: CURRENT
feature: APP: BASELINE
purpose: Build brief V2 for queue line 7 - add a simulator option to run.sh, build offline for the simulator, then take the nine baseline captures (answers QUESTIONS row 2; replaces V1)
links: [DOC-WAFA-0021, DOC-WAFA-0007, DOC-WAFA-0008]
owner: WAFA chat (written by Fable on the Founder's answer)
---

# BUILD BRIEF V2 — SIMULATOR OPTION + BASELINE CAPTURES — 10 NOV 2026

**Founder, 10 Nov 2026 (clickable answer to "How should it build for the simulator?"):** "Add simulator option (Recommended)". Answers QUESTIONS row 2. Replaces V1 (DOC-WAFA-0021), whose step 3 wrongly called `run.sh --build-only --unsigned` simulator-compatible: that command uses `-sdk iphoneos` and makes `Release-iphoneos/Runner.app` for real iPhones.

**Copy exactly. Unclear or blocked → stop, file it in `APP/APPROVED/QUESTIONS.md`, set this line to QUESTION (rule 10). No downloads, installs, upgrades or SDK changes of any kind.**

| # | Step | Detail |
|---|---|---|
| 1 | Toolchain | The existing Flutter 3.44.2 at the wrapper's default, the existing Xcode and the existing simulators only |
| 2 | Packages, offline only | From `SOURCE/`: `./tooling/flutter_cached.sh pub get --offline`, only if `.dart_tool/package_config.json` is missing. A package not in the local cache → stop and file its exact name and version as a question |
| 3 | Add `--simulator` to `SOURCE/run.sh` | A new option, valid only together with `--build-only` (refuse it with `--device`, with a clear message). It builds for the iOS Simulator, unsigned, with the same offline guards the script already has (`--no-pub`, `-disableAutomaticPackageResolution`, `-skipPackageUpdates`) and the same bundle ID check. Flutter builds for the simulator in Debug only, so this option builds Debug for the simulator SDK and prints the path of the `Runner.app` it made. If the installed Flutter supports something else, use what it supports and record it in the task note. Nothing about the existing `--device` and `--build-only` paths may change: their commands, outputs and messages stay byte-for-byte the same |
| 4 | Check the script | `bash -n SOURCE/run.sh`; `./run.sh --help` shows the new option; `./run.sh --simulator` without `--build-only` and `./run.sh --device X --simulator` both refuse; the existing script tests, if any, still pass |
| 5 | Documents | Update the usage text in `run.sh`, and the run sections of `README.md` and `SOURCE/README.md`, so they say plainly which command builds for a real iPhone and which for the simulator. Public repository: run the usual public checks A-F |
| 6 | Build and install | From `SOURCE/`: `./run.sh --build-only --simulator`. Install the built app on the existing iPhone Pro Max simulator (`xcrun simctl install`) and launch `app.wafa.preview`. Create or download no simulator. If Xcode or Swift Package Manager tries to download anything, stop and file the exact message as a question |
| 7 | Captures | Exactly as V1 step 5: 430 × 932 points @3x (1290 × 2796 PNG) into `APP/APPROVED/BASELINE/SCREENSHOTS/member/<area>/<screen>__<state>.png` for Home (top, and scrolled to the bottom), Agreements list, one agreement detail, Payments page, Tracker, Profile, Create step 1, Invitations. If the simulator's screen size differs, capture at its size and record it in INDEX.md; do not resize or redraw. The app already hides the debug banner (`debugShowCheckedModeBanner: false`); if a banner still shows, file a question instead of changing app code |
| 8 | Index | Rewrite `BASELINE/SCREENSHOTS/INDEX.md`: one row per file (path, screen, state, how reached) plus the source commit, Flutter version, simulator and the words "Debug simulator build". Keep `RUN.json` as the line 2 history and add `RUN_LINE7.json` beside it |
| 9 | Nothing committed from the build | `.dart_tool/`, `build/` and `ios/Flutter/ephemeral/` stay uncommitted. Commit only `run.sh`, the two READMEs, the PNGs, INDEX.md and RUN_LINE7.json |
| 10 | Hand back | Task note; mark line 7 BUILT or FAILED; commit and push (core rule 2). Shut the simulator down afterwards. Then carry on with line 3 (it waits for this line) |

**Approval rule (AD-AIOS-139):** if any step waits more than 15 minutes on an approval, mark the line FAILED and file a QUESTIONS row.

## Clarification — 10 Nov 2026 (QUESTIONS row 3, WAFA chat)

Step 3's offline guards are exactly the three already in `run.sh`: `--no-pub` (Flutter), `-disableAutomaticPackageResolution` and `-skipPackageUpdates` (xcodebuild). **Do not wrap any command in `sandbox-exec`** - Xcode's package resolver cannot start inside another sandbox (`sandbox_apply: Operation not permitted`). The Swift packages are local path packages only (`FlutterGeneratedPluginSwiftPackage` → `../.packages/FlutterFramework`); nothing can be downloaded. Before building: `grep -rn 'url:' ios/Flutter/ephemeral/Packages` must find nothing - otherwise stop and ask.

## Clarification 2 — 10 Nov 2026 (QUESTIONS row 4, WAFA chat)

Xcode's system components were installed by Shakeel himself. Check `xcodebuild -checkFirstLaunchStatus` exits 0 first (otherwise stop). Install with headless `simctl` on the existing simulator. Navigate and capture with an integration test (`integration_test` from the Flutter SDK only, offline) run through `./tooling/flutter_cached.sh test ... -d <UDID>`; screenshots via `xcrun simctl io <UDID> screenshot` or the integration_test API. Keep the test for later build renders. No app code change, no download, no system install.
