# 5. Testing & Validation — Microsoft Purview Tenant Assessment

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
The assessment tools are read-only; the only writes are the Step-5 quick-win fixes, applied
simulation/test/pilot-first. Do not declare the assessment "delivered" until the inventory is complete,
the register is reviewed, and every remediated finding validates for the pilot scope.

> **Remember:** a capability reported as **not licensed / not enabled / portal-only** is a legitimate
> result, not a test failure. These gates confirm the assessment *read what exists correctly* and that
> any quick-win fix took effect — they do not judge whether a policy is *correct* (that is a
> compliance/records/legal determination).

## Gate 1 — Preflight is clean (licensing + roles + endpoints)
- **Method:** `PURVASSESS-Scope.ps1`.
- **Pass:** every in-scope capability read **succeeds** (no permissions error), all needed endpoints connect, and the licensed/not-licensed picture is recorded.
- **Fail:** resolve the missing role (Requirement 2.2) or endpoint before assessing — otherwise a permission gap masquerades as a coverage gap.

## Gate 2 — Every enabled capability is inventoried
- **Method:** `PURVASSESS-Discovery.ps1`.
- **Pass:** each of the 11 capabilities is recorded as **enabled / not enabled / not licensed / portal-only — review manually** — nothing is silently skipped.
- **Fail:** if a capability you know is enabled shows no read, check the role (Gate 1) and endpoint; if it is genuinely portal-only, confirm it is flagged for manual review with the portal location.

## Gate 3 — DLP coverage and mode are captured correctly
- **Method:** `PURVASSESS-Discovery.ps1` DLP section vs the Purview portal DLP policy list.
- **Pass:** every DLP policy is listed with its **workload locations** and **mode** (enforce vs test); an enforced-tenant-wide-without-pilot policy is flagged as a **P1** finding.
- **Fail:** re-read with the correct role; confirm the mode value matches the portal.

## Gate 4 — Labels, retention, and audit states are read correctly
- **Method:** `PURVASSESS-Discovery.ps1` sections for Information Protection, Data Lifecycle, and Audit.
- **Pass:** published-label scope, auto-labeling mode, retention-policy **enabled** state, and `UnifiedAuditLogIngestionEnabled` all match the portal; a **disabled** retention policy and **audit off** each surface as findings.
- **Fail:** confirm the endpoint (retention/labels via `Connect-IPPSSession`; audit via `Connect-ExchangeOnline`) and re-read.

## Gate 5 — Portal-only capabilities are flagged, not fabricated
- **Method:** `PURVASSESS-Discovery.ps1` output for Insider Risk, Communication Compliance, DSPM, Compliance Manager, Unified Catalog.
- **Pass:** each is marked **portal-only — review manually** with the exact portal location, or read only where a reliable cmdlet exists — never asserted with an invented value.
- **Fail:** if any shows an unverifiable value, treat it as a bug; the honest result is "review manually / verify your licensing/tenant."

## Gate 6 — Findings register is complete and prioritized
- **Method:** `PURVASSESS-Report.ps1` → `Purview Assessment – Tenant – Findings` + `… Priorities – P1P2P3`.
- **Pass:** every finding has **capability · observation · evidence source · risk · recommendation · priority**, and the P1/P2/P3 roll-up matches the register.
- **Fail:** fill the missing field; re-run the report.

## Gate 7 — Scorecard reflects the inventory
- **Method:** `PURVASSESS-Report.ps1` → `Purview Assessment – Capabilities – Scorecard`.
- **Pass:** each capability's coverage/maturity read and enabled/not-enabled/portal-only state agrees with the Step-2 inventory.
- **Fail:** reconcile the scorecard to the inventory; re-run.

## Gate 8 — Quick-win remediations previewed before commit
- **Method:** `PURVASSESS-Remediate.ps1 -Fix <name> ... -WhatIf` for each intended fix.
- **Pass:** `-WhatIf` prints the exact cmdlet it would run and makes **no change**; a permissions error (if any) is reported rather than a silent failure.
- **Fail:** resolve the write role (Requirement 2.5) or the parameter, and re-preview — never commit an unreviewed fix.

## Gate 9 — Remediated findings validate green
- **Method:** `PURVASSESS-Validate.ps1`, then re-run `PURVASSESS-Report.ps1`.
- **Pass:** each committed fix shows its target state (DLP in `TestWithNotifications`, auto-labeling in simulation, retention `Enabled = True`, audit ingestion `True`) and the corresponding finding shows **cleared** for the pilot scope.
- **Fail:** re-check the fix and the pilot scope; if it didn't take, revert (`-Revert -Commit`) and investigate before retrying.

## Gate 10 — Readout delivered and backlog owned
- **Method:** `Purview Assessment – Tenant – Readout` reviewed with stakeholders.
- **Pass:** the readout presents the scorecard + prioritized findings; every non-remediated P1/P2 has an owner and a route (governance decision / build engagement / deferred), and the re-baseline cadence is scheduled.
- **Fail:** assign the missing owners/dates before closing the engagement.

## Evidence to retain
- `PURVASSESS-Scope.ps1` and `PURVASSESS-Discovery.ps1` outputs (the baseline inventory).
- `Purview Assessment – Tenant – Findings`, `… Priorities – P1P2P3`, `… Capabilities – Scorecard`.
- The `-WhatIf` transcripts and `-Commit` confirmations for every remediation (Requirement 2.7).
- `PURVASSESS-Validate.ps1` output showing findings cleared, and the change approvals.

> Whether a policy is **correct** — a retention duration, a DLP rule's regulatory sufficiency, whether a
> capability is *required* — is a **compliance/records/legal determination**. These gates prove the
> assessment read the tenant correctly and the fixes took effect, not that the resulting configuration
> satisfies a regulation.
