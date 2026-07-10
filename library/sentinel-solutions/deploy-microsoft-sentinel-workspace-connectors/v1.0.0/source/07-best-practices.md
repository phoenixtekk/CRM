# Best Practices — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Keep-it-clean guidance for a Sentinel foundation that stays governed, cost-aware, and detection-ready
over time.

## Design the workspace once, deliberately

- **Region is forever.** The workspace region fixes data residency and cannot be changed — decide it
  with compliance **before** ingestion, not after (**R1**).
- **One security workspace, not many.** Prefer a single, well-governed workspace for security telemetry
  over a sprawl of per-team workspaces; cross-workspace queries and RBAC get complex fast. Consolidate
  unless residency or hard tenancy boundaries force a split.
- **Separate security telemetry from application/ops logs.** Mixing a chatty application's logs into the
  SIEM workspace inflates cost and clutters detections. Keep `RG-Security-Sentinel` for security data.

## Collect what detections consume — not everything

- **Every GB is a recurring bill.** Ingestion and retention are the dominant Sentinel costs. Connect a
  source because a **detection or investigation needs it**, not because the connector exists.
- **Filter at the DCR, not after.** The cheapest log is the one you never ingest. Constrain syslog
  facilities/severities and CEF streams in `DCR-Syslog-Linux-Pilot` / `DCR-CEF-Appliances-Pilot` — do
  not ingest `Debug`/`Info` firehoses and try to filter in queries later.
- **Be selective with high-volume Microsoft tables.** `NonInteractiveUserSignInLogs`, Defender
  `DeviceNetworkEvents`, and full Office activity can dwarf everything else. Enable them only when a
  detection or hunt genuinely needs them.

## Use the log tiers on purpose

- **Analytics** for detection-driving, frequently queried tables (sign-ins, audit, incidents, key CEF).
- **Basic / Auxiliary** for high-volume, low-signal data kept for hunting/forensics — cheaper to ingest,
  search-only. *(Tier eligibility varies by table and evolves — verify per table.)*
- **Match retention to purpose, not habit.** Interactive retention for what analysts query day to day;
  **archive** for what you keep for compliance/forensics but rarely touch. Set retention **per table**,
  not one blanket number.

## Govern access with least privilege

- **Role-scoped groups, not blanket Contributor.** `SG-Sentinel-Reader/Responder/Contributor-Tenant`
  mapped to Sentinel's built-in roles at the resource-group/workspace scope. Analysts read and triage;
  only a small team changes configuration.
- **Make Contributor just-in-time** where Entra ID P2 allows (PIM-eligible) so standing high privilege
  is minimized (*verify licensing*).
- **Review assignments regularly** — access that made sense at rollout drifts.

## Prove data is arriving — continuously

- **Enable health monitoring** (`SentinelHealth`) and deploy `Workbook-IngestionHealth-Tenant`. A source
  that silently stops sending is a **blind detection** — the most dangerous failure in a SIEM because it
  is invisible until an incident is missed.
- **Alert on ingestion drift**, not just spikes. A table going to **zero** matters as much as a table
  doubling.
- **Watch the cost trend, not just the day.** Re-run `SENTDEP-Report.ps1` on a schedule and compare
  GB/day against the G5 budget; catch creep early.

## Change safely

- **Pilot the noisy path first.** Syslog/CEF via AMA is where cost blows up — one forwarder, one
  appliance, a filtering DCR, measured, before you scale.
- **Name everything and record rollback.** Every diagnostic setting and DCR is named per convention and
  listed in the change record so it can be removed cleanly.
- **Move to commitment tiers with evidence.** Only step up to a commitment tier once real measured
  volume (not a guess) justifies it.

## Where to go next

With the foundation collecting the right data at a controlled cost, the natural next steps in this
catalog are:

- **Sentinel Analytics Rules & MITRE ATT&CK Coverage** — turn this telemetry into tuned detections
  mapped to the ATT&CK matrix, with false-positive control and detection-as-code. *(The direct
  companion to this solution.)*
- **Sentinel SOAR / automation** — automation rules and playbooks to respond to the incidents those
  detections raise.
- **Microsoft Defender XDR** and **Microsoft Entra ID** hardening solutions — strengthen the sources
  feeding this workspace.
- **Microsoft Purview** solutions — for the data-governance and insider-risk signals that complement
  security telemetry.
