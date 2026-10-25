#!/usr/bin/env bash
# Wafa release preview delivery. Uses local signing only; never updates
# provisioning, registers devices, submits archives, or invokes SDK wrappers.
set -euo pipefail
unset CDPATH

WAFA_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
WAFA_DEVICE=""
WAFA_BUILD_ONLY=false
WAFA_UNSIGNED=false
WAFA_BUNDLE_ID=app.wafa.preview

usage() {
  printf '%s\n' \
    'Usage: ./run.sh --device DEVICE_ID' \
    '       ./run.sh --build-only [--unsigned]' \
    'Builds a Release preview. Device installation requires an explicit paired-device ID or name.' \
    'Signing uses the existing local Xcode certificate/profile; no provisioning updates are allowed.'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
        printf '%s\n' '--device requires the paired device ID or name.' >&2
        exit 2
      fi
      WAFA_DEVICE="$2"
      shift 2
      ;;
    --build-only) WAFA_BUILD_ONLY=true; shift ;;
    --unsigned) WAFA_UNSIGNED=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$WAFA_BUILD_ONLY" != true && -z "$WAFA_DEVICE" ]]; then
  usage >&2
  exit 2
fi
if [[ "$WAFA_UNSIGNED" == true && "$WAFA_BUILD_ONLY" != true ]]; then
  printf '%s\n' '--unsigned requires --build-only; unsigned apps cannot be installed.' >&2
  exit 2
fi

cd -- "$WAFA_PROJECT_ROOT"
if [[ ! -f .dart_tool/package_config.json ]]; then
  printf '%s\n' 'Dependencies are not prepared. Run tooling/flutter_cached.sh pub get first.' >&2
  exit 1
fi

# Flutter's normal signed iOS command enables Apple provisioning changes.
# Generate build settings without codesigning, then run Xcode ourselves.
/bin/bash "$WAFA_PROJECT_ROOT/tooling/flutter_cached.sh" build ios \
  --release --config-only --no-codesign --no-pub

WAFA_DERIVED_DATA="$WAFA_PROJECT_ROOT/build/wafa-ios-release"
WAFA_APP="$WAFA_DERIVED_DATA/Build/Products/Release-iphoneos/Runner.app"
WAFA_XCODE_ARGS=(
  -quiet
  -workspace "$WAFA_PROJECT_ROOT/ios/Runner.xcworkspace"
  -scheme Runner
  -configuration Release
  -sdk iphoneos
  -destination generic/platform=iOS
  -derivedDataPath "$WAFA_DERIVED_DATA"
  -disableAutomaticPackageResolution
  -skipPackageUpdates
  -hideShellScriptEnvironment
  "PRODUCT_BUNDLE_IDENTIFIER=$WAFA_BUNDLE_ID"
)
if [[ "$WAFA_UNSIGNED" == true ]]; then
  WAFA_XCODE_ARGS+=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 'CODE_SIGN_IDENTITY=')
fi

if ! xcrun xcodebuild "${WAFA_XCODE_ARGS[@]}" build; then
  printf '%s\n' \
    'Wafa Release build failed. No install was attempted.' \
    'If signing is missing, the Founder must prepare the app.wafa.preview profile in Xcode; this script does not enable provisioning changes.' >&2
  exit 1
fi

if [[ ! -d "$WAFA_APP" ]]; then
  printf 'Expected Release app was not produced: %s\n' "$WAFA_APP" >&2
  exit 1
fi
WAFA_BUILT_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$WAFA_APP/Info.plist")"
if [[ "$WAFA_BUILT_BUNDLE_ID" != "$WAFA_BUNDLE_ID" ]]; then
  printf 'Bundle verification failed: expected %s, found %s.\n' "$WAFA_BUNDLE_ID" "$WAFA_BUILT_BUNDLE_ID" >&2
  exit 1
fi

if [[ "$WAFA_BUILD_ONLY" == true ]]; then
  printf 'Wafa Release app: %s\n' "$WAFA_APP"
  exit 0
fi

/usr/bin/codesign --verify --deep --strict "$WAFA_APP"
xcrun devicectl device install app --device "$WAFA_DEVICE" "$WAFA_APP" --timeout 60
xcrun devicectl device process launch --device "$WAFA_DEVICE" \
  --terminate-existing "$WAFA_BUNDLE_ID" --timeout 60
printf 'Wafa Release preview installed and launched on %s.\n' "$WAFA_DEVICE"
