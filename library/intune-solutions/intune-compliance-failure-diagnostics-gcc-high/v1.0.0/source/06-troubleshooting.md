# 6. Troubleshooting Guide — Compliance-Failure Diagnostics (Government / GCC High)

Failures specific to running compliance diagnostics on a US sovereign-cloud tenant. The **Diagnostic
Playbook** (section 3) handles *device* compliance symptoms; this section handles the failures of the
**tooling and environment** you use to diagnose them. All portals are **`*.us`**.

## Scripts return nothing / "no devices found"
- **Cause:** connected to the **Commercial** cloud. `Connect-MgGraph` without `-Environment` defaults
  to Global.
- **Fix:** `Connect-MgGraph -Environment USGov` (DoD: `USGovDoD`). Confirm with
  `(Get-MgContext).Environment` = **USGov**. This is the single most common GCC High scripting failure.

## `Connect-MgGraph` fails to authenticate on GCC High
- **Cause:** wrong environment value, unconsented scopes, or (for non-USGov/USGovDoD sovereign clouds)
  the built-in app isn't usable.
- **Fix:** verify `Get-MgEnvironment` lists **USGov** (`graph.microsoft.us`, `login.microsoftonline.us`)
  and **USGovDoD** (`dod-graph.microsoft.us`). For USGov/USGovDoD the built-in Microsoft Graph
  PowerShell app is supported; **other** sovereign clouds require a **custom app registration** created
  at `portal.azure.us` — **verify for GCC High** which cloud your tenant is in.

## A portal URL won't load or bounces to a sign-in loop
- **Cause:** a `.com` portal URL on a GCC High tenant, or a stale Commercial bookmark.
- **Fix:** use the `*.us` equivalent (section 1 map). Clear cached Commercial creds; sign in at
  `login.microsoftonline.us`.

## Device stuck at "Not evaluated" no matter what you assign
- **Cause (GCC High-specific):** the device can't reach `*.manage.microsoft.us`, **or** a proxy is
  **SSL-inspecting** it (unsupported).
- **Fix:** allow `*.manage.microsoft.us` (unauthenticated where required) and **exclude it from TLS
  inspection**; same for `*.dm.microsoft.us` (Defender/EPM). Force **Sync**, re-run Discovery.

## BitLocker/Secure Boot/Code Integrity rule fails on a healthy device
- **Cause:** device hasn't **rebooted** since encryption; firmware/TPM outdated; attestation dependency
  (`has.spserv.microsoft.com`) blocked or TLS-inspected; **or** the rule uses a newer DHA capability
  that is **planned, not yet available** in GCC High.
- **Fix:** reboot; update firmware; unblock/exclude the attestation endpoint from inspection. If the
  rule depends on an unavailable DHA capability, **verify for GCC High** and substitute (parity notes).

## "Device threat level" rule never evaluates
- **Cause (GCC High-specific):** the **MTD vendor isn't present in GCC High** — MTD connectors work
  only for vendors that also support Gov.
- **Fix:** in `intune.microsoft.us` → **Tenant administration → Connectors and tokens**, confirm a Gov
  connector exists. If not, **remove or replace** the threat-level rule; don't try to "fix" it.

## Device isn't compliant right after provisioning
- **Cause (GCC High-specific):** you expected **classic Windows Autopilot** timing — **classic
  Autopilot is not available in GCC High** (only Autopilot **device preparation**, with some modes
  planned).
- **Fix:** use Autopilot device preparation or standard enrollment; don't apply Commercial Autopilot
  compliance-grace guidance.

## A device from the old tenant never appears in GCC High
- **Cause:** there is **no in-place migration** from Commercial to the government cloud.
- **Fix:** the device must **unenroll** from the Commercial tenant and **re-enroll** in the GCC High
  tenant. Until then it will never appear or evaluate here.

## Compliant in Intune, still blocked from Microsoft 365
- **Cause:** Conditional Access, not compliance (propagation lag, platform mismatch, or a different CA
  policy).
- **Fix:** Branch D — `portal.azure.us` → **Sign-in logs** → the blocking CA policy + grant control.

## Remediation changed something you didn't expect
- **Cause:** you ran it with an execute flag before piloting.
- **Fix:** Remediation and Set-ScopeTargeting default to **`-WhatIf`**. Always preview first; execute
  (`-Execute` / `-WhatIf:$false`) only after a pilot passes. Roll back via the policy's assignment/
  setting history.

## Report counts don't match the portal
- **Cause:** wrong environment, wrong group/scope filter, or comparing different time windows.
- **Fix:** confirm **USGov** environment, the exact group targeted, and compare against **Devices →
  Compliance → Overview** in `intune.microsoft.us`.

## Endpoints that worked last month now fail
- **Cause:** the `*.us` wildcard hosts / IP ranges rotate as the service scales (and Intune adds Azure
  Front Door ranges).
- **Fix:** re-pull Microsoft's live **US Government endpoints** list; allow the current ranges; never
  pin stale IPs. Keep the wildcard allow-rules (`*.manage.microsoft.us`, `*.dm.microsoft.us`).

---
**Still stuck?** Re-run Step 0 of the Diagnostic Playbook (section 3), confirm you're in USGov +
`*.us`, and confirm the failing rule's feature is actually **supported in GCC High**
(`gcc-high-parity-notes.md`) before escalating — a parity gap is not a bug.
