# 5. Testing & Validation — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

Validate against explicit gates. Each gate has a **Test**, an **Expected result**, and **Evidence**. A
gate is **PASS** only when the expected result is observed and evidence is stored in the repository
(R11). Run gates after each phase and again as a full pass before declaring the solution operational.
All supplied scripts default to read-only and connect with **`-Environment USGov`**.

> Testing proves the **technical controls** operate and produce evidence on a sovereign tenant. It is
> not a HIPAA audit or a HITRUST assessment.

---

## Gate 0 — You are on the GCC High cloud (do this first)

- **Test:** Run **`HIPAACOMPG-Discovery.ps1`**. Confirm the connection banner reports **Environment:
  USGov** and your GCC High tenant id, and that managed devices are listed.
- **Expected:** `Get-MgContext` Environment = **USGov**; devices returned. An **empty result** or a
  **Commercial-authority error** means the session reached the wrong cloud — see `06-troubleshooting.md`,
  section F.
- **Evidence:** Discovery console output showing Environment = USGov, stored with date.

## Gate 1 — Tenant readiness (Assess/Configure prerequisites)

- **Test:** From **`HIPAACOMPG-Discovery.ps1`** output, confirm the named compliance policy and
  configuration baselines exist and are assigned to **`HIPAA – Clinical Endpoints`**; Defender-for-GCC-
  High onboarding is active; the CA gate exists; BitLocker policy is present.
- **Expected:** All named objects present and assigned; Defender connector healthy in
  `security.microsoft.us`; `Require Compliance – Clinical Endpoints – Gate` found; no missing
  prerequisites.
- **Evidence:** Discovery output (console/CSV) stored with date.

## Gate 2 — Devices evaluate Compliant

- **Test:** On enrolled clinical endpoints, force a sync (Settings > Accounts > Access work or school >
  Info > Sync) and wait an evaluation cycle. In **Intune admin center** (`https://intune.microsoft.us`)
  > **Devices** > **Compliance** > **`HIPAA Compliance – Clinical Endpoints – Policy`** > **Device
  status**, review state. Run **`HIPAACOMPG-Validation.ps1`** per device.
- **Expected:** Target clinical endpoints report **Compliant**; validation returns **PASS** for each
  in-scope device (any FAIL identifies a real gap).
- **Evidence:** Intune compliance export + validation PASS/FAIL output.

## Gate 3 — Conditional Access blocks non-compliant devices

- **Test:** From a deliberately non-compliant clinical Windows device, attempt to access a gated
  resource; then repeat from a compliant device. Confirm via **Entra** (`entra.microsoft.us`) >
  **Monitoring** > **Sign-in logs** > **Conditional Access** tab for `Require Compliance – Clinical
  Endpoints – Gate`.
- **Expected:** Non-compliant device **blocked** (policy Not satisfied); compliant device **allowed**
  (Success). Break-glass account unaffected.
- **Evidence:** Sign-in log entries (both outcomes) exported; screenshot of the block.

## Gate 4 — Key safeguards enforced

Verify each safeguard is actually enforced on a sample device (not merely measured):

- **BitLocker / encryption:** `manage-bde -status` shows the OS volume **Fully Encrypted**; recovery key
  escrowed to the **Gov** directory (Intune > device > Recovery keys). **Expected:** encrypted + key
  present.
- **Automatic lock / timeout:** device locks after the configured inactivity period (15 min).
  **Expected:** screen locks, password required on resume.
- **Antivirus (Defender):** `Get-MpComputerStatus` shows *RealTimeProtectionEnabled = True*,
  *AntivirusSignatureAge* low, cloud protection on. **Expected:** real-time on, signatures current
  (updated from the **US Gov** service endpoints).
- **Firewall:** `Get-NetFirewallProfile` shows **Enabled = True** for Domain/Private/Public.
  **Expected:** all profiles enabled.
- **Patch currency:** device build ≥ the compliance policy *Minimum OS version*, driven by the
  **Update ring** (`Patch – Clinical Endpoints – Baseline`). **Expected:** at/above the bar.
- **Evidence:** command output / config report per safeguard, captured by
  **`HIPAACOMPG-Validation.ps1`** and stored.

## Gate 5 — TVM exposure reduced

- **Test:** Compare the current **Exposure score** for the clinical device group in **Defender portal**
  (`https://security.microsoft.us`) > **Vulnerability management** > **Dashboard** against the Step 10
  baseline after remediation (`Vulnerability – Clinical Endpoints – Remediation`) and patching. Run
  **`HIPAACOMPG-Report.ps1`** to capture exposure context.
- **Expected:** Exposure score **lower** than baseline (or top recommendations closed); open remediation
  tasks trending down; documented exceptions only.
- **Evidence:** Dashboard export (baseline vs current), remediation/exception status, report CSV.
  > **GCC High note:** if a specific Secure Score recommendation you expected is absent, that may be an
  > **expected Gov parity gap**, not a failure — confirm against `gcc-high-parity-notes.md` before
  > treating it as a defect.

## Gate 6 — Evidence produced and retained (sovereign)

- **Test:** Run **`HIPAACOMPG-Report.ps1`** and confirm a consolidated CSV (per-device compliance,
  safeguard status, exposure context) is written to the **GCC High** evidence repository; confirm
  Intune/Defender exports are date-stamped and retained.
- **Expected:** Complete, dated evidence set present in the access-controlled sovereign repository;
  contents are configuration/compliance metadata only (no ePHI, per GR6).
- **Evidence:** The report file itself + repository listing showing retention.

---

## Regression / ongoing validation

- Re-run **Gate 0** whenever a script returns nothing — the most common GCC High regression is a session
  that reached the Commercial cloud.
- Re-run **Gate 1** (Discovery) periodically to catch drift (deleted/unassigned policy, Defender
  connector failure, CA gate disabled).
- Re-run **Gate 2/4** (Validation) on the recurring cadence; investigate any new FAIL.
- Re-run **Gate 5** each period; re-run **Gate 3** after any CA change.
- For remediation, always run **`HIPAACOMPG-Remediation.ps1`** in default `-WhatIf` mode and review the
  planned action before `-WhatIf:$false -Confirm:$false`.

> A full PASS across Gates 0–6 with stored evidence is the bar for "operational." Re-test after any
> change to a named object, gated by change control (R12).
