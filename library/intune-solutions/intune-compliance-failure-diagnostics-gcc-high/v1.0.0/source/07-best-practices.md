# 7. Best Practices — Compliance-Failure Diagnostics (Government / GCC High)

Operating principles for diagnosing and remediating Intune compliance on a US sovereign-cloud tenant.
They exist to prevent the two failure modes unique to GCC High: **silent wrong-cloud errors** and
**chasing parity gaps as if they were bugs.**

## Sovereign-cloud hygiene
- **Bookmark the `*.us` portals; delete the `.com` ones.** `intune.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`, `security.microsoft.us`, `compliance.microsoft.us`,
  `portal.manage.microsoft.us`. A `.com` bookmark is how a wrong-cloud diagnosis starts.
- **Always pass `-Environment USGov`** (DoD: `USGovDoD`) to `Connect-MgGraph`. Bake it into every
  script and runbook; empty Graph output on GCC High is almost always a missing `-Environment`.
- **Never SSL-inspect** `*.manage.microsoft.us` or `*.dm.microsoft.us`. Add explicit proxy exclusions
  and treat any new TLS-inspection rule as a change that can silently break compliance check-in.

## Diagnose before you change
- **Start from the symptom, not the setting.** Use the Branch A–E tree; capture the exact state with
  Discovery/Report before touching a policy.
- **Confirm the feature exists in GCC High first.** Before "fixing" a failing rule, check it against
  `gcc-high-parity-notes.md`. A rule tied to an absent/planned Gov feature (MTD vendor not in Gov,
  classic Autopilot, an expanded DHA capability, Cloud PKI, Remote Help) can't be fixed — it must be
  removed or replaced.
- **One variable at a time.** Change a single setting, force sync, re-evaluate. Batching changes hides
  which one fixed (or broke) compliance.

## Safety and change control
- **Pilot every fix** on one device or a small group before expanding. A compliance change that flips a
  fleet to **Not compliant** blocks every user simultaneously through Conditional Access.
- **Keep Remediation and Set-ScopeTargeting in `-WhatIf` until reviewed.** Read the planned actions;
  execute only with an explicit `-Execute` (or `-WhatIf:$false`) after the pilot passes.
- **Expand in waves**, re-validating each wave. Confirm the escrow/attestation dependency (for
  DHA-backed rules) per wave.

## Grace periods and Conditional Access
- **Set grace periods deliberately.** Too long hides real failures; too short blocks users mid-fix.
- **Fix CA problems in CA, compliance problems in compliance.** If a device is Compliant but blocked,
  the answer is in `portal.azure.us` Conditional Access + sign-in logs — not in the compliance policy.
- **Account for propagation lag.** A just-compliant device may need a sign-out/in before CA sees it.

## Evidence and least privilege
- **Trust the portal as source of truth.** A script result isn't "done" until `intune.microsoft.us`
  agrees. Keep Discovery/Report output as before/after evidence for change records.
- **Use Intune Administrator, not Global Administrator**, for day-to-day diagnosis. Reserve GA for
  tenant-wide changes. The scripts run read-only (Discovery/Validation/Report) or preview-first
  (Remediation/Set-ScopeTargeting) by design — keep it that way.
- **Re-verify endpoints periodically.** The `*.us` wildcard hosts and IPs rotate as the service
  scales; re-check Microsoft's live US Government endpoints list rather than pinning stale IPs.

## Documentation discipline
- **Record every parity substitution.** When you replace a Gov-unavailable rule, note what it replaced
  and why, so the next admin doesn't "restore" a rule that can't evaluate in GCC High.
- **Flag anything unverified.** If Microsoft doesn't explicitly confirm a behavior for GCC High, label
  it **"verify for GCC High"** in your runbook rather than assuming Commercial behavior.
