# 3. Implementation Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Follow these steps **in order**. They use three sovereign portals: the **Azure Government portal** (`https://portal.azure.us`) for the workspace, Microsoft Sentinel, and analytics; the **Entra admin center for Gov** (`https://entra.microsoft.us`) for the Entra ID diagnostic setting; and the **Intune admin center for Gov** (`https://intune.microsoft.us`) for the Intune diagnostic setting.

> **GCC High caveat — read first.** Every portal below is the `.us` sovereign portal, not `.com`. If you land on a `.com` portal you are in the wrong cloud and the steps will not find your Gov tenant. Sign-in is `login.microsoftonline.us`. All scripts connect with `-Environment USGov` (Graph) / `-Environment AzureUSGovernment` (Az). Do **not** rely on `Repositories`/CI-CD or the `SIEM migration experience` to deploy content here — neither is available in Azure Government; install from **Content hub** and create rules from templates directly.

> Model: stand up the destination, route each source, set retention, enable baseline analytics, then validate ingestion on a pilot before expanding. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Workspace: `Security Telemetry - Tenant - Workspace`
- Entra ID diagnostic setting: `Audit Telemetry - Entra ID - Pilot`
- Intune diagnostic setting: `Audit Telemetry - Intune - Pilot`
- Sentinel analytics rules (from templates): `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot`
- RBAC scope: `Microsoft Sentinel Contributor - Workspace - Pilot`

## Step 1 — Confirm the workspace and Sentinel (Azure Government)

1. `portal.azure.us` → search `Log Analytics workspaces` → confirm `Security Telemetry - Tenant - Workspace` exists (create it if not; see global requirements G2). Confirm its **region is an Azure Government region** and note its resource group.
2. `portal.azure.us` → search `Microsoft Sentinel` → confirm the workspace is listed. If not: `Create` → select the workspace → `Add`.
3. Caveat: confirm the URL stays on `portal.azure.us` throughout — a redirect to `.com` means you authenticated against Commercial.

## Step 2 — Route Entra ID logs via Diagnostic settings (entra.microsoft.us)

1. Go to `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings`.
2. Click `Add diagnostic setting`.
3. `Diagnostic setting name`: `Audit Telemetry - Entra ID - Pilot`.
4. Under `Logs`, select the categories in scope for the pilot: `SignInLogs` and `AuditLogs`. (Leave higher-volume categories such as non-interactive and service-principal sign-ins for the Expand step.)
   - Caveat: in Azure Government the Entra ID Sentinel connector supports **sign-in logs and audit logs**; confirm any additional category you select is actually exposed by your Gov Entra SKU before you rely on it.
5. Under `Destination details`, tick `Send to Log Analytics workspace`, then choose the **Azure Government** subscription and `Security Telemetry - Tenant - Workspace`.
6. Click `Save`. Data typically begins arriving within about 15 minutes (first events can take longer).

## Step 3 — Enable the Microsoft Entra ID data connector in Sentinel

1. `portal.azure.us` → `Microsoft Sentinel` → select `Security Telemetry - Tenant - Workspace`.
2. `Configuration` → `Data connectors` → search `Microsoft Entra ID` → `Open connector page`. If the connector is not present, install the **Microsoft Entra ID** solution from `Content hub` first (Content hub is GA in Azure Government).
3. On the connector page, select the same log types you routed in Step 2 (`Sign-in logs`, `Audit logs`) and `Apply Changes` / `Connect`. (The connector and the diagnostic setting are complementary: the diagnostic setting routes the data; the connector registers the source in Sentinel and unlocks the matching analytics rule templates.)

## Step 4 — Route Intune audit telemetry (intune.microsoft.us)

1. Go to `intune.microsoft.us` → `Reports` → `Diagnostics settings` → `Add diagnostic setting` (turn the feature on the first time).
2. `Diagnostic setting name`: `Audit Telemetry - Intune - Pilot`.
3. Under `Logs`, select `AuditLogs` (and `OperationalLogs` if you want enrollment success/failure). These land in the workspace as `IntuneAuditLogs` and `IntuneOperationalLogs`.
   - Caveat: routing Intune logs requires the **Intune Service Administrator** Entra role plus **Log Analytics Contributor** on the workspace (Requirement 2.3). `DeviceComplianceOrg` / `IntuneDevices` exports can take up to 48 hours to appear (audit/operational logs arrive within ~30 minutes); expect the export pipeline to occasionally duplicate data — downstream queries should tolerate duplicates.
4. Under `Destination details`, tick `Send to Log Analytics workspace`, choose the Azure Government subscription and `Security Telemetry - Tenant - Workspace`, then `Save`.
5. Verify in `Logs` (in Sentinel): run `IntuneAuditLogs | where TimeGenerated > ago(1h) | take 10` and confirm rows return.

## Step 5 — Set retention

1. `portal.azure.us` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Settings` → `Usage and estimated costs` → `Data Retention` for the workspace default.
2. For per-table control, open `Tables`, select a table (for example `SigninLogs` or `IntuneAuditLogs`), and set its interactive retention and any long-term/archive period to the value your retention decision specifies (Requirement 2.5) — usually the value your compliance mandate (CMMC / DFARS / FedRAMP) requires.

## Step 6 — Enable baseline analytics rules

1. `Microsoft Sentinel` → (workspace) → `Configuration` → `Analytics` → `Rule templates`.
2. Filter by the `Microsoft Entra ID` data source. Select a sign-in baseline template (for example a rule for multiple failed sign-ins / sign-in from a risky source) → `Create rule`. Name it `Baseline - Entra Sign-in - Pilot`, accept the default logic for the pilot, set severity, `Next` through to `Create`.
3. Repeat for a directory-audit template (for example privileged role assignment changes) → name it `Baseline - Entra Audit - Pilot` → `Create`.
4. Confirm both appear under `Analytics` → `Active rules` as `Enabled`.
   - Caveat: scheduled and Microsoft rules, NRT rules, and Fusion are GA in Azure Government, so baseline analytics work as expected. `SOC optimizations` and `Summary rules` are **not** available in Gov — do not build the pipeline around them.

## Step 7 — Scope RBAC

1. `portal.azure.us` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Access control (IAM)` → `Add role assignment`.
2. Assign `Microsoft Sentinel Contributor` (manage Sentinel) or `Microsoft Sentinel Reader` (read-only analysts) to the appropriate group; record the assignment as `Microsoft Sentinel Contributor - Workspace - Pilot`.
3. The helper script `SENTLOGG-Set-ScopeTargeting.ps1` (connecting with `-Environment AzureUSGovernment`) reports current assignments and can apply the scoped role.

## Step 8 — Validate the pilot (the gate)

1. Run `SENTLOGG-Validation.ps1` → confirms the connector is connected and the pilot tables (`SigninLogs`, `AuditLogs`, `IntuneAuditLogs`) are receiving data.
2. Run `SENTLOGG-Report.ps1` → confirms log coverage and the retention set per table, and reports ingestion volume against the estimate.
3. In `Microsoft Sentinel` → `Analytics` → `Active rules`, confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are enabled and have run. Complete the Testing Guide.
4. Pilot gate: do not proceed until data is confirmed arriving and at least one baseline rule is live.

## Step 9 — Expand

1. Once the gate passes, edit `Audit Telemetry - Entra ID - Pilot` (or create `Audit Telemetry - Entra ID - Production`) to add the higher-volume categories you deferred (non-interactive, service-principal, managed-identity sign-ins) as budget allows — confirming each is exposed by your Gov SKU.
2. Enable additional baseline analytics rules from the templates, renaming to the `... - Production` stage.
3. Re-run `SENTLOGG-Report.ps1` each cycle to track coverage, retention, and ingestion volume/cost.

---

### Order of operations

`Workspace + Sentinel (Azure Gov) -> Entra ID diagnostic setting (entra.microsoft.us) -> Entra ID connector -> Intune diagnostic setting (intune.microsoft.us) -> retention -> baseline analytics -> RBAC -> validate ingestion (gate) -> expand`
