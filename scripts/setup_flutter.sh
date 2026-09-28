#!/usr/bin/env bash
# Installs the pinned Flutter SDK if `flutter` isn't available yet.
# Safe to run repeatedly. Used by the Claude Code SessionStart hook and run_web.sh.
set -euo pipefail

FLUTTER_VERSION="3.47.5"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if command -v flutter >/dev/null 2>&1; then
  exit 0
fi
for candidate in "$FLUTTER_HOME" /opt/flutter; do
  if [ -x "$candidate/bin/flutter" ]; then
    echo "Flutter found at $candidate (add $candidate/bin to PATH)"
    exit 0
  fi
done

echo "Installing Flutter $FLUTTER_VERSION into $FLUTTER_HOME ..."
case "$(uname -s)" in
  Linux) archive="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"; os=linux ;;
  Darwin) archive="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"; os=macos ;;
  *) echo "Unsupported OS; install Flutter manually: https://docs.flutter.dev/get-started/install" >&2; exit 1 ;;
esac
url="https://storage.googleapis.com/flutter_infra_release/releases/stable/$os/$archive"
tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/$archive" "$url"
mkdir -p "$(dirname "$FLUTTER_HOME")"
if [[ "$archive" == *.zip ]]; then
  unzip -q "$tmp/$archive" -d "$(dirname "$FLUTTER_HOME")"
else
  tar -xf "$tmp/$archive" -C "$(dirname "$FLUTTER_HOME")"
fi
rm -f "$tmp/$archive"
rmdir "$tmp" 2>/dev/null || true
git config --global --add safe.directory "$FLUTTER_HOME" || true
"$FLUTTER_HOME/bin/flutter" config --no-analytics >/dev/null 2>&1 || true
echo "Flutter installed. Add to PATH: export PATH=\"$FLUTTER_HOME/bin:\$PATH\""
