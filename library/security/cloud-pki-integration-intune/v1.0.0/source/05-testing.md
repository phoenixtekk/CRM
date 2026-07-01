# 5. Testing Guide — Cloud PKI Integration with Intune

Run after the pilot profiles apply (Implementation Step 7) and again after each migration step and at
expansion. Use `CPKI-Validation.ps1` for per-device checks and `CPKI-Report.ps1` for fleet coverage.

## Test 1 — Connector healthy
**Do:** Intune → **Tenant administration → Connectors and tokens → Certificate connectors**; run `CPKI-Discovery.ps1`.
**Expected:** The cloud PKI certificate connector shows **Active/healthy** with a recent check-in.

## Test 2 — Trust chain installed on the device
**Do:** On a pilot device, check the root/intermediate (Windows: `certlm.msc` → **Trusted Root** / **Intermediate**), or run `CPKI-Validation.ps1`.
**Expected:** The cloud PKI **root** (and intermediate, if any) is present and trusted.

## Test 3 — Certificate issued to the device
**Do:** Intune → `SCEP Cert – Device Auth – Pilot` (and `PKCS Cert – User Auth – Pilot` if used) **→ Device status**; or `CPKI-Validation.ps1`.
**Expected:** Status **Succeeded**; the leaf certificate is present in the device's **Personal** store, chains to the cloud PKI root, and is within validity.

## Test 4 — Certificate properties correct
**Do:** Inspect the issued certificate (subject/SAN, EKU, validity, issuer) via `CPKI-Validation.ps1` or the certificate store.
**Expected:** Subject/SAN match the profile, **issuer = cloud PKI CA**, EKU includes **Client Authentication**, and the validity matches the template.

## Test 5 — Wi-Fi scenario works on the cloud certificate
**Do:** On a pilot device, connect to the certificate-backed Wi-Fi.
**Expected:** The device authenticates and connects **using the cloud-issued certificate** (not the legacy one).

## Test 6 — VPN / auth scenario works on the cloud certificate
**Do:** Connect the certificate-backed VPN (or perform the authentication action) on a pilot device.
**Expected:** The scenario succeeds using the cloud-issued certificate.

## Test 7 — Renewal behaves
**Do:** Confirm the **renewal threshold** is set on the profile; for a near-expiry test certificate (or by inspection) confirm Intune renews before expiry.
**Expected:** Devices auto-renew before expiry; no gap in certificate coverage.

## Test 8 — Coexistence (during migration)
**Do:** During migration, run `CPKI-Validation.ps1`.
**Expected:** Both the **legacy** and the **cloud PKI** roots are trusted; the re-pointed scenario uses the cloud certificate; no scenario is broken.

## Test 9 — Fleet coverage + expiry report
**Do:** Run `CPKI-Report.ps1`.
**Expected:** A clear per-device certificate coverage report — who has a cloud-issued certificate, issuer, expiry, and any devices still on the legacy CA.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass on the pilot; the Wi-Fi/VPN/auth scenario works on the cloud-issued certificate |
| **Migration pass (per scenario)** | Tests 5/6 pass on the cloud certificate fleet-wide and Test 8 confirms coexistence before draining the legacy CA |
| **Expand pass** | Tests 3, 5/6, 9 pass for the broad scope before retiring the legacy CA |
