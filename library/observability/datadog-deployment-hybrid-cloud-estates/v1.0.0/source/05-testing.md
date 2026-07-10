# 5. Testing & Validation — Datadog Deployment for Hybrid & Cloud Estates

Validate against the **pilot** (one host + one cluster + the connected clouds) first. Each test has a
**pass/fail** signal. Do not expand agents or widen monitors estate-wide until all four gates pass.
Reference scripts are named in each row. Everything is **plan-first**; **no keys in code**.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Agent reports** | `datadog-agent status` on the pilot host; check Infrastructure → Host Map | Pilot Linux/Windows host + cluster show **recent** metrics; status = OK | Host absent / agent error / no data |
| 2 | **G1 Tags applied** | Inspect a pilot host's tags in Datadog | `env`, `service`, `team` tags present as set by the installer | Missing/incorrect tags (dashboards/monitors won't scope) |
| 3 | **G2 Azure integration** | `OBSDDOG-Validate.ps1`; Datadog Azure integration status | Subscription **connected**; Azure metrics arriving | Not connected / app-registration/role error |
| 4 | **G2 AWS integration** | Datadog AWS integration status | Account **connected**; CloudWatch metrics arriving | Role assume fails / not connected |
| 5 | **G2 No keys in code** | Secret scan the repo; inspect `main.tf`/installers | Keys read from env/secret store only; scan clean | An API/APP key or secret found in code/state |
| 6 | **G3 Monitor fires** | Trigger a pilot condition (stop a host / spike CPU) | `OBSDDOG-Monitor-*-Pilot` fires; state changes to Alert | Monitor never triggers |
| 7 | **G3 Notification routes** | Confirm the fired monitor's notification | Arrives in the mapped **Slack/Teams/PagerDuty** handle | No notification / wrong channel |
| 8 | **G3 Log pipeline** | Send a pilot app log | `OBSDDOG-Pipeline-AppLogs` parses it; it lands in the intended index with tags | Unparsed / wrong index |
| 9 | **G4 Dashboard + SLO** | Open `OBSDDOG-Dashboard-EstateOverview` and `OBSDDOG-SLO-APIAvailability` | Dashboard renders with pilot data; SLO shows a status/error budget | Blank / query errors / SLO not tracking |

## Automated checks
- **`OBSDDOG-Validate.ps1`** — confirms Terraform provider auth works (API+APP keys present via env, not
  in code), the expected Datadog resources exist (dashboard, SLO, the three pilot monitors, log
  pipeline), the Azure/AWS integrations report connected, and **no keys are present in the repo/state**.
  **Read-only.**
- **`OBSDDOG-Report.ps1`** — inventory/coverage report via the Datadog API: hosts reporting (by
  env/service tag), monitors and their states, SLO status/error budget, and an ingestion snapshot to
  watch against the cost plan. **Read-only.**
- **`install-datadog-agent.sh` / `Install-DatadogAgent.ps1`** — the agent installers themselves; their
  `status` output is the Gate-1 evidence per host.
- **`main.tf`** — `terraform plan` is the primary what-if gate for every Datadog-resource change.

## Evidence to capture
- `datadog-agent status` (Linux + Windows) and a Host Map screenshot showing the pilot reporting.
- Datadog **Azure** and **AWS** integration status pages showing *connected*.
- A **secret-scan** report showing the repo/state is key-free.
- A fired-monitor screenshot **and** the received Slack/Teams/PagerDuty notification.
- `OBSDDOG-Report.ps1` output (hosts, monitors, SLO) — the coverage baseline before Expand.

## Exit criteria (before Expand / estate-wide rollout)
- [ ] G1 — pilot agents report with correct `env`/`service`/`team` tags
- [ ] G2 — Azure + AWS + K8s integrations connected; **secret scan clean (no keys in code/state)**
- [ ] G3 — a monitor fires and routes to the correct notification handle; log pipeline parses to index
- [ ] G4 — estate-overview dashboard renders and the SLO tracks an error budget
- [ ] `OBSDDOG-Validate.ps1` and `OBSDDOG-Report.ps1` run clean; ingestion within the cost plan
