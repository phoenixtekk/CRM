# 2. Requirements — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

This solution **tunes an RMM that is already deployed and collecting data**. The requirements below are what must be true before the tuning loop can run. For each, the Description states what is needed, **Why** explains why it matters to tuning, **Verify** gives a concrete check, and **Implement-if-missing** gives the remediation so the requirement is never merely assumed. Category-wide prerequisites common to all Managed solutions are in `global-requirements-managed.md`.

---

## R1 — A production RMM with administrative access and reporting/export
**Description.** An RMM platform (e.g. NinjaOne, Datto RMM, ConnectWise Automate) in production with at least 30 days of alert history, an administrator account, and the ability to export or report on the alert/event stream (CSV, API, or scheduled report).
**Why.** Tuning is a data exercise. Without admin rights you cannot edit monitor policies, thresholds, or routing; without export you cannot compute the baseline that every later phase is measured against.
**Verify.** Sign in as an administrator; confirm you can edit a monitor policy and produce an alert export covering the last 30 days.
**Implement-if-missing.** Request an admin role from the RMM owner; if history is shorter than 30 days, enable alert/event logging and reporting now and defer the **Assess** phase until at least 14 days of representative data exist.

## R2 — A PSA for ticket routing
**Description.** A Professional Services Automation / ticketing platform (e.g. ConnectWise PSA, Autotask, Halo, Freshservice) integrated, or integratable, with the RMM.
**Why.** The value of tuning is realized when surviving alerts become correctly-categorized tickets. Without a PSA target there is nowhere to route the **Alert-to-Ticket Mapping – PSA Integration – Route**.
**Verify.** Confirm the RMM-to-PSA integration is connected and that a test alert can open a ticket in the correct board/queue.
**Implement-if-missing.** Enable and authenticate the native RMM↔PSA integration; if none exists, configure email-parsing or webhook ticket creation as an interim and record it as a known limitation.

## R3 — A baseline alert export
**Description.** A complete export of the current alert/event stream for the measurement window, with timestamp, device, alert type/source, severity, and (if available) acknowledge/resolve times.
**Why.** The **Alert Inventory & Baseline – RMM Estate – Assess** is computed from this export. No export, no baseline, no provable result.
**Verify.** Open the export and confirm it contains per-alert timestamp, device, and type columns for the full window.
**Implement-if-missing.** Build a scheduled RMM report or use the RMM API to pull the alert log; `RMMTUNE-Discovery.ps1` parses common export shapes.

## R4 — Defined business hours and on-call schedule
**Description.** Documented business hours per client/site and a current on-call/after-hours roster.
**Why.** The **Routing & Escalation Matrix – Business Hours / On-Call – Route** routes by severity *and* time-of-day; ambiguous hours produce mis-paged technicians or silent gaps.
**Verify.** Confirm a written business-hours definition (with time zone) and the active on-call schedule exist.
**Implement-if-missing.** Capture business hours per client in the CMDB/PSA and stand up an on-call rotation before configuring after-hours routing.

## R5 — Automation/scripting capability in the RMM
**Description.** The RMM's scripting/automation engine (PowerShell, Bash, or the product's native automation) enabled, with the ability to trigger a script from an alert condition.
**Why.** The **Self-Heal Automation Library – Common Conditions – Automate** depends on the RMM being able to run a remediation on a monitored condition; without it, SEV-4 self-heal is impossible and noise stays high.
**Verify.** Run a trivial script (e.g. write a log line) against a pilot device from the RMM, and confirm an alert can trigger a script.
**Implement-if-missing.** Enable the automation module, deploy the agent script runner, and grant the automation role the rights to execute remediations.

## R6 — Change control / change management
**Description.** A change-control process so threshold, routing, and automation changes are approved, recorded, and reversible.
**Why.** Tuning edits live monitoring for production clients; an un-reviewed change can suppress a real critical. Every change must be traceable and rollback-able.
**Verify.** Confirm a change record can be raised and that the prior policy state is captured before edits.
**Implement-if-missing.** Adopt the change-control process in `global-requirements-managed.md`; snapshot/export every policy set before editing it.

## R7 — Defined monitored estate and client scope
**Description.** A known, current inventory of which devices/clients are in scope, so per-endpoint metrics are meaningful.
**Why.** Alerts-per-endpoint-per-day requires an accurate endpoint count; a stale count distorts the baseline and the result.
**Verify.** Reconcile the RMM device count against the CMDB for the in-scope clients.
**Implement-if-missing.** Sync the RMM inventory, decommission stale agents, and confirm the endpoint count before computing the baseline.

## R8 — Severity and disposition definitions agreed with stakeholders
**Description.** Agreement from service-desk and account stakeholders on what SEV-1…SEV-4 mean and the response expectation for each.
**Why.** The **Severity & Taxonomy Matrix – Alert Classes – Classify** is only useful if the desk acts on the tiers consistently; undefined severity is the root cause of noise.
**Verify.** Confirm a signed-off severity definition (the four canonical tiers) exists and the desk has seen it.
**Implement-if-missing.** Run a short workshop to ratify the four-tier model in Section 1 before classifying alerts.

## R9 — A pilot client/site for safe rollout
**Description.** One representative client or device group designated for first application of tuned policies before fleet-wide rollout.
**Why.** Tuning changes must be validated on a contained population so a mistake affects one client, not all.
**Verify.** Confirm a pilot client is named and its stakeholders accept piloting.
**Implement-if-missing.** Select a representative, lower-risk client; align with the pilot-client requirement in `global-requirements-managed.md`.

## R10 — Metric tooling and a reporting home
**Description.** The ability to compute and store baseline/after metrics (alerts/endpoint/day, % actionable, MTTA, MTTR) and a documented home for the resulting reports.
**Why.** The loop is only closed if before/after metrics are computed and retained; the **Tuning Baseline Report – Noise & Actionability – Validate** must live somewhere durable.
**Verify.** Confirm a location (PSA, SharePoint, docs site) for the reports and that the supplied scripts can run against the exports.
**Implement-if-missing.** Designate the documentation home (see `global-requirements-managed.md`); use `RMMTUNE-Report.ps1` and `RMMTUNE-Set-AlertBaseline.ps1` to produce and store the metrics.

## R11 — Read-only operating posture for assessment
**Description.** Agreement that the **Assess** and **Classify** phases are read-only and make no live changes.
**Why.** Trust in the process depends on proving you can measure without disrupting; all supplied discovery/report scripts default to read-only/`-WhatIf`.
**Verify.** Confirm `RMMTUNE-Discovery.ps1` and `RMMTUNE-Report.ps1` are run before any policy edit.
**Implement-if-missing.** Sequence the engagement so no threshold or routing change occurs until the baseline is signed off.
