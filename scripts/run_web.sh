#!/usr/bin/env bash
# Builds the app for the web and serves it at http://localhost:${PORT:-8080}.
#
#   scripts/run_web.sh          # release build + static server
#   scripts/run_web.sh --dev    # `flutter run` web-server with hot reload
#
# With SUPABASE_URL and SUPABASE_ANON_KEY in the environment, food search
# also queries the full server database (the anon key is public, read-only).
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/setup_flutter.sh
for candidate in "${FLUTTER_HOME:-$HOME/flutter}" /opt/flutter; do
  [ -x "$candidate/bin/flutter" ] && export PATH="$candidate/bin:$PATH" && break
done

PORT="${PORT:-8080}"
flutter pub get >/dev/null
DEFINES=()
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  DEFINES=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
fi

if [ "${1:-}" = "--dev" ]; then
  exec flutter run -d web-server --web-hostname 0.0.0.0 --web-port "$PORT" ${DEFINES[@]+"${DEFINES[@]}"}
fi

flutter build web --release --no-web-resources-cdn ${DEFINES[@]+"${DEFINES[@]}"}
echo "Serving on http://localhost:$PORT  (Ctrl+C to stop)"
exec python3 -m http.server "$PORT" --directory build/web
