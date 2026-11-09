---
id: DOC-WAFA-0015
type: SPEC
status: CURRENT
feature: APP: VERIFICATION
purpose: LOCK 3 - optional verification with two badges (Basic, Verified); Profile row, Verification page, badges next to names
links: [DOC-WAFA-0002, DOC-WAFA-0012, DOC-WAFA-0016, DOC-WAFA-0017]
owner: WAFA chat
---

# VERIFICATION SPEC — CURRENT VERSION V1

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCK 3, 8 Nov 2026 |
| Founder's words | "A · Two badges (Recommended)" · "No, always optional (Recommended)" · "LOCK it (Recommended)" |
| ROADMAP row | "Define verification tiers" (4 h) - finished by this LOCK |
| Masters | `MASTERS/w17`-`w20`, 1290 × 2796; badges also in `AGREEMENTS/MASTERS/w10`-`w15` (re-rendered). Prototype V10 |

## 1. Rules

| # | Rule |
|---|---|
| 1 | Two badges only. **Basic** = email and phone confirmed. **Verified** = photo ID and a live selfie checked. Email only = no badge |
| 2 | Verification is **always optional**. No agreement, role or amount requires it |
| 3 | The badge shows next to the person's name wherever people are listed on an agreement (Who's in it, review, agreement page, Who paid?) and next to the member's own name on Profile |
| 4 | Demo app: every check is simulated with fictional data - no codes are sent, no ID or photo is taken, nothing leaves the phone. Real checks need a separate approved design and a privacy review first |

## 2. Badge look

| Badge | Look |
|---|---|
| Verified | "✓ Verified" - white text on green #123F32, pill, 10.5 pt bold |
| Basic | "Basic" - green #123F32 on mint #EDF5EF, pill, 10.5 pt bold |

## 3. Profile (master w17)

Add, in this order at the top of the existing Profile: the "A first look at Wafa" note (from LOCK 1 §4) · the member's name with their badge · a **Verification** row: check icon, "Verification", status line ("Not verified yet" · "Basic · add photo ID to be Verified" · "Verified"), "›". The rest of Profile stays as built - w17 shows where the new parts go, not a new Profile.

## 4. Verification page (masters w18, w19, w20)

| Part | Content |
|---|---|
| Header | Back · "Verification" |
| Who | Initial circle · "Amina Noor" + badge · "Others see your badge next to your name on every agreement. Verification is optional." |
| Levels | Two boxes side by side: "Basic / Email + phone" · "Verified / + photo ID and selfie"; a box turns mint with a green border when reached |
| Checks | Three rows: "Email address / Confirmed by a code we email you" · "Phone number / Confirmed by a text message code" · "Photo ID and selfie / A passport or driving licence, matched to a live selfie". Right side: "Done" (green) or a button "Add" (email, phone) / "Verify" (photo ID) |
| Note | "Photo ID is checked by a specialist ID company. Wafa keeps the result, not a copy of your ID." (muted, 12.5 pt) |
| Demo | Tapping Add/Verify marks the check done with a message: "Demo: confirmed. In the real app you enter a code we send you." / "Demo: identity checked. In the real app a specialist ID company does this." |

## 5. Example records

| Person | Level |
|---|---|
| Amina Noor (member) | Email only - no badge |
| Omar Farooq | Verified |
| Sara Malik | Basic |
| Yusuf Rahman | Email only |
| Maryam Saleh | Verified |

## 6. Must not change

LOCK 1 and LOCK 2 screens apart from the badge next to names · sign-in preview · payments wording ("Record, not verification").

## 7. Not decided

| Item | Note |
|---|---|
| Which ID company, what is stored, for how long | Privacy review before any real build (kept private) |
| Badge in Amanah Score | Later ROADMAP row |

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-08 | V1 | LOCK 3 - Founder words above |
