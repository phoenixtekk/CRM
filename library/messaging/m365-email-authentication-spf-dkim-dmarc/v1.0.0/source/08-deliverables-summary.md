# Deliverables Summary

This solution delivers a complete, self-guided package to implement SPF, DKIM, and DMARC on a
Microsoft 365 domain — and reach DMARC enforcement (`p=reject`) without breaking legitimate mail.

## Documentation

- **Solution Overview** — SPF/DKIM/DMARC and alignment, the Exchange Online DKIM model (CNAMEs +
  rotation), third-party sender handling, and the monitor→enforce journey.
- **Requirements Guide** — the solution-specific prerequisites (sender inventory, accepted/verified
  domains, tenant initial domain & Domain GUID, DNS TXT/CNAME support, third-party alignment methods,
  RUA destination, Exchange Administrator role), each with how to *verify* and *implement*, referencing
  the shared messaging global requirements.
- **Implementation Guide** — exact ordered steps across Assess → Design → Configure → Pilot → Validate →
  Expand, with every artifact named, pass/fail gates, and a rollback at each DNS/auth change.
- **Testing & Validation** — eight tests (T1–T8), each with an explicit pass/fail, including the
  enforcement gate.
- **Troubleshooting** — common failure modes (SPF >10 lookups, DKIM CNAME/`onmicrosoft` alignment,
  DMARC failures, forwarding, no reports, GCC High differences) with resolutions.
- **Best Practices** — durable guidance for reaching and holding `p=reject` safely.
- **Executive Summary** — outcome, approach, and why the rollout is low-risk.

## PowerShell scripts (Exchange Online PowerShell / Microsoft Graph)

All are **read-only or `-WhatIf`/`-Commit`-gated by default**, use modern auth
(`Connect-ExchangeOnline`), and contain **no hardcoded credentials or secrets**.

1. **`Get-EmailAuthPosture.ps1`** — *Discovery (read-only).* Baselines SPF (record count, lookup
   estimate, all-qualifier), DKIM (enabled/status, CNAME resolution), and DMARC (policy, RUA) across all
   accepted domains.
2. **`Set-DkimSigning.ps1`** — *Configuration/Remediation (safe by default).* Shows the exact Selector1/2
   CNAME targets and, only with `-Commit`, enables DKIM (`Set-DkimSigningConfig -Enabled $true`) or, with
   `-Rotate`, rotates keys (`Rotate-DkimSigningConfig`). Supports `-WhatIf`.
3. **`Invoke-DmarcReportAnalysis.ps1`** — *Reporting (read-only).* Parses DMARC aggregate (RUA) report
   XML and rolls up by source IP with SPF/DKIM alignment and DMARC pass %; `-FailingOnly` surfaces the
   enforcement-blocking sources.
4. **`Test-EmailAuthAlignment.ps1`** — *Validation (read-only).* Emits a green/red report per domain:
   SPF scoped (≤10 lookups), DKIM Valid with resolving CNAMEs, DMARC present — the enforcement go/no-go.
5. **`Get-SpfLookupHealth.ps1`** — *Scope/health helper (read-only).* Recursively resolves the SPF
   record, counts real DNS lookups against the 10-lookup limit, and prints the include tree so you can
   see which sender consumes the budget.

## Packaged artifacts

- `M365AUTH-Solution.pdf` — the compiled solution document (all sections above).
- `M365AUTH-Scripts.zip` — the five PowerShell scripts.
