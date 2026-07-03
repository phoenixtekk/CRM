# Best Practices — Device Compliance Policies (Government / GCC High edition)

These practices keep a GCC High compliance deployment correct, auditable, and safe to expand.
They assume the objects and stages defined in `01-solution-overview.md` and
`03-implementation.md`.

## Sovereign-cloud hygiene

- **Bookmark the `.us` portals and use only those.** `intune.microsoft.us`,
  `entra.microsoft.us` / `portal.azure.us`, `portal.office365.us`. A Commercial `.com`
  bookmark opened by habit is the most common way a change lands in the wrong place — or
  appears to "not save" because you were never in your tenant.
- **Never SSL-inspect `*.manage.microsoft.us` or `*.dm.microsoft.us`.** Microsoft does not
  support TLS inspection on these; inspecting them breaks enrollment and compliance check-in.
  [[MS-GOV-EP]](gcc-high-parity-notes.md)
- **Always pass `-Environment USGov`** (or `USGovDoD`) on every `Connect-MgGraph`. Set it as a
  PowerShell default so no script can silently hit Commercial Graph. [[MS-GRAPH-ENV]](gcc-high-parity-notes.md)

## Design and naming

- **One naming convention, reused everywhere.** `CP-…-GovHigh`, `SG-…`, `MT-…-GovHigh`,
  `CA-…-GovHigh`. Consistent names make the discovery/validation scripts, audits, and
  handovers trivial.
- **Keep compliance policy and Conditional Access in lockstep.** The compliance policy is the
  *label*; Conditional Access is the *enforcement*. Never enforce CA on a population the
  compliance policy has not yet reached, or you will lock users out of resources they can't
  remediate.
- **Prefer platform-specific policies over one giant policy.** A Windows baseline
  (`CP-Win-Baseline-GovHigh`) plus separate mobile policies is easier to reason about and to
  target than a single sprawling policy.

## Handling the parity gaps

- **Treat DHA-dependent settings as unverified until proven** on your tenant (Require
  BitLocker / Secure Boot / code integrity). Microsoft's own docs disagree on GCC High
  availability — validate on a pilot device and, if they don't resolve, fall back to
  **Encryption of data storage** + **TPM**, which don't need attestation.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Confirm MTD vendor GCC High support before designing a mobile threat-level rule.** If no
  GCC-High-capable MTD partner is connected, leave the device-threat-level setting **Not
  configured** rather than assuming it will populate. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Don't design around Commercial-only features.** Chrome Enterprise Connector, Windows
  Autopilot, Microsoft Store for Business, TeamViewer/ServiceNow connectors, and several
  Windows update-reporting features are **not available** in GCC High/DoD. Verify a feature's
  GCC High status before it becomes a dependency. [[MS-GOV-SVC]](gcc-high-parity-notes.md)

## Safe rollout

- **Pilot first, always.** `SG-Compliance-Pilot` → wave groups → fleet. Gate each stage.
- **Start Conditional Access in Report-only.** Review Entra sign-in logs before switching to
  **On**. Broaden target resources toward "All cloud apps" only after the pilot is clean.
- **Keep a break-glass account excluded** from every Conditional Access policy, and test that
  it still works. A locked-out tenant with no exclusion is a self-inflicted outage.
- **Give users a grace period.** A short "mark noncompliant after 1 day" schedule plus the
  notification email lets users self-remediate before losing access, cutting help-desk load.

## Change control and evidence

- **Remediate with intent, not by hand.** Use `DCPG-Remediation.ps1` (defaults to **-WhatIf**)
  so every change is previewed and logged before it applies.
- **Re-run discovery/validation/report on a schedule.** These read-only scripts give you
  point-in-time proof the tenant still matches this design — useful for CMMC/NIST evidence and
  for catching drift.
- **Document the DHA decision.** Record whether the three Device Health settings work on your
  tenant; it is the single most tenant-specific choice in this deployment.

## Compliance-program alignment

- **Map settings to your controls.** BitLocker/encryption → media protection; firewall,
  antivirus, real-time protection → system/communications protection; minimum OS → flaw
  remediation. Keeping the mapping written down turns your compliance report into audit
  evidence for NIST SP 800-171 / CMMC. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
