# Best Practices — Repeatable Pre-Logon VPN Triage

The Diagnostic Workflow isolates a missing precondition in one incident. These practices make that
repeatable across incidents and across the team, so every triage is faster and cleaner than the last.
Everything here stays **read-only** and vendor-boundary-aware.

> Reuse names verbatim: **`Pre-Logon VPN – Device Tunnel – Profile`**,
> **`Pre-Logon VPN – SBL Module – Win32`**, **`Pre-Logon VPN – SBL – Profile`**,
> **`Pre-Logon VPN – Trusted Root`**, **`Pre-Logon VPN – Device Cert (SCEP)`**,
> **`PILOT – Pre-Logon VPN Devices`**.

## 1. Name the intended mechanism before you touch anything
- Every pre-logon device should be **designed for one mechanism** — Cisco SBL/PLAP **or** the AOVPN
  device tunnel — not "whichever happens to be on it." The single biggest time-saver is confirming the
  intended mechanism (R5) before diagnosing, so you don't "fix" a device tunnel on a machine that was
  only ever meant to use SBL.
- Standardize the choice per device population (e.g. device tunnel for domain/hybrid Enterprise
  fleets; SBL where the head-end and client demand it) and record it with the deployment.

## 2. Collect first, reason second
- Run `PLAPDX-Collect-Diagnostics.ps1` **once, early** — snapshot the whole device state before you
  change anything, so you have a before/after and don't lose the failing state.
- Prefer the scripts over click-by-click checks for anything you'll do more than once: they're
  consistent, and the collector's `-OutFile` report attaches straight to the ticket.
- Snapshot **both mechanisms** even when you think you know which one is at fault — the collector
  frequently reveals a second, quieter gap (e.g. a machine cert that's also expired) that would have
  caused a repeat incident.

## 3. Check preconditions in a fixed order
- **SBL:** module installed (Core VPN first) → `vpnplap64.dll` present → PLAP provider registered →
  profile present → `UseStartBeforeLogon=true`. The first FAIL is almost always the whole reason.
- **Device tunnel:** SKU/join eligible → exactly one device tunnel → IKEv2 → `DeviceTunnel`/`AlwaysOn`
  set → machine cert valid. Don't chase the cert while the SKU/join is unverified.
- Treat a rejected connection as a pointer to the **certificate** first, and the **gateway trust
  store** only after the device-side cert checks clean.

## 4. Keep a known-good baseline current
- Maintain at least one working reference device (R6), ideally from `PILOT – Pre-Logon VPN Devices`,
  and record its **issuer, template, profile name, and gateway**. Diagnosis is comparison; a baseline
  turns open questions into diffs.
- Refresh the baseline whenever the CA, gateway, trusted root, or VPN profile changes. A stale baseline
  lies.

## 5. Get the assignment scope right — device vs user
- The **device-tunnel profile must target a device group**, never a user group — the tunnel connects
  with no user at boot. Audit this with `PLAPDX-Check-Intune.ps1` on a schedule; a mis-scoped profile
  is the single most common silent device-tunnel failure.
- Keep SBL module + SBL profile + cert profiles assigned to the **same** device population, so a device
  is either fully pre-logon-ready or clearly not — never half-configured.

## 6. Read-only discipline
- Diagnostics **observe; they never remediate.** No script here changes device, tenant, or gateway
  state. This keeps triage safe to run in production, on a user's device, mid-incident, without a
  change window.
- When you *do* remediate, do it in the owning plane (the Intune app/profile/cert, or a gateway-side
  change by the gateway admin) — deliberately, under change control for anything shared or
  outward-facing (the issuing CA, the gateway, a broadly assigned profile).

## 7. Respect the vendor boundary
- For the **VPN head-end / gateway** (Cisco ASA/FTD, RRAS, or a third-party IKEv2 gateway) and the
  Cisco Secure Client **profile editor**, gather the evidence the checks name (the issuing-CA name, the
  rejection reason, whether the attempt arrived) and read it — but follow the **vendor's official
  documentation** for exact console navigation and trust-store configuration. Don't invent menu paths.
- Author every check on the **Windows / Intune / Entra / certificate** side at exact detail — that's
  where your leverage and precision are.

## 8. Least-privilege, auditable access
- Use **read-only** roles (Global Reader / a custom read role) for portal work, and **read scopes
  only** for Graph. The toolkit never needs write access. Run the device-side scripts **elevated** for
  visibility (R2), not to change anything.

## 9. Close the loop
- After every incident, confirm with the matching **gate in `05-testing.md`** and reboot to see the
  tile appear / the tunnel connect — a fix isn't done until pre-logon connectivity demonstrably works.
- Record the **root-cause precondition** on the ticket (module / flag / provider / SKU-join /
  single-tunnel / IKEv2 / cert / scope). Patterns emerge: repeated cert failures mean the trusted-root
  or SCEP profile needs attention; repeated device-tunnel mis-scopes mean the assignment process needs
  a guardrail. Fix the pattern, not just the incident.
