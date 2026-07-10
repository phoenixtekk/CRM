# 2. Requirements Guide — Datadog Deployment for Hybrid & Cloud Estates

Verify **every** requirement before you deploy. Each entry: **Description · Why required · How to verify
· How to implement if missing.** The category-wide prerequisites (a target cloud/estate with rights, a
telemetry destination i.e. a Datadog org, an at-scale rollout channel, IaC tooling + source control,
secrets management, an ingestion-cost plan, notification targets, and a pilot scope) are defined once in
`global-requirements-observability.md` — confirm those first. The items below are **specific to deploying
Datadog across a hybrid/multicloud estate**.

## 2.1 A Datadog organization on the correct site, with API + APP keys
**Description:** A Datadog **organization** provisioned on the right **site** (e.g. US1/US3/US5/EU/AP —
*verify your org's site*), with a **API key** (agent + provider) and an **Application (APP) key**
(provider), issued to a service/automation identity.
**Why required:** The agent submits data with the API key; the Terraform provider manages resources with
API + APP keys. The site determines the endpoints the agent and provider talk to.
**How to verify:** You can sign in to the Datadog org; the API/APP keys exist under **Organization
Settings → API Keys / Application Keys**; `OBSDDOG-Validate.ps1` confirms provider auth.
**How to implement if missing:** Create the org (Datadog-side), generate an API key and an APP key for
automation, and record the **site**. Store both keys in the **secret store** (§2.4). *Datadog plan/SKU
selection is deferred to Datadog's docs.*

## 2.2 Datadog Terraform provider + version pinned
**Description:** The **`DataDog/datadog`** Terraform provider, **pinned** to a supported version, plus
Terraform CLI, recorded in the repo.
**Why required:** The dashboards/monitors/SLOs/integrations are provider resources; an unpinned provider
upgrade can change plan behavior mid-rollout.
**How to verify:** `terraform version` and the `required_providers` block match; `terraform init`
resolves the provider. *Verify the current supported provider version against the registry/Datadog docs.*
**How to implement if missing:** Pin `datadog` in `main.tf` (example provided, flagged "verify"), commit
`.terraform.lock.hcl`.

## 2.3 Agent rollout channel for hybrid + cloud hosts
**Description:** A way to deploy the agent at scale: a **config-management/IaC channel** (Ansible/Chef,
Intune/Configuration Manager, cloud-init/user-data) for VMs, and **Helm/DaemonSet** for Kubernetes —
plus network egress from hosts to the Datadog **site** endpoints.
**Why required:** Hand-installing the agent per host doesn't scale or stay consistent; the installers
here are the per-host action the rollout channel invokes.
**How to verify:** A pilot host can run `install-datadog-agent.sh` / `Install-DatadogAgent.ps1` and
reach Datadog (agent status = OK); the K8s cluster can pull the Datadog Helm chart.
**How to implement if missing:** Establish the rollout channel and confirm outbound network/proxy access
to the Datadog site before onboarding hosts.

## 2.4 Secret store for API/APP keys and integration credentials
**Description:** A secure store — **Key Vault / AWS Secrets Manager / pipeline secrets** — holding the
Datadog **API key**, **APP key**, the Azure integration **app-registration secret**, and the AWS
**role** details. **Never in code, images, or state committed to the repo.**
**Why required:** These keys grant broad read (and monitoring write); a committed key leaks the estate's
observability and can incur cost/abuse.
**How to verify:** No keys in the repo (secret scanning passes); the installers and Terraform read keys
from env/secret references at runtime.
**How to implement if missing:** Put every key in the secret store; wire the installers and CI to read
them; enable secret scanning; store Terraform **state** in a secured backend (not the repo).

## 2.5 Azure integration prerequisites (if monitoring Azure)
**Description:** An Entra **app registration** (service principal) with the **Monitoring Reader** (and
**Reader**) role at the target subscription(s)/management group, and its client secret in the secret
store.
**Why required:** The Datadog Azure integration authenticates as this app to pull Azure metrics and
inventory.
**How to verify:** The app has Monitoring Reader at scope; `OBSDDOG-Validate.ps1` (or the Datadog Azure
integration status page) shows the subscription connected.
**How to implement if missing:** Create the app registration, assign Monitoring Reader at scope, generate
a client secret (to the secret store), and register it in the `datadog_integration_azure` resource.

## 2.6 AWS integration prerequisites (if monitoring AWS)
**Description:** A cross-account **IAM role** Datadog can assume (Datadog's account as trusted principal
with the standard integration policy), in each target AWS account.
**Why required:** The Datadog AWS integration assumes this role to read CloudWatch metrics, tags, and
inventory.
**How to verify:** The role exists with the correct trust + policy; the Datadog AWS integration status
shows the account connected.
**How to implement if missing:** Create the IAM role/policy per Datadog's AWS integration guidance and
reference it in the `datadog_integration_aws` resource. *Verify the current required policy in Datadog's docs.*

## 2.7 A defined pilot host + cluster and notification targets
**Description:** A **pilot** set — at least one Linux VM, one Windows VM (if applicable), and one
Kubernetes cluster/namespace — plus the concrete **notification handles** (Slack/Teams channel,
PagerDuty service, email) for the pilot monitors.
**Why required:** Agents, integrations, monitor thresholds, and routing are validated on the pilot before
estate-wide rollout.
**How to verify:** The pilot hosts/cluster exist and are reachable; the Slack/PagerDuty integration is
connected in Datadog and a test notification succeeds.
**How to implement if missing:** Nominate the pilot scope and connect the notification integrations in
Datadog. *Thresholds, SLO targets, and on-call routing are the service owner's decisions; the guide wires
them up.*

## 2.8 Terraform + shell/PowerShell tooling on the operator workstation
**Description:** **Terraform CLI**, **Git**, a **bash** shell (for the Linux installer / plan runs), and
**PowerShell** (for the Windows installer and the validate/report helpers).
**Why required:** The stack deploys from Terraform; the helpers and installers are bash/PowerShell.
**How to verify:** `terraform version`, `git --version`, `bash --version`, and `pwsh --version` all work.
**How to implement if missing:** Install Terraform, Git, and PowerShell; ensure a bash environment is
available for the Linux installer.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-observability.md`)
- [ ] Datadog org on the correct **site**; API + APP keys issued to automation — *verify site*
- [ ] `DataDog/datadog` Terraform provider **pinned** — *verify current version*
- [ ] Agent rollout channel ready (config-mgmt/IaC for VMs, Helm/DaemonSet for K8s) + network egress
- [ ] Secret store holds API/APP keys + integration creds; **no keys in code**; state secured
- [ ] Azure integration: app registration + **Monitoring Reader** (if monitoring Azure)
- [ ] AWS integration: cross-account **IAM role** (if monitoring AWS)
- [ ] Pilot host + cluster nominated; Slack/Teams/PagerDuty notification targets connected
- [ ] Terraform + Git + bash + PowerShell installed
