#!/usr/bin/env bash
# Builds the app for the web and serves it at http://localhost:${PORT:-8080}.
#
#   scripts/run_web.sh          # release build + static server
#   scripts/run_web.sh --dev    # `flutter run` web-server with hot reload
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/setup_flutter.sh
for candidate in "${FLUTTER_HOME:-$HOME/flutter}" /opt/flutter; do
  [ -x "$candidate/bin/flutter" ] && export PATH="$candidate/bin:$PATH" && break
done

PORT="${PORT:-8080}"
flutter pub get >/dev/null

if [ "${1:-}" = "--dev" ]; then
  exec flutter run -d web-server --web-hostname 0.0.0.0 --web-port "$PORT"
fi

flutter build web --release --no-web-resources-cdn
echo "Serving on http://localhost:$PORT  (Ctrl+C to stop)"
exec python3 -m http.server "$PORT" --directory build/web
