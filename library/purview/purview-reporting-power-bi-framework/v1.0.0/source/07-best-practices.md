# 7. Best Practices — Microsoft Purview Reporting & Power BI Framework

Field-tested practices for a Purview reporting framework that stays accurate, defensible, and safe.
Grouped by theme; each is actionable.

## Data lineage & defensibility
- **Treat the dataset contract as law.** `Purview Compliance Dataset – Report` is the single agreement
  between the exports and the dashboards. Change the contract *first*, then the export, then the model —
  never let the Power BI model reach around the contract to a raw source.
- **Every number needs a source you can name.** For each dashboard figure, be able to say which cmdlet
  or Graph endpoint produced it and for what window. That sentence is your audit answer.
- **Keep the reconciliation evidence current.** Re-run `OPSREPORT-Validation.ps1` on a cadence and
  retain the output; a dashboard nobody has reconciled in six months is not defensible.
- **Version the model.** Keep the `.pbix` in source control (or a Fabric deployment pipeline) so a
  dashboard change is reviewable and revertible.

## Read-only & least privilege
- **Report with a read-only identity.** The reporting account needs *View-Only* / *Reader* roles, not
  Compliance Administrator write access and never Global Administrator. Reporting should not be able to
  change a policy.
- **Separate the reporting identity from case roles.** The account that builds insider-risk /
  communication-compliance aggregates must hold **no** case role — role separation is the privacy
  control.
- **Scope Graph consent to read.** Consent only `*.Read.All` scopes; there is no reason a reporting
  pipeline holds a write scope.

## Privacy-by-design (HR-sensitive sources)
- **Aggregate-only, always.** For insider risk and communication compliance, export counts by
  severity/date — never subjects, reviewers, or case content. If a field could identify a person under
  investigation, it does not belong in a report dataset.
- **Pseudonymize where a breakdown is needed.** If leadership needs a by-department cut, aggregate to
  the department, not the individual.
- **Defer the outcome.** The report shows *that* signals exist and their volume; whether any warrants
  action is an HR/legal decision, stated as such on the dashboard.

## Pilot-before-broad (the reporting equivalent of simulate-first)
- **Never publish an unreconciled dashboard to leadership.** The pilot workspace exists so wrong numbers
  are caught before the board sees them. A reporting error erodes trust as badly as a policy error.
- **Reconcile against the portal, not against yourself.** Validation compares your export to Purview's
  own numbers — the portal is the reference of record.
- **Explain every variance.** A small difference between export and portal is fine when documented
  (latency, grouping); an unexplained difference is a defect.

## Freshness & reliability
- **A stale dashboard is worse than none.** Health-check freshness on every run; if the export didn't
  refresh, surface it on the dashboard (a "data as of" stamp) rather than showing yesterday's number as
  today's.
- **Fail loud.** If a source returns empty when it should have data, the pipeline flags it — an empty
  chart must never be indistinguishable from "no incidents."
- **Watch licensing drift.** If an E5 add-on lapses, a source silently goes empty; the health check
  catches it and marks the page *not licensed — verify tenant*.

## Licensing & tenant reality
- **Verify each source in *your* tenant.** Purview features are plan-gated and some are preview; confirm
  availability before promising a page, and label unavailable pages honestly.
- **Don't invent a source.** If a capability isn't licensed, the page is empty and labelled — never
  synthesize or estimate a compliance number.

## Operations
- **Least-privilege the audience too.** Grant leadership *Viewer* on the app/workspace, not
  contributor.
- **Keep the export set retained per policy.** The dated exports are records; retain and dispose of them
  per the organization's records schedule (a records determination — defer to records management).
- **Document the runbook.** Who owns the pipeline, what the daily job does, and how to recover a failed
  refresh (see `ADMIN_DOCS`/troubleshooting).
