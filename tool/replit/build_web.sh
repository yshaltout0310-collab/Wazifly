#!/usr/bin/env bash
# Produces the deployable Flutter web bundle in build/web.
#
# Used as the Replit deployment build command (see .replit) and runnable by hand
# inside the Repl shell: `bash tool/replit/build_web.sh`.
set -euo pipefail

cd "$(dirname "$0")/../.."

source tool/replit/install_flutter.sh
export PATH="${FLUTTER_HOME:-$HOME/flutter}/bin:$PATH"

log() { printf '\033[36m[build-web]\033[0m %s\n' "$*"; }

log "Fetching packages"
flutter pub get

log "Building release web bundle"
# --no-web-resources-cdn copies CanvasKit into build/web instead of loading it
# from gstatic.com at runtime. It costs ~10 MB of bundle but makes the deployed
# site self-contained: no third-party CDN request, so the app still renders on a
# network that blocks or throttles gstatic (and on a reviewer's locked-down
# laptop). Drop the flag if bundle size matters more than that.
#
# --no-wasm-dry-run suppresses the advisory wasm-incompatibility report for
# flutter_secure_storage_web; this build targets JavaScript, not WebAssembly.
flutter build web \
  --release \
  --no-web-resources-cdn \
  --no-wasm-dry-run \
  --dart-define=APP_VERSION="${APP_VERSION:-1.0.0}"

log "Bundle ready: $(du -sh build/web | cut -f1) in build/web"
