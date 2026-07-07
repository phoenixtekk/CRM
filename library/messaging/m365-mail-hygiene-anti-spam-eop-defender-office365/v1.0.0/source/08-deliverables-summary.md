# Deliverables Summary

This solution delivers a complete, self-guided package to configure and tune Microsoft 365 mail
hygiene (EOP + Defender for Office 365), plus five PowerShell tools. Everything is white-label and
safe-by-default.

## Documentation

- **Solution Overview** — the hygiene stack (EOP anti-spam/malware/spoof, Defender for Office 365
  anti-phish/Safe Links/Safe Attachments), preset vs custom policies, quarantine, reference design,
  benefits, limitations, and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (confirmed EOP/Defender for Office 365
  licensing; SPF/DKIM/DMARC; pilot scope; test mailbox + safe test artifacts; quarantine owner; a
  captured before-state including filter-bypassing transport rules; Government-cloud confirmation),
  each with how to verify/implement, on top of the shared messaging requirements.
- **Implementation Guide** — exact ordered steps (portal paths **and** EXO PowerShell cmdlets)
  through Assess → Design → Configure → Pilot → Validate → Expand, every artifact named, with
  pass/fail gates and a rollback.
- **Testing & Validation** — nine procedures (GTUBE spam, EICAR malware, spoof, bulk/BCL, Safe
  Attachments, Safe Links, quarantine notify/release, TABL behavior, and a false-positive gate),
  each with expected pass/fail.
- **Troubleshooting** — common failure modes and resolutions.
- **Best Practices** — durable hygiene tuning, quarantine/allow-block governance, licensing
  discipline, and false-positive minimization.

## PowerShell tools (5) — EXO V3 / Microsoft Graph, read-only or `-WhatIf` by default

1. **`Get-MailHygieneAssessment.ps1`** — *Discovery / assessment (read-only).* Exports the current
   hygiene posture — anti-spam, anti-malware, anti-phish, Safe Links/Attachments, connection filter,
   quarantine policies, preset state, Tenant Allow/Block List — and flags risky legacy mail-flow
   rules (e.g. `SCL -1` bypasses) and gaps against the Standard baseline. Produces the rollback
   baseline. Never changes anything.

2. **`Set-MailHygieneBaseline.ps1`** — *Configuration helper (safe-by-default, `-WhatIf`).* Helps
   apply/tune the baseline: scope the Standard preset to a pilot group, or create the named custom
   anti-spam/anti-malware/anti-phish policies and the quarantine policy. **Dry-run by default** — it
   only makes changes when `-Commit` is passed; otherwise it reports the intended actions via
   `-WhatIf`. No stored credentials.

3. **`Test-MailHygienePolicy.ps1`** — *Validation (read-only).* Verifies that the expected policies
   exist and are scoped correctly, the quarantine actions are set, TABL entries are present, and
   SPF/DKIM/DMARC authentication posture is healthy — summarizing pass/fail for the validation gates.

4. **`Get-QuarantineAndAllowBlockReport.ps1`** — *Reporting (read-only).* Produces the quarantine
   review report and the Tenant Allow/Block List review (including stale/expiring allows) for the
   review owner, plus a false-positive / spoof-intelligence oriented summary from message data.

5. **`Get-MailHygieneScopeHealth.ps1`** — *Scope / health helper (read-only).* Resolves which policy
   actually applies to a given user (policy precedence), lists preset scope and custom policy
   priorities, and reports connection-filter and Enhanced-Filtering-for-Connectors state — the helper
   used to answer "why did this user get this verdict?".

> All scripts require the **ExchangeOnlineManagement (EXO V3)** module (and **Microsoft Graph
> PowerShell** where noted); connect with modern-auth `Connect-ExchangeOnline` / `Connect-MgGraph`.
> **No hardcoded credentials or secrets.** Writes are gated behind an explicit switch.
