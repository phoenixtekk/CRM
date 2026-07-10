# 2. Requirements Guide — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

Verify **every** requirement before you deploy. Each entry: **Description · Why required · How to verify
· How to implement if missing.** The category-wide prerequisites (a target cloud/estate with sufficient
rights, a telemetry destination, an at-scale rollout channel, IaC tooling + source control, secrets
management, an ingestion-cost plan, notification targets, and a pilot scope) are defined once in
`global-requirements-observability.md` — confirm those first. The items below are **specific to building
the Azure Monitor foundation**.

## 2.1 Monitoring-capable rights at the target scope
**Description:** The deploying identity holds **Contributor** (or **Monitoring Contributor** + **Log
Analytics Contributor**) at the target **subscription** (or management group), and can **assign Azure
Policy** at that scope.
**Why required:** You must create a workspace, create diagnostic settings, deploy alert rules and action
groups, and assign a `DeployIfNotExists` policy — all of which need resource-write plus policy-assign
rights.
**How to verify:** `az account show` returns the target subscription; **`OBSAZMON-Discovery.ps1`**
reports your effective roles and confirms you can list Monitor resources and policy assignments.
**How to implement if missing:** Have an Owner/User Access Administrator grant Contributor +
Monitoring Contributor at the subscription, and Resource Policy Contributor to assign policy.

## 2.2 A Log Analytics workspace design decision (retention, region, tier)
**Description:** Decisions for the workspace: **region** (co-locate with the bulk of resources /
data-residency needs), **retention** (interactive + optional long-term/archive), whether to use a
**daily cap**, and which **table tiers** (Analytics / Basic / Auxiliary) apply.
**Why required:** These are the cost and access levers; they are encoded into the Bicep and cannot be
defaulted sensibly without your inputs.
**How to verify:** A documented decision exists (region, retention days, cap, tiers) that maps to the
Bicep parameters. *Verify current tier availability and pricing in your tenant.*
**How to implement if missing:** Decide retention and tiers against your cost/compliance posture (this
is the customer's decision), then set them as `OBSAZMON-Foundation.bicep` parameters.

## 2.3 Azure Monitor Agent (AMA) + Data Collection Rule readiness (for VM/container insights)
**Description:** The **Azure Monitor Agent** extension deployable to the pilot VMs, and rights to create
**Data Collection Rules** and associations; for AKS, rights to enable the **container insights** add-on.
**Why required:** VM and container insights collect guest/container telemetry via AMA + DCRs (the
retired Log Analytics/MMA agent is not used). *Verify AMA availability for your OS/region.*
**How to verify:** `Get-AzVMExtension` can be queried on a pilot VM; you can create a DCR in the target
region. **`OBSAZMON-Discovery.ps1`** lists VMs and any existing agents/extensions.
**How to implement if missing:** Ensure the pilot VMs are running and reachable, and that AMA is
supported for their OS; grant Monitoring Contributor so DCRs and associations can be created.

## 2.4 Azure Policy managed-identity permissions for DeployIfNotExists
**Description:** The diagnostics policy assignment uses a **system-assigned managed identity** that must
be granted the roles needed to create diagnostic settings — typically **Monitoring Contributor** and
**Log Analytics Contributor** at the assignment scope.
**Why required:** `DeployIfNotExists` remediation runs *as* the assignment's managed identity; without
those roles, remediation fails to create the diagnostic settings.
**How to verify:** After assigning the policy, the assignment's identity shows the expected role
assignments at scope; a remediation task succeeds on one resource.
**How to implement if missing:** Assign the policy with **`--location`** (so an identity is created) and
let Azure grant the declared roles, or grant them manually to the assignment's identity.

## 2.5 Notification channel details (action group)
**Description:** The concrete targets for the action group `OBSAZMON-AG-Platform-Ops`: **email
address(es)**, a **Teams/Slack incoming webhook URL**, and/or a **PagerDuty integration key**, plus who
should receive what.
**Why required:** An alert is only useful if it reaches a responder; the action group needs real targets.
**How to verify:** The webhook/integration is created in Teams/Slack/PagerDuty and a test message
succeeds; the email distribution list exists.
**How to implement if missing:** Create the channel(s) and capture the webhook URL / integration key
into **secure input / Key Vault** (never in code), then wire them into the action group.

## 2.6 A defined pilot resource group
**Description:** A **pilot resource group** (`rg-obsazmon-pilot` or an existing non-critical RG) whose
resources are onboarded to diagnostics + alerts first.
**Why required:** Diagnostics coverage, alert thresholds, and insight collection are validated on a
pilot before the policy is remediated estate-wide.
**How to verify:** The pilot RG exists and contains representative resources (a VM, a PaaS resource,
ideally an AKS cluster). **`OBSAZMON-Discovery.ps1`** enumerates it.
**How to implement if missing:** Nominate/create a pilot RG with representative resources before scaling.
*Alert thresholds and on-call routing are the service owner's decision; this guide provides the wiring.*

## 2.7 Az PowerShell + Bicep tooling on the operator workstation
**Description:** **Az PowerShell** (Az.Accounts, Az.Monitor, Az.OperationalInsights, Az.Resources), the
**Azure CLI** with **Bicep**, and Git.
**Why required:** The read-only helper scripts and the KQL pack use Az; the foundation deploys from
**Bicep** (`az deployment ... --template-file OBSAZMON-Foundation.bicep`).
**How to verify:** `Get-Module -ListAvailable Az.Monitor` returns a version; `az bicep version` works;
`Connect-AzAccount` succeeds.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`; install the Azure CLI and run
`az bicep install`; sign in with `Connect-AzAccount` / `az login`.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-observability.md`)
- [ ] Contributor + Monitoring/Log Analytics Contributor + policy-assign rights — `OBSAZMON-Discovery.ps1`
- [ ] Workspace design decided (region, retention, daily cap, table tiers) — *verify tiers/pricing*
- [ ] AMA + DCR readiness for pilot VMs / container insights for AKS — *verify AMA support*
- [ ] Policy managed-identity roles for `DeployIfNotExists` planned
- [ ] Action-group targets (email / Teams-Slack webhook / PagerDuty key) captured to a secret store
- [ ] Pilot resource group nominated with representative resources
- [ ] Az PowerShell + Azure CLI + Bicep installed and signed in
