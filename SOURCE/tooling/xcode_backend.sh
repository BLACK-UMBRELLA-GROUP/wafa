#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Wafa project-local entry point: invoke cached Dart, never bin/dart.
set -euo pipefail
unset CDPATH

WAFA_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$WAFA_SCRIPT_DIR/flutter_env.sh"
exec "$WAFA_CACHED_DART" "$WAFA_SCRIPT_DIR/xcode_backend.dart" "$@" ios
