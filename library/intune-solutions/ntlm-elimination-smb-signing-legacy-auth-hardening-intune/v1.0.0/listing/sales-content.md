# Sales Content — NTLM Elimination & SMB Signing (Legacy Authentication Hardening)

## Hook
**Shut down the legacy authentication attackers rely on.** Eliminate NTLM and enforce SMB signing on
Windows 10/11 via an Intune Settings Catalog policy — refuse LM/NTLMv1, defeat SMB relay, close insecure
guest logons and unauthenticated RPC — deployed audit-first so nothing breaks.

## The problem
Your Windows endpoints are enrolled and managed, but they still accept and emit the weak authentication
that fuels credential theft, NTLM relay, and lateral movement: LM/NTLMv1 responses, unsigned SMB,
insecure guest logons, and unauthenticated RPC. Most tenants have never turned it off — because turning
it off blind breaks the one legacy app, NAS, or scanner that still needs NTLM. The fix isn't a risky
big-bang change; it's an **audit-first** hardening pass that finds the dependencies before it refuses
them, then enforces the exact **Local Policies\Security Options / SMB** settings that shrink the attack
surface.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune steps with full navigation paths; the policies you create
  (`NTLM-SMB Hardening - Pilot`, `NTLM Audit - Pilot`) are named and reused through testing and
  troubleshooting.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new
  device fleet.
- **Tested** — a pilot-first, audit-first method (**Assess → Configure → Pilot → Validate → Expand**)
  with explicit pass/fail gates and read-only validation scripts.

## Resolves ~7 Windows Client assessment findings
LAN Manager authentication level (refuse LM & NTLM) · NTLM SSP minimum session security (clients **and**
servers) · SMB signing (client **and** server) · insecure guest logons disabled · restrict
unauthenticated RPC — plus the enabling **Restrict NTLM: Audit** control so you enforce with eyes open.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about the audit-first / Kerberos-first posture, SMB-signing
  readiness on both ends, and cross-referencing (not rebuilding) CIS/STIG.
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus
  Remediation and Set-ScopeTargeting (default to `-WhatIf` preview).

## Focused, not a duplicate baseline
This product owns the NTLM-elimination + SMB-signing slice and cross-references the CIS Windows 11 and
DISA STIG solutions rather than rebuilding them — the legacy-auth fix without paying for, or colliding
with, a full baseline.

## The bottom line
LM/NTLMv1 refused, NTLM audited then eliminated where safe, SMB signing required on both ends, guest
logons and unauthenticated RPC shut down — a materially smaller credential-theft and relay surface,
proven on a pilot before you scale.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
