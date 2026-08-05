# 8. Deliverables Summary — NTLM Elimination & SMB Signing

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: a focused
  NTLM-elimination + SMB-signing hardening policy for Windows 10/11 endpoints, audit-first, that resolves
  ~7 legacy-auth findings and cross-references (not rebuilds) CIS/STIG.
- **Solution Overview** — the threat this closes (LM/NTLMv1, NTLM relay, unsigned SMB, guest logons,
  unauthenticated RPC), the exact settings and their registry anchors, where they live in the Settings
  Catalog, and the audit-first / Kerberos-first posture aligned with Microsoft's NTLM deprecation.
- **Requirements Guide** — every Intune/Windows/identity prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: assess, **audit
  NTLM first**, build the `NTLM-SMB Hardening - Pilot` Settings Catalog policy (seven settings), pilot,
  then validate and expand.
- **Testing & Validation** — nine tests with explicit pass/fail gates (including registry-anchor checks
  and a negative baseline-conflict test) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for policy-not-applying, broken shares, NTLM-dependent apps,
  Kerberos fallback, RPC breakage, and baseline conflicts.
- **Best Practices** — audit-before-enforce, move-to-Kerberos, SMB signing on both ends, conservative RPC
  restriction, owning only your slice vs CIS/STIG, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `NTLMHARD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK); each
has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and Report are
**read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first, then apply).

1. **`NTLMHARD-Discovery.ps1`** — tenant readiness: a Settings Catalog policy carrying the NTLM/SMB
   legacy-auth settings is present with the correct values, and reports the current NTLM/SMB posture.
2. **`NTLMHARD-Validation.ps1`** — validates the policy's **assignment** and per-device **applied** state,
   with a clear PASS/FAIL summary.
3. **`NTLMHARD-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the NTLM/SMB
   hardening policy is applied — the coverage report.
4. **`NTLMHARD-Remediation.ps1`** — safe remediation: scaffolds the Settings Catalog hardening policy if
   missing (with the seven settings) and assigns it to a target group. **`-WhatIf` by default**; applies
   only when re-run to commit.
5. **`NTLMHARD-Set-ScopeTargeting.ps1`** — sets/adjusts the policy's group assignment (target-group
   builder), with optional exclusion group. **`-WhatIf` by default.**

## Hero image
- **`NTLMHARD-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
