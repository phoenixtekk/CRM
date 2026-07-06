# 7. Best Practices — Regulated Google Workspace: Assured Controls, ITAR & DFARS (Evidence & Audit)

Practices for running a controlled-data Workspace configuration that is **defensible** — with the
evidence and audit trail an assessor expects. The theme throughout: **configure once, name it, apply it
by scope, and prove it.** Regulatory **interpretation stays with legal/compliance**; these practices
keep the **technical evidence** clean.

## Governance & interpretation
- **Keep the interpretation owner explicit.** Every "which region / which policy / is CSE required"
  decision is recorded against a named legal/compliance owner and an approval date. The technical team
  configures to the approved requirement — it does not decide the requirement.
- **Separate "configured" from "compliant."** Your reports state *technical coverage* ("Access
  Management = U.S.-only, applied to OU X, licensed"), never "ITAR compliant." Compliance is legal's
  written determination on top of the evidence.
- **Re-review on regime or contract change.** ITAR/DFARS interpretations, Google SKUs, and
  Access-Management policy options evolve — schedule a periodic re-confirmation and flag
  add-on/edition-gated items as **"verify in your tenant."**

## Scope & configuration discipline
- **Name and reuse configurations.** Use stable names — `RES-US-Controlled`, `AXM-US-Controlled` /
  `AXM-CJIS-Controlled` — and apply them verbatim across every controlled OU so the fleet is
  consistent and auditable. Never hand-tune per OU.
- **Right-size the controlled scope.** Apply residency and support-access restrictions to the
  **controlled-data OUs only** (from the data classification, requirement 2.3) — over-broad application
  is disruptive; too-narrow leaves data exposed.
- **Verify licensing before applying Access Management.** The policy silently does not apply to
  unlicensed OUs — confirm Assured Controls licensing on every OU you target.
- **Pilot everything; roll back cleanly.** Prove each control on the pilot OU with a documented rollback
  before touching the wider fleet; residency and CSE changes are high-impact.

## Evidence & audit
- **Treat Access Transparency as the primary provider-access evidence.** It logs Google-staff access
  allowed via Access Management / Access Approvals — route it to your SIEM/evidence store with the
  retention the regime requires (requirement 2.8).
- **Collect the bundled evidence features.** Enable and retain **policy-compliance log events**,
  **data-regions advanced reporting**, and **compliance data exports** — these are the coverage proof
  the add-on provides.
- **Snapshot coverage on a cadence.** Run `GWREG-Report.ps1` on a schedule (and before each audit) so
  you have a dated coverage/evidence record per controlled OU; keep the history.
- **Validate continuously, not just at go-live.** Re-run `GWREG-Validation.ps1` after any change and on a
  cadence to catch drift (an OU added without the policy, a region reverted, a license lapse).
- **Keep change records.** Every residency/access/CSE change ties to a change ticket with approver,
  window, and rollback — the audit trail is the ticket **plus** the before/after validation output.

## Operational safety
- **Default to read-only / `-WhatIf`.** Discovery, Validation, and Report are read-only; Remediation and
  Set-ScopeTargeting default to `-WhatIf` — preview and get approval before executing.
- **Least privilege.** Reserve super-admin for the Access-Management change; use scoped compliance/data
  admin roles for Data regions, Access Approvals, and CSE.
- **Protect CSE keys and account for functional tradeoffs.** If CSE is relied upon, key-service
  ownership and availability are part of the control — and some features cannot read CSE content, so
  scope deliberately and document the tradeoffs for users.
- **Never publish secrets in evidence.** Coverage reports record *that* a control is configured and its
  scope — never keys, tokens, or credentials.

## Anti-patterns to avoid
- Declaring "ITAR/DFARS compliant" from a script pass — that is legal's determination.
- Applying Access Management to an **unlicensed** OU and assuming it took effect.
- Expanding fleet-wide before a pilot pass **and** legal sign-off.
- Disabling cross-region processing or enabling CSE tenant-wide without piloting the functional impact.
- Inventing an Access-Management policy option or Assured Controls feature not in Google's documentation
  — cite or flag "verify in your tenant" instead.
