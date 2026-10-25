#!/usr/bin/env bash
# Scoped Wafa developer commands using Flutter's existing cached snapshot.
set -euo pipefail
unset CDPATH

WAFA_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$WAFA_SCRIPT_DIR/flutter_env.sh"

if [[ $# -eq 0 ]]; then
  printf '%s\n' 'Usage: tooling/flutter_cached.sh {analyze|test|pub get|build ios|assemble} [arguments]' >&2
  exit 2
fi

case "$1" in
  analyze|test|assemble) ;;
  pub)
    [[ "${2:-}" == get ]] || {
      printf '%s\n' 'Only pub get is supported by this preview wrapper.' >&2
      exit 2
    }
    ;;
  build)
    [[ "${2:-}" == ios ]] || {
      printf '%s\n' 'Only build ios is supported by this preview wrapper.' >&2
      exit 2
    }
    WAFA_BUILD_SAFE=false
    for argument in "$@"; do
      if [[ "$argument" == --config-only || "$argument" == --no-codesign ]]; then
        WAFA_BUILD_SAFE=true
      fi
    done
    if [[ "$WAFA_BUILD_SAFE" != true ]]; then
      printf '%s\n' 'Use --config-only or --no-codesign. Signed preview builds use run.sh so Flutter cannot enable provisioning updates.' >&2
      exit 2
    fi
    ;;
  *)
    printf '%s\n' 'Command outside the Wafa preview scope. SDK upgrades, channels and Git operations belong to the Founder.' >&2
    exit 2
    ;;
esac

for argument in "$@"; do
  if [[ "$argument" == --version-check || "$argument" == --version-check=* ]]; then
    printf '%s\n' 'Version checking is disabled for this cached no-Git workflow.' >&2
    exit 2
  fi
  if [[ "$argument" == --codesign || "$argument" == --codesign=* || "$argument" == --no-config-only ]]; then
    printf '%s\n' 'Signing and configuration overrides are outside this cached wrapper scope.' >&2
    exit 2
  fi
done

exec "$WAFA_CACHED_DART" "$WAFA_FLUTTER_SNAPSHOT" --no-version-check --suppress-analytics "$@"
