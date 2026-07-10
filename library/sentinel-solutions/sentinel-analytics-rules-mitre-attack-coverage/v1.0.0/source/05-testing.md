# Testing & Validation — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

Work these gates **in order**. Each is **pass/fail**: do not advance a phase until its gate passes. Run
**`SENTRULE-Validate.ps1`** for a consolidated pass/fail summary, **`SENTRULE-Coverage.ps1`** for the
ATT&CK map, and **`SENTRULE-Report.ps1`** for per-rule alert and false-positive rates. KQL queries can
be run in Sentinel → **Logs**.

---

## Gate 1 — Telemetry the rules need is present

- **Check (KQL):** for each table a target rule queries, `<TableName> | where TimeGenerated > ago(24h) |
  count` → non-zero (e.g. `SigninLogs`, `AuditLogs`).
- **Automated:** `SENTRULE-Discovery.ps1` reports which expected tables have recent data.
- **Pass:** every table a pilot rule depends on has recent data. **Fail:** connect the source first
  (companion ingestion solution) — do not enable a rule against an empty table.

## Gate 2 — Baseline coverage map exists and gaps are ranked

- **Check:** `SENTRULE-Coverage.ps1` produces a tactic/technique coverage matrix and a gap list;
  Sentinel → **MITRE ATT&CK** corroborates it.
- **Pass:** a measured coverage map and a risk-ranked gap list (against the R5 priority) exist. **Fail:**
  build them before enabling rules — coverage decisions must be measured, not assumed.

## Gate 3 — Enrichment watchlists imported and referenced

- **Check:** Sentinel → **Watchlists** — `WL-VIPUsers-Tenant`, `WL-AuthorizedAdminIPs-Tenant`,
  `WL-TerminatedUsers-Tenant`, `WL-HighValueAssets-Tenant` exist with rows. A pilot rule query references
  at least one via `_GetWatchlist('<alias>')`.
- **Automated:** `SENTRULE-Validate.ps1` lists watchlists and flags any pilot rule that should reference
  one but does not.
- **Pass:** watchlists present, populated, and referenced. **Fail:** import/repopulate them (Phase 1,
  Step 1).

## Gate 4 — Pilot rules enabled with entity mappings, in low-impact posture

- **Check:** Sentinel → **Analytics** — `Rule-BruteForce-Entra-Pilot`, `Rule-AtypicalTravel-Entra-Pilot`,
  `Rule-NewAdminRole-Entra-Pilot` are **Enabled**, each has **entity mappings** (Account/IP/Host as
  applicable), and **Create incidents** is **Disabled** (low-impact posture) until sign-off.
- **Automated:** `SENTRULE-Validate.ps1` confirms each pilot rule is enabled, has entity mappings, and
  reports its incident-creation setting (flags any that create incidents before Gate 6).
- **Pass:** rules enabled, mapped, and still in low-impact posture. **Fail:** correct the rule (Phase 1,
  Steps 2–3).

## Gate 5 — Alert volume and false-positive rate measured

- **Check:** `SENTRULE-Report.ps1` reports per pilot rule: alert count over the pilot window and, where
  dispositions exist, the benign/false-positive rate.
- **KQL cross-check:**
  `SecurityAlert | where TimeGenerated > ago(7d) | summarize Alerts=count() by AlertName | sort by Alerts desc`
- **Pass:** you have per-rule alert volume and a false-positive signal. **Fail:** let the pilot run
  longer / confirm the rule is actually firing.

## Gate 6 — False-positive rate within tolerance (trust gate)

- **Check:** For each pilot rule, the benign/false-positive rate meets the agreed **R5** tolerance after
  tuning (allow-list → suppression → threshold → grouping).
- **Automated:** `SENTRULE-Report.ps1` shows the post-tuning rate per rule against the tolerance.
- **Pass:** every rule to be promoted is within tolerance. **Fail:** keep tuning (Phase 3); do **not**
  enable incident creation for a rule over tolerance.

## Gate 7 — Targeted ATT&CK gaps are now covered

- **Check:** Re-run `SENTRULE-Coverage.ps1` — the specific tactic/technique cells you targeted (e.g.
  T1110, T1078, T1098) now show as covered by the enabled rules.
- **Pass:** the targeted gap cells moved from uncovered to covered. **Fail:** confirm the rules are
  tagged with the intended techniques; add the mapping.

## Gate 8 — Rules exported as code

- **Check:** `SENTRULE-Export.ps1` produced ARM/JSON (or YAML for Repositories) for the enabled rules,
  committed to `Repo-Detections-Main` / version control.
- **Pass:** every promoted rule exists as versioned code with a rollback point. **Fail:** export and
  commit before considering the batch done.

## Gate 9 — Promotion and rollback are documented

- **Check:** The change record (**G7**) lists every rule promoted to incident creation, every watchlist,
  and the automation rule `AR-Suppress-KnownScanners-Pilot`, so each can be disabled/reverted cleanly.
- **Pass:** a named, complete promotion + rollback list exists. **Fail:** complete it before the next
  expansion loop.

---

### Consolidated pass criteria

The detection set is **tuned, mapped, and trustworthy** when **Gates 1–9 pass**: telemetry present, a
measured coverage map with ranked gaps, enrichment watchlists in use, pilot rules enabled and mapped,
alert volume and false-positive rate measured and **within tolerance**, the targeted ATT&CK gaps now
covered, rules exported as code, and promotion/rollback documented. Then repeat the loop for the next
batch of gaps.
