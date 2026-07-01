# Executive Summary — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

When software requests live in email and reclamation never happens, two things break at once: the
service desk drowns in untracked asks, and licenses leak — paid for, assigned once, then abandoned on
departed users and idle machines. This solution designs a repeatable ServiceNow Software Asset
Management (SAM) workflow for the full request lifecycle — intake and triage, entitlement and
fulfillment, and automated reclamation of unused licenses — with the catalog items, workflows, and
reporting that turn license operations into a measured, auditable process.

This is a complete, deploy-it-today design for running software requests and reclamation as a clean
ServiceNow workflow, written for a SAM/ITAM analyst with no prior workflow-design experience. The
exact internal configuration of the ServiceNow SAM module (plugins, store apps, console layouts) is
deferred to ServiceNow's official documentation; this package gives you the correct, vendor-neutral
workflow design and the named artifacts to build it.

## What you get
- A plain-language Solution Overview of the request lifecycle (intake to reclamation), catalog items,
  workflows, entitlement matching, and KPI reporting.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps to build the catalog items, triage and fulfillment
  workflows, reclamation rules, and the KPI set — then pilot, validate, and expand.
- Five PowerShell/integration scripts for request and entitlement discovery, fulfillment-data
  validation, a request and reclamation report, safe remediation of stale entitlements, and a
  scope/assignment helper (ServiceNow data via the Table API where available).
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A repeatable request-to-reclamation workflow — a catalog-driven intake, an approval and triage path, an
entitlement check before fulfillment, and a scheduled reclamation loop that harvests unused licenses
back into the available pool — all measured by a named KPI set so the service desk keeps pace and
licenses stop leaking.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand — proven on a pilot product family before you scale.

## Outcome
Software requests and reclamation run as a clean, auditable ServiceNow workflow — intake to fulfillment
to reclamation — measured, repeatable, and validated on a pilot before fleet-wide rollout.
