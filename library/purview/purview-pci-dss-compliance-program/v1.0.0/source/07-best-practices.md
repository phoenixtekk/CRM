# 7. Best Practices — Microsoft Purview PCI-DSS Compliance Program

- **Let the QSA/compliance owners scope the CDE — not the technical team.** *Which* systems are in the
  Cardholder Data Environment, *which* SAQ/version applies, and *whether* the evidence satisfies the
  standard are **QSA/compliance/legal determinations**. The tool provides method, score, and evidence —
  not the attestation. Record the scope decision in `PCI Scope – Record` and configure to it.
- **Pilot cardholder-data DLP in simulation, always.** Deploy `DLP-PCI-CardholderData` in
  **`TestWithNotifications`/`TestWithoutNotifications` (simulation)** first. It audits and notifies but
  never blocks, so you see what *would* be caught with zero user impact. Only move to **enforce** after
  the simulation is validated and tuned — enforcing a card-number block blind can break legitimate
  payment operations.
- **Tune for precision before you enforce.** The Credit Card Number SIT uses a Luhn checksum plus
  context, but 16-digit order IDs and test data still cause noise. Raise the rule's confidence/instance
  threshold and add context requirements until the simulation flags real PAN and little else — then
  enforce.
- **Enable and retain the audit log — it *is* Requirement 10.** Keep unified audit logging **on** and
  retained to your PCI-DSS version's figure (Audit (Premium) for extended/custom retention). Disabling
  it fails Req 10 at the source; `CMPPCI-Validation.ps1` is your on-going check.
- **Least privilege and separation are Requirement 7 applied to yourselves.** Keep **Administrators**
  separate from **Contributors**, and keep **Readers/auditors/QSA** read-only. Manage membership with
  `CMPPCI-Set-Scope.ps1` (`-WhatIf` then `-Commit`) and re-snapshot with `CMPPCI-Discovery.ps1` —
  membership drifts as people join and leave.
- **Evidence is the deliverable a QSA wants.** Attach documentation, test results, an owner, and a test
  date to each action. The score is only defensible with the proof behind it — `PCI Evidence –
  Register` is the audit-ready record. Record Requirement 3 as *piloted, pending enforcement* until the
  DLP is actually enforcing.
- **Represent the whole standard, even what Purview can't enforce.** Firewalls, segmentation, physical
  security, anti-malware, and vulnerability/penetration testing live in other systems — track them as
  **evidence links** in Compliance Manager so `PCI Assessment` reflects the complete requirement set,
  not just the Purview slice.
- **Lean on control mapping.** Implement a shared control once (unified audit logging, least-privilege
  access) and let it score across PCI-DSS, NIST, ISO, and your internal baseline. Prioritize
  **high-point, widely-mapped** actions, and when you add a framework only do the *gap*.
- **Never mark a control implemented without proof.** A false "implemented" inflates the score and fails
  the first QSA review. If the DLP is only in simulation, Req 3 is not "implemented"; if audit logging
  is off, Req 10 is not met — `CMPPCI-Validation.ps1` is your cross-check against wishful status.
- **Always dry-run automation.** `CMPPCI-Configuration.ps1` and `CMPPCI-Set-Scope.ps1` default to
  **`-WhatIf`**. Read every line of the planned change — especially the DLP policy definition and any
  mode change from simulation to enforce — and run `-Commit` only after the output is right. The
  discovery, validation, and report scripts are read-only.
- **Never store or log real PAN in test.** Use standard **synthetic test card numbers** for DLP
  validation, never a real cardholder's account number, and keep test data out of scripts and logs.
  Treat DLP matches as signals to review, not proof — detection is pattern-based and can err.
- **Watch for PCI-DSS version and template updates.** PCI-DSS evolves (v4.x introduced new
  requirements); Microsoft updates the PCI-DSS assessment template accordingly. A template/version
  update can add controls and move your score — review on a cadence and re-baseline affected
  assessments.
- **Verify licensing and availability against your tenant.** The PCI-DSS template, endpoint DLP,
  auto-labeling, and Audit (Premium) are entitlement-gated; GCC/GCC High may differ. Confirm — never
  assume a template or feature is available.
- **The portal is authoritative.** Assessments, evidence upload, DLP simulation results, and the
  official score/export live in the Purview portal; the scripts assess readiness, configure the DLP in
  simulation, validate technical evidence, and report — they support the portal, they don't replace it.
