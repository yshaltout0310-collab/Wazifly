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
# CanvasKit is loaded from gstatic.com at runtime (Flutter's default).
#
# This build previously passed --no-web-resources-cdn. That flag does NOT
# change what lands in build/web: measured both ways, the output is 45.7 MB in
# 44 files either way, because Flutter 3.44 copies the CanvasKit artifacts
# regardless. All it does is set "useLocalCanvasKit": true in
# flutter_bootstrap.js's buildConfig, which changes the RUNTIME URL.
#
# What dropping it actually buys, measured in a browser against a release
# build: this origin serves 7,723 KB instead of ~13,261 KB. The 5.6 MB
# CanvasKit fetch moves to gstatic, a CDN faster than this static host and
# shared by every Flutter web app on the same engine revision, so it is often
# already in the visitor's HTTP cache. A COLD visitor still downloads roughly
# the same total (~13.4 MB) -- this is a latency and offload win, not a
# byte-count win.
#
# The trade the flag existed to avoid is therefore live: on a network that
# blocks or throttles gstatic.com, the app will not render at all.
#
# TO ROLL BACK: re-add `--no-web-resources-cdn \` as its own line in the
# flutter build web invocation below (or `git revert` the commit that removed
# it). Nothing else depends on this choice.
#
# NOTE: always build from a clean build/web. An incremental rebuild can leave a
# stale flutter_bootstrap.js carrying the previous buildConfig while
# main.dart.js has the new one, so the two disagree about where CanvasKit
# lives. `rm -rf build/web` first.
#
# RECAPTCHA_SITE_KEY attests the web client to Firebase App Check. It must be
# a score-based reCAPTCHA ENTERPRISE site key - AI Logic does not accept v3.
# App Check enforcement is required for AI Logic, so an unattested web client
# is refused - set this as a Replit secret.
#
# --no-wasm-dry-run suppresses the advisory wasm-incompatibility report for
# flutter_secure_storage_web; this build targets JavaScript, not WebAssembly.
flutter build web \
  --release \
  --no-wasm-dry-run \
  --dart-define=APP_VERSION="${APP_VERSION:-1.0.0}" \
  --dart-define=RECAPTCHA_SITE_KEY="${RECAPTCHA_SITE_KEY:-}"

if [ -z "${RECAPTCHA_SITE_KEY:-}" ]; then
  log "WARNING: RECAPTCHA_SITE_KEY is not set - this build is UNATTESTED;"
  log "         AI features are denied while App Check is enforced."
fi

log "Bundle ready: $(du -sh build/web | cut -f1) in build/web"
