# 5. Testing Guide — SSL/TLS Inspection & Decryption Rollout (Netskope)

Run after the pilot decryption policy and the trusted-certificate profile apply (Implementation Steps
6-7), and again at each expansion stage.

## Test 1 — Inspection root trusted on device
Do: On a pilot device run `NSSSL-Validation.ps1`, or open the certificate manager and confirm the
inspection root is in Computer -> Trusted Root Certification Authorities.
Expected: The inspection root (and any intermediate) is present and the chain validates.

## Test 2 — Decrypted sites show no certificate warning
Do: On a pilot device, browse general/inspectable sites that are in decryption scope.
Expected: Pages load cleanly; the presented certificate is the inspection-signed certificate; no
certificate warnings.

## Test 3 — Do-not-decrypt categories are bypassed
Do: Open a banking site and a health site (categories in `Do-Not-Decrypt – Sensitive & Pinned – All
Stages`).
Expected: Each site presents its original (real) certificate, not the inspection certificate — proof
the bypass is taking precedence over the decrypt rule.

## Test 4 — Certificate-pinned applications still work
Do: Launch known certificate-pinned applications on a pilot device.
Expected: They connect and function normally (they are passed through, not decrypted/broken).

## Test 5 — Pilot scope only (no fleet impact yet)
Do: On a non-pilot device, confirm traffic is not being decrypted.
Expected: Non-pilot devices are unaffected until expansion (Implementation Steps 8-9).

## Test 6 — User experience acceptable
Do: On pilot devices, browse normally and note page-load responsiveness during inspected traffic.
Expected: No material degradation in user experience under normal browsing.

## Test 7 — Coverage and readiness report
Do: Run `NSSSL-Report.ps1` across pilot devices.
Expected: A per-device certificate-trust + decryption-readiness summary (root present, chain valid,
last sync) with laggards flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-4 pass: trust is silent, decrypted sites show no warning, do-not-decrypt categories are bypassed, and pinned apps work |
| Broad pass | Tests 1-3, 7 pass at each expansion stage before widening scope; no devices in scope are missing certificate trust |
