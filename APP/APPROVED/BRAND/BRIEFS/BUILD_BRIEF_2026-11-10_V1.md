---
id: DOC-WAFA-0029
type: PLAN
status: CURRENT
feature: APP: BRAND
purpose: Build brief for queue line 9 - LOCK 6 app icon, launch screen, in-app logo
links: [DOC-WAFA-0027, DOC-WAFA-0028]
owner: WAFA chat
---

# BUILD BRIEF — APP ICON + LAUNCH SCREEN — LOCK 6 — 10 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 8. No ROADMAP row (brand work); name it "LOCK 6 brand" in the commit.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `BRAND/RECORD/BRAND_SPEC_CURRENT_VERSION_V1.md` (all), its LOCK record, everything in `BRAND/MASTERS/` |
| 2 | Icon | Update `SOURCE/tooling/generate_icon.swift` to draw spec §1-§2 (white waw, mint dot, #123F32), run it from `SOURCE/` to regenerate every AppIcon size. Compare the 1024 px output with `BRAND/MASTERS/wafa_icon_1024.png` |
| 3 | Launch screen | Spec §3: storyboard background #123F32; LaunchImage @1x/@2x/@3x = the launch mark (draw with the same tool, or copy `BRAND/MASTERS/wafa_launch_mark@*.png`); light status bar during launch |
| 4 | In-app logo | Spec §4 in `BrandMark` |
| 5 | Nothing else | No other screen, name, bundle ID or signing change; no downloads |
| 6 | Tests | `BrandMark` shows the icon and "wafa", no leaf; existing tests pass; `flutter analyze` clean |
| 7 | Hand back | Task note (icon 1024 beside master); line 9 BUILT or FAILED; commit and push (core rule 2) |

## Founder note — 10 Nov 2026 (WAFA chat)

Founder: "Build now, check on my iPhone (Recommended)". The simulator on the Mac is not working, so: do not wait for baseline captures (line 7 is WITHDRAWN), and **skip the simulator render step** - say in the task note that renders were skipped. Widget tests still run. The WAFA chat checks the result on Shakeel's iPhone after queue line 10 installs it.
