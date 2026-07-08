# Testing & Validation — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the user certificate and the VPN profile**,
> that the tunnel **auto-connects on sign-in**, and that **Conditional Access gates access** as intended.
> Deep head-end diagnostics (why the RRAS/Azure gateway rejects an EAP handshake) are Microsoft-side and
> deferred to Microsoft docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant readiness | Discovery script | Objects found; CA policy present |
| T2 | User certificate issued | Intune monitor + device | SCEP cert *Succeeded*, in `CurrentUser\My` |
| T3 | VPN profile applied | Intune monitor + device | Profile *Succeeded*; `AOVPN User Tunnel` present |
| T4 | Auto-connect on sign-in | Pilot device | Tunnel *Connected* after sign-in |
| T5 | Internal resource over tunnel | Pilot device | Internal-only resource reachable |
| T6 | Conditional Access behaves | Entra report-only / sign-in logs | Compliant allowed, non-compliant blocked |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Fleet coverage report | Report script | Coverage ≥ target |
| T9 | Rollback / report-only | Test device + CA policy | Profiles removed; CA reverts cleanly |

---

## T1 — Tenant and object readiness
**Steps:** Run `AOVUT-Discovery.ps1`. Review the readiness table: the trusted-root profile, the user SCEP
profile, the VPN profile, the Conditional Access policy `CA – AOVPN User Tunnel Access`, and the
pilot/prod user groups — each present and (profiles) assigned to `PILOT – AOVPN User Tunnel Users`.
**PASS:** Every expected object is present, profiles are assigned, and the Conditional Access policy is
found.
**FAIL:** Any expected object missing/unassigned → fix in Requirements/Implementation before piloting.

## T2 — User certificate issued
**Steps:** Intune → **Devices > Configuration >** `AOVPN – User Tunnel – User Cert (SCEP) – Windows` **>
Device status**. On the device, open **certmgr.msc** (Current User) → **Personal > Certificates** and
confirm a valid user certificate with **Client Authentication** EKU.
**PASS:** Profile status *Succeeded* and a non-expired user cert chains to the trusted root in
`CurrentUser\My`.
**FAIL:** *Error* / no cert / broken chain → see Troubleshooting §Certificate issues.

## T3 — VPN profile applied
**Steps:** Intune → **Devices > Configuration >** `AOVPN – User Tunnel – Profile – Windows` **> Device
status**. On the device, open **Settings > Network & internet > VPN** and confirm `AOVPN User Tunnel`
appears.
**PASS:** Profile status *Succeeded* and the `AOVPN User Tunnel` connection is present with the correct
gateway FQDN.
**FAIL:** *Error* / *Conflict* or no connection entry → see Troubleshooting §Profile not applying.

## T4 — Auto-connect on sign-in (the decisive delivery test)
**Steps:** Have the pilot user **sign out and back in** on the pilot device. Watch the `AOVPN User Tunnel`
connection under **Settings > Network & internet > VPN** (or run `Get-VpnConnection -AllUserConnection`).
**PASS:** The tunnel reaches **Connected** automatically shortly after sign-in, with no manual click
(Always On working).
**FAIL:** Stays *Disconnected* / requires manual connect → see Troubleshooting §Tunnel not auto-connecting.

## T5 — Internal resource over the tunnel
**Steps:** With the tunnel connected, reach an **internal-only** resource (internal URL, file share, or
ping an internal host) that is *not* reachable without the VPN.
**PASS:** The internal resource is reachable while connected; disconnecting (off the corporate LAN) makes
it unreachable again.
**FAIL:** Resource unreachable while connected → check split-tunnel routes/DNS in the profile (R6); if
routing is correct but traffic never arrives, confirm the head-end with your network admin.

## T6 — Conditional Access behaves
**Steps:** Review **Protection > Conditional Access > Insights and reporting** (report-only) for
`CA – AOVPN User Tunnel Access`. Sign in as the pilot user from a **compliant** device and from a
**non-compliant** device (or simulate) against the targeted cloud app.
**PASS:** Report-only shows the policy **would grant** access from a compliant/hybrid-joined device (with
MFA satisfied) and **would block** a non-compliant device — with **no unexpected lockouts** of legitimate
users.
**FAIL:** Legit compliant users would be blocked, or non-compliant devices would be allowed → adjust the
policy scope/grant (Implementation §2.4) before turning it **On**.

## T7 — On-device validation script
**Steps:** On a pilot device, signed in as the pilot user, run `AOVUT-Validation.ps1`.
**PASS:** Script reports the `AOVPN User Tunnel` VPN connection present **and** a valid user cert in
`CurrentUser\My` → overall **PASS**.
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Fleet coverage report
**Steps:** Run `AOVUT-Report.ps1`; review VPN profile + user-cert profile apply coverage across the
assigned groups.
**PASS (pilot):** 100% of pilot devices with the VPN profile *Succeeded* and the user cert *Succeeded*.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T9 — Rollback / report-only verification
**Steps:** On a disposable test device, exclude it from `PILOT – AOVPN User Tunnel Users` (removing the
profiles). Separately, flip `CA – AOVPN User Tunnel Access` to **Report-only**. Sync.
**PASS:** The VPN profile and user certificate are removed from the test device; the Conditional Access
policy stops enforcing immediately when set to report-only.
**FAIL:** Residual tunnel/cert or policy still enforcing → confirm the unassignment and the policy state
took effect.

---

## Overall exit criteria (before Expand)
All of T1–T7 **PASS** on the pilot, T8 shows 100% pilot coverage, and T9 confirms a clean rollback and a
working report-only toggle. Record results against each gate; only then proceed to Phase 5 (Expand) and
turn the Conditional Access policy **On**.
