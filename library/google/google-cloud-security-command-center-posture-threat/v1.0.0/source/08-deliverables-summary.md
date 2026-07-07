# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — what SCC is, how posture/vulnerability/threat findings, notifications,
  export, and triage fit together; the reference design (named artifacts); benefits, limitations,
  and the pilot-first deployment model. Flags that **editions and detectors are version-dependent —
  verify your edition.**
- **Requirements Guide** — the solution-specific prerequisites (confirmed SCC edition, SCC IAM
  roles, required APIs, a SecOps project, a SIEM/notification destination, a triage operating model,
  a named pilot scope), each with how to *verify* and *implement*, building on the shared GCP global
  requirements.
- **Implementation Guide** — exact ordered steps: assess coverage, design the posture baseline and
  export topology, enable/tune services, create the notification config + export topic, apply the
  posture baseline and mutes, run a pilot triage cycle, then expand org-wide — with pass/fail gates
  and a documented rollback.
- **Testing & Validation** — nine procedures (coverage, notification delivery, SIEM ingestion,
  detector fires, mute behavior, remediation closure, triage/SLA report, least privilege, rollback),
  each with an explicit pass/fail signal.
- **Troubleshooting** — common failure modes (no findings, no notifications, SIEM not ingesting,
  noisy queue, permission errors) and their resolutions.
- **Best Practices** — coverage, noise control, triage/ownership, export hygiene, security, and the
  operating rhythm that keeps findings worked.
- **Executive Summary** — the outcome, approach, and why it is safe/governed.

## Python tools (5)

All are `gcloud` / Cloud Client Library automation, **read-only or dry-run by default**, with no
hardcoded credentials or committed keys (they use ADC / the environment). Run any with `--help`.

1. **`scc_coverage_assessment.py`** — *Assessment / discovery (read-only).* Inventories the
   Organization's SCC state: active services, existing notification configs, and finding counts by
   severity/category — the baseline for the design. Outputs JSON.
2. **`scc_notify_export_setup.py`** — *Configuration helper (dry-run default).* Sets up the
   notification/export plumbing — creates **Finding Notification – Org – v1** publishing to
   **Finding Export Topic – SecOps – v1**, and (optionally) applies posture **mute** rules. Prints a
   plan; only writes with `--apply`.
3. **`scc_triage_sla_report.py`** — *Validation / report generator (read-only).* Pulls active
   findings, maps each to its owner and severity→SLA from **Triage Runbook – SecOps – v1**, computes
   due dates and at-risk/breached flags, and emits an HTML triage report.
4. **`scc_posture_check.py`** — *Policy / guardrail check (read-only).* Compares live posture
   findings and mute state against **Posture Baseline – Corp – v1**, reporting drift (un-approved
   mutes, missing exceptions, unexpected active detectors). Exits non-zero on drift for CI.
5. **`scc_scope_config_helper.py`** — *Scope / config helper (read-only).* Resolves and validates the
   SCC scope (org/folder/project), the SecOps project, and the export topic/subscription wiring —
   confirming IAM bindings (e.g. the SCC notification service account's publish rights) so the other
   tools have a correct, verified target.

## Packaged artifacts

- **`GCPSCC-Solution.pdf`** — the compiled documentation set above.
- **`GCPSCC-Scripts.zip`** — the five Python tools.
