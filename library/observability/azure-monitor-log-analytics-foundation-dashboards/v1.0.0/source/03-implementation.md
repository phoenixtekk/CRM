# 3. Implementation Guide — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

Follow these steps **in order**. Work in the **Azure portal** (verification + workbooks/dashboards), the
**Azure CLI / Az PowerShell** (deployment + scripts), and your **Git repo** (the Bicep + KQL). Names in
`code` are the exact objects to create — keep them consistent so the Bicep, policy, alerts, scripts, and
dashboards all refer to the same objects. Feature/tier/pricing points are flagged **"verify."**

**Object naming convention:** `<Purpose> – <Scope> – <Stage>` (mapped to Azure resource naming). The
objects you build:

| Object | Name |
|--------|------|
| Monitoring resource group | `rg-obsazmon-monitor` |
| Pilot resource group | `rg-obsazmon-pilot` |
| Log Analytics workspace | `log-obsazmon-platform` |
| Action group | `OBSAZMON-AG-Platform-Ops` |
| Diagnostics policy assignment | `OBSAZMON-Policy-Diagnostics-Subscription` |
| Data Collection Rule (VM insights) | `dcr-obsazmon-vminsights` |
| Metric alert (VM CPU) | `OBSAZMON-Alert-VMCPUHigh-Pilot` |
| Log alert (heartbeat missing) | `OBSAZMON-Alert-HeartbeatMissing-Pilot` |
| Ops workbook | `OBSAZMON-Workbook-OpsOverview` |
| Executive dashboard | `OBSAZMON-Dashboard-Exec` |

> **Model:** Assess → Configure → **Pilot against `rg-obsazmon-pilot` first** → Validate → Expand
> (remediate policy + roll out alerts estate-wide). The diagnostics policy is staged **DoNotEnforce /
> audit first**; nothing disruptive is remediated fleet-wide before the pilot passes. Rollback guidance
> is at the end.

## Step 1 — Assess: baseline the estate and existing telemetry
1. Run **`OBSAZMON-Discovery.ps1`** — it inventories subscriptions, resources by type, any **existing
   Log Analytics workspaces**, current **diagnostic settings** coverage, existing **action groups** and
   **alert rules**, and your effective rights.
2. Record the **coverage gap** (resources with no diagnostic setting) — this is what the policy will
   close.
3. Confirm the requirements checklist (§2), especially **rights**, the **workspace design decision**
   (region/retention/tiers), and the **notification channel** details.

## Step 2 — Configure: deploy the workspace foundation (Bicep)
1. In the portal, create the two resource groups if absent: **Home → Resource groups → Create** →
   `rg-obsazmon-monitor` and `rg-obsazmon-pilot` in your chosen region.
2. Deploy the foundation with the provided **`OBSAZMON-Foundation.bicep`**, which creates the workspace,
   the action group, and the two pilot alert rules in one reviewed deployment:
   ```
   az deployment group create \
     --resource-group rg-obsazmon-monitor \
     --template-file OBSAZMON-Foundation.bicep \
     --parameters workspaceName=log-obsazmon-platform \
                  retentionDays=90 \
                  opsEmail='ops@contoso.com' \
                  teamsWebhookUri='<from-secure-input>' \
     --what-if           # REVIEW the what-if first
   ```
   Re-run without `--what-if` to apply. *Set `retentionDays`, daily cap, and table tiers from your §2.2
   decision — verify current tier availability/pricing.*
3. Confirm in **Monitor → Logs**: the workspace `log-obsazmon-platform` exists; set **retention** and
   (optionally) a **daily cap** under the workspace's **Usage and estimated costs**.
4. Set workspace **access**: assign **Log Analytics Reader** to the ops group and **Log Analytics
   Contributor** to the platform-admin group (workspace **Access control (IAM)**).

## Step 3 — Configure: stage the diagnostics policy (audit / DoNotEnforce first)
1. In **Policy → Definitions**, find the built-in initiative for routing resource logs to Log Analytics
   (e.g. the "Deploy Diagnostic Settings … to Log Analytics workspace" category — *verify the current
   built-in name/ID*), or use the per-resource-type built-ins.
2. **Assign** it at the **subscription** (or management-group) scope as
   `OBSAZMON-Policy-Diagnostics-Subscription`:
   - **Parameters:** target workspace = `log-obsazmon-platform`.
   - **Enforcement mode:** set to **Disabled (DoNotEnforce)** for now so it **reports** coverage without
     auto-creating settings yet.
   - **Remediation:** allow the assignment to **create a system-assigned managed identity** and grant it
     **Monitoring Contributor** + **Log Analytics Contributor** at scope (§2.4).
3. Give it time to evaluate, then run **`OBSAZMON-Report.ps1`** to see the **compliance / coverage** —
   which resources *would* get a diagnostic setting. Do **not** remediate estate-wide yet.

## Step 4 — Pilot: onboard the pilot resource group
1. **Diagnostics on the pilot:** create a **remediation task** for
   `OBSAZMON-Policy-Diagnostics-Subscription` **scoped to `rg-obsazmon-pilot` only** (Policy →
   Remediation → New), or temporarily flip enforcement to **Enabled** limited to the pilot RG. This
   creates the diagnostic settings on pilot resources → telemetry flows to `log-obsazmon-platform`.
2. **VM insights:** create the DCR `dcr-obsazmon-vminsights` (Monitor → **Data Collection Rules** →
   Create, or via the VM insights onboarding) pointing at `log-obsazmon-platform`, and **associate** the
   pilot VMs — this installs/uses the **Azure Monitor Agent**. For AKS, enable the **container insights**
   add-on on the pilot cluster.
3. **Confirm telemetry lands:** in **Monitor → Logs**, run from `OBSAZMON-Queries.kql`:
   ```kql
   Heartbeat | summarize LastBeat = max(TimeGenerated) by Computer | order by LastBeat desc
   ```
   Pilot VMs should appear with a recent heartbeat; `AzureDiagnostics` / resource-specific tables should
   show pilot PaaS logs.

## Step 5 — Pilot: wire alerts + action group
1. Confirm the action group `OBSAZMON-AG-Platform-Ops` (created by the Bicep) has the right
   **email**, **Teams/Slack webhook**, and optional **PagerDuty** targets; send a **test notification**
   (action group → **Test**).
2. Confirm the two pilot alert rules (created by the Bicep), **scoped to `rg-obsazmon-pilot`**:
   - **`OBSAZMON-Alert-VMCPUHigh-Pilot`** — a **metric alert** on VM `Percentage CPU` over your
     threshold for N minutes → `OBSAZMON-AG-Platform-Ops`.
   - **`OBSAZMON-Alert-HeartbeatMissing-Pilot`** — a **log (scheduled query) alert** on the `Heartbeat`
     table detecting a VM that has stopped reporting → `OBSAZMON-AG-Platform-Ops`.
   *Thresholds/evaluation windows are your operational decision — set them to your SLOs.*
3. **Prove an alert fires:** stress a pilot VM's CPU (or lower the threshold briefly) and confirm the
   alert fires and the notification arrives with context. Reset the threshold afterward.

## Step 6 — Validate the pilot (the gates)
Run **`OBSAZMON-Validate.ps1`** and **`OBSAZMON-Report.ps1`** and confirm the four gates in §5 pass:
telemetry lands, diagnostics cover the pilot, an alert fires and notifies, and the workbook/dashboard
render. **Pass** = all gates green → proceed to Expand. **Fail** = fix before scaling (see §6).

## Step 7 — Build the workbooks and dashboards
1. **Ops workbook:** Monitor → **Workbooks → New**, build `OBSAZMON-Workbook-OpsOverview` using queries
   from `OBSAZMON-Queries.kql` (heartbeat/health, top resources by ingestion, alert summary, VM
   performance). **Save** it to `rg-obsazmon-monitor`.
2. **Executive dashboard:** create an Azure **shared dashboard** `OBSAZMON-Dashboard-Exec`, pin the
   key workbook tiles and a couple of metric charts, and **share** it (RBAC) with leadership.
3. Confirm both render with real pilot data.

## Step 8 — Expand: remediate diagnostics + roll out alerts estate-wide
1. **Promote the diagnostics policy:** once the pilot is clean, flip
   `OBSAZMON-Policy-Diagnostics-Subscription` enforcement to **Enabled** and run an **estate-wide
   remediation task** — in **waves** (by resource group / resource type), re-running
   **`OBSAZMON-Report.ps1`** after each wave to confirm coverage climbs and ingestion stays within your
   cost plan.
2. **Expand alerts:** widen the alert-rule scope from `rg-obsazmon-pilot` to broader scopes (or clone
   the rules per critical service), keeping the same action group and naming pattern. Add
   resource-health and service-specific alerts as needed.
3. **Enable insights** on the remaining VMs/clusters by associating them to `dcr-obsazmon-vminsights`
   (or per-environment DCRs).
4. Re-run **`OBSAZMON-Report.ps1`** to capture the final **coverage + estimated ingestion** snapshot.

> **Rollback / safety (any step):** Everything is reversible. To stop auto-provisioning, set
> `OBSAZMON-Policy-Diagnostics-Subscription` back to **DoNotEnforce** (existing settings remain, none
> new are created). To silence noise, **disable** an alert rule or the action group rather than deleting
> it. To cut cost fast, lower **retention** or set a **daily cap** on the workspace. Removing a
> diagnostic setting stops collection for that resource without affecting the resource itself. Do the
> estate-wide remediation **in waves under change control** — never remediate the whole estate in one
> shot (ingestion cost + noise spike).

---
### Order of operations
`Assess (Discovery) → deploy workspace + action group + pilot alerts (Bicep, what-if first) → stage
diagnostics policy in DoNotEnforce → pilot: remediate pilot RG + VM/container insights + prove alerts →
validate the 4 gates → build workbook + dashboard → expand: enforce policy + remediate estate-wide in
waves + widen alerts`
