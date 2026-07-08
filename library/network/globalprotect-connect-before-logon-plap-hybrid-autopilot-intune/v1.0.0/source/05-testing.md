# Testing & Validation — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Run these tests on the **pilot Windows 11 device** before expanding, and spot-check during expansion.
Each test has an explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object
names match the Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered and registered Connect Before Logon during
> Autopilot** and that a device **can bring the tunnel up at the sign-in screen and complete a hybrid
> domain logon over it**. Deep GlobalProtect **portal / gateway** diagnostics (why a specific portal
> rejects an auth method, gateway routing) are Palo Alto-side and deferred to Palo Alto docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/object readiness + group SP owner | Discovery script | Objects found & assigned; group Assigned + SP owner |
| T2 | Autopilot Hybrid-Join provisioning (Win11) | Autopilot + ESP | Provisioning completes; ESP blocks then releases on the app |
| T3 | Win32 app installed + CBL enabled + registered | Intune monitor + device | App *Installed*; GP≥5.2, `Prelogon=1`, PLAP registered |
| T4 | (If cert auth) device certificate applied | Intune monitor + device | Cert *Succeeded*, machine cert in `LocalMachine\My` |
| T5 | Connect Before Logon tile visible at sign-in | Pilot device | CBL / network sign-in tile appears at the lock screen |
| T6 | Pre-logon tunnel + first hybrid logon off-network | Pilot device | Tunnel up before logon; first-time domain logon succeeds |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Log-capture runbook | Pilot device | Evidence ZIP produced (IME + Autopilot + GP logs) |
| T9 | Fleet coverage report | Report script | Coverage ≥ target |
| T10 | Rollback / uninstall | Test device | App/PLAP/cert removed; CBL tile gone |

---

## T1 — Tenant and object readiness (including the group's SP owner)
**Steps:** Run `GPPLAP-Discovery.ps1`. Review the readiness table: the app
`GlobalProtect – Connect Before Logon (PLAP) – Win32` (or the two-app alternative), the optional cert
profile, the device groups `PILOT – / PROD – GlobalProtect PLAP – Autopilot Devices`, whether the app is
referenced as an **ESP blocking app**, and — critically — whether the **Assigned** group has the Intune
Provisioning Client SP (`f1346770-5b25-470b-88bd-d5744ab7952c`) as an **owner**.
**PASS:** Every expected object is present and assigned; the pilot group is **Assigned** and the SP owner
is present.
**FAIL:** Any object missing/unassigned, or the group missing its SP owner → fix in Requirements/
Implementation (R9 / §2.0) before piloting.

## T2 — Autopilot Hybrid-Join provisioning on Windows 11
**Steps:** Provision a **Windows 11** Autopilot device (user-driven, Hybrid Azure AD Join) from an
off-LAN network position. Watch the **Enrollment Status Page**.
**PASS:** The ESP **blocks** on `GlobalProtect – Connect Before Logon (PLAP) – Win32`, the app installs,
the ESP-managed reboot (from the `3010` return) occurs, and provisioning **completes** to the desktop.
**FAIL:** ESP hangs on the app, an "unzipping" error, or a reboot loop → run `GPPLAP-Collect-Logs.ps1`
and see Troubleshooting §"Unzipping" / 0x87D30067, §Autopilot ESP hangs on the app, and §Install fails
after reboot.

## T3 — Win32 app installed, Connect Before Logon enabled and registered
**Steps:** Intune → **Apps > Monitor > App install status** for
`GlobalProtect – Connect Before Logon (PLAP) – Win32`. On the device, confirm GlobalProtect is present
and **≥ 5.2**, `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon` = `1` with the portal
set, and a PLAP credential provider is registered under
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`.
**PASS:** Status *Installed* and all three conditions (GP≥5.2, `Prelogon=1`, PLAP registered) are true.
**FAIL:** *Failed*/*Pending*, or installed but CBL not registered → see Troubleshooting §PLAP tile not
visible and §Install failures.

## T4 — Device certificate applied (cert-auth deployments only)
**Steps:** Confirm `GlobalProtect – PLAP – Device Cert (SCEP) – Windows` shows *Succeeded* in Intune and
a **machine** certificate is present in `LocalMachine\My` (`certlm.msc`), chaining to the trusted root.
**PASS:** A valid, unexpired **device** certificate is present and chains to a CA the portal trusts.
**FAIL:** *Error*/no cert / wrong store (user not machine) → see Troubleshooting §Tunnel up but hybrid
first-logon fails (cert/trust) and confirm portal trust with your Palo Alto admin.

## T5 — Connect Before Logon tile shows at the sign-in screen
**Steps:** **Lock** the Windows 11 device (or sign out) to reach the sign-in screen. Look for the
**Connect Before Logon / network sign-in** tile (a credential-provider option that launches the
GlobalProtect pre-logon window). A reboot after install may be required for it to appear.
**PASS:** The Connect Before Logon / network sign-in tile is visible at the sign-in screen.
**FAIL:** No tile → see Troubleshooting §PLAP tile not visible (GP<5.2, `Prelogon` not set,
`-registerplap` not run or not in SYSTEM, or registration ran before the GP service was ready).

## T6 — Pre-logon tunnel + first hybrid logon off-network (the decisive test)
**Steps:** From the sign-in screen, use the **Connect Before Logon** tile to establish the GlobalProtect
tunnel (portal FQDN from R7) **before** any user signs in. With the tunnel up, perform a **first
interactive logon of a hybrid domain user who has never signed in to this device** (no cached
credentials), from **off the corporate network**.
**PASS:** The tunnel establishes **before** logon; the domain controller is reachable; the first-time
hybrid domain logon **completes over the tunnel**.
**FAIL:** Tunnel won't establish, or logon fails with the tunnel up → see Troubleshooting §Tunnel up but
hybrid first-logon fails (DC/ODJ/time skew) and, for a cached-credential false pass, re-test with a truly
new user.

## T7 — On-device validation script
**Steps:** On the pilot device run `GPPLAP-Validation.ps1`.
**PASS:** Script reports GlobalProtect installed **and ≥ 5.2**, `Prelogon=1` with portal set, **and PLAP
registered** → overall **PASS** (and the join type shows DomainJoined + AzureAdJoined = hybrid).
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Log-capture runbook (the Friday test-window tool)
**Steps:** On the pilot device run
`GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap`. Confirm it produces a timestamped ZIP containing the
IME logs (`IntuneManagementExtension.log`, `AgentExecutor.log`, `AppWorkload.log`), the
`MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip` output, the GlobalProtect
`PanGPS`/`PanGPA` logs, and the relevant Event Viewer channels.
**PASS:** A single evidence ZIP is produced containing the IME, Autopilot/MDM, and GlobalProtect logs.
**FAIL:** Missing sections → re-run elevated; confirm the source paths exist on this device.

## T9 — Fleet coverage report
**Steps:** Run `GPPLAP-Report.ps1`; review app install coverage (and cert coverage if used) across the
Autopilot device groups.
**PASS (pilot):** 100% of pilot devices *Installed* with Connect Before Logon registered.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T10 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Win32 app to
**Uninstall**). Sync and reboot.
**PASS:** GlobalProtect and the PLAP registration are removed (the Connect Before Logon tile disappears),
the certificate (if used) is removed, and the device returns to its pre-deployment state.
**FAIL:** Residual app / CBL tile / cert → confirm the Uninstall command (incl. `-unregisterplap`) and
the unassignment took effect.

---

## Overall exit criteria (before Expand)
All of T1–T8 **PASS** on the pilot Windows 11 device (including the decisive pre-logon tunnel + first
hybrid logon test T6), T9 shows 100% pilot coverage, and T10 confirms a clean rollback. Record results
against each gate; only then proceed to Phase 5 (Expand).
