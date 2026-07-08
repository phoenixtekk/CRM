# Testing & Validation — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered the modules, the SBL-enabled profile,
> and the device certificate** and that a device **can bring the tunnel up at the logon screen and log
> on over it**. Deep head-end diagnostics (why a specific tunnel-group rejects a cert, ISE posture
> results) are Cisco-side and deferred to Cisco docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/object readiness | Discovery script | Objects found and assigned |
| T2 | Trusted root + device cert applied | Intune monitor + device | Cert *Succeeded*, cert in `LocalMachine\My` |
| T3 | Win32 app installed — Core **and** SBL | Intune monitor + device | App *Installed*, `vpnplap64.dll` present |
| T4 | VPN profile applied / XML has SBL | Device | Profile *Succeeded*, `UseStartBeforeLogon=true` |
| T5 | PLAP option shows at logon screen | Pilot device | "Network sign-in" option visible |
| T6 | Pre-logon connect + logon over tunnel | Pilot device | Tunnel up before logon; Windows logon succeeds |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Fleet coverage report | Report script | Coverage ≥ target |
| T9 | Rollback / uninstall | Test device | App/SBL/profile/cert removed cleanly |

---

## T1 — Tenant and object readiness
**Steps:** Run `SBLVPN-Discovery.ps1`. Review the readiness table: the app
`Cisco Secure Client – Pre-Logon (SBL) – Win32`, the VPN profile
`Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, the trusted-root profile
`Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`, the SCEP profile
`Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`, and the groups, each assigned to
`PILOT – Pre-Logon VPN (SBL) Users`.
**PASS:** Every expected object is present and assigned.
**FAIL:** Any object missing/unassigned → fix in Requirements/Implementation before piloting.

## T2 — Trusted root + device certificate applied
**Steps:** Intune → **Devices > Configuration >** the two certificate profiles **> Device status**.
On the device, confirm the device certificate is in the **LocalMachine\My** store (`certlm.msc`) and
chains to the root delivered by `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`.
**PASS:** Both profiles *Succeeded*; a valid, unexpired **machine** certificate is present and chains
to the trusted root.
**FAIL:** *Error*/no cert / wrong store (user not machine) → see Troubleshooting §Certificate issues.

## T3 — Win32 app installed (Core **and** Start Before Logon)
**Steps:** Intune → **Apps > Monitor > App install status** for
`Cisco Secure Client – Pre-Logon (SBL) – Win32`. On the device, confirm the Secure Client is present
**and** the PLAP DLL exists (e.g. `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll`).
**PASS:** Status *Installed* and the SBL component (`vpnplap64.dll`) is present.
**FAIL:** *Failed*/*Pending*, or the client is present but `vpnplap64.dll` is missing → see
Troubleshooting §Install failures and §PLAP option not showing.

## T4 — VPN profile applied and SBL enabled in the XML
**Steps:** Confirm the VPN client profile XML is present in
`%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile` and contains
`<UseStartBeforeLogon>true</UseStartBeforeLogon>`. If you also push
`Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, confirm it shows *Succeeded* in Intune.
**PASS:** The profile XML is present with `UseStartBeforeLogon` set to `true` (and the Intune profile,
if used, *Succeeded*).
**FAIL:** No XML, or `UseStartBeforeLogon` missing/`false` → see Troubleshooting §PLAP option not
showing.

## T5 — PLAP "Network sign-in" option shows at the logon screen
**Steps:** **Lock** the device (or sign out) to reach the Windows logon screen. Look for the
**"Network sign-in"** (PLAP) option (typically a button/link at the logon screen that launches the
Cisco Secure Client pre-logon window). A reboot after install may be required for it to appear.
**PASS:** The "Network sign-in" / PLAP option is visible at the logon screen.
**FAIL:** No option → see Troubleshooting §PLAP option not showing (module missing, wrong install
order, or `UseStartBeforeLogon` not `true`).

## T6 — Pre-logon connect + Windows logon over the tunnel (the decisive test)
**Steps:** From the logon screen, click **"Network sign-in"**, select the configured connection
(gateway FQDN from R7), and connect — the **device certificate** authenticates the tunnel with no user
signed in. With the tunnel up, **log on to Windows**. To exercise the real use case, test with a user
who has **never** signed in to this device (no cached credentials) and/or perform an **off-network
password change** that must reach a domain controller.
**PASS:** The tunnel establishes **before** logon; the Windows logon completes over the tunnel; a
first-time/no-cached-credential logon and/or off-network password change succeeds.
**FAIL:** Tunnel won't establish, or logon fails with the tunnel up → see Troubleshooting §Tunnel up
but logon fails and §Pre-logon tunnel won't connect (confirm the head-end/tunnel-group with Cisco).

## T7 — On-device validation script
**Steps:** On a pilot device run `SBLVPN-Validation.ps1`.
**PASS:** Script reports the client installed **and** SBL/PLAP present **and**
`UseStartBeforeLogon=true` → overall **PASS** (device cert also PASS if `-RequireCertificate`).
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Fleet coverage report
**Steps:** Run `SBLVPN-Report.ps1`; review app install + VPN/cert profile coverage across the assigned
groups.
**PASS (pilot):** 100% of pilot devices *Installed* + profiles *Succeeded* + certificate present.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3/T4 failures) before widening further.

## T9 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Windows Win32 app
to **Uninstall**). Sync and reboot.
**PASS:** The client, the SBL/PLAP component (the "Network sign-in" option disappears), the VPN
profile, and the device certificate are removed; the device returns to its pre-deployment state.
**FAIL:** Residual client/PLAP option/profile/cert → confirm the Uninstall command and unassignment
took effect.

---

## Overall exit criteria (before Expand)
All of T1–T7 **PASS** on every pilot device (including the decisive pre-logon connect + logon test T6),
T8 shows 100% pilot coverage, and T9 confirms a clean rollback. Record results against each gate; only
then proceed to Phase 5 (Expand).
