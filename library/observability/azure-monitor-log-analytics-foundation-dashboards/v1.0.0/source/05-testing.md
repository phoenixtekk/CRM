# 5. Testing & Validation — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

Validate against the **pilot resource group** (`rg-obsazmon-pilot`) first. Each test has a **pass/fail**
signal. Do not remediate the diagnostics policy estate-wide or widen alerts until all four gates pass.
Reference scripts/queries are named in each row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Telemetry lands** | Run the `Heartbeat` and resource-log queries from `OBSAZMON-Queries.kql` in Monitor → Logs | Pilot VMs show a recent **heartbeat**; pilot PaaS **resource logs** appear in the workspace | Tables empty / no recent data |
| 2 | **G1 Workspace healthy** | `OBSAZMON-Validate.ps1` | Workspace `log-obsazmon-platform` exists, retention set, RBAC applied | Workspace missing / open access / no retention |
| 3 | **G2 Diagnostics cover pilot** | `OBSAZMON-Report.ps1` after the pilot remediation | Pilot resources have a **diagnostic setting → workspace**; coverage % reported | Pilot resources still uncovered |
| 4 | **G2 Policy staged safely** | Check `OBSAZMON-Policy-Diagnostics-Subscription` | Assigned at scope, **DoNotEnforce** (estate) with pilot remediated; managed identity has roles | Policy enforcing estate-wide already / identity lacks roles |
| 5 | **G3 Metric alert fires** | Breach the CPU threshold on a pilot VM (or lower it briefly) | `OBSAZMON-Alert-VMCPUHigh-Pilot` fires; notification arrives via `OBSAZMON-AG-Platform-Ops` | Alert never fires / no notification |
| 6 | **G3 Log alert fires** | Stop the AMA/heartbeat on a pilot VM (or simulate) | `OBSAZMON-Alert-HeartbeatMissing-Pilot` fires with context | No alert on a silent VM |
| 7 | **G3 Action group reaches responder** | Action group → **Test** (email + webhook + PagerDuty) | Test message received on **every** channel | A channel does not receive |
| 8 | **G4 Workbook renders** | Open `OBSAZMON-Workbook-OpsOverview` | Tiles populate with real pilot data | Empty / query errors |
| 9 | **G4 Dashboard renders** | Open `OBSAZMON-Dashboard-Exec` | Pinned tiles show current data; shared with the right group | Blank / not shared |

## Automated checks
- **`OBSAZMON-Discovery.ps1`** — inventories resources, existing workspaces, diagnostic-settings
  coverage, action groups, and alert rules; use it to confirm the pre-state and the coverage gap.
  **Read-only.**
- **`OBSAZMON-Validate.ps1`** — checks the deployed foundation: workspace exists with retention + RBAC,
  the action group has channels, the pilot alert rules exist and are enabled, and the DCR is associated
  to pilot VMs. **Read-only.**
- **`OBSAZMON-Report.ps1`** — reports **diagnostics coverage** (% of in-scope resources with a setting →
  the workspace), policy **compliance**, and **estimated ingestion** by table/resource for the cost
  plan. **Read-only.**
- **`OBSAZMON-Queries.kql`** — the curated KQL used by the tests, workbook, and dashboard (heartbeat,
  resource logs, alert summary, top ingesters, VM performance).

## Evidence to capture
- A `Heartbeat` query result showing pilot VMs reporting.
- `OBSAZMON-Report.ps1` coverage CSV (before vs after the pilot remediation).
- A screenshot of the fired **CPU** and **heartbeat** alerts and the received notifications.
- The action-group **Test** confirmation on each channel.
- Screenshots of `OBSAZMON-Workbook-OpsOverview` and `OBSAZMON-Dashboard-Exec` populated.

## Exit criteria (before Expand / estate-wide remediation)
- [ ] G1 — telemetry lands: pilot heartbeats + resource logs in `log-obsazmon-platform`
- [ ] G2 — diagnostics cover the pilot; policy staged **DoNotEnforce** estate-wide with roles granted
- [ ] G3 — both alert rules fire and notify through the action group on every channel
- [ ] G4 — ops workbook and exec dashboard render with real data
- [ ] `OBSAZMON-Validate.ps1` and `OBSAZMON-Report.ps1` run clean; ingestion within the cost plan
