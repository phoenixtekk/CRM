# Testing & Validation — Windows Always On VPN Device Tunnel (Pre-Logon) via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the certificate and the ProfileXML** and
> that a device **establishes the device tunnel at boot, before logon**. Deep head-end diagnostics (why
> the gateway rejects a specific certificate, IKEv2 negotiation internals) are head-end-side and
> deferred to Microsoft docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant / PKI readiness | Discovery script | Objects found; PKI healthy |
| T2 | Trusted Root CA profile applied | Intune monitor + device | Profile *Succeeded*; root trusted |
| T3 | Machine certificate issued | Device | Cert in `LocalMachine\My` with Client Auth EKU |
| T4 | ProfileXML applied (device context) | Intune monitor + device | Custom profile *Succeeded*; `AOVPN Device Tunnel` present |
| T5 | **Device tunnel up BEFORE logon** | Pilot device at logon screen | Tunnel *Connected*; DC reachable pre-logon |
| T6 | On-device validation script | Pilot device | Script reports PASS |
| T7 | Fleet coverage report | Report script | Coverage ≥ target |
| T8 | Rollback / remove | Test device | Profile + tunnel removed cleanly |

---

## T1 — Tenant and PKI readiness
**Steps:** Run `AOVDT-Discovery.ps1`. Review the readiness table: the Trusted Root CA profile, the SCEP
machine-cert profile, and the Custom ProfileXML profile found and assigned to
`PILOT – AOVPN Device Tunnel – Devices`, and the pilot/prod **device** groups present.
**PASS:** Every expected object is present and assigned to the **device** group; PKI/connector healthy.
**FAIL:** Any object missing/unassigned, or assigned to a **user** group → fix in Implementation before
piloting.

## T2 — Trusted Root CA profile applied
**Steps:** Intune → **Devices > Configuration >** `AOVPN – Device Tunnel – Trusted Root CA – Windows`
**> Device status**. On the device, open `certlm.msc` → **Trusted Root Certification Authorities** and
confirm the issuing CA's root is present.
**PASS:** Profile *Succeeded* and the root CA is in the machine Trusted Root store.
**FAIL:** *Error* or root absent → see Troubleshooting §Certificate issues.

## T3 — Machine certificate issued
**Steps:** Intune → **Devices > Configuration >** `AOVPN – Device Tunnel – Machine Cert (SCEP) –
Windows` **> Device status**. On the device, run
`Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.EnhancedKeyUsageList.FriendlyName -match 'Client Authentication' }`.
**PASS:** SCEP profile *Succeeded*; a non-expired certificate with **Client Authentication** EKU is in
`LocalMachine\My` and chains to a CA the head-end trusts.
**FAIL:** No cert / wrong EKU / wrong chain → see Troubleshooting §Certificate issues.

## T4 — ProfileXML applied in device context
**Steps:** Intune → **Devices > Configuration >** `AOVPN – Device Tunnel – ProfileXML – Windows`
**> Device status**. On the device, run `Get-VpnConnection -AllUserConnection` and confirm the
`AOVPN Device Tunnel` profile is listed.
**PASS:** Custom profile *Succeeded* and the `AOVPN Device Tunnel` profile exists **at the machine
level** (`-AllUserConnection`).
**FAIL:** *Error*/*Conflict*, or the profile appears only per-user / not at all → confirm the profile
is assigned to the **DEVICE** group (see Troubleshooting §Device tunnel absent).

## T5 — Device tunnel up BEFORE logon (the decisive test)
**Steps:** **Reboot** the pilot device. **At the Windows logon screen, with no user signed in**,
confirm the device tunnel is established — e.g. from another session or a management path, or by
signing in as a **brand-new** user with **no cached credential** to confirm authentication against a
domain controller succeeds off-network. Confirm `Get-VpnConnection -AllUserConnection` reports
`AOVPN Device Tunnel` with `ConnectionStatus : Connected`, and an internal DC/host is reachable that is
*not* reachable without the tunnel.
**PASS:** The device tunnel is *Connected* at/around the logon screen before any interactive user
signs in, and a domain controller / internal resource is reachable pre-logon.
**FAIL:** Tunnel not connected pre-logon, or DC unreachable → see Troubleshooting §Tunnel not
connecting (and confirm head-end/IKEv2/CA trust per Microsoft docs).

## T6 — On-device validation script
**Steps:** On a pilot device run `AOVDT-Validation.ps1`.
**PASS:** Script reports the `AOVPN Device Tunnel` profile present **and** a valid machine certificate
in `LocalMachine\My` → overall **PASS**.
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T7 — Fleet coverage report
**Steps:** Run `AOVDT-Report.ps1`; review certificate + ProfileXML apply coverage across the assigned
device groups.
**PASS (pilot):** 100% of pilot devices with both cert profiles and the ProfileXML *Succeeded*.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3/T4 failures) before widening further.

## T8 — Rollback / remove verification
**Steps:** On a disposable test device, remove it from `PILOT – AOVPN Device Tunnel – Devices` (or push
a Custom profile that removes the `AOVPN Device Tunnel` VPNv2 profile). Sync and reboot.
**PASS:** The `AOVPN Device Tunnel` profile is removed; the device boots normally and users log on
without the device tunnel. No pre-logon disruption.
**FAIL:** Residual profile or a broken logon path → confirm the remove profile / unassignment took
effect before touching production.

---

## Overall exit criteria (before Expand)
All of T1–T6 **PASS** on every pilot device, **T5 confirms the tunnel is up before logon with a DC
reachable**, T7 shows 100% pilot coverage, and T8 confirms a clean rollback. Record results against
each gate; only then proceed to Phase 5 (Expand).
