---
id: DOC-WAFA-0012
type: SPEC
status: CURRENT
feature: APP: AGREEMENTS
purpose: LOCK 2 - seven launch agreement types and many people on one agreement (create flow, agreement page, who paid)
links: [DOC-WAFA-0002, DOC-WAFA-0009, DOC-WAFA-0013, DOC-WAFA-0014]
owner: WAFA chat
---

# AGREEMENTS SPEC — CURRENT VERSION V1

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCK 2, 8 Nov 2026 |
| Founder's words | Types: "a - plus custom agreemtn and family agreement, we have to also figure a multi agreement way for example family" · "Many people, one agreement" · "LOCK both (Recommended)" · Signing: "it would be option 2" (everyone signs, witnesses included) |
| ROADMAP row | "Define MVP contract types" (4 h) - finished by this LOCK |
| Masters | `MASTERS/w08`-`w16`, 1290 × 2796. Prototype V8: `APP/APPROVED/PROTOTYPE/wafa-prototype.html` |
| Research behind it | Kept privately (public-repo rule): not a religious or legal ruling; scholar and solicitor review still needed before public claims |

## 1. Launch types (Type step, masters w08, w09)

Order, words and icons exactly as below. Heading and sub-text unchanged from the app ("Every promise starts here." / "Choose what you would like to record. You can review everything before saving.").

| # | Type | Description line | Icon (Material) | Change |
|---|---|---|---|---|
| 1 | Interest-free loan | Qard Hasan · Record what is lent and repaid | handshake_outlined | As built |
| 2 | Sale | Make the item, price and handover clear | shopping_bag_outlined | As built |
| 3 | Item lending | Lend something for free and agree when it comes back | inventory_2_outlined | **New** |
| 4 | Item rental | Hire out a car, tools or equipment. Not homes or rooms | key_outlined | **Replaces Rental** (homes and rooms are out at launch) |
| 5 | Service | Set out the work, timing and agreed value | work_outline_rounded | As built |
| 6 | Family agreement | Record what family members agree between them | groups_outlined | **New** |
| 7 | Custom agreement | Write your own terms | edit_note_rounded | **New** |

Under the list: "Later, after review: business partnership, charity pledge, employment." (muted, 13 pt). The list scrolls on small screens; Continue stays at the bottom.

## 2. Details step - many people (masters w10, w11, w12, w16)

Replaces the single "Who is this with?" field. Keeps the step bar, "Make the details clear.", the optional title and the due date as built.

| Part | Exact content | Rule |
|---|---|---|
| Sub-line | "{Type} · add everyone who is part of it." | |
| Agreement title | "Agreement title" + "optional", hint "Give this promise a name" | As built |
| Who's in it | Heading "Who's in it", right "{n} people". One row per person: initial circle · name ("You" for the member) · role chip · amount on the right · "×" to remove (not on "You") | Starts with You (Owes a share) and one more person (Is owed) |
| Role chip | "Owes a share ▾" (amber) · "Is owed ▾" (green) · "Witness ▾" (blue-grey). Tap cycles the three | Any type can have any number of people |
| Add a person | "+ Add a person" | Picks from the member's saved Wafa contacts or by Wafa ID, using the existing person-finding in the participants flow. No phone contacts |
| Split | Two-part switch: "Split equally" · "Set each amount" | Default Split equally |
| Split equally | "Total amount" field (£); line under it: "{n} people owe £{x} each" / "1 person owes £{x} each" / "Nobody owes a share yet" | Pennies left over go to the first people in the list, so shares always add up to the total |
| Set each amount | Each "Owes a share" row gets its own £ field; line "Total: £{sum}" | Total = sum of shares |
| Is owed / Witness rows | Amount shows "—" | They owe nothing |
| Due date | "Due date" field, as built | |
| Custom warning (Custom only, w16) | Amber box: "Your own terms must not include interest or anything prohibited. If you are unsure, ask a scholar before you sign." | Shown above Review draft |
| Errors (w12) | Red box above "Review draft", one at a time, in this order: "Someone needs to owe a share." · "Someone needs to be owed." · "Enter an amount above £0." · "Give everyone who owes a share an amount above £0." | Clears on any change |
| Button | "Review draft" | |

## 3. Review step (master w13)

Title = agreement title (or type name). "Take a moment to check your draft. Nothing is signed or sent." Summary card: Type · Total · People · Currency "British pound (GBP)". People list read-only (name, role, share). Line: "Each person gets an invitation and signs the same agreement. It becomes active when everyone has signed, witnesses too." Button "Save draft".

On save: the draft is created with every person and their role and share, and an invitation is prepared for each person other than You (existing invitation flow; their role carried over). A two-person agreement still shows the other person's name wherever the app shows the counterparty today.

## 4. Agreement page with three or more people (master w14)

| Part | Content |
|---|---|
| Who's in it | Heading + "{n} people"; one row per person: initial · name/"You" · "{role}" and for Owes a share " · £{paid} of £{share} paid" · small progress bar for people who owe |
| Summary | Type · Amount · Paid · Due (the "With" row is dropped when there is a people list) |
| Rest | Progress bar, "{x}% paid · £{left} left", "View the agreement copy" and the bottom action as built |

## 5. Who paid? (master w15)

"Record a payment" on an agreement with people who owe opens **Who paid?** first: "{title} · choose who this payment is from." and one row per person who owes: initial · name · "£{paid} of £{share} paid" · right "£{left} left" or "Paid" (row disabled when paid). Tapping a row opens the existing payment form for that person; the payment is counted against their share and the total. Overpaying a share is not allowed.

## 6. Signing rule (recorded now, built with signing)

An agreement becomes Active only when **every person has signed, witnesses included** (Founder: "option 2"). The demo collects no signatures today ("Joining is not signing"), so this build changes only the review line in §3; the rule is built when signing is designed.

## 7. Example records

| Change | Detail |
|---|---|
| Studio rental → Van hire | Same person, amount and dates; type Item rental |
| New: Mum's care costs | Family agreement, £300, due 30 Nov 2026, Active: You owe £150 (paid £100), Omar Farooq owes £150 (paid £0), Sara Malik is owed. Fictional |

LOCK 1 dashboard masters w01-w07 were re-rendered with these records (layout unchanged; see the dashboard LOCK record).

## 8. Must not change

Step bar and step names · Home (LOCK 1) · agreement copy wording · payment form fields · invitation confirmation ("Is this the right person?") · Interest-free loan has no interest, fee or extra-repayment field.

## 9. Not decided

| Item | Note |
|---|---|
| Witness number and make-up | Not encoded; scholar question |
| Item lending: who carries a loss if the item is damaged | Scholar question before any wording |
| Business partnership, charity pledge, employment | Later, after review |
| Automatic check of custom terms | Later (approved compliance-engine feature) |

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-08 | V1 | LOCK 2 - Founder words above |
