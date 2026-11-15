---
id: DOC-WAFA-0023
type: SPEC
status: CURRENT
feature: APP: EVIDENCE
purpose: LOCK 5 - Evidence Vault on every agreement - 25 files per agreement, 10 MB each, free at launch; removable only while Draft
links: [DOC-WAFA-0003, DOC-WAFA-0012, DOC-WAFA-0024, DOC-WAFA-0025]
owner: WAFA chat
---

# EVIDENCE SPEC — CURRENT VERSION V1

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCK 5, 10 Nov 2026 |
| Founder's words | "A · Per agreement (Recommended)" · "Free at launch (Recommended)" · "LOCK it (Recommended)" |
| ROADMAP row | "Define Evidence Vault limits and pricing" (3 h) - finished by this LOCK (no charge for the Evidence Vault in the preview) |
| Masters | `MASTERS/w24`-`w27`; Evidence on the many-people page in `AGREEMENTS/MASTERS/w14` (re-rendered). Prototype V16 |

## 1. Rules

| # | Rule |
|---|---|
| 1 | Every agreement has an Evidence section. Up to **25 files per agreement, up to 10 MB each**. Free |
| 2 | Types: Photo · Receipt · Bank confirmation · Document · Voice note |
| 3 | Everyone on the agreement can see its evidence |
| 4 | While the agreement is **Draft**, the person who added a file can remove it (×). Once it is not Draft, evidence **cannot be removed** - it stays with the agreement (approved: "Nothing is deleted") |
| 5 | Demo: files are fictional; "Choose a file" adds a sample entry. Nothing leaves the phone; no camera, microphone, photo library or upload. Real storage needs a separate approved design and a privacy review |

## 2. Evidence section on the agreement page (w24, w26, w27)

Placed after the progress line, before "View the agreement copy".

| Part | Content |
|---|---|
| Heading | "Evidence" · right: "+ Add" (green link) |
| List | One row per file: type icon in a mint circle (Photo camera, Receipt document, Bank confirmation tick, Document document, Voice note microphone) · name · "{Type} · {size} MB · added {d MMM}" · "×" only in Draft (rule 4) |
| Empty (w26) | "No evidence yet. Add receipts, photos or bank confirmations so everyone has the same record." (muted, 13 pt) |
| Meter | "**{n} of 25 files** on this agreement · up to 10 MB each" + thin bar (green on #E3EAE5) |

## 3. Add evidence page (w25)

| Part | Content |
|---|---|
| Header | Back · "Add evidence" |
| Sub-line | "{title} · what are you adding?" |
| Types | Five selectable rows (same look as the Type step in LOCK 2): Photo, Receipt, Bank confirmation, Document, Voice note |
| Note (mint) | "Everyone on this agreement can see it. Once everyone has signed, evidence can't be removed - it stays with the agreement." |
| Meter | As §2 |
| Button | "Choose a file". No type chosen → "Choose what you are adding first." At 25 files → "This agreement has 25 files, the most it can hold." Demo add → "Demo: file added. In the real app you choose it from your phone." |

## 4. Example records

| Agreement | Evidence |
|---|---|
| Garden design (Samira Khan) | Photo "Garden before the work", 2.4 MB, 2 Oct · Receipt "Plants receipt", 0.3 MB, 5 Oct |
| Mum's care costs | Bank confirmation "Transfer to Sara · £100", 0.2 MB, 1 Nov |
| All others | None |

## 5. Must not change

LOCK 1-4 screens apart from the new Evidence section on the agreement page · the agreement copy · payments.

## 6. Not decided

| Item | Note |
|---|---|
| Extra storage beyond the limits | Decided later, once real use is known (not part of this LOCK) |
| How long files are kept after completion | Decided before launch (not part of this LOCK) |
| Who can remove a file in Draft (adder only vs creator) | Adder only in this build |

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-10 | V1 | LOCK 5 - Founder words above |
