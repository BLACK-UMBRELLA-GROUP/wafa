---
id: DOC-WAFA-0027
type: SPEC
status: CURRENT
feature: APP: BRAND
purpose: LOCK 6 - app icon (waw letter), green launch screen, and the same mark in the app's top-left logo
links: [DOC-WAFA-0009, DOC-WAFA-0028, DOC-WAFA-0029]
owner: WAFA chat
---

# BRAND SPEC — CURRENT VERSION V1

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — LOCK 6, 10 Nov 2026 |
| Founder's words | "C · Waw letter" · "Green with white mark" · "Yes, match the icon (Recommended)" · "LOCK it (Recommended)" |
| Masters | `MASTERS/w28_icon__home_screen.png`, `w29_launch_screen.png`, `w30_in_app_mark__home_top.png`; Home masters `DASHBOARD/MASTERS/w01`-`w05` re-rendered with the new logo. Prototype V19 |
| Source of truth for the drawing | `MASTERS/wafa_icon.svg` and `MASTERS/wafa_launch_mark.svg` (100 × 100 units). The PNGs beside them are renders for checking |

## 1. The mark (same drawing everywhere)

In a 100 × 100 box:

| Part | Exact drawing |
|---|---|
| Waw stroke | Path `M58 52 C47 54 43 45 47 38 C51 31 63 32 64 42 C66 58 52 72 33 76`, stroke width 7, round caps, no fill |
| Dot | Circle centre (70, 24), radius 4 |

The letter is the Arabic waw (و), first letter of وفاء. It is drawn, not typed - no font.

## 2. App icon (w28)

| Item | Value |
|---|---|
| Background | Solid #123F32, full square (iOS rounds the corners itself; no transparency, no own rounding) |
| Waw stroke | #FFFFFF |
| Dot | #BDDCCC (mint) |
| Sizes | Every size in `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`, drawn from §1 by updating `SOURCE/tooling/generate_icon.swift` (keep the tool; replace its W drawing). 1024 px must match `MASTERS/wafa_icon_1024.png` |

## 3. Launch screen (w29)

| Item | Value |
|---|---|
| Background | #123F32 full screen (`LaunchScreen.storyboard` background; was white) |
| Mark | §1 with a white stroke and mint dot, no background, **132 × 132 pt**, centred. LaunchImage @1x/@2x/@3x = 132/264/396 px with a transparent background (match `MASTERS/wafa_launch_mark@*.png`) |
| Text | None (Apple: no words on a launch screen) |
| Status bar | Light (white) while the launch screen shows |

## 4. In-app logo (w30, and Home w01-w05)

`BrandMark` in `SOURCE/lib/ui/wafa_ui.dart`: replace the leaf icon (`Icons.spa_outlined`) with the app icon drawn at **30 × 30 pt**, corner radius 6.75 pt (§2 colours). Keep the word "wafa" exactly as built (30 pt in the code today; w30 shows the prototype's smaller size - the built size wins). The `DemoBadge` ("PREVIEW") and the profile button stay.

## 5. Must not change

App name on the home screen ("Wafa") · bundle ID · every other screen.

## Version history

| Date | Version | Change |
|---|---|---|
| 2026-11-10 | V1 | LOCK 6 - Founder words above |
