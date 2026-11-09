---
id: DOC-WAFA-0009
type: SPEC
status: CURRENT
feature: APP: DASHBOARD
purpose: Home dashboard - LOCK 1 - "Needs you first" layout with five sections; words, rules, states and masters
links: [DOC-WAFA-0004, DOC-WAFA-0010, DOC-WAFA-0011]
owner: WAFA chat
---

# DASHBOARD SPEC — CURRENT VERSION V1

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCK 1, 8 Nov 2026 |
| Founder's words | "A · Needs you first (Recommended)" · Disputes: "Add later (Recommended)" · "LOCK it" |
| Replaces | The Home tab as built in `SOURCE/lib/main.dart` `dashboard()` (welcome message, green card, two metrics, recent agreements, "A first look at Wafa" note) |
| ROADMAP row | "WAFA design chat specifies the dashboard" (5 h) - finished by this LOCK |
| Masters | `MASTERS/` - 1290 × 2796 PNG (iPhone 15 Pro Max, 430 × 932 @3x). Prototype source: `APP/APPROVED/PROTOTYPE/wafa-prototype.html` (V4) |

## 1. Home screen, top to bottom (master w01)

| # | Part | Exact content | Rule |
|---|---|---|---|
| 1 | Top row | Existing `BrandMark`, existing `DemoBadge` ("PREVIEW"), round profile button on the right showing the member's first initial | Profile button opens the Profile tab (as today) |
| 2 | Greeting | "Good morning, {first name}" - 26 pt, bold | "Good morning" before 12:00, "Good afternoon" 12:00-17:59, "Good evening" from 18:00, device time |
| 3 | Sub-line | "{d MMM} · {n} agreement running" / "{n} agreements running" | n = Active + Overdue agreements |
| 4 | Needs you card | Heading "Needs you", right: "{n} thing" / "{n} things". One row per item, in this order: (a) each open invitation, (b) each Overdue agreement, (c) each Awaiting signatures agreement, (d) each Active agreement due in 7 days or fewer | Row = coloured stripe · title line · detail line · "Open ›". Whole row is tappable |
| 4a | Invitation row | "Invitation · {inviter name}" / "Asks you to join an agreement" | Stripe green. Opens Invitations (as today's "Invitations · n waiting" button does). Keep the key `open-invitations` on the first invitation row |
| 4b | Overdue row | "{title} · {other person}" / "{d} days overdue · £{left} left" ("1 day overdue") | Stripe red. Opens the agreement |
| 4c | Awaiting row | "{title} · {other person}" / "Waiting for your signature" | Stripe amber. Opens the agreement |
| 4d | Due-soon row | "{title} · {other person}" / "Due in {d} days · £{left} left" ("Due tomorrow", "Due today") | Stripe green. Opens the agreement |
| 5 | Calm card (when 4 has no rows, master w02) | Tick icon · "Nothing needs you today" / "We'll tell you when a payment or signature is due." | Mint card, replaces the Needs you card |
| 6 | Section heading | "Your agreements" · "See all" | "See all" opens the Agreements tab |
| 7 | Five section tiles | Active · Drafts · Awaiting signatures · Completed · Overdue - big number + label. Row 1: three tiles; row 2: two wider tiles | Tap opens that section's list (§3). A tile with 0 shows the number in grey. The Overdue tile turns light red with a red number when it is 1 or more. Active counts Active only (Overdue has its own tile) |
| 8 | Next payment (calm state only, w02) | Heading "Next payment" + the existing `AgreementTile` of the Active agreement due soonest | Shown only when the Needs you card is empty, so no agreement appears twice |
| 9 | Create button | Full-width green "+ Create an agreement" at the bottom of the content, above the tab bar | Opens the existing three-step create flow; keep the key `create-agreement` |

Colours are the existing `WafaColors` (green #123F32, ink #182D25, muted #68776F, mint #EDF5EF, line #E3EAE5). Red #A3312A on #FBECEA; amber #9B541D on #FCF2E8 (the existing warning pair). Content fills the screen; the Create button sits at the bottom with no dead space below it on the Pro Max. On small phones the page scrolls.

## 2. Other Home states

| State | Master | What shows |
|---|---|---|
| New member - no agreements | w03 | Top row · "Welcome, {first name}" · centre: document icon, "No agreements yet", "Write down what you agree with someone, sign it together, and keep track of every payment." · bottom: green "+ Create your first agreement", outlined "Invitations · {n} waiting" (hidden when n = 0) |
| Loading | w04 | Top row, then grey placeholder blocks in the shape of w01 (greeting, card, 3 + 2 tiles, rows) |
| Couldn't load | w05 | Top row · greeting · red-tinted card: "Your agreements didn't load" / "Check your connection, then try again. Nothing you saved has been lost." / green "Try again" · outlined "+ Create an agreement" at the bottom |

Loading and Couldn't load are recorded now so the look is fixed, but the demo keeps its records in memory and can never be loading or fail. **Do not build w04 or w05 now** (no unreachable code); they are built with the first real backend.

## 3. Section list page (new)

| Part | Content | Master |
|---|---|---|
| Header | Round back button · section name ("Overdue") | w06 |
| List | Existing `AgreementTile` for each agreement in that section, soonest due date first | w06 |
| Empty | Document icon · "Nothing here yet" · one line per section: Active "No active agreements." · Drafts "No drafts. Agreements you start but don't send wait here." · Awaiting "Nothing waiting for a signature." · Completed "No completed agreements yet." · Overdue "Nothing overdue." | w07 |
| Tab bar | Stays visible; tapping a tab leaves the list | w06 |

## 4. Moves and removals

| Item | Where it goes |
|---|---|
| "A first look at Wafa" note (fictional examples only) | Top of the Profile tab, text unchanged, above "Built around keeping your word" |
| "Invitations · n waiting" button | Becomes the invitation row(s) in Needs you (and the outlined button in the new-member state) |
| Welcome message, green "Your agreements" card, two metrics, "Recent agreements" list | Removed from Home (no dead code) |

## 5. Must not change

Bottom tab bar (labels and icons as built) · Agreements, Tracker, Profile tabs (apart from §4) · agreement detail, document copy, payments, create and invitation flows · example records · app title.

## 6. Not decided

| Item | Note |
|---|---|
| Disputes section | Added when the dispute flow is designed (Founder 8 Nov "Add later") |
| Reminders ("Remind" action) | Rows say "Open ›" only; the app does not send reminders yet |

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-08 | V1 | LOCK 1 - Founder: "A · Needs you first (Recommended)", "Add later (Recommended)", "LOCK it" |
