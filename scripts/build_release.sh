#!/bin/bash
# Release packaging: bake prod env, build obfuscated artifacts, collect them.
#
#   scripts/build_release.sh [all|aos|ios]     (default: all)
#
# Dart symbols are obfuscated; the per-version symbol mapping needed to
# symbolicate crashes is collected alongside the artifacts.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${SDUI_BUILD_DEST:-$HOME/Downloads/sdui_starter_build}"
SYMBOLS_DIR="build/symbols"
HARDEN_FLAGS=(--obfuscate --split-debug-info="$SYMBOLS_DIR")
TARGET="${1:-all}"

cd "$PROJECT_DIR"

# Env values are compile-time constants — always rebake from .env.prod first.
"$PROJECT_DIR/scripts/gen_env.sh" prod

VERSION=$(grep '^version:' pubspec.yaml | tr -d ' ' | sed 's/version://')

collect() {
  local src="$1" label="$2"
  local ext="${src##*.}"
  mkdir -p "$DEST"
  cp "$src" "$DEST/sdui_starter-$VERSION.release.$ext"
  echo "$label -> $DEST/sdui_starter-$VERSION.release.$ext"
}

build_aos() {
  flutter build appbundle --release "${HARDEN_FLAGS[@]}"
  collect build/app/outputs/bundle/release/app-release.aab "Android"
}

build_ios() {
  flutter build ipa --release "${HARDEN_FLAGS[@]}"
  local ipa
  ipa=$(find build/ios/ipa -name '*.ipa' | head -1)
  collect "$ipa" "iOS"
}

case "$TARGET" in
  all) build_aos; build_ios ;;
  aos) build_aos ;;
  ios) build_ios ;;
  *) echo "Usage: $0 [all|aos|ios]"; exit 1 ;;
esac

# Keep the symbol mapping with the artifacts, named by version.
if [ -d "$SYMBOLS_DIR" ]; then
  mkdir -p "$DEST/symbols-$VERSION"
  cp -R "$SYMBOLS_DIR"/. "$DEST/symbols-$VERSION/"
  echo "Symbols -> $DEST/symbols-$VERSION"
fi

# Leave the tree on local env so a following `flutter run` is not silently prod.
"$PROJECT_DIR/scripts/gen_env.sh" local
