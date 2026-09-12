#!/usr/bin/env bash
# Installs a pinned Flutter SDK into the Repl's persistent home directory.
#
# Why not `pkgs.flutter` from replit.nix: the Nix channels Replit pins lag the
# Flutter stable channel by several releases, and this project's pubspec
# requires Flutter >= 3.27 / Dart >= 3.6. Downloading a pinned tarball keeps the
# Repl on the exact SDK the app was built and tested against, and survives a
# nixpkgs bump.
#
# Idempotent: re-running is a no-op once the right version is installed, so it
# is safe to call from both the run command and the deployment build.
set -euo pipefail

# The SDK this project is developed and verified against. Bump deliberately.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.4}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux"

log() { printf '\033[36m[flutter-setup]\033[0m %s\n' "$*"; }

if [ -x "$FLUTTER_HOME/bin/flutter" ] &&
   "$FLUTTER_HOME/bin/flutter" --version 2>/dev/null | grep -q "Flutter ${FLUTTER_VERSION}"; then
  log "Flutter ${FLUTTER_VERSION} already installed at ${FLUTTER_HOME}"
else
  log "Installing Flutter ${FLUTTER_VERSION} into ${FLUTTER_HOME} (first run only, ~1-3 min)"
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  curl -fsSL "${BASE_URL}/${ARCHIVE}" -o "/tmp/${ARCHIVE}"
  tar -xJf "/tmp/${ARCHIVE}" -C "$(dirname "$FLUTTER_HOME")"
  rm -f "/tmp/${ARCHIVE}"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# The Repl's filesystem is not the SDK author's, and git refuses to operate on a
# tree owned by another user. Flutter shells out to git on almost every command.
git config --global --add safe.directory "$FLUTTER_HOME" 2>/dev/null || true

# Web is the only target this Repl builds; disabling the rest skips their
# toolchain probes and keeps `flutter doctor`/first-run fast.
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

log "$(flutter --version | head -1)"
