# 8. Deliverables Summary — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## What you receive
A complete, self-guided package to configure **label-based encryption and usage rights for Office
documents and PDFs** in Microsoft Purview — so protection travels with the file — piloted on a ring,
validated, then expanded, using the Microsoft Purview portal, Security & Compliance PowerShell, and the
AIPService module. Includes the recovery (super-user) and evidence path.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The rights-protection levers (RMS activation, label encryption, usage rights, DNF/Encrypt-Only, offline/expiry, Office+PDF coverage), assigned-vs-user-defined design, the protection-label design, the naming convention, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (existing label taxonomy, licensing for label encryption, Information Protection role + RMS/Global Admin for activation, S&C PowerShell + AIPService, RMS activated, IRM enabled for the workloads + PDF handling, a pilot ring, and a super-user/recovery and named-audience decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess RMS + posture → confirm activation + super-user recovery → design labels/rights → prepare pilot policy → configure the template, user-defined, and named-recipient labels → publish to the pilot ring → validate (Office + PDF, right vs wrong, recovery) → expand to broad → operate. Each step named, gated, reversible; `-WhatIf` before every commit; pilot-first (no simulation). |
| **Testing & Validation Guide** | 10 pass/fail tests — RMS activated + recoverable, effective encryption per label, template label protects for the right audience, wrong recipient denied, view-only restricts print/copy, DNF/Encrypt-Only, protected PDF honored, super-user recovery, expiry/offline, and broad == accepted pilot. |
| **Best Practices** | Designing least-privilege usage rights, no-simulation rollout discipline, recovery/revocation/continuity, Office+PDF specifics, avoiding drift/conflicts, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (label won't encrypt, RMS not activated, wrong recipient can open, view-only can still print, DNF not honored, PDF opens unprotected, super-user can't recover, external can't open) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell) and/or `Connect-AipService`
(AIPService); read-only or `-WhatIf` by default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `IPRMS-Discovery.ps1` | **Posture assessment** — report the RMS/Rights Management service state, which labels have encryption enabled and their protection type, usage rights, offline/expiry, the super-user group, and Exchange IRM state. | Read-only |
| `IPRMS-LabelProtection.ps1` | **Configuration / remediation helper** — create the pilot policy, set a label to **template (assigned)** rights, set a label to **user-defined** (Do Not Forward / Encrypt-Only), set offline-access and content-expiry, publish labels to a policy, and remove protection (rollback). | `-WhatIf` |
| `IPRMS-Validation.ps1` | **Effective-settings validation** — confirm a label's resolved encryption settings (enabled, protection type, rights definition, offline days, expiry) match the signed-off design. | Read-only |
| `IPRMS-Report.ps1` | **Posture matrix / evidence** — export the protection matrix across all labels (encryption on/off, type, rights, offline, expiry) plus RMS activation and super-user state to CSV. | Read-only |
| `IPRMS-Readiness.ps1` | **Scope/health helper** — check RMS activated, super-user configured, Exchange IRM enabled, licensing signal, and pilot-scope sanity (protection labels left only in the pilot policy). | Read-only |

## Outcomes
- A signed-off set of **protection labels** configured in the tenant — encryption + the right usage
  rights per audience, so protection travels with Office **and** PDF files.
- A confirmed **recovery path** (super-user) so encrypted content is never unrecoverable, and a known
  revocation path.
- Protection **piloted on a ring** and validated (right people open, wrong people denied, PDF covered)
  before broad publish — the safe substitute for a non-existent simulation mode.
- Repeatable read-only tooling to report the protection posture and catch RMS/IRM/super-user drift.

## Explicitly out of scope (deferred)
- **The label taxonomy, content marking, DLP, retention, and auto-labeling at scale** — assumed to exist
  or covered by separate Purview solutions; this solution configures *encryption and rights* over the
  labels.
- **Double Key Encryption (DKE) and HYOK** — separate builds; this covers cloud-based RMS label encryption.
- **Who may access what, content-expiry rules, and how encrypted content is preserved/produced for
  legal-hold/eDiscovery** — governance and legal determinations owned by compliance/security/records/
  legal; this solution provides the configuration method, recovery method, and evidence.
- Any capability your **licensing/tenant/PDF-reader** does not include — verify before relying on label
  encryption, PDF protection, or external sharing.
