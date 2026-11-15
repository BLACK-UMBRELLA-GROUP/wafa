---
id: DOC-WAFA-0031
type: SPEC
status: CURRENT
feature: APP: AGREEMENT RULES
purpose: LOCK 7 - agreement rules: the person owed confirms payments, only they mark it paid in full, the creator is never the witness
links: [DOC-WAFA-0009, DOC-WAFA-0012, DOC-WAFA-0032]
owner: WAFA chat
---

# AGREEMENT RULES — CURRENT VERSION V1 (LOCK 7)

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCKed 13 Nov 2026 |
| Founder's words | "Yes, they confirm (Recommended)" · "Only the person owed (Recommended)" · "No, never (Recommended)" · "A · Waiting box (Recommended)" · "LOCK it (Recommended)" |
| Prototype | WAFA prototype V22 (Family support = you are owed; Mum's care costs = you owe) |
| Masters | `MASTERS/` w32-w38, 1290 × 2796 |
| Why | Project audit 13 Nov (A-11): the app let anyone record a payment that counted at once, let the person who owes mark a debt complete, and let the creator be the witness |

## 1. Rules

| # | Rule |
|---|---|
| R1 | A payment recorded by anyone who is **not** owed is **waiting**. A waiting payment does not count anywhere: not in Paid, the "% paid" line, progress bars, Overdue, Home or the Tracker |
| R2 | A payment recorded by a person who is owed counts straight away (recording it is confirming it) |
| R3 | The person owed confirms each waiting payment: **Confirm** (it counts, dated the day it was recorded) or **Not received** (it leaves the waiting list; the person who recorded it is told) |
| R4 | No time limit and no automatic confirmation |
| R5 | Only a person who is owed can **Mark as paid in full**. It records the rest of the amount as one confirmed payment dated today ("Marked paid in full by {name}"), clears any waiting payments and makes the agreement Completed |
| R6 | When confirmed payments reach the total, the agreement becomes Completed (as today) |
| R7 | The creator can never be the witness. In the create flow the creator's chip cycles only "Owes a share ▾" ↔ "Is owed ▾"; tapping it from "Is owed" shows the message in §4 |
| R8 | Paid + waiting can never be more than a person's share (or the total, for two-person agreements) |

## 2. Agreement page (w33, w34, w36, w37)

| Part | Spec |
|---|---|
| Waiting box | Only when something is waiting. Placed after the "{x}% paid · £{left} left" line, before Evidence. Background amber light (`warnBg`), radius 16, padding 12 × 14, gap 8 |
| Heading | "Waiting to be confirmed" · 14 pt bold · amber (`warn`) |
| Each row | "£{amount} from {First name}" (or "from you") · 13.5 pt ink. Under it, 12 pt muted: viewer owed → "Recorded {d MMM} · only you can confirm it"; anyone else → "Recorded {d MMM} · counts once {First name of person owed} confirms" |
| Buttons | Viewer owed only: "Confirm" and "Not received" (the existing small outlined chip buttons), on the right of the row |
| Bottom (Active or Overdue) | Viewer owed: outlined full-width button "Mark as paid in full" under the main button, then 12.5 pt muted centred line "Only you can do this, because you are owed." Anyone else: only the line "Only {First name} can mark this as paid in full." |
| Removed | Any existing "mark complete" control for people who are not owed |

## 3. Who paid? (w35) and Home (w32)

| Part | Spec |
|---|---|
| Who paid? sub-line | Add "It counts once {First name} confirms." after the existing sub-line (not shown when the viewer is owed) |
| Who paid? row | Second line "£{paid} of £{share} paid · £{waiting} waiting" (the waiting part only when above £0). Right side: "£{share − paid − waiting} left"; "Waiting" when that is £0 and something waits; "Paid" when paid = share. Row disabled when paid + waiting = share |
| Home "Needs you" | New row for the person owed, one per waiting payment: amber stripe; title "{agreement title} · {other person}"; detail "{First name} says they paid £{amount} · confirm it"; "Open ›" opens the agreement page. Order: invitation › overdue › waiting for your signature › **confirm a payment** › due soon. Counted in "{n} things" |

## 4. Messages

| When | Message |
|---|---|
| Someone not owed records | "£{amount} from {you / First name} recorded. It counts once {First name} confirms." |
| The person owed records | "£{amount} recorded. You are owed, so it counts straight away." |
| Confirm | "Confirmed. £{amount} now counts as paid." · if that completes it: "Confirmed. Everything is paid, so the agreement is complete." |
| Not received | "Marked as not received. {First name} is told." |
| Mark as paid in full | "Marked as paid in full. The agreement is complete." |
| Creator taps Witness | "You can’t be the witness on your own agreement. A witness is someone else." |

## 5. Demo data

| Item | Value |
|---|---|
| Waiting payment | On the demo loan where the signed-in demo person is owed (prototype: Family support · Yusuf Rahman): one waiting payment of £40 from the other person, recorded 5 days before the demo's today |
| Everything else | Unchanged |

## 6. Must not change

LOCK 1-6 screens and rules except where this spec says so; LOCK 1-6 masters are **not** re-rendered (lesson: masters show only what their own line builds). No new tab, field or setting.

## 7. Not decided

| Item | Note |
|---|---|
| Several people owed on one agreement | For now any person who is owed may confirm and mark paid in full |
| What follows "Not received" | Disputes - "Add later" (Founder, 8 Nov) |
| Reminders to confirm | Later |
| Witness number and make-up | Still a scholar question (LOCK 2 §9) |

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-13 | V1 | LOCK 7 |
