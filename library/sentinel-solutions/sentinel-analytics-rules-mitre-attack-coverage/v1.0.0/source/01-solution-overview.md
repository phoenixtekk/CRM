# Solution Overview — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

## What this is

A complete, self-guided method for turning the telemetry already in your Microsoft Sentinel workspace
into **tuned, trustworthy detections mapped to the MITRE ATT&CK matrix** — with explicit gap analysis,
false-positive reduction, enrichment, and **detection-as-code** so your detection logic is a versioned,
portable asset rather than a pile of portal clicks.

It is the **detection** layer of a Sentinel program. It assumes a connected, cost-aware workspace (the
companion *Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion* solution) and builds the
analytics rules on top of it.

## How the technology works (the mental model)

- **Analytics rules.** The detections in Sentinel. The main types:
  - **Scheduled rules** — a **KQL** query that runs on a schedule (e.g. every 5–60 minutes), looks back
    over a window, and raises an **alert** (and optionally an **incident**) when the query returns
    results over a threshold. The workhorse of custom detection.
  - **Near-real-time (NRT) rules** — a special scheduled rule that runs about once a minute for
    low-latency detection of high-priority events. Limited in number and query shape (*verify current
    limits in your tenant*).
  - **Microsoft Security / Fusion / ML rules** — rules that surface alerts from Microsoft security
    products or Microsoft's correlation/ML. You enable rather than author these.
  - **Rule templates** — Microsoft- and community-provided detections (installed via the Content hub)
    you enable and then tune, instead of writing every rule from scratch.
- **MITRE ATT&CK mapping.** ATT&CK is a matrix of adversary **tactics** (the "why" — e.g. *Credential
  Access*, *Privilege Escalation*) and **techniques** (the "how" — e.g. *T1110 Brute Force*). Each
  analytics rule is tagged with the tactics/techniques it detects. Aggregating those tags across all
  enabled rules produces a **coverage map**; the untagged cells are your **gaps**.
- **Tuning (threshold & entity).** A rule fires too often when its **threshold** is too low or it lacks
  **allow-lists/suppression** for known-benign activity. Tuning adjusts the query, threshold, and
  grouping, and adds **entity mappings** (user, host, IP) so alerts are correlated into meaningful
  incidents and known-good sources are excluded.
- **Watchlists & enrichment.** **Watchlists** are reference tables (VIP users, authorized admin IPs,
  terminated staff, high-value assets) you join to in rule queries — so a rule can, for example, fire
  *only* when a sensitive account is involved, or *suppress* when the source is a sanctioned scanner.
- **Automation rules.** Rules that act on incidents (assign, change severity, suppress duplicates,
  trigger a playbook). Used here mainly for **suppression/tuning**, not full SOAR.
- **Detection-as-code.** Exporting rules to a version-controlled format (ARM/JSON, or YAML via Sentinel
  **Repositories**) so detections are reviewed, diffed, and deployed like software.

## The standard deployment model

Every solution in this program follows the same five stages:

1. **Assess.** Inventory current enabled rules and available templates; build the **ATT&CK coverage
   map** and rank gaps by risk (run `SENTRULE-Discovery.ps1`, `SENTRULE-Coverage.ps1`).
2. **Configure.** Create the enrichment **watchlists**, enable a small high-value rule set against the
   top-risk gaps, and set entity mappings — naming every object.
3. **Pilot.** Run the new rules in a **low-impact** posture — they produce alerts you triage, but
   incident creation/automation is held back — so you can measure noise before it reaches the queue.
4. **Validate.** Confirm coverage improved and the **false-positive rate** is acceptable per rule; tune
   thresholds/suppression until it is (run `SENTRULE-Report.ps1`, `SENTRULE-Validate.ps1`).
5. **Expand.** Turn the tuned rules to full incident creation, then repeat the map→enable→tune loop
   across the rest of the ATT&CK matrix, exporting each tuned rule as code (`SENTRULE-Export.ps1`).

## Scope — what this solution covers

- **Rule enablement** — scheduled rules, NRT rules, and Microsoft-provided rule templates.
- **MITRE ATT&CK coverage mapping and gap analysis** — a measured map and a risk-ranked gap list.
- **Threshold and entity tuning** — cutting false positives with thresholds, grouping, suppression, and
  allow-lists.
- **Watchlists and enrichment** — reference data joined into detections for context and precision.
- **Detection-as-code export** — versioning and reuse of tuned rules.

## Out of scope (handled elsewhere)

- **Standing up the workspace and connectors / ingestion** — the companion *Deploy Microsoft Sentinel:
  Workspace, Data Connectors & Ingestion* solution (this detection layer depends on it).
- **Full SOAR / playbook automation** beyond suppression/tuning automation rules — a separate Sentinel
  automation solution.
- **Threat-hunting content and notebooks** beyond what supports tuning.
- **The determination of risk tolerance and alerting priorities** — which techniques matter most, and
  what false-positive rate is acceptable, are security-leadership decisions; this solution measures and
  implements against the priorities you set.

## Authentication and connections used

- **Microsoft Sentinel** (Azure portal or Defender portal) for rule authoring, watchlists, and MITRE
  view.
- **PowerShell** with the **Az** modules (`Az.Accounts`, `Az.SecurityInsights`, `Az.OperationalInsights`)
  for rule/template/watchlist discovery, coverage/gap analysis, per-rule reporting, validation, and
  detection-as-code export; **Microsoft.Graph** where identity context is needed.
- **KQL** run against the workspace (via `Invoke-AzOperationalInsightsQuery`) for false-positive/alert
  reporting.
- All tools authenticate **interactively** with an MFA-capable admin; **no credentials are stored in
  code**. Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.
