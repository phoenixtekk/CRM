# Executive Summary — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

When Oracle Utilities Customer to Meter (C2M) breaks, the cost is not the fix — it is the **hours spent
guessing which layer failed**. The same symptom (a login that hangs, a screen that crawls, an
integration that errors) can be a WebLogic data source that cannot reach the database, an expired
keystore, a saturated thread pool, a blocking database session, or a genuine application fault. Triage
by guesswork restores service late, produces no root cause, and lets the same outage return. This
toolkit replaces that with a **structured root-cause tree and diagnostic scripts** for C2M and WebLogic
14c — so you isolate the failing layer, restore service, and produce a defensible root-cause analysis.

This is a complete, do-it-today package for an experienced C2M / WebLogic administrator. The method is
built on four **fault domains** — WebLogic/middleware, database, network, and application/OUAF — and a
single **layered ladder** (Reachable → Up → Authenticated → Resourced → Correct) walked from the
cheapest, broadest layer down. Every symptom has a branch; every branch names the exact check and the
layer it isolates. Every artifact is named once — the fault-domain map, the symptom decision tree, the
layer-isolation checklist, the diagnostic snapshot, the root-cause record — and reused on every
incident.

## What you get
- A plain-language Solution Overview of the C2M fault domains and the layered root-cause model — why a
  middleware symptom is so often a database or network cause, and how the ladder proves it.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — log access, WLST
  connectivity, DB read access, thread-dump/JMX access, keystore inspection, and a healthy baseline —
  so you are ready *before* the outage.
- A Diagnostic Playbook: a symptom-driven decision tree — won't start / can't log in; batch fails; JMS
  backs up; IWS/integration errors; performance stall; outage — with the exact WLST, console, SQL, and
  log checks per branch and the layer each isolates.
- Five automation scripts (shell, WLST/Jython, and SQL — not PowerShell): a read-only diagnostic
  snapshot collector, per-layer validation, a consolidated database diagnostics report, a safe restore
  previewer (dry-run by default), and a scope/branch helper — authentic to C2M and WebLogic
  administration.
- Testing and Troubleshooting guides with explicit pass/fail gates (toolkit-ready, method-proven,
  restore-complete), plus Best Practices for defensible RCA and escalation to Oracle.

## What this delivers
The failing layer isolated fast, service restored with the smallest safe action, and a defensible
root-cause analysis produced — instead of guesswork triage, a late restore, and a repeat outage.

## The deployment model
Assess (scope the symptom, capture the snapshot), then Configure the checks, then Pilot on
non-production or a captured snapshot, then Validate the restore against a gate, then Expand — with a
documented rollback for every production change.

## Outcome
C2M incidents resolved the repeatable way: the right layer found the first time, service restored
safely, and a root-cause record that stops the repeat — with read-only scripts and a playbook the team
keeps and reuses.
