#!/usr/bin/env bash
# Keep the Flutter environment and dependencies ready after task merges.
#
# Replit invokes this script with bash from the project root and closed stdin.
set -euo pipefail

cd "$(dirname "$0")/../.."

if [[ -n "${RECAPTCHA_SITE_KEY:-}" ]]; then
  printf '[post-merge] Building the attested Flutter web release\n'
  bash tool/replit/build_web.sh
else
  source tool/replit/install_flutter.sh
  export PATH="${FLUTTER_HOME:-$HOME/flutter}/bin:$PATH"
  printf '[post-merge] Fetching Flutter dependencies\n'
  flutter pub get
  printf '[post-merge] RECAPTCHA_SITE_KEY is unavailable; skipped release build.\n'
  printf '[post-merge] Release builds still require the site key via build_web.sh.\n'
fi
