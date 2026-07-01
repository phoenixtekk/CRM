# 5. Testing & Validation — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender)

Validate the solution against explicit gates. Each gate has a **Test**, an **Expected result**, and **Evidence** to capture. A gate is **PASS** only when the expected result is observed and evidence is stored in the repository (R11). Run gates after each phase and again as a full pass before declaring the solution operational. Use the supplied scripts where noted; all default to read-only.

> Testing proves the **technical controls** operate and produce evidence. It is not a HIPAA audit or a HITRUST assessment.

---

## Gate 1 — Tenant readiness (Assess/Configure prerequisites)

- **Test:** Run **`HIPAACOMP-Discovery.ps1`**. Confirm the named compliance policy and configuration baselines exist and are assigned to **`HIPAA – Clinical Endpoints`**; Defender for Endpoint onboarding is active; the CA gate exists; BitLocker policy is present.
- **Expected:** Discovery reports all named objects present and assigned; Defender connector healthy; `Require Compliance – Clinical Endpoints – Gate` found; no missing prerequisites.
- **Evidence:** Discovery output (console/CSV) stored with date.

## Gate 2 — Devices evaluate Compliant

- **Test:** On enrolled clinical endpoints, force a sync (Settings > Accounts > Access work or school > Info > Sync) and wait an evaluation cycle. In **Intune admin center** > **Devices** > **Compliance** > **`HIPAA Compliance – Clinical Endpoints – Policy`** > **Device status**, review state. Run **`HIPAACOMP-Validation.ps1`** per device.
- **Expected:** Target clinical endpoints report **Compliant**; validation returns **PASS** for each in-scope device (any FAIL identifies a real gap to remediate).
- **Evidence:** Intune compliance export + validation PASS/FAIL output.

## Gate 3 — Conditional Access blocks non-compliant devices

- **Test:** From a deliberately non-compliant clinical Windows device (e.g. BitLocker temporarily suspended in a test, or a freshly enrolled device not yet compliant), attempt to access a gated resource. Then repeat from a compliant device. Confirm via **Entra** > **Monitoring** > **Sign-in logs** > **Conditional Access** tab for `Require Compliance – Clinical Endpoints – Gate`.
- **Expected:** Non-compliant device is **blocked** (access denied, policy applied = Failure/Not satisfied); compliant device is **allowed** (Success). Break-glass account is unaffected.
- **Evidence:** Sign-in log entries (both outcomes) exported; screenshot of the block.

## Gate 4 — Key safeguards enforced

Verify each safeguard is actually enforced on a sample device (not merely measured):

- **BitLocker / encryption:** `manage-bde -status` shows the OS volume **Fully Encrypted**; recovery key escrowed (Intune > device > Recovery keys). **Expected:** encrypted + key present.
- **Automatic lock / timeout:** device locks after the configured inactivity period (15 min). **Expected:** screen locks, password required on resume.
- **Antivirus (Defender):** `Get-MpComputerStatus` shows *RealTimeProtectionEnabled = True*, *AntivirusSignatureAge* low, cloud protection on. **Expected:** real-time on, signatures current.
- **Firewall:** `Get-NetFirewallProfile` shows **Enabled = True** for Domain/Private/Public. **Expected:** all profiles enabled.
- **Patch currency:** device build ≥ the compliance policy *Minimum OS version*. **Expected:** at/above the bar.
- **Evidence:** command output / config report per safeguard, captured by **`HIPAACOMP-Validation.ps1`** and stored.

## Gate 5 — TVM exposure reduced

- **Test:** Compare the current **Exposure score** for the clinical device group in **Defender portal** > **Vulnerability management** > **Dashboard** against the Step 10 baseline after remediation tasks (`Vulnerability – Clinical Endpoints – Remediation`) and patching have run. Run **`HIPAACOMP-Report.ps1`** to capture exposure.
- **Expected:** Exposure score **lower** than baseline (or top recommendations closed); open remediation tasks trending down; documented exceptions only.
- **Evidence:** Dashboard export (baseline vs current), remediation/exception status, report CSV.

## Gate 6 — Evidence produced and retained

- **Test:** Run **`HIPAACOMP-Report.ps1`** and confirm a consolidated CSV (per-device compliance, safeguard status, TVM exposure) is written to the evidence repository; confirm Intune/Defender exports are date-stamped and retained.
- **Expected:** Complete, dated evidence set present in the access-controlled repository; contents are configuration/compliance metadata only (no ePHI, per GR6).
- **Evidence:** The report file itself + repository listing showing retention.

---

## Regression / ongoing validation

- Re-run **Gate 1** (Discovery) periodically to catch drift (deleted/unassigned policy, Defender connector failure, CA gate disabled).
- Re-run **Gate 2/4** (Validation) on the recurring cadence; investigate any new FAIL.
- Re-run **Gate 5** each period to confirm exposure stays controlled; re-run **Gate 3** after any CA change.
- For remediation actions, always run **`HIPAACOMP-Remediation.ps1`** in default `-WhatIf` mode and review the planned action before `-Apply`.

> A full PASS across Gates 1–6 with stored evidence is the bar for "operational." Re-test after any change to a named object, gated by change control (R12).
