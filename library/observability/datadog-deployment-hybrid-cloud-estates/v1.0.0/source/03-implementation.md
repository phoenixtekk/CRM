# 3. Implementation Guide — Datadog Deployment for Hybrid & Cloud Estates

Follow these steps **in order**. Work in your **Git repo** (Terraform + agent config), a **terminal**
(agent installers + `terraform plan/apply`), the **Datadog console** (verification + connecting
notification integrations), and your **cloud portals** (integration prerequisites). Names in `code` are
the exact objects to create — keep them consistent so the Terraform, monitors, dashboards, and SLOs all
refer to the same objects. Provider/agent versions and any Datadog SKU/pricing points are flagged
**"verify."**

**Object naming convention:** `<Purpose>-<Scope>-<Stage>`. The objects you build:

| Object | Name |
|--------|------|
| Estate-overview dashboard | `OBSDDOG-Dashboard-EstateOverview` |
| SLO (API availability) | `OBSDDOG-SLO-APIAvailability` |
| Monitor — host unreachable | `OBSDDOG-Monitor-HostUnreachable-Pilot` |
| Monitor — CPU high | `OBSDDOG-Monitor-CPUHigh-Pilot` |
| Monitor — K8s pod crashloop | `OBSDDOG-Monitor-K8sPodCrashloop-Pilot` |
| Log pipeline | `OBSDDOG-Pipeline-AppLogs` |
| Azure integration | `datadog_integration_azure` (per subscription) |
| AWS integration | `datadog_integration_aws` (per account) |
| Base agent tags | `env:<env>`, `service:<svc>`, `team:<team>` |

> **Model:** Assess → Configure → **Pilot on one host + one cluster first** → Validate → Expand
> (estate-wide in waves). Every change is a reviewed **`terraform plan` before `apply`**. **API/APP keys
> come from the secret store — never in code or state committed to the repo.** Rollback guidance is at
> the end.

## Step 1 — Assess: inventory the estate and confirm access
1. Inventory hosts, clusters, and cloud accounts to be monitored; identify the **pilot** (one Linux VM,
   one Windows VM if applicable, one Kubernetes cluster/namespace).
2. Confirm the **Datadog org + site** and that the **API key** and **APP key** are in the **secret
   store** (§2.1, §2.4). Confirm the Azure app registration / AWS role prerequisites (§2.5–2.6) exist if
   monitoring those clouds.
3. Confirm outbound **network egress** from pilot hosts to the Datadog site endpoints.

## Step 2 — Configure: pin the provider and set backend + variables (no keys in code)
1. In your repo, add the provided **`main.tf`** (Datadog provider + integrations, dashboard, monitors,
   SLO, log pipeline). **Pin** the `DataDog/datadog` provider version and run `terraform init`; commit
   `.terraform.lock.hcl`. *Verify the current supported provider version.*
2. Configure the Datadog provider to read **`DD_API_KEY`**, **`DD_APP_KEY`**, and the **site** from
   **environment variables / secret store** — do **not** put keys in `.tf`. Store Terraform **state** in
   a secured backend (not the repo).
3. Set your inputs (env/service/team tags, pilot host filter, notification handles, thresholds, SLO
   target) in `variables.tf` / `terraform.tfvars`.

## Step 3 — Pilot: install the agent on the pilot hosts
1. **Linux:** on the pilot Linux VM, run **`install-datadog-agent.sh`** — it reads the **API key from
   the secret store** (env var / vault call), sets the **site** and base **tags** (`env`, `service`,
   `team`), optionally enables **logs** and **APM**, installs the agent, and starts it.
   ```
   DD_API_KEY="$(read-from-secret-store)" DD_SITE="datadoghq.com" \
     ./install-datadog-agent.sh --env pilot --service demo --team platform --logs --apm
   ```
2. **Windows:** on the pilot Windows VM, run **`Install-DatadogAgent.ps1`** with the same inputs (API
   key from the secret store, site, tags).
3. **Kubernetes:** install the Datadog **Helm chart** (or apply the DaemonSet) on the pilot cluster with
   the API key from a **Kubernetes secret** (never a literal) and the same base tags.
4. **Confirm the agent reports:** in Datadog → **Infrastructure → Host Map / Containers**, the pilot
   host(s) and cluster appear with recent data; `datadog-agent status` on a host shows **OK**.

## Step 4 — Pilot: wire the cloud integrations
1. **Azure:** in `main.tf`, configure `datadog_integration_azure` with the app-registration
   `client_id`/tenant and the **secret from the secret store**; `terraform plan` → review → `apply`.
2. **AWS:** configure `datadog_integration_aws` with the cross-account **IAM role**; `plan` → `apply`.
3. **Kubernetes:** confirm the cluster agent integration is reporting (it comes with the Helm install).
4. **Confirm in Datadog:** the Azure/AWS integration status pages show the subscription/account
   **connected** and metrics arriving.

## Step 5 — Pilot: apply dashboard, SLO, monitors, and log pipeline (plan first)
1. Run **`terraform plan -out tfplan`** and **read the what-if**: it should create
   `OBSDDOG-Dashboard-EstateOverview`, `OBSDDOG-SLO-APIAvailability`, the three **pilot** monitors
   (`OBSDDOG-Monitor-HostUnreachable-Pilot`, `-CPUHigh-Pilot`, `-K8sPodCrashloop-Pilot`), and
   `OBSDDOG-Pipeline-AppLogs` — and **nothing unexpected**.
2. `terraform apply tfplan`.
3. Confirm the monitors are **scoped to the pilot** (via the `env:pilot` / host tag filter) and their
   **notification handles** (`@slack-…` / `@pagerduty-…`) are set — send a monitor **test notification**.
4. Confirm the **log pipeline** parses pilot logs and routes them to the intended **index**.

## Step 6 — Validate the pilot (the gates)
Run **`OBSDDOG-Validate.ps1`** and **`OBSDDOG-Report.ps1`** and confirm the four gates in §5 pass: agents
report, integrations connected, a monitor fires and routes, and the dashboard/SLO render. **Pass** = all
gates green → proceed to Expand. **Fail** = fix before scaling (see §6).

## Step 7 — Expand: roll out across the estate in waves
1. **Agents:** drive the installers through the **rollout channel** (config-mgmt/IaC for VMs,
   Helm/DaemonSet for the remaining clusters) in **waves** — a host group / environment at a time —
   keeping the API key sourced from the secret store.
2. **Monitors + SLOs:** widen monitor scopes from `env:pilot` to broader tag scopes (or clone per
   critical service), **tuning thresholds** as real data arrives; add SLOs for the services that need
   them. Every change is a reviewed `plan → apply`.
3. **Integrations:** add the remaining Azure subscriptions / AWS accounts / clusters to the integration
   resources.
4. Re-run **`OBSDDOG-Report.ps1`** after each wave to capture host/monitor/SLO coverage and watch
   ingestion against the cost plan.

> **Rollback / safety (any step):** Terraform is your rollback for Datadog resources — **revert the
> commit** and `apply` the previous known-good state (a bad monitor/dashboard is one revert away). To
> stop paging without deleting, **mute** or set a monitor to `no-data`/downtime, or narrow its scope. To
> remove the agent from a host, run the installer's **uninstall** path (or the OS package removal). To
> disconnect a cloud, remove the integration resource and revoke the app-registration/role. **Roll out
> in waves under change control** — never install estate-wide in one shot (cost + notification-storm
> risk). **Never** hard-code a key to "make it work" — fix the secret-store reference instead.

---
### Order of operations
`Assess (inventory + keys in secret store) → pin provider + secure backend/vars (no keys in code) →
pilot: install agent (Linux/Windows/K8s) → wire Azure/AWS/K8s integrations → plan/apply dashboard + SLO
+ pilot monitors + log pipeline → validate the 4 gates → expand agents + monitors + integrations
estate-wide in waves`
