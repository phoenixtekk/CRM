# Executive Summary — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

Keeping Oracle Utilities Customer to Meter (C2M) supportable means staying current: applying Oracle
patches to C2M/OUAF and to Oracle WebLogic Server, and periodically performing version upgrades
(for example, toward **C2M 25.4**). Done ad hoc, this is where production outages come from — a patch
applied without a backup, an upgrade run straight against production, a change with no rollback. This
solution is the disciplined method to do it safely: readiness, backup, apply, validate, rollback,
proven in lower environments before production.

This is a complete, do-it-today runbook written for a C2M/WebLogic administrator. It treats every
patch and every upgrade as the same governed operation — the repeatable way — so the outcome does not
depend on who is on shift.

## What you get
- A plain-language Solution Overview of the C2M/OUAF + WebLogic patch and upgrade model:
  supportability, the certified-version matrix, the OPatch and OUAF install/upgrade utilities, and
  the environment progression (lower environments first).
- A Requirements Guide with verify / implement-if-missing for every prerequisite — My Oracle Support
  (MOS) patch access, verified backups, a certified target release, change control, and a
  non-production pilot environment.
- An Upgrade & Patch Runbook of precise, ordered steps: readiness and backup, apply Oracle patches or
  perform the version upgrade, post-apply validation, and documented rollback — per environment with
  explicit go/no-go gates.
- Five automation scripts (WLST/Jython, shell, and SQL) for read-only patch/version discovery,
  read-only post-patch validation, a read-only health/coverage report, a dry-run-by-default
  remediation helper, and a scope/target helper — authentic to C2M and WebLogic administration.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices
  for staying current safely.

## What this delivers
C2M and WebLogic kept current and secure — patches and upgrades applied with readiness, backup,
validation, and a documented rollback — proven in lower environments before production, so you close
support gaps without unplanned outages.

## Version boundary
Version-specific details (C2M 25.4 / minimum OUAF v2.9, WebLogic 14c) are cited or flagged
"verify for your version." Specific patch numbers and MOS notes are pointed to on My Oracle Support,
not reproduced here — always read each patch's own README before applying it.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — every patch and upgrade proven in a
non-production environment before production, with a backup and a documented rollback at every step.

## Outcome
A supportable, current C2M/WebLogic estate: patches and version upgrades applied on a disciplined
cadence with go/no-go gates and a rollback you have actually tested — replacing risky, one-off
patching with a repeatable runbook.
