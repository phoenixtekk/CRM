# Testing & Validation — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim. The two decisive scenario tests are **T1 (first-time off-network
logon)** and **T2 (off-network password change)** — this product exists to prove them.

> **Scope note:** these tests validate the **outcome** — that a never-logged-on user and an
> expired-password user can get in from off the network — and that the pre-logon path and DC
> reachability are present. Building the tunnel itself is done in the companion products; deep VPN
> gateway / head-end diagnostics are deferred to those products and the vendor's documentation.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | **First-time off-network logon** | Freshly provisioned pilot device | Never-logged-on user completes first logon off-network |
| T2 | **Off-network password change** | Pilot device, expired password | User changes password at logon/lock screen and signs in |
| T3 | Pre-logon path present | On-device validation script | Tunnel (device tunnel or SBL/PLAP) present |
| T4 | DC reachable through the tunnel | Pilot device | A DC is located/reachable once the tunnel is up |
| T5 | Machine cert present (device tunnel only) | Pilot device | Valid cert in LocalMachine\My, chains to trusted CA |
| T6 | Entra-joined control behaves correctly | Entra-joined device | Signs in with no pre-logon tunnel; SSPR/TAP cover password |
| T7 | Fleet readiness roll-up | Report script | In-scope coverage ≥ target |
| T8 | Break-glass / fallback | Test device | Local admin / TAP / on-network path recovers a failed device |

---

## T1 — First-time off-network logon (the decisive test #1)
**Steps:** Take a **freshly provisioned** hybrid-joined (or domain-joined) device that a specific test
user has **never signed in to** (no cached credential for that user). Keep the device **off the
corporate network** (e.g. home Wi-Fi / hotspot). Attempt the user's **first interactive Windows
logon**:
- **Device tunnel (A):** the machine tunnel should already be up at the logon screen (auto at boot);
  submit the credentials.
- **SBL / PLAP (B):** at the logon screen, use the network/VPN option to bring up
  `Cisco Secure Client – Pre-Logon (SBL) – Win32` first, then submit the credentials.
**PASS:** The first interactive logon **succeeds** off-network — the DC was reachable through the
pre-logon tunnel and validated the never-before-cached user.
**FAIL:** Logon rejected / "no logon servers available" → see Troubleshooting §First logon still fails
(tunnel not up before credential submit, DC not reachable, or wrong approach for the join type).

## T2 — Off-network password change (the decisive test #2)
**Steps:** For a pilot user, **expire the password** (or set "must change at next logon"). Off-network,
have the user reach the **logon/lock screen** and attempt the **password change**:
- **Device tunnel (A):** the machine tunnel is up at the lock screen; change the password.
- **SBL / PLAP (B):** bring up the pre-logon VPN first, then change the password.
**PASS:** The password change **completes** and the user signs in — the AD/Kerberos password change
reached a DC through the tunnel.
**FAIL:** "Unable to change password" / change not accepted → see Troubleshooting §Password change
fails (no DC path, clock skew). Note that **SSPR alone does not** satisfy a hybrid/domain-joined
device's local interactive change — confirm the DC path.

## T3 — Pre-logon path present
**Steps:** On a pilot device run `PREVPN-Validation.ps1`.
**PASS:** The script reports a pre-logon tunnel present — a **device tunnel** (`Get-VpnConnection
-AllUserConnection`) **or** the **SBL/PLAP** credential provider (`vpnplap64.dll`) — matching the
chosen approach.
**FAIL:** No pre-logon capability found → the chosen approach's object is not deployed/assigned; fix
via the companion product, then re-run.

## T4 — DC reachable through the tunnel
**Steps:** With the tunnel up on a pilot device, run `PREVPN-Validation.ps1` (it performs a
best-effort DC check), or manually `nltest /dsgetdc:<domain>` / `Test-NetConnection <dc-fqdn> -Port
389`.
**PASS:** A domain controller is located and reachable through the tunnel.
**FAIL:** No DC found / unreachable → see Troubleshooting §First logon still fails (routes/DNS/firewall
for the DC subnets through the tunnel).

## T5 — Machine certificate present (device-tunnel deployments only)
**Steps:** On a device-tunnel pilot device, confirm a valid machine certificate is in
**LocalMachine\My** and chains to a CA the gateway trusts (`PREVPN-Validation.ps1 -RequireCertificate`).
**PASS:** Certificate present, not expired, correct chain.
**FAIL:** No/invalid cert → the silent tunnel cannot authenticate; fix the machine-cert profile in the
companion device-tunnel product. (Not applicable to SBL/PLAP.)

## T6 — Entra-joined control behaves correctly
**Steps:** On the **Entra-joined** control device, confirm a first sign-in and (if applicable) a
password change work **without** any pre-logon tunnel; confirm SSPR/TAP cover the cloud password path.
**PASS:** The Entra-joined device signs in over ordinary internet with **no** pre-logon path present —
confirming cloud-only devices do not need this deployment.
**FAIL:** If it appears to need a pre-logon tunnel, re-check the join type (`dsregcmd /status`) — it
may actually be hybrid-joined, not Entra-joined.

## T7 — Fleet readiness roll-up
**Steps:** Run `PREVPN-Report.ps1`; review counts by join type and the **coverage %** of in-scope
(hybrid/domain-joined) devices that have a pre-logon path.
**PASS (pilot):** 100% of in-scope pilot devices have a validated pre-logon path.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining gaps triaged.
**FAIL:** Coverage below target → remediate with `PREVPN-Remediation.ps1` (adds lacking devices/users
to the pilot group for the chosen approach) before widening.

## T8 — Break-glass / fallback verification
**Steps:** On a disposable test device, simulate a pre-logon failure (e.g. gateway unreachable) and
confirm a recovery path works: **local administrator** logon, **TAP** for a cloud-capable first
sign-in, or bringing the device **on-network** once.
**PASS:** At least one break-glass path recovers the device without stranding the user.
**FAIL:** No fallback works → establish the R8 break-glass path before expanding.

---

## Overall exit criteria (before Expand)
**T1 and T2 PASS** on every in-scope join type, T3–T5 PASS on the pilot, T6 confirms the Entra-joined
control needs no tunnel, T7 shows 100% in-scope pilot coverage, and T8 confirms a working break-glass
path. Record results against each gate; only then proceed to Phase 5 (Expand).
