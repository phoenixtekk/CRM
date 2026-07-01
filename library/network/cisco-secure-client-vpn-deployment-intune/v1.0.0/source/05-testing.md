# Testing & Validation — Cisco Secure Client (AnyConnect) VPN via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the client and profile** and that a
> device **can establish the VPN**. Deep head-end diagnostics (why a specific tunnel-group rejects a
> cert, ISE posture results) are Cisco-side and deferred to Cisco docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/connector readiness | Discovery script | Connectors green; objects found |
| T2 | App install per platform | Intune monitor + device | App *Installed* |
| T3 | VPN profile applied per platform | Intune monitor + device | Profile *Succeeded* |
| T4 | Certificate present (if cert auth) | Device | Cert issued & chains to trusted CA |
| T5 | Manual VPN connect | Pilot device | Tunnel up, internal resource reachable |
| T6 | On-device validation script | Pilot device | Script reports PASS |
| T7 | Fleet coverage report | Report script | Coverage ≥ target |
| T8 | Rollback / uninstall | Test device | App/profile removed cleanly |

---

## T1 — Tenant and connector readiness
**Steps:** Run `CSCVPN-Discovery.ps1`. Review the readiness table: APNs (iOS), Managed Google Play
(Android), the four apps, the four VPN profiles, and the cert profile (if used), each assigned to
`PILOT – Cisco VPN Users`.
**PASS:** All required connectors are active and every expected object is present and assigned.
**FAIL:** Any connector inactive or any expected object missing/unassigned → fix in Requirements/
Implementation before piloting.

## T2 — App install per platform
**Steps:** For each platform, Intune → **Apps > Monitor > App install status** for
`Cisco Secure Client – VPN – (platform)`. On the device, confirm the client binary/app exists
(Windows: Secure Client present in Programs; macOS: app in /Applications; iOS/Android: app icon).
**PASS:** Status *Installed* for the pilot device and the app is visibly present.
**FAIL:** *Failed*/*Pending* beyond the expected window → see Troubleshooting §Install failures.

## T3 — VPN profile applied per platform
**Steps:** Intune → **Devices > Configuration >** `Cisco Secure Client – VPN – Profile – (platform)`
**> Device status**. On device, confirm the VPN connection entry appears (Windows: Secure Client
shows the configured gateway; macOS/iOS: VPN entry in Settings; Android: VPN present).
**PASS:** Profile status *Succeeded* and the connection entry with the correct gateway FQDN is present.
**FAIL:** *Error*/*Conflict* or no connection entry → see Troubleshooting §Profile not applying.

## T4 — Certificate present (cert-auth deployments only)
**Steps:** Confirm `Cisco Secure Client – VPN – Device Cert (SCEP)` shows *Succeeded* in Intune and
the certificate is in the device store (Windows: certlm/certmgr; macOS: Keychain; iOS/Android: the
managed profile shows the cert).
**PASS:** Certificate issued, not expired, and chains to a CA the head-end trusts.
**FAIL:** No cert / wrong chain → see Troubleshooting §Certificate issues.

## T5 — Manual VPN connect (the decisive test)
**Steps:** On the pilot device, open **Cisco Secure Client**, select the configured connection
(gateway FQDN from R6), connect, and authenticate with the intended method (certificate / SAML-Entra
/ RADIUS). Once connected, reach an **internal-only** resource (internal URL, file share, or ping an
internal host) that is *not* reachable without the VPN.
**PASS:** Tunnel establishes; the internal resource is reachable; disconnect returns to normal.
Repeat on **every** piloted platform.
**FAIL:** Auth rejected, no tunnel, or resource unreachable → capture the Secure Client message and
see Troubleshooting §VPN won't connect (and confirm the head-end/tunnel-group with Cisco).

## T6 — On-device validation script
**Steps:** On a pilot device run `CSCVPN-Validation.ps1`.
**PASS:** Script reports the client installed **and** the VPN profile present → overall **PASS**.
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T7 — Fleet coverage report
**Steps:** Run `CSCVPN-Report.ps1`; review install + profile coverage across the assigned groups.
**PASS (pilot):** 100% of pilot devices *Installed* + profile *Succeeded*.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T8 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Windows Win32
app to **Uninstall**). Sync.
**PASS:** The managed app and VPN profile are removed; the device returns to its pre-deployment state.
**FAIL:** Residual app/profile → confirm the Uninstall command (Windows) or unassignment took effect.

---

## Overall exit criteria (before Expand)
All of T1–T6 **PASS** on every piloted platform, T7 shows 100% pilot coverage, and T8 confirms a
clean rollback. Record results against each gate; only then proceed to Phase 5 (Expand).
