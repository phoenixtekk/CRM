# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — ADFS federation for Microsoft 365 (claims, token-signing certs, WAP,
  endpoints, the Entra federation trust), its failure modes, and the managed-auth alternatives (PHS/PTA +
  Seamless SSO) with the staged-migration model and the `Assess → Design → Configure → Pilot → Validate →
  Expand` deployment model.
- **Requirements Guide** — the solution-specific prerequisites (Entra Connect health, Global/Hybrid
  Identity Admin, ADFS/WAP access, federation & cert visibility, chosen managed method, Conditional
  Access parity, pilot group + change window), building on the shared Messaging global requirements.
- **Implementation Guide** — the ordered steps split into **Track A** (deploy/troubleshoot ADFS: claims
  rules, token-signing cert rollover, endpoints/WAP) and **Track B** (migrate: enable PHS/PTA + Seamless
  SSO, Staged Rollout pilot, convert domains federated→managed, decommission ADFS/WAP) — pilot-first,
  with pass/fail gates and a rollback table.
- **Testing & Validation** — ten validation procedures (T1–T10), each with an explicit pass/fail signal,
  tied to the implementation gates.
- **Troubleshooting** — the common ADFS/federation and migration failure modes and their resolutions.
- **Best Practices** — durable practices for federation health, choosing/running managed auth, migration
  discipline, and tooling/security hygiene.
- **Executive Summary** — the outcome, approach, and why the change is low-risk.

## PowerShell scripts (5)

All scripts use modern-auth interactive sign-in (`Connect-MgGraph` / `Connect-ExchangeOnline`) — **no
stored credentials** — and are **safe-by-default** (read-only, or `-WhatIf` unless an explicit
`-Commit`/`-Apply` switch is passed).

1. **`Get-M365FederationAssessment.ps1`** *(Discovery — read-only)* — produces `Federation Assessment –
   M365 – Prod`: enumerates each domain's authentication type and, for federated domains, the Entra
   federation trust (issuer, endpoints, trusted signing certificate thumbprint + expiry). Flags certs
   expiring within a threshold. Read-only.
2. **`Invoke-TokenSigningCertRollover.ps1`** *(Remediation — `-WhatIf` by default)* — previews (and, with
   `-Commit`, performs) the `Token-Signing Cert – ADFS – Rollover`: reports current ADFS token-signing
   certs vs the Entra-trusted cert and the Entra federation-metadata update needed so Entra trusts the
   new cert. Defaults to a dry run.
3. **`Test-CloudAuthSignIn.ps1`** *(Validation — read-only)* — reports the effective sign-in method per
   domain and, for the Staged Rollout pilot, checks the target managed method (PHS/PTA) and Seamless SSO
   readiness so you can confirm pilot users authenticate via the cloud. Read-only.
4. **`Get-M365SignInMethodReport.ps1`** *(Reporting — read-only)* — a consolidated report of every
   domain's authentication type (Federated/Managed), the tenant sign-in method (PHS/PTA/Seamless SSO
   status), and Staged Rollout groups, exportable to CSV for the change record. Read-only.
5. **`Invoke-DomainConversionPlan.ps1`** *(Scope/health helper — `-WhatIf` by default)* — previews (and,
   with `-Commit`, performs) the `Domain Conversion – <domain> – Managed`: validates prerequisites
   (managed method enabled, pilot validated), shows the federated→managed conversion plan and rollback,
   and only converts when explicitly committed. Defaults to a dry run.
