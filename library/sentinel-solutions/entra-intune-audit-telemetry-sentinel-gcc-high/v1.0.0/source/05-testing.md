# 5. Testing Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Run after the pilot is configured (Implementation Step 8) and after each expansion. **Every portal below is the `.us` sovereign portal.**

## Test 0 — You are in the sovereign cloud

**Do:** Confirm the portal URL bar reads `portal.azure.us` / `entra.microsoft.us` / `intune.microsoft.us` (not `.com`), and that scripts connected with `-Environment AzureUSGovernment` (Az) / `-Environment USGov` (Graph).
**Expected:** All surfaces resolve on `.us`. A `.com` redirect or a Graph "AADSTS / redirect" error means you authenticated against Commercial — fix before continuing.

## Test 1 — Entra ID diagnostic setting present

**Do:** `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings` → confirm `Audit Telemetry - Entra ID - Pilot` exists and lists `SignInLogs` and `AuditLogs` to `Security Telemetry - Tenant - Workspace`.
**Expected:** The named setting is present with the in-scope categories routed to the correct Azure Government workspace.

## Test 2 — Intune diagnostic setting present

**Do:** `intune.microsoft.us` → `Reports` → `Diagnostics settings` → confirm `Audit Telemetry - Intune - Pilot` routes `AuditLogs` (and optionally `OperationalLogs`) to the workspace.
**Expected:** The named setting is present and targets the correct workspace.

## Test 3 — Connector connected

**Do:** `portal.azure.us` → `Microsoft Sentinel` → (workspace) → `Data connectors` → `Microsoft Entra ID`, or run `SENTLOGG-Validation.ps1`.
**Expected:** Connector status is `Connected`; the data-received indicator is recent.

## Test 4 — Data is arriving (sign-in)

**Do:** `Microsoft Sentinel` → `Logs` → run `SigninLogs | where TimeGenerated > ago(1h) | take 10`.
**Expected:** Rows return — interactive sign-ins are landing in the workspace.

## Test 5 — Data is arriving (directory + Intune audit)

**Do:** `Logs` → run `AuditLogs | where TimeGenerated > ago(24h) | take 10` and `IntuneAuditLogs | where TimeGenerated > ago(24h) | take 10`.
**Expected:** Rows return from both — directory changes and Intune audit events are landing. (Intune `DeviceComplianceOrg` / `IntuneDevices` can take up to 48h; audit/operational logs arrive within ~30 min.)

## Test 6 — Retention set

**Do:** `Log Analytics workspaces` → workspace → `Tables` → check `SigninLogs`, `AuditLogs`, `IntuneAuditLogs`, or run `SENTLOGG-Report.ps1`.
**Expected:** Interactive (and any long-term) retention matches the retention decision in Requirement 2.5 / the compliance mandate.

## Test 7 — Baseline analytics rules live

**Do:** `Microsoft Sentinel` → `Analytics` → `Active rules` → confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are `Enabled`.
**Expected:** Both rules are enabled and show a recent run; a deliberate test event (for example a failed sign-in pattern) produces an alert/incident.

## Test 8 — Coverage and volume report

**Do:** Run `SENTLOGG-Report.ps1`.
**Expected:** A clear table-by-table view of which categories have data, their retention, and ingestion volume against the estimate.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Sovereign-cloud check | Test 0 passes: all surfaces on `.us`, scripts on US Gov endpoints |
| Pilot pass | Tests 1-7 pass: data is confirmed arriving in `SigninLogs`, `AuditLogs`, and `IntuneAuditLogs`, retention is set, and at least one baseline rule is live |
| Expand pass | Tests 4, 5, 8 pass for the added categories, and volume/cost is within budget, before enabling more rules or sources |
