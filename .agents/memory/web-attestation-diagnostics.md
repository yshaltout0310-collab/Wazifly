---
name: Web attestation diagnostics
description: Distinguishing reCAPTCHA key/domain rejection from network and Firebase AI failures.
---

For web App Check failures, inspect the reCAPTCHA Enterprise iframe's site-owner
error on the actual production origin. A successful script-loader response does
not prove that the site key accepts that hostname.

**Why:** The JS SDK can wrap a domain rejection as generic `recaptcha-error`,
while a later Firebase AI request reports an invalid App Check token. Static
hosting telemetry cannot observe the browser's direct requests to Firebase.

**How to apply:** Collect the actual protected request's HTTP status and Firebase
error code, inspect the iframe, and verify the existing key's exact hostname
allowlist. Do not infer connectivity failure from a broad SDK exception type.
Never log tokens, keys, headers, CV text, or complete successful response bodies.
When a Console update is reported complete, verify its effect rather than
assuming the correct project/key was changed or that propagation has finished.
