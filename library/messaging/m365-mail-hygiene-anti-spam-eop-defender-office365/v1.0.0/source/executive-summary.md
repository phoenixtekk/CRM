# Executive Summary

**Outcome.** Microsoft 365 mail hygiene is configured and tuned so that phishing, spoofing, malware,
and malicious links/attachments are **blocked**, while legitimate business mail **flows without being
wrongly quarantined**. Default, out-of-the-box filtering lets threats through *and* traps good mail —
both erode trust. This solution fixes both.

**Approach.** It configures the two layers of the Microsoft cloud email-security stack:
**Exchange Online Protection (EOP)** — anti-spam, anti-malware, connection filtering, and
anti-spoofing (available to every Exchange Online tenant) — and, where licensed, **Microsoft
Defender for Office 365** — anti-phishing (impersonation protection), **Safe Links**, and **Safe
Attachments**. It applies Microsoft's recommended **preset security policies** (Standard, with Strict
for high-risk roles) rather than hand-built policies where possible, governs **quarantine** with
notifications and right-sized release permissions, and manages every exception through the supported
**Tenant Allow/Block List** — retiring the legacy `SCL -1` transport rules that silently defeat
filtering.

**Why it is low-risk.** Mail-hygiene changes are high-impact to production mail, so the work follows
a disciplined **Assess → Design → Configure → Pilot → Validate → Expand** model: a read-only
assessment captures the rollback baseline, all changes are staged on a **pilot scope** first,
explicit **pass/fail gates** (threats blocked, false-positive rate low, quarantine reviewed) must be
met before expansion, and a **documented rollback** exists at every step. Five PowerShell tools
(Exchange Online PowerShell V3 / Microsoft Graph) assess, help configure, validate, and report — all
**read-only or dry-run (`-WhatIf`) by default**, with no stored credentials.

**One critical caveat, surfaced up front.** Advanced protections — anti-phishing impersonation, Safe
Links, and Safe Attachments — **require Defender for Office 365 (Plan 1 or 2)** and do not exist on
an EOP-only tenant. **Verify the tenant's plan and cloud (Commercial vs Government) before
starting.** The solution delivers substantial value on EOP alone and flags every plan-dependent step.

The result: hygiene that stops threats and passes good mail — tuned to a proven baseline, quarantine
governed, false positives down — self-guided and validated at a fraction of consulting cost.
