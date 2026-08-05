# Executive Summary — Windows Advanced Audit Policy & Security Logging Baseline (Intune)

Most Windows fleets are under-audited without anyone realizing it: the default audit policy captures too
little to investigate an incident, it drifts from machine to machine, and — worst of all — the modern
**Advanced Audit Policy** subcategories are often silently ignored because a single override switch is
off. When a breach or insider event happens, the events you needed were never written. This solution
fixes that at the source. It configures the full **Windows Advanced Audit Policy Configuration** on
**Windows 10/11** endpoints via **Microsoft Intune** — a consistent, **CIS / Microsoft security
baseline-aligned** audit trail on every device, deployed pilot-first and fully reversible.

**A deliberately scoped, distinct capability.** This is the audit **configuration** baseline — which
subcategories to audit, at what Success/Failure level, plus **command-line process auditing** and a
right-sized Security log. It is **not** SIEM forwarding (getting those events into Microsoft Sentinel is
the separate *Entra ID & Intune Audit Telemetry to Microsoft Sentinel* solution), and it is **not** a
broad CIS/STIG hardening baseline (that is a separate, wider product). It deploys a single Settings
Catalog profile and is reversible by unassigning it — no re-enrollment, no re-imaging.

Two things this package makes explicit that teams routinely miss:

- **The override that makes everything work.** Windows only honors the advanced subcategories when
  **"Force audit policy subcategory settings to override audit policy category settings"** is enabled
  (`SCENoApplyLegacyAuditPolicy = 1`). The baseline sets it explicitly and the scripts verify it — so
  your audit settings can't be silently voided by a leftover legacy policy.
- **The event that catches attackers.** **Process Creation with the full command line** (Event ID 4688)
  is the highest-value detection for living-off-the-land activity. The baseline turns it on, sizes the
  log for it, and hands the volume decision to your SIEM instead of turning it off.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A `Win Audit Policy - Baseline - Pilot` Settings Catalog profile
  carrying the force-subcategory override, all ~24 recommended audit subcategories, command-line process
  auditing, and the Security-log size — deployed pilot-first.
- **Baseline-aligned and role-aware.** Recommended Success/Failure values cited to CIS / Microsoft, tuned
  for workstations, with explicit guidance to clone a server variant for high-volume roles.
- **Honest about volume.** The loud subcategories (Process Creation, File Share, Filtering Platform
  Connection) are flagged, tuned, and paired with the forwarding solution so auditing is never turned
  off for the wrong reason.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting guides
with clear pass/fail gates.

**Outcome:** a consistent, baseline-aligned Windows audit trail — with command-line process auditing and
a right-sized log — on every corporate endpoint, deployed and proven on a pilot before you scale, without
a consulting engagement and without touching how the device is enrolled. This one product resolves the
cluster of "Configure Auditing for …" and "Audit Logon" findings a typical Windows client security
assessment raises.
