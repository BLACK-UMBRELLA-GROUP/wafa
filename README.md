# WAFA — Islamic Contracts

WAFA is a standalone Flutter prototype for Muslims exploring how to create and honour agreements. It rehearses agreement creation, participants, unsigned document copies and payment records in a local phone preview.

People, agreements and payments in this preview are fictional. Records stay in memory and reset when the process restarts. Authentication and invitations are simulations. Agreement copies remain unsigned, no signatures are collected, and payment records are fictional. The app does not create binding contracts, move money or claim religious certification.

## Status

Pre-launch visual demo, version `0.1.0+3`. A local iPhone preview has been delivered; the current source and its delivery limits are documented in [SOURCE/README.md](SOURCE/README.md). Installation and Founder visual acceptance are separate checks. App feature development is frozen until the Founder authorizes it. No production backend, Supabase integration or public app release is included.

## Built with

- Flutter `3.44.2` and Dart `3.12.2`, pinned by the project-local cached tooling.
- Flutter Material widgets and Cupertino Icons `1.0.9` from the lockfile.
- Flutter Test and Flutter Lints `6.0.0`.
- The existing native project targets iOS 15 or later. iOS delivery requires macOS and Xcode.

## Prepare and check a checkout

Use an existing Flutter `3.44.2` installation with its Dart SDK, Flutter tools snapshot and version metadata already cached. The project wrapper checks the pinned release; it does not install or repair the SDK. Point it at that installation:

```bash
cd SOURCE
export WAFA_FLUTTER_ROOT=/path/to/flutter-3.44.2
./tooling/flutter_cached.sh pub get
./tooling/flutter_cached.sh analyze --no-pub
./tooling/flutter_cached.sh test --no-pub
```

These commands use the project's existing tooling. See [SOURCE/README.md](SOURCE/README.md) for its documented checks and limitations. No environment file or service credentials are needed for the in-memory demo.

## Run the iPhone preview

For an unsigned build without installing an app:

```bash
# From SOURCE/
./run.sh --build-only --unsigned
```

For a signed local preview, replace `YOUR_APPLE_TEAM_ID` in `SOURCE/ios/Runner.xcodeproj/project.pbxproj` with your own development team locally, prepare the `app.wafa.preview` signing profile in Xcode and pair the target device. Then use its explicit device ID or name:

```bash
# From SOURCE/
./run.sh --device YOUR_DEVICE_ID
```

The script uses existing local signing and does not register devices or update provisioning. It requires prepared dependencies. Build, signing and device delivery are separate from source checks.

## Repository layout

- `SOURCE/`: Flutter app, tests, iOS project and local tooling.
- `APP/`: product summaries and the approved build queue.
- `ARCHIVE/`: preserved MITHAQ product documents from before the WAFA rename.
- `AGENTS.md` and `MAP.md`: working rules and document routes.
- `ROADMAP.md`: planned work and approval gates.

## How work is done

The WAFA design chat prepares designs and specifications. The Founder locks designs before AI coding assistants implement them. Authorized builds pass through `APP/APPROVED/BUILD_QUEUE.md`; its current task list is empty. Review, documentation and a separately approved repository preparation task do not lift the app feature freeze.

## History and sample data

The current Git lineage starts in October 2026; earlier June product documents are preserved in `ARCHIVE/`. History is retained as it was. Historical commits may contain Founder-owned technical identifiers such as an Apple signing-team ID; these are not credentials. Current native signing settings use placeholders. Demo identities and agreement records are fictional.

## Licence

Original project code and documentation are licensed under [Apache License 2.0](LICENSE); see [NOTICE](NOTICE). Flutter-derived tooling retains its existing BSD terms in [SOURCE/tooling/LICENSE](SOURCE/tooling/LICENSE). The WAFA name, logo and domains are not licensed for reuse by this grant; brand rights are reserved.
