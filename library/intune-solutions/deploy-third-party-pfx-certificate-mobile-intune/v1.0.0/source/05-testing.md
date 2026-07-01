# 5. Testing Guide — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

Run after the pilot profile applies (Implementation Step 5) and again before expanding.

## Test 1 — Trusted chain installed
**Do:** On a pilot device, **Settings → General → VPN & Device Management →** open
`Trusted Root – Org CA – iOS`; or run `PFXMOB-Validation.ps1`.
**Expected:** The root (and intermediate, if any) CA certificate is present and trusted.

## Test 2 — Identity (leaf) present on the device
**Do:** On the pilot device, open the delivery profile (`PFX Imported – iOS App Cert – Pilot` or
`Custom PKCS12 – iOS App Cert – Pilot`) and confirm the certificate appears; or run
`PFXMOB-Validation.ps1`.
**Expected:** The leaf identity is installed and chains to the trusted root.

## Test 3 — Profile reports Succeeded
**Do:** Intune → **Devices → Configuration →** open the delivery profile **→ Device status**.
**Expected:** Pilot devices show **Succeeded** (not Error/Pending).

## Test 4 — Certificate Connector decrypted the import (Path A only)
**Do:** Intune → **Tenant administration → Connectors and tokens → Certificate connectors**; confirm
the connector is healthy and the imported PFX deployed.
**Expected:** Connector **Active/Healthy**; the imported-PFX profile delivers without connector errors.

## Test 5 — The app can use the certificate (the real success criterion)
**Do:** Open the target app on the pilot device and exercise the function that consumes the
certificate.
**Expected:** The app reads/uses the identity successfully. If not, re-check the app vendor's keychain
access / App Configuration requirement (Implementation Step 5) — delivery can be correct while the app
still needs its vendor-specified access method.

## Test 6 — Intended purpose matches (Path A, non-S/MIME app cert)
**Do:** Confirm the imported PFX intended purpose set at import matches the imported-PFX profile and
what the app expects.
**Expected:** Values match. A mismatch here is a common reason a non-S/MIME app cert deploys but is
not consumed as expected — consider Path B if the S/MIME framing does not fit.

## Test 7 — Fleet report
**Do:** Run `PFXMOB-Report.ps1`.
**Expected:** A clear per-device certificate-deployment status across the targeted groups.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–3 and **Test 5** pass on `iOS App Cert – Pilot` (plus Test 4/6 for Path A) |
| **Broad pass** | Tests 1–3, 5, 7 pass after assigning `iOS App Cert – Broad` |
