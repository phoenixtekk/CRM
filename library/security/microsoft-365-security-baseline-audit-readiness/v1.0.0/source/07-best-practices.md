# 7. Best Practices — Microsoft 365 Security Baseline & Audit Readiness

- **Write the baseline down.** A documented baseline register (`M365 Security Baseline Register –
  Tenant Services – Baseline`) with a desired value and rationale per setting is what makes the
  posture repeatable and auditable — not tribal knowledge.
- **Pilot every change.** Scope Conditional Access, DLP, and preset policies to `M365 Baseline Scope
  – Pilot – Users` first; sign-in, mail flow, and sharing are easy to break tenant-wide.
- **Measure with Secure Score, don't stop there.** Use Secure Score to drive and track improvement,
  but pair it with the Compliance Manager framework assessment — the score is a measure, the
  assessment is the mapping an auditor reads.
- **Map controls once, maintain forever.** Keep `Compliance Assessment – Target Framework – Mapping`
  current so improvement-action status reflects reality instead of drifting.
- **Capture evidence as you configure.** File dated evidence into `Control Evidence Pack – Tenant
  Baseline – Audit` at the moment you make each change; reconstructing evidence at audit time is the
  fire drill this solution exists to remove.
- **Least privilege for operators.** Use Security Administrator plus scoped service-admin roles;
  reserve Global Administrator for genuinely tenant-wide changes.
- **One baseline owner.** A named owner keeps the register authoritative and prevents silent drift.
- **Re-validate on a cadence.** Run `M365SEC-Validation.ps1` and `M365SEC-Report.ps1` on a set
  schedule so posture and evidence stay current between audits.
- **Remediate safely.** Run `M365SEC-Remediation.ps1` in its default `-WhatIf` mode, review the
  proposed changes, then apply — never blind-apply security changes.
- **Keep this distinct from endpoint hardening.** This baselines the M365 tenant/service layer; the
  CIS/STIG endpoint baseline is a separate control set — track them separately so neither hides gaps
  in the other.
