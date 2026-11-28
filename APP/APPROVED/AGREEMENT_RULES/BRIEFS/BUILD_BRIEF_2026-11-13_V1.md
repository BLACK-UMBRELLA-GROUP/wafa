---
id: DOC-WAFA-0033
type: PLAN
status: CURRENT
feature: APP: AGREEMENT RULES
purpose: Build brief for queue line 12 - LOCK 7 agreement rules
links: [DOC-WAFA-0031, DOC-WAFA-0032]
owner: WAFA chat
---

# BUILD BRIEF — AGREEMENT RULES — LOCK 7 — 13 NOV 2026

**Copy exactly. No improvements. Unclear or conflicting → stop, file it in `APP/APPROVED/QUESTIONS.md`, set the line to QUESTION (rule 10).**

Build after line 11 **and** after the WAFA chat has recorded the line 11 build check (Founder, 13 Nov: the build waits until the check is done).

Needs: `NEEDS line 11 BUILT - Founder 13 Nov: line 12 is built only after the line 11 build check is recorded, and line 12's captures use line 11's capture method` (Fable 27 Nov, QUESTIONS 9). Master w36's "Demo: confirm as Sara" is a prototype-only helper - build no such control (spec section 2); captures use a fixed demo today of 12 Nov 2026 (spec section 5 gives 7 Nov for the Family support payment); the £50 from Omar recorded 8 Nov on w36 is a capture-only test fixture (Fable removed the demo link from master w36 on 27 Nov). No ROADMAP row; name it "LOCK 7 agreement rules" in the commit.

| # | Step | Detail |
|---|---|---|
| 1 | Read | `AGREEMENT_RULES/RECORD/AGREEMENT_RULES_SPEC_CURRENT_VERSION_V1.md` (all), its LOCK record, every master w32-w38 |
| 2 | Check first | How the app knows who is owed on a two-person agreement. If it is not stored, stop and file a QUESTION - do not guess |
| 3 | Domain | Payments get a state: waiting / confirmed. Recording, confirming, "not received" and "mark as paid in full" take the acting person and enforce R1-R8 in the domain layer, not only in screens (audit C-02) |
| 4 | Screens | Spec §2-§4 exactly: Waiting box, bottom button and line, Who paid? rows, Home "Needs you" row and order, messages. Remove any "mark complete" control for people who are not owed |
| 5 | Create flow | R7: the creator's chip never offers Witness; the message in §4 |
| 6 | Demo data | Spec §5 |
| 7 | Nothing else | No other screen, wording, tab or setting; no downloads; LOCK 1-6 masters untouched |
| 8 | Tests | One test per rule R1-R8 (keys, not copy where possible); the Needs you order; existing tests updated only where this spec changes behaviour; `flutter analyze` clean |
| 9 | Hand back | Task note with "Built from:" these paths; render w32-w38 into `AGREEMENT_RULES/BUILT/` with the line 11 method; line 12 BUILT or FAILED; commit and push (core rule 2); public checks A-F |
