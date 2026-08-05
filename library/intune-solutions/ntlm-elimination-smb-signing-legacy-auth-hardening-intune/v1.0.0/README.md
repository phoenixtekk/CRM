# NTLM Elimination & SMB Signing — Legacy Authentication Hardening (Intune)

**Category:** Intune Solutions · **Solution code:** NTLMHARD · **Version:** 1.0.0 · **Status:** generated

Eliminates **NTLM** (LM/NTLMv1 first, then NTLM) and enforces **SMB signing** on **Intune-managed Windows
10/11** endpoints via a **Settings Catalog** policy, using the exact Local Policies\Security Options / MS
Security Guide / SMB settings that harden the authentication stack. Deployed **audit-first** (Restrict
NTLM: Audit) so dependencies are found before enforcement, pilot-first, and reversible. Resolves ~7
Windows Client assessment findings.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-NTLMHARD-COMM-001 | Commercial | $2,795.00 |
| PTK-NTLMHARD-NPO-001  | Non-Profit (−40%) | $1,677.00 |
| PTK-NTLMHARD-GOV-001  | Government (−15%) | $2,375.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `NTLMHARD-Discovery.ps1`, `NTLMHARD-Validation.ps1`, `NTLMHARD-Report.ps1`,
  `NTLMHARD-Remediation.ps1`, `NTLMHARD-Set-ScopeTargeting.ps1` (read-only discovery/validation/reporting;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `NTLMHARD-Solution.docx`, `NTLMHARD-Solution.pdf`, `NTLMHARD-Scripts.zip`,
  `NTLMHARD-hero.png`.

## The ~7 findings resolved
1. LAN Manager authentication level → *Send NTLMv2 only. Refuse LM & NTLM* (`LmCompatibilityLevel=5`).
2. NTLM SSP min session security — **clients** (NTLMv2 + 128-bit, `NtlmMinClientSec=0x20080000`).
3. NTLM SSP min session security — **servers** (`NtlmMinServerSec=0x20080000`).
4. SMB signing — **client** (*digitally sign communications (always)* = Enabled).
5. SMB signing — **server** (`RequireSecuritySignature=1`).
6. Insecure guest logons disabled (`AllowInsecureGuestAuth=0`).
7. Restrict unauthenticated RPC clients → Authenticated (`RestrictRemoteClients=1`).

Plus the enabling **Restrict NTLM: Audit** (in-domain + outgoing) so NTLM usage is discovered before it
is refused.

## Named objects (reused across the guide)
- **`NTLM-SMB Hardening - Pilot`** — the enforcement Settings Catalog policy.
- **`NTLM Audit - Pilot`** — the audit-first NTLM discovery policy.

## Scope notes
- **Gap-only:** owns the NTLM-elimination + SMB-signing slice; **cross-references** (does not rebuild)
  the CIS Windows 11 and DISA STIG baselines. Endpoint (client/member) side only — not
  domain-controller NTLM policy or Kerberos infrastructure.
- **Audit-first / Kerberos-first:** aligned with Microsoft's NTLM deprecation direction.
- **Verify-in-tenant:** exact Settings Catalog display strings flagged where uncertain; stable identity
  is the registry value.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
deliverables/      built DOCX/PDF/ZIP + hero PNG/SVG
solution.meta.json
```

Next: `/publish-solution ntlm-elimination-smb-signing-legacy-auth-hardening-intune`
