---
id: EVID-WAFA-BASELINE-2026-11-08
type: EVIDENCE
status: FAILED
feature: BASELINE
purpose: Real app capture outcome for build queue line 2
owner: Codex
---

# Current app baseline — 8 November 2026

FAILED. No PNG files were captured. No baseline or visual acceptance is claimed.

The existing iPhone simulator booted, but had no `app.wafa.preview` installation.
The documented `SOURCE/run.sh --build-only --unsigned` stopped because dependencies
are not prepared (`SOURCE/.dart_tool/package_config.json` is absent). The cached
unsigned Debug simulator build then failed in Xcode: the local generated package
`SOURCE/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` is missing.
Commands, exit codes, source commit and simulator details are in [RUN.json](RUN.json).
The simulator was returned to its initial Shutdown state.

Requested capture: 430 × 932 points at 3x (1290 × 2796 PNG pixels), using example
records only. Required screens: Home top, Home scrolled to bottom, Agreements list,
one agreement detail, Payments, Tracker, Profile, Create step 1 and Invitations.
None was reachable. Device resolution was not verified because WAFA could not run.

## Captured PNG files

| Path | Screen | State | How reached |
|---|---|---|---|

There are no file rows because no screenshots exist.

Written refusal: dependency preparation, downloads, simulator configuration changes
and app changes are outside this capture-only task. No screens were drawn or
substituted. The lead owner must resolve the local run prerequisites and requeue
line 2 before a real baseline can be captured. No other queue line was worked.
