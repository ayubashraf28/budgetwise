#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SKIP_BUILD="${SKIP_BUILD:-0}"

flutter pub get
flutter pub outdated
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test -j 1

if [[ "$SKIP_BUILD" != "1" ]]; then
  flutter build apk --debug
fi

echo "Quality gate passed."
