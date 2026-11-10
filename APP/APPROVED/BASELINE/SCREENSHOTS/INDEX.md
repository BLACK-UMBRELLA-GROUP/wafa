---
id: EVID-WAFA-BASELINE-2026-11-08
type: REPORT
status: CURRENT
feature: BASELINE
purpose: Real app capture outcome for WAFA build queue line 7
owner: Codex
---

# Current app baseline, 10 November 2026

**FAILED. 0 of 9 native screenshots captured.** The unsigned Wafa 0.1.0 build 3 bundle used the old layout at source commit `5315573a5be88802313e97a59b527d8279f7bbde`, with Flutter 3.44.2 and Xcode 27.2 (27B52). Debug simulator build.

| iPhone 18 Pro Max runtime | Result |
|---|---|
| iOS 27.2 | Boot completed after the single simulator service restart. `simctl install` timed out after 45 seconds (timeout wrapper exit 124, no simulator diagnostic). |
| iOS 27.0 | The 95-second boot check and a further 90-second check on the same boot both timed out (wrapper exit 124). The last status at 3m 12s was `Waiting on Data Migration`, running `com.apple.dataaccess.migrator (DAAccount.migrator)`. Install was not reached. |

Both simulators were verified shut down. The iOS 27.0 simulator's primary display reported 1320 × 2868 native pixels at 3× (440 × 956 points) via `simctl io enumerate`. This is a display measurement.

## Captured PNG files

No files. The integration runner never launched. The nine requested states were Home top and bottom, Agreements list and detail, Payments, Tracker, Profile, Create step 1, and Invitations.

The two route results and earlier line 7 attempt are recorded in [RUN_LINE7.json](RUN_LINE7.json). Line 2's history is in [RUN.json](RUN.json).
