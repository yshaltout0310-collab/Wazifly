---
name: Flutter web startup in Replit preview
description: Constraints for keeping the Flutter web shell visible while optional Firebase and GPU-dependent features initialize.
---

Firebase Core, browser messaging/token setup, telemetry, App Check, and GPU
decorations must not be awaited or required before the first Flutter frame in
the Replit preview.

**Why:** The preview may have no WebGL, and browser Firebase plugins can resolve
slowly or report unsupported-platform errors. Blocking the first frame makes a
healthy bundle look blank even though the server is serving it.

**How to apply:** Start the app shell first, run optional Firebase/telemetry
work best-effort in the background, and avoid blur filters on the web path when
the renderer reports CPU-only mode.