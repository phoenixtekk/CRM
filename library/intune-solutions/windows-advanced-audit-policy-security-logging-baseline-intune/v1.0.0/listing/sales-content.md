# Sales Content — Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

## Hook
**Turn on the Windows audit trail your investigations actually need.** Configure the full Windows
Advanced Audit Policy on Windows 10/11 via Intune Settings Catalog — CIS / Microsoft-aligned
subcategories, command-line process auditing, the force-subcategory override, and a right-sized Security
log — deployed pilot-first across every corporate endpoint.

## The problem
Most Windows fleets are under-audited and nobody notices until an incident. The default policy captures
too little to investigate, it drifts from machine to machine, and — worst of all — the modern Advanced
Audit Policy subcategories are frequently ignored because one override (`SCENoApplyLegacyAuditPolicy`) is
off. When a breach or insider event happens, the events you needed were never written. The fix isn't
another script; it's a consistent, baseline-aligned audit configuration on every device, with the
override set explicitly and the loud-but-valuable events (like Process Creation *with command line*)
turned on and sized for.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — one named Settings Catalog profile (`Win Audit Policy - Baseline - Pilot`) with exact,
  ordered Intune steps and a recommended Success/Failure value for every subcategory.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new
  device fleet.
- **Tested** — a pilot-first method (**Assess → Configure → Pilot → Validate → Expand**) with explicit
  pass/fail gates, including the mandatory on-device `auditpol` and Event Viewer checks.

## What it fixes (one product, ~24 findings)
Resolves the cluster of "Configure Auditing for …" and "Audit Logon" findings a Windows client security
assessment raises — Account Logon, Account/Group Management, Logon/Logoff, Object Access (File Share,
Removable Storage), Detailed Tracking (Process Creation with command line), Privilege Use, Policy
Change, and System — plus the force-subcategory override and a right-sized Security event log.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about the override that makes it apply, the recommended
  subcategory values (CIS/Microsoft), and the event-volume trade-offs (Process Creation and File Share
  are loud).
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus
  Remediation (scaffolds the full profile) and Set-ScopeTargeting (default to `-WhatIf` preview).

## Not log forwarding — and that's on purpose
This baseline makes each endpoint *generate and retain* the right events. Getting them into a SIEM
(Azure Monitor Agent + Data Collection Rules to Microsoft Sentinel) is a **separate** solution — this is
the source, that is the transport. It is also distinct from a broad CIS/STIG hardening baseline; this is
the focused *auditing* slice.

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next wave and the next project.

## The bottom line
A consistent, baseline-aligned Windows audit trail — with command-line process auditing and a right-sized
log — on every corporate endpoint, proven on a pilot before you scale, without a consulting engagement
and without touching how the device is enrolled.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
