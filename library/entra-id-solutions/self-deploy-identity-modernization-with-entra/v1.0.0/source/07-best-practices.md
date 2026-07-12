# 7. Best Practices & Where to Go Next — Self-Deploy: Identity Modernization with Entra

## Running the kit cleanly
- **Train in a lab, not in production.** Use a non-production tenant if you have one. If you must use
  production, keep every control **report-only / preview** and scoped only to
  `Identity Modernization – Pilot – Lab`. Never scope a lab policy to all users.
- **Break-glass first, always.** Confirm two excluded emergency-access accounts before building any
  policy, and re-confirm they are excluded from every lab policy.
- **Preview before commit.** The change helper (`EKIDMOD-LabSetup.ps1`) defaults to `-WhatIf`; read
  the preview, then run with `-Commit`. Tear down with `-Remove` (preview first) when finished.
- **One building block at a time.** Work the labs in order; do not stack multiple new controls on the
  pilot group at once, or you cannot attribute an effect to a cause.
- **Least-privilege Graph scopes.** Consent only to the read scopes the scripts request; use a
  non-privileged operator identity for discovery/reporting.

## Modernization principles the team should carry forward
- **Report-only → pilot → rings → all.** Every real change follows the same staged path with pass/fail
  gates; this is the deployment model (**Assess → Configure → Pilot → Validate → Expand**) applied to
  each building block.
- **Signal-driven, not rule-sprawl.** Prefer a small number of well-scoped Conditional Access policies
  driven by risk and device signals over many overlapping legacy rules.
- **Phishing-resistant is the destination.** Treat passwordless / FIDO2 / Windows Hello for Business as
  the target, with legacy MFA as a stepping stone, not the finish line.
- **Least privilege by default.** Put privileged roles behind PIM (eligible, time-bound, approved) and
  govern access with reviews and access packages, not standing membership.
- **Coexist deliberately, retire legacy on evidence.** Keep hybrid sync healthy through the transition;
  convert federated domains to cloud auth via staged rollout; decommission AD FS only once nothing
  depends on it.
- **Measure.** Re-run the discovery and scorecard on a cadence so modernization progress is visible and
  defensible.
- **Defer the decisions that are not yours.** Regulatory, records, legal, data-classification, and
  production change-approval calls belong to the customer's compliance / security / operations
  functions — the kit supplies the technical controls, not those determinations.

## Where to go next (adjacent catalog areas)
When the team is ready to implement in production, hand each building block to its dedicated solution:

- **Conditional Access baseline** → *Zero Trust Conditional Access baseline* (ENTZTCA).
- **Identity Protection / risk-based CA** → *Entra Identity Protection & Advanced Conditional Access*.
- **Passwordless** → *Entra Passwordless / FIDO2 passkey rollout* (ENTPASSKEY).
- **Governance** → *Entra ID Governance — PIM & Access Reviews / Entitlement* (ENTPIM / ENTIGA).
- **Hybrid / coexistence** → *Hybrid Identity with AD & Entra Connect* (HYBID) and the
  *Self-Deploy — Hybrid Identity* (EKHYBID).
- **Application modernization** → *Enterprise App & Service Principal Governance* and the
  *SAML App Factory*.
- **Network Zero Trust** → the *Global Secure Access* solution.
- **Verifiable credentials** → the *Entra Verified ID* solution.

Continue the enablement track with the other Entra self-deploys (Identity Fundamentals, MFA &
Conditional Access, Hybrid Identity) to round out the team's coverage.
