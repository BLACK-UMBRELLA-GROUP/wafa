---
id: DOC-WAFA-0007
type: REGISTER
status: CURRENT
feature: GOVERNANCE
purpose: Build queue - every LOCKed brief waits here; Codex builds WAITING lines at 01:00 or on GO (charters rule 9)
links: [AD-AIOS-115]
owner: WAFA chat
---

# BUILD QUEUE - WAFA

Only the WAFA chat (Claude) writes here, and only after Shakeel says LOCK. Codex builds every WAITING line in order:
at his 01:00 job, or at once when Shakeel types GO in the WAFA Codex chat. Codex changes only the Status column and
adds the task-note date; he never adds a line. A FAILED line stays until the WAFA chat decides. Fable checks at 04:15
that every BUILT line has a LOCK record. Newest line at the bottom. A line blocked only by another line not yet BUILT stays WAITING with the note "waits for line N" - never FAILED (Founder, 1 Nov). A line whose Note begins with PRIORITY is built before every other WAITING line in every queue, after the line in progress (Founder, 1 Nov; only Shakeel or Fable quoting him may write it). QUESTION = Codex filed a question in `QUESTIONS.md` beside this file and moved on; the business chat answers and sets the line back to WAITING (rule 10).

| # | Added | Brief path | Status (WAITING / BUILT / FAILED / QUESTION) | Built on | Note |
|---|---|---|---|---|---|
| 1 | 2026-11-08 | WAFA/APP/APPROVED/BUILD_QUEUE.md (this line is the brief) | BUILT | 2026-11-08 | Founder, 8 Nov (AD-AIOS-131, via Fable: WAFA's freeze is lifted; THE FOUR GATES and WAFA are the two active businesses). Documentation only, no app code. (a) `README.md` Status: replace "Feature development is paused while the Founder's first product (ZYRA) reaches launch." with "WAFA is active again (8 Nov 2026): design work goes ahead with the WAFA design chat, and features are built only from LOCKed briefs in `APP/APPROVED/BUILD_QUEUE.md`." (b) `README.md` How work is done: delete "; its current task list is empty" and replace the last sentence ("Review, documentation and ... do not lift the app feature freeze.") with "Nothing is built without a LOCK." (c) `ROADMAP.md` second paragraph: replace "App feature development is paused until ZYRA launches. The current `APP/APPROVED/BUILD_QUEUE.md` has no task rows, and no venture outstanding-actions index is present in the routed location." with "WAFA is active again (Founder, 8 Nov 2026). Work is built only from LOCKed briefs in `APP/APPROVED/BUILD_QUEUE.md`." (d) `ROADMAP.md` Gates, item 1: append " - done 8 Nov 2026." Do not change any ROADMAP row, estimate or hours; no ROADMAP row is finished, so close no GitHub issue. Search both files for any other "paused" / "freeze" sentence; if one remains, file it in QUESTIONS.md, do not invent wording. Neutral wording (rule 12). Check: `grep -niE "paused|freeze" README.md ROADMAP.md` shows only the Gate 1 line. Commit and push (core rule 2) |
| 2 | 2026-11-08 | WAFA/APP/APPROVED/BUILD_QUEUE.md (this line is the brief) | FAILED | 2026-11-08 | Founder-named, 8 Nov ("Start the dashboard (Recommended)"; PROTOTYPE_STANDARD §3 and §9 step 2: real screen first). Capture only, no code change. Run the current app in the iPhone simulator at 430 × 932 @3x and save PNGs to `APP/APPROVED/BASELINE/SCREENSHOTS/member/<area>/<screen>__<state>.png` for: Home (top, and scrolled to the bottom), Agreements list, one agreement detail, Payments page, Tracker, Profile, Create step 1, Invitations. Add `BASELINE/SCREENSHOTS/INDEX.md`: one row per file (path, screen, state, how reached). Example records only. If the simulator cannot run, mark FAILED with the reason; do not draw screens. Commit and push (core rule 2) |
