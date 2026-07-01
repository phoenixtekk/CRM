# 5. Testing Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Run after the pilot is configured (Implementation Step 8) and after each expansion.

## Test 1 — Diagnostic setting present

**Do:** `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings` → confirm `Audit Telemetry - Entra ID - Pilot` exists and lists `SignInLogs` and `AuditLogs` to `Security Telemetry - Tenant - Workspace`.
**Expected:** The named setting is present with the in-scope categories routed to the correct workspace.

## Test 2 — Connector connected

**Do:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Data connectors` → `Microsoft Entra ID`, or run `SENTLOG-Validation.ps1`.
**Expected:** Connector status is `Connected`; the data-received indicator is recent.

## Test 3 — Data is arriving (sign-in)

**Do:** `Microsoft Sentinel` → `Logs` → run `SigninLogs | where TimeGenerated > ago(1h) | take 10`.
**Expected:** Rows return — interactive sign-ins are landing in the workspace.

## Test 4 — Data is arriving (directory audit)

**Do:** `Logs` → run `AuditLogs | where TimeGenerated > ago(24h) | take 10`.
**Expected:** Rows return — directory changes (including Intune-originated audit entries) are landing.

## Test 5 — Retention set

**Do:** `Log Analytics workspaces` → workspace → `Tables` → check `SigninLogs` and `AuditLogs`, or run `SENTLOG-Report.ps1`.
**Expected:** Interactive (and any long-term) retention matches the retention decision in Requirement 2.5.

## Test 6 — Baseline analytics rules live

**Do:** `Microsoft Sentinel` → `Analytics` → `Active rules` → confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are `Enabled`.
**Expected:** Both rules are enabled and show a recent run; a deliberate test event (for example a failed sign-in pattern) produces an alert/incident.

## Test 7 — Coverage and volume report

**Do:** Run `SENTLOG-Report.ps1`.
**Expected:** A clear table-by-table view of which categories have data, their retention, and ingestion volume against the estimate.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass: data is confirmed arriving in `SigninLogs` and `AuditLogs`, retention is set, and at least one baseline rule is live |
| Expand pass | Tests 3, 4, 7 pass for the added categories, and volume/cost is within budget, before enabling more rules or sources |
