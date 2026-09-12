#!/usr/bin/env bash
# Dev/preview server for the Repl's Run button: builds the web bundle if it is
# missing, then serves it over HTTP.
#
# A plain static file server is sufficient because the app uses Flutter's
# default hash-based URL strategy (`/#/home`) — every route is served by
# index.html already, so no SPA rewrite rule is needed.
set -euo pipefail

cd "$(dirname "$0")/../.."

PORT="${PORT:-8080}"

log() { printf '\033[36m[serve-web]\033[0m %s\n' "$*"; }

if [ ! -f build/web/index.html ]; then
  log "No bundle found — building first"
  bash tool/replit/build_web.sh
fi

log "Serving build/web on 0.0.0.0:${PORT}"
log "Rebuild after a code change with: bash tool/replit/build_web.sh"
exec python3 -m http.server "$PORT" --bind 0.0.0.0 --directory build/web
