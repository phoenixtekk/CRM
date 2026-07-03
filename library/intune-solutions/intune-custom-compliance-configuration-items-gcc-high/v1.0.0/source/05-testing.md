# Testing & Validation — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

Run this playbook against the **pilot** group before expanding. Every check uses the **GCC High (`*.us`)** portals and **US Gov Graph** (`-Environment USGov`). Each test has an explicit **pass/fail gate**. Do not proceed to Expand until all gates pass.

> **Golden rule for GCC High:** a "no result" is **not** the same as "compliant." On a sovereign tenant the most common cause of a device showing no custom-compliance status is a **TLS-breaking proxy on `*.manage.microsoft.us`** (SSL inspection is unsupported there). Treat missing results as a failure to investigate, not a pass.

---

## T1. Connection targets the sovereign cloud
**Do:** `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementConfiguration.Read.All"`, then `(Get-MgContext).Environment`.
**Pass:** returns **`USGov`**.
**Fail:** returns `Global` (you connected to commercial `graph.microsoft.com`) — reconnect with `-Environment USGov`.
**Reference:** [Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph).

## T2. Discovery script emits valid single-line JSON
**Do:** Run the discovery script locally on a representative Windows device.
**Pass:** Output is **one compressed JSON line** (from `ConvertTo-Json -Compress`), e.g. `{"BiosVersion":"1.24","TPMChipPresent":true}`; script finishes in **≤ 10 minutes**; script file **≤ 1 MB**; output **≤ 1 MB**.
**Fail:** Multi-line output, missing keys, or over any limit — Intune won't grade it correctly.
**Reference:** [Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script).

## T3. JSON rules align with discovered keys (case-sensitive)
**Do:** Run **`CUSTCOMPG-Validation.ps1`** against the discovery output and `CUSTCOMPG-Rules.json`.
**Pass:** Every rule `SettingName` matches a returned key **exactly** (case-sensitive), and each `DataType` matches the value's type (`Boolean`/`String`/`Int64`/`Version`).
**Fail:** Any mismatch — fix the JSON or the script so keys and types line up. A case difference alone will cause a silent grading failure.

## T4. Objects exist in the GCC High tenant
**Do:** Run **`CUSTCOMPG-Discovery.ps1`** (`-Environment USGov`).
**Pass:** It lists the script `CUSTCOMPG-Discovery-Win`, the policy `CUSTCOMPG-Compliance-Baseline` (with a custom-compliance setting), and the pilot group `CUSTCOMPG-Pilot-Devices`.
**Fail:** Missing objects — revisit Configure (Phase 1). (Remember: Graph Explorer can't be used against `graph.microsoft.us`, so this script *is* your API recon.)

## T5. Compliant device grades as Compliant
**Do:** On a known-good pilot device, **Sync**, wait, then check `https://intune.microsoft.us/` → **Devices → Compliance → `CUSTCOMPG-Compliance-Baseline` → Device status**, and cross-check with **`CUSTCOMPG-Report.ps1`**.
**Pass:** Device shows **Compliant** for the custom setting.
**Fail:** Shows "not evaluated" / no result → suspect TLS inspection on `*.manage.microsoft.us` (see T8) or an unenrolled/unlicensed device.

## T6. Deliberately non-compliant device grades as Not compliant
**Do:** On a second pilot device, force the checked condition to fail (e.g., set the value below the required baseline). **Sync**, wait, re-check.
**Pass:** Device shows **Not compliant** for the expected `SettingName`, and the **RemediationStrings** Title/Description appear in Company Portal at `https://portal.manage.microsoft.us/`.
**Fail:** Still compliant → operator/DataType mismatch in the JSON, or the script isn't returning that key.

## T7. Noncompliance actions and grace period behave as configured
**Do:** Confirm the grace period and the "Mark device noncompliant" / notification action fire on the failing device per your policy settings.
**Pass:** Action and timing match what you configured in Step 1.5.
**Fail:** Re-check **Actions for noncompliance** on the policy.

## T8. Proxy does not break TLS on the sovereign device endpoints
**Do:** From a pilot device, reach `https://portal.manage.microsoft.us/` and `https://login.microsoftonline.us`; confirm the proxy is **not** re-signing certificates for `*.manage.microsoft.us`.
**Pass:** Endpoints reachable; certificate chain for `*.manage.microsoft.us` is Microsoft's (not your proxy's).
**Fail:** Proxy is intercepting `*.manage.microsoft.us` → exempt it from SSL inspection (Requirement R7). This is the leading GCC High cause of missing compliance results.
**Reference:** [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints).

## T9. Scope-targeting preview is accurate before any write
**Do:** Run **`CUSTCOMPG-Set-ScopeTargeting.ps1`** in its default **`-WhatIf`** mode.
**Pass:** The preview lists exactly the devices you intend to add/remove from the target group; **no changes are made**.
**Fail:** Preview shows unexpected devices → refine the input before ever running with `-WhatIf:$false`.

---

**Overall validation gate:** T1–T9 all pass on the pilot group, with at least one true Compliant and one true Not-compliant result and **zero** "no result" devices. Only then move to **Expand**.
