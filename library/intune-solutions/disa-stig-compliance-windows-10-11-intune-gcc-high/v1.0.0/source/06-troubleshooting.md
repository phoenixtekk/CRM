# Troubleshooting — Government / GCC High edition

Symptom-first fixes for the most common failures when delivering DISA STIG alignment via Intune in the **US Government cloud (GCC High / DoD)**. Most GCC-High-specific failures trace back to one of three roots: **wrong cloud/URL**, **SSL-inspected `*.us` endpoints**, or **assuming a Commercial-only feature exists**.

---

## A. Sign-in, portal, and cloud-targeting

**Symptom: the admin portal shows "tenant not found," redirects to a `.com` sign-in, or shows a different tenant.**
- **Cause:** you opened the **Commercial** portal.
- **Fix:** use **`https://intune.microsoft.us`** and **`https://portal.azure.us`**. Confirm the sign-in authority is **`login.microsoftonline.us`**. Clear cached `.com` sessions if the browser auto-redirects.

**Symptom: `Connect-MgGraph` succeeds but scripts see none of your Intune objects.**
- **Cause:** you connected to the **Global** (Commercial) cloud — the default.
- **Fix:** always pass **`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD). Verify with `Get-MgContext`; the account/host must be the sovereign one (`graph.microsoft.us` / `dod-graph.microsoft.us`). Run `Get-MgEnvironment` to confirm both Gov environments are present.

**Symptom: the interactive Graph sign-in popup hangs or times out (often from a jumpbox).**
- **Cause:** the WAM broker doesn't work in that environment.
- **Fix:** `Set-MgGraphOption -DisableLoginByWAM $true` (persists across sessions), then reconnect. Use **PowerShell 7+**.

**Symptom: `-Environment USGovDoD` fails but `USGov` works (or vice-versa).**
- **Cause:** you're using the wrong Gov sub-cloud for your tenant. GCC High = `USGov`; DoD = `USGovDoD` (`dod-graph.microsoft.us`).
- **Fix:** match `-Environment` to your tenant type.

---

## B. Enrollment & device check-in

**Symptom: devices won't enroll, or enrolled devices never check in / never receive policy.**
- **Cause 1 — SSL inspection on `*.manage.microsoft.us`.** This is **unsupported** and silently breaks check-in.
  - **Fix:** exclude `*.manage.microsoft.us` (and `*.dm.microsoft.us` for Defender/EPM) from SSL/TLS inspection.
- **Cause 2 — Commercial endpoints allowed instead of `*.us`.**
  - **Fix:** allow the **US Gov** endpoints (`*.manage.microsoft.us`, `login.microsoftonline.us`, `enterpriseregistration.microsoftonline.us`, `graph.microsoft.us`/`dod-graph.microsoft.us`, `*.events.data.microsoft.com`). See `gcc-high-parity-notes.md` §3.
- **Cause 3 — proxy requires auth for update downloads.**
  - **Fix:** some tasks need **unauthenticated** proxy access to `manage.microsoft.us`.

**Symptom: "I set up Autopilot but it doesn't work in GCC High."**
- **Cause:** classic **Windows Autopilot is not available** in GCC High/DoD.
- **Fix:** use **Autopilot device preparation** (partial — user-driven only) or a non-Autopilot enrollment (Entra join + automatic enrollment). See parity notes §6–§7.

---

## C. Policy authoring & assignment

**Symptom: a Settings Catalog setting I need in Commercial isn't in `intune.microsoft.us`.**
- **Cause:** the CSP hasn't reached the sovereign cloud yet (features lag in GCC High/DoD).
- **Fix:** first confirm it isn't a permanent gap (parity notes §6–§7). If it's just lagging, deliver that STIG rule via **Administrative Templates (ADMX)** or a **custom OMA-URI** profile (`03-implementation.md` §2c–2d). **Verify for GCC High/DoD.**

**Symptom: profile deployment shows Conflict on a device.**
- **Cause:** two profiles set the **same setting** to different values.
- **Fix:** run `STIGG-Validation.ps1 -Environment USGov`; it flags overlapping settings. Consolidate to one authoritative profile per domain (best-practice: split by domain, one owner per setting).

**Symptom: a custom OMA-URI profile shows Error.**
- **Cause:** malformed OMA-URI path/data type/value, or the CSP doesn't exist in the Gov cloud.
- **Fix:** re-check the OMA-URI against the CSP reference; confirm the CSP is available in GCC High/DoD (**verify**). Test on one pilot device before wider assignment.

**Symptom: I assigned a lockdown and broke a workflow across many devices.**
- **Cause:** assignment skipped the pilot gate, or expanded before Gate 4.
- **Fix:** remove the prod assignment, re-scope to `SG-STIG-Pilot-Devices`, and re-run the gates. This is exactly what the gated model prevents — never assign a new lockdown fleet-wide at once.

---

## D. STIG audit baseline (Advanced Analytics)

**Symptom: the STIG audit baseline doesn't appear.**
- **Cause:** Advanced Analytics isn't licensed/enabled, or the feature hasn't reached your tenant (it's GCC-High-oriented).
- **Fix:** confirm the **Advanced Analytics** add-on is licensed and enabled (`02-requirements.md` R9). **Verify for GCC High/DoD** — DoD status can differ. If unavailable, that's expected; enforce via profiles and report with `STIGG-Report.ps1`.

**Symptom: audit baseline shows non-compliance but my enforcement profiles are applied.**
- **Cause:** the audit baseline is **audit-only** and assesses against DISA recommendations that may exceed what you enforce, or the device hasn't re-checked-in.
- **Fix:** treat audit results as **advisory**. Reconcile deltas against your rule→setting map; force a device sync; decide whether to add the flagged setting to an enforcement profile.

---

## E. Scripts (this package)

**Symptom: a script errors on connect.**
- **Fix:** ensure `Install-Module Microsoft.Graph` is done, you're on **PS7+**, and you pass **`-Environment USGov`/`USGovDoD`**. Confirm required read scopes were consented.

**Symptom: `STIGG-Remediation.ps1` / `STIGG-Set-ScopeTargeting.ps1` "didn't do anything."**
- **Cause:** they default to **`-WhatIf`** (preview only) — by design.
- **Fix:** review the previewed actions, get approval, then re-run with **`-WhatIf:$false`** to apply.

**Symptom: Report/Validation output looks empty.**
- **Cause:** connected to the wrong cloud, or insufficient read scope.
- **Fix:** verify `Get-MgContext` shows the Gov host; re-consent read scopes (`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`).

---

## F. When to escalate to DISA vs Microsoft

- **Rule content questions** (what a STIG rule requires, its severity/CCI) → **DISA / DoD Cyber Exchange** (`public.cyber.mil`) and **STIG Viewer**. This solution does not author rule content.
- **Intune/sovereign platform questions** (a setting missing in Gov, an endpoint behavior, feature availability) → **Microsoft US Gov support** and the cited Microsoft Learn docs in `gcc-high-parity-notes.md`.

## Quick diagnostic order

1. Am I in **`*.us`** and on **`-Environment USGov/USGovDoD`**? (Root of most issues.)
2. Are the **`*.us` endpoints** allowed and **not SSL-inspected**?
3. Is the feature I expect **actually available** in GCC High/DoD? (Parity notes §6–§7.)
4. Did I skip a **gate** (assigned before pilot/validate)?
5. For scripts: PS7+, module installed, correct `-Environment`, `-WhatIf` understood.
