#!/usr/bin/env bash
# Project-local cached tooling only. Never source Flutter's shared.sh.
set -euo pipefail
unset CDPATH

WAFA_TOOLING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
FLUTTER_ROOT="${WAFA_FLUTTER_ROOT:-${FLUTTER_ROOT:-/opt/homebrew/Caskroom/flutter/3.44.2/flutter}}"
WAFA_CACHED_DART="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart"
WAFA_FLUTTER_SNAPSHOT="$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot"

if [[ ! -x "$WAFA_CACHED_DART" ]]; then
  printf '%s\n' 'The pinned cached Dart executable is unavailable. Ask the Founder to repair the Flutter SDK.' >&2
  exit 1
fi

export FLUTTER_ROOT
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
"$WAFA_CACHED_DART" "$WAFA_TOOLING_DIR/cached_version.dart" "$FLUTTER_ROOT"
