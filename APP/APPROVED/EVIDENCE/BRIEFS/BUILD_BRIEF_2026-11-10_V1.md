---
id: DOC-WAFA-0025
type: BRIEF
status: CURRENT
feature: APP: EVIDENCE
purpose: Build brief for queue line 8 - LOCK 5 Evidence Vault
links: [DOC-WAFA-0023, DOC-WAFA-0024]
owner: WAFA chat
---

# BUILD BRIEF — EVIDENCE VAULT — LOCK 5 — 10 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 6. ROADMAP row: **"Define Evidence Vault limits and pricing"** - tick it and close its GitHub issue when this line is BUILT.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `EVIDENCE/RECORD/EVIDENCE_SPEC_CURRENT_VERSION_V1.md` (all), its LOCK record, masters w24-w27, `AGREEMENTS/MASTERS/w14`, today's agreement-detail capture (line 7) |
| 2 | Data | Evidence list per agreement, in memory; spec §4 example records |
| 3 | Section | Spec §2 on the existing agreement detail page, in the stated place |
| 4 | Add page | Spec §3 with its messages |
| 5 | Rules | Spec §1: 25-file limit, removal only in Draft and only by the adder, nothing real (no camera, mic, photo library, upload, network, no new permissions or Info.plist keys) |
| 6 | Tests | Section on every agreement; empty text; meter count; 25-file limit message; type required message; × only in Draft and gone after the status leaves Draft; example records. `flutter analyze` clean, all tests pass |
| 7 | Render | w24-w27 and w14 into `EVIDENCE/BUILT/V1/` as `<master>__master_beside_build.png` |
| 8 | Hand back | Task note; line 8 BUILT or FAILED; tick the ROADMAP row and close its issue; commit and push (core rule 2) |

## Founder note — 10 Nov 2026 (WAFA chat)

Founder: "Build now, check on my iPhone (Recommended)". The simulator on the Mac is not working, so: do not wait for baseline captures (line 7 is WITHDRAWN), and **skip the simulator render step** - say in the task note that renders were skipped. Widget tests still run. The WAFA chat checks the result on Shakeel's iPhone after queue line 10 installs it.
