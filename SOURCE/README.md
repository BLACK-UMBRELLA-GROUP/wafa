---
id: DOC-WAFA-0006
type: GUIDE
status: CURRENT
feature: CODE AND RUNNING
purpose: Wafa phone preview and developer guide
links: []
owner: WAFA chat
---

# Wafa phone preview

Wafa is a standalone Flutter visual prototype with a white
background and dark-green accents. Records are fictional and session-local.
There is no backend, real AI, binding contract generation, signature collection,
bank connection or payment processing. Apple and Google buttons, Wafa IDs,
invitations, contacts and participant accounts are local fictional rehearsals.

## Authority and product scope

The Founder selected the working title and requested an initial app on his phone
for visual iteration on 13 October 2026. ZYRA ADMIN supplied delivery guidance
only. Wafa has its own source, bundle ID and code-drawn icon; ZYRA source,
accounts and data are not reused or modified.

The Founder then approved a visual multi-person agreement rehearsal on
13 October 2026. That approval covers this local preview only. It does not
authorise real identity providers, accounts, invitations, messages, QR scans,
signatures, a backend, production data or release.

The parent APP summaries remain the roadmap. They do not mean every planned
capability is implemented. The Founder–Codex operating model and Implementation
Handover Standard govern this work. Code checks, installation and the Founder's
visual acceptance remain distinct.

## Actual screens and navigation

- **Home.** The Needs you dashboard lists open invitations, overdue agreements,
  agreements awaiting signatures and active payments due within seven days, in
  that order. Tiles open dedicated lists for Active, Drafts, Awaiting signatures,
  Completed and Overdue. When nothing needs attention, Home shows the next
  active payment if there is one. Members with no visible agreements can start
  their first one or open waiting invitations.
- Sign-in preview: select Amina, Omar or Sara and simulate Apple or Google
  sign-in without opening a provider or collecting credentials.
- Agreements: name/title search, status filters and detail navigation.
- **Creation.** Type → Details → Review supports interest-free loans, sales,
  item lending, item rental, services, family agreements and custom agreements.
  Select fictional people, assign who owes a share, who is owed and who is a
  witness, then split a positive GBP total equally or set each amount. Review
  the due date, people and shares before saving an unsigned local draft. Saving
  prepares a separate demo invitation for each selected person other than you.
- **Details.** View the summary, people, unsigned agreement copy, payment timeline
  and Evidence Vault. Group agreements show payment progress for each person who
  owes a share. Eligible non-loan obligations can be marked complete locally.
- Agreement copy: a selectable, copyable document-style record generated only
  from stored demo fields, including people, roles, value, due date and status.
  Missing clauses are not invented and the copy is clearly unsigned.
- Payments: overall due date, paid/remaining summary and itemised fictional
  payments with amount, date, method, recorder, optional reference and notes.
  On an eligible agreement with recorded shares, **Who paid?** selects the
  person whose share the payment counts towards. Parties may add payment
  records. Witnesses can view them.
- People: add a fictional party or witness to an unsigned draft by Wafa ID,
  accepted Wafa contact, invitation preview or QR preview.
- Invitations: request access under the intended fictional account. The
  agreement remains private until its creator confirms the requester.
- Tracker: example loan totals and progress, retaining completed loan history.
- **Profile.** View the current fictional account, switch accounts, manage Wafa
  contacts and open Verification or Your track record.
- **Verification.** Optional demo checks show a Basic badge for confirmed email
  and phone, and a Verified badge after the simulated photo ID and selfie check.
  Badges appear on Profile and alongside people in the draft, review, agreement
  and Who paid? screens. The checks send no codes and collect no ID or photos.
- **Track record.** Profile shows fixed fictional facts such as completed
  agreements and on-time payments. Sharing is optional and can be turned off
  during the session. A shared record opens from the people section of a group
  agreement when the viewer has access. Drafts require confirmed membership.
- **Evidence Vault.** Confirmed participants, including witnesses, can view and
  add sample entries on the agreement. The preview caps the list at 25 entries
  and displays a 10 MB limit per file. **Choose a file** adds metadata for a
  fictional sample such as a receipt. The app reads and uploads no files and
  keeps the metadata in memory. Only the person who added an entry can remove
  it while the agreement is a draft.

Every relevant screen labels the preview. No invitation, charge, notice or
signature is sent. No religious certification or legal enforceability is claimed.

## Architecture and live files

| File | Responsibility |
| --- | --- |
| lib/main.dart | Session-owned repositories, four tabs, search and navigation |
| lib/domain/demo_connections.dart | Fictional identities, access, roles, contacts, invitations, verification and Track record sharing |
| lib/domain/demo_models.dart | Agreements, shares, payments and in-memory evidence metadata |
| lib/ui/wafa_ui.dart | Theme, shared components and exact GBP parsing |
| lib/ui/dashboard.dart | Home dashboard and agreement lists by status |
| lib/ui/create_agreement.dart | Three-step unsigned draft creation and share allocation |
| lib/ui/agreement_detail.dart | Agreement access, participant progress, document and payment links, Track record links and Evidence Vault |
| lib/ui/agreement_document.dart | Generated unsigned document-style copy and guarded clipboard action |
| lib/ui/payments_screen.dart | Payment summary, timeline, payer selection and validated party-only entry form |
| lib/ui/demo_account.dart | Simulated provider sign-in and incoming invitation flow |
| lib/ui/participants_screen.dart | Creator-managed participant and invitation rehearsal |
| lib/ui/verification_screen.dart | Optional simulated identity checks and badge display |
| lib/ui/track_record_screen.dart | Fictional facts and session-local sharing controls |
| lib/ui/evidence_vault.dart | Fictional evidence entries and add/remove controls |
| tooling/flutter_cached.sh and flutter_env.sh | Restricted cached SDK commands |
| tooling/cached_version.dart | Fail-closed SDK metadata validation |
| tooling/xcode_backend.dart and xcode_backend.sh | Project-local generic Flutter backend adaptation |
| tooling/generate_icon.swift | Original CoreGraphics app icon generator |
| run.sh | Release build, local signing and explicit-device installation |
| test/*.dart | Domain and screen regressions for preview flows |

The generic Flutter backend retains its BSD licence in tooling/LICENSE.
Its launcher paths and cache checks are adapted locally and resolve relative to this folder.
The project folder is DEVELOPMENT/WAFA (renamed from MITHAQ on 2026-10-24 by
Founder decision; no script hard-coded the old name).

## Data flow and invariants

Form input is converted to integer pence and validated by the repository.
Payment records cannot be zero, negative, greater than the remaining value,
future-dated or applied to an ineligible state. Notes and references are bounded.
On agreements with recorded shares, a payment also cannot exceed the selected
person's remaining share.
Each entry records a fictional amount, date, method and actor, but Wafa neither
moves money nor verifies that it moved. The UI warns against entering bank
account or card details. A default repository is created once for the app
session, so root rebuilds do not erase drafts or payments. Process restart
resets edits. No database, disk persistence, network requests or analytics
record user input. The fixed default demo date is 13 October 2026. Use
fictional details only.

The agreement copy is derived from the exact stored demo fields. It does not
silently add clauses, signatures, evidence, legal status or approval from
qualified scholars of the community. Confirmed participants may view it; a
pending invitation still reveals nothing. Copying places the labelled demo text on the local clipboard.

Every agreement has one immutable fictional creator and a separate access
roster. Only the creator can invite people, and only while the agreement is an
unsigned draft. An invitation code permits a request only. The creator must
confirm the exact fictional Wafa account before that person can see the shared
draft. Opening, requesting or joining does not accept terms or sign anything.
Each confirmed person has a bound Party or Witness role, and only confirmed
people can see the roster. Selecting a fictional account during creation
records their intended role and share. Access for that account starts only
after the creator confirms its join request.

The three identities, seven-day expiry and sequential demo codes are fixed
prototype presets, not approved production identity or security policy. The
preview does not read phone contacts, phone numbers, camera data or the network.
Accepted fictional connections are saved only in the current in-memory session.

## App icon and launch screen

The iOS icon and green launch screen use the white waw mark and mint dot.
The app header pairs the same mark with the Wafa wordmark.
From this directory, run `swift tooling/generate_icon.swift` to regenerate
the iOS AppIcon PNGs.
Run `python3 tooling/test_ios_brand_assets.py` to check the iOS asset catalogs,
PNG dimensions and transparency metadata, and launch configuration offline.

## Toolchain and device boundary

Flutter 3.44.2 and Dart 3.12.2 are the installed pinned caches. Ordinary Flutter
and shell Dart wrappers invoke Git and must not be used by an agent. This app's
wrapper validates cache fields and revision, then invokes raw cached Dart and
the Flutter snapshot with update checks and analytics disabled. Native Xcode
prepare, build and embed phases use the same local adapter. SDK changes require
review; the scripts must fail rather than fall back to the ordinary wrappers.

Runner uses app.wafa.preview, display name Wafa, and an iOS 15 minimum for this
SDK. Source is prepared as version 0.1.0 build 3. The delivery results below
record specific local builds. A new checkout requires its own signing setup
for native delivery.

### Prepare a checkout for native delivery

Start with the cached SDK and dependency preparation in the repository's
[setup instructions](../README.md#prepare-and-check-a-checkout). The generated
Flutter configuration and package cache are local prerequisites, not supplied
by the checked-in iOS project.

For a build without signing or installing, run from this SOURCE directory:

```bash
./run.sh --build-only --unsigned
```

A signed build requires separate local Xcode setup. All three app build
configurations in `ios/Runner.xcodeproj/project.pbxproj` contain the placeholder
`YOUR_APPLE_TEAM_ID`. Replace it locally with your development team, prepare a
signing identity and provisioning profile for `app.wafa.preview` in Xcode, and
pair the target phone before using:

```bash
./run.sh --build-only
./run.sh --device DEVICE_ID
```

The first command builds and signs without installation; the second also
requires an explicitly selected paired phone. No account, certificate, device
or profile is registered by these scripts. run.sh omits Apple provisioning-update
and device-registration flags; missing local signing must stop for a
Founder-controlled setup step. Verify the artifact's signature and bundle
before installing; availability is not proof that an app was installed or that
the Founder accepted its design.

## Verification on 13 October 2026

The initial build verification completed with 32 tests. After the sign-in and
participant preview was added, final cached-tool analysis reported no issues and
all 75 tests passed. The additional checks cover identity switching, immutable
ownership, targeted and generic invitations, expiry, decline and revocation,
duplicate/replay prevention, three-person rosters, role limits, private details
before confirmation, contacts after confirmation, wrong-account metadata
protection and two-times system text on a 375 × 812 phone layout. Formatting
completed successfully.

The internal review found a repository-reset bug and the accessibility check
found an overflowing agreements-count row. Both are fixed and regression-tested.
The repayment dialog was also made scrollable. No separate shared OA is raised
for these resolved, task-local preview defects: this paragraph records the
written refusal and their resolution under the direct prototype approval, not
a claim that production readiness or any existing OA is complete.

The initial device build exposed the scaffold's iOS 13 target incompatibility
with this Xcode SDK. The preview target was corrected to iOS 15. A signed Release
build then succeeded using the existing local wildcard profile. An earlier
simulator attempt failed and is not represented as successful verification.
Final-source native installation and Founder visual acceptance remain distinct;
delivery results are recorded below when verified.

The multi-person update did not require a backend, dependency download,
database migration, Apple capability or provider configuration. No separate
shared OA is raised for resolved task-local preview defects. The existing
roadmap and OA-101 remain open and unchanged.

The agreement-document and payment-record update was internally verified on
13 October 2026. Cached-tool analysis reported no issues and all 88 tests
passed. New coverage checks generated fields and disclaimers, private access,
clipboard output, exact payment details, invalid/stale changes, Party/Witness
permissions, immutable timelines and compact-phone/large-text layouts. This is
source verification only: build 3 was deliberately not installed or launched
while the Founder was away.

### Phone delivery — 13 October 2026 (Europe/London)

The final Release build succeeded. Deep/strict signature verification passed.
Native device tools installed and launched Wafa on the Founder's connected,
paired iPhone 15 Pro Max. The installed-app query independently returned
Wafa / app.wafa.preview / version 0.1.0 / build 1. Its matching executable
was observed running, and a terminate-existing relaunch succeeded without a
Flutter debugger. Artifact metadata confirms minimum iOS 15.0.
The embedded local provisioning profile expires on 9 October 2027 at 13:36 UTC;
this is a development-signed preview, not an App Store release.

The delivery check was recorded at 2026-10-12T23:54:39Z (13 October locally).
Final lib/main.dart SHA-256:
8a90541067dfc0aa885bff43436193f74000747926cc932bdb32446145171816.
Installed-build App.framework/App SHA-256:
2a8337dac7e94f814d76bbf82e05e31540eb4185acf6c6441d6f614873536205.
The local artifact is build/wafa-ios-release/Build/Products/Release-iphoneos/Runner.app.

This verifies installation and process launch, not actual phone-screen appearance
or Founder acceptance. The Founder should open the green Wafa icon, try the
demo flows, and confirm it also opens after closing the app and disconnecting
the cable. No App Store upload or submission was performed. The task's test
simulator was shut down after checks to release its memory; unrelated apps and
data were not removed.

### Participant preview delivery — 13 October 2026 (Europe/London)

Version 0.1.0 build 2 was built from the multi-person preview source, signed
with the existing local profile and installed on the same paired iPhone 15 Pro
Max. A separate installed-app query returned Wafa / app.wafa.preview / version
0.1.0 / build 2 at its new device installation URL. Deep/strict signature
verification passed, and artifact metadata confirms minimum iOS 15.0. The
embedded profile expiry remains 9 October 2027 at 13:36:16 UTC.

Three earlier automated launch attempts timed out while another chat may have
been using the phone build route. After the Founder confirmed a retry, no
competing build process was present. A fresh signed build then installed and
launched successfully. The installed-app query returned version 0.1.0 build 2
at the new installation path, and the matching executable was independently
observed running as process 4258 at 2026-10-13T11:40:05Z. This confirms native
installation and process launch, not the actual phone-screen appearance or
Founder visual acceptance.

The verification was recorded at 2026-10-13T11:14:00Z. Final lib/main.dart
SHA-256:
3a23c56740d3bdc0ba8c27e11d4d7ad9566adc9e7141a14cdda29a48852173a3.
Installed-build App.framework/App SHA-256:
0f2547735cd225589f026e93d22a03b8d03a4be7fb3c38bb4e9786e0f6f5cc2c.
The local artifact remains
build/wafa-ios-release/Build/Products/Release-iphoneos/Runner.app.

## Phone delivery and source checks — 11 November 2026

The signed Release preview installed and launched as Wafa `0.1.0` (build `3`).
The installed-app query confirmed the version and build. Commit
`9fa1c1bb6f97f89af9b2132e8861adb50b1b17fa` supplied the delivered source. Its
six LOCKs cover the Home dashboard, seven agreement types and group agreements,
optional verification, Track record, Evidence Vault and matching waw branding. Deep,
strict signature verification passed. The delivery commit had clean cached
Flutter analysis and 115 passing Flutter tests. Founder visual acceptance
requires a separate review.

During the 11 November documentation update, cached Flutter `analyze --no-pub`
reported no issues and `test --no-pub` passed 116 tests. The offline run-command,
cached-wrapper and iOS brand asset checks also passed.

## Remaining scope and action trace

Real accounts, persistent storage, file uploads, AI, validated contract
templates, identity checks, witness participation, signatures, money movement,
bank verification and translations remain outside the preview. Other remaining
scope includes PDF export, reminders, agreed instalment schedules and dispute
handling. The [roadmap](../ROADMAP.md) tracks naming and qualified review work.
There are no database migrations.

No new shared OA is raised for these existing roadmap items in this bounded
visual preview: it does not authorise their production implementation. Future
work needs its own scoped approval and action trace. Existing group OA-101 covers
whether this project (formerly MITHAQ) needs a dedicated governance SYSTEM; this
preview does not create a separate governance programme or close that action.

Next, the Founder reviews the phone layout and navigation. Visual acceptance
does not approve pricing, contract validity, certification, production data,
store submission or public release.
