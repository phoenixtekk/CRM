# 3. Implementation Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Follow these steps **in order**. They use two portals: the Azure portal (`https://portal.azure.com`) for the workspace, Microsoft Sentinel, and analytics, and the Entra admin center (`https://entra.microsoft.com`) for the Entra ID diagnostic setting. Intune audit telemetry is routed in through Sentinel's connectors.

> Model: stand up the destination, route each source, set retention, enable baseline analytics, then validate ingestion on a pilot before expanding. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Workspace: `Security Telemetry - Tenant - Workspace`
- Entra ID diagnostic setting: `Audit Telemetry - Entra ID - Pilot`
- Sentinel analytics rules (from templates): `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot`
- RBAC scope: `Microsoft Sentinel Contributor - Workspace - Pilot`

## Step 1 — Confirm the workspace and Sentinel

1. `portal.azure.com` → search `Log Analytics workspaces` → confirm `Security Telemetry - Tenant - Workspace` exists (create it if not; see global requirements G2). Note its region and resource group.
2. `portal.azure.com` → search `Microsoft Sentinel` → confirm the workspace is listed. If not: `Create` → select the workspace → `Add`.

## Step 2 — Route Entra ID logs via Diagnostic settings

1. Go to `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings`.
2. Click `Add diagnostic setting`.
3. `Diagnostic setting name`: `Audit Telemetry - Entra ID - Pilot`.
4. Under `Logs`, select the categories in scope for the pilot: `SignInLogs` and `AuditLogs`. (Leave higher-volume categories such as non-interactive and service-principal sign-ins for the Expand step.)
5. Under `Destination details`, tick `Send to Log Analytics workspace`, then choose the subscription and `Security Telemetry - Tenant - Workspace`.
6. Click `Save`. Data typically begins arriving within about 15 minutes (first events can take longer).

## Step 3 — Enable the Microsoft Entra ID data connector in Sentinel

1. `portal.azure.com` → `Microsoft Sentinel` → select `Security Telemetry - Tenant - Workspace`.
2. `Configuration` → `Data connectors` → search `Microsoft Entra ID` → `Open connector page`.
3. On the connector page, select the same log types you routed in Step 2 (`Sign-in logs`, `Audit logs`) and `Apply Changes` / `Connect`. (The connector and the diagnostic setting are complementary: the diagnostic setting routes the data; the connector registers the source in Sentinel and unlocks the matching analytics rule templates.)

## Step 4 — Route Intune audit telemetry

1. Still in `Microsoft Sentinel` → `Data connectors`, this telemetry arrives with the Entra ID / Microsoft 365 connectors and the Intune audit stream that Entra-integrated device events flow through; confirm the device, compliance, and enrollment audit events are present in the workspace.
2. Verify in `Logs`: run a query against the device/compliance/audit tables (for example check `AuditLogs` for Intune-originated entries and any device-management table available in your tenant) and confirm rows are returning.
3. If a dedicated Intune/endpoint connector solution is offered in `Content hub` for your tenant, install it from there to add its tables and rule templates.

## Step 5 — Set retention

1. `portal.azure.com` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Settings` → `Usage and estimated costs` → `Data Retention` for the workspace default.
2. For per-table control, open `Tables`, select a table (for example `SigninLogs`), and set its interactive retention and any long-term/archive period to the value your retention decision specifies (Requirement 2.5).

## Step 6 — Enable baseline analytics rules

1. `Microsoft Sentinel` → (workspace) → `Configuration` → `Analytics` → `Rule templates`.
2. Filter by the `Microsoft Entra ID` data source. Select a sign-in baseline template (for example a rule for multiple failed sign-ins / sign-in from a risky source) → `Create rule`. Name it `Baseline - Entra Sign-in - Pilot`, accept the default logic for the pilot, set severity, `Next` through to `Create`.
3. Repeat for a directory-audit template (for example privileged role assignment changes) → name it `Baseline - Entra Audit - Pilot` → `Create`.
4. Confirm both appear under `Analytics` → `Active rules` as `Enabled`.

## Step 7 — Scope RBAC

1. `portal.azure.com` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Access control (IAM)` → `Add role assignment`.
2. Assign `Microsoft Sentinel Contributor` (manage Sentinel) or `Microsoft Sentinel Reader` (read-only analysts) to the appropriate group; record the assignment as `Microsoft Sentinel Contributor - Workspace - Pilot`.
3. The helper script `SENTLOG-Set-WorkspaceScopeTargeting.ps1` reports current assignments and can apply the scoped role.

## Step 8 — Validate the pilot (the gate)

1. Run `SENTLOG-Validation.ps1` → confirms the connector is connected and the pilot tables (`SigninLogs`, `AuditLogs`) are receiving data.
2. Run `SENTLOG-Report.ps1` → confirms log coverage and the retention set per table, and reports ingestion volume against the estimate.
3. In `Microsoft Sentinel` → `Analytics` → `Active rules`, confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are enabled and have run. Complete the Testing Guide.
4. Pilot gate: do not proceed until data is confirmed arriving and at least one baseline rule is live.

## Step 9 — Expand

1. Once the gate passes, edit `Audit Telemetry - Entra ID - Pilot` (or create `Audit Telemetry - Entra ID - Production`) to add the higher-volume categories you deferred (non-interactive, service-principal, managed-identity sign-ins) as budget allows.
2. Enable additional baseline analytics rules from the templates, renaming to the `... - Production` stage.
3. Re-run `SENTLOG-Report.ps1` each cycle to track coverage, retention, and ingestion volume/cost.

---

### Order of operations

`Workspace + Sentinel -> Entra ID diagnostic setting -> Entra ID connector -> Intune audit telemetry -> retention -> baseline analytics -> RBAC -> validate ingestion (gate) -> expand`
