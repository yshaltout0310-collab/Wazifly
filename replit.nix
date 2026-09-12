# System packages for the Wazifly Repl.
#
# Deliberately NOT including pkgs.flutter: the pinned nixpkgs channel ships an
# SDK older than this project's `flutter >= 3.27` constraint. The SDK is
# installed by tool/replit/install_flutter.sh instead, which pins an exact
# version. Everything below is what that script and the web build need.
{ pkgs }: {
  deps = [
    pkgs.bash
    pkgs.curl # download the Flutter SDK tarball
    pkgs.gnutar # unpack it
    pkgs.xz # .tar.xz decompression
    pkgs.git # Flutter shells out to git for version/state
    pkgs.unzip # pub package extraction
    pkgs.which
    pkgs.python3 # static preview server (tool/replit/serve_web.sh)
  ];
}
