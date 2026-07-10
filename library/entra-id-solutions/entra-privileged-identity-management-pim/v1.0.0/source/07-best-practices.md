# 7. Best Practices — Entra Privileged Identity Management (PIM)

- Break-glass first, always. Create, exclude, and alert two cloud-only emergency Global Administrators
  *before* you remove anyone's standing access — and never make them PIM-eligible. They are what makes
  removing standing privilege safe.
- Drive standing Global Administrators to (almost) zero. Aim for only the break-glass accounts holding
  permanent Global Administrator; everyone else is eligible-not-active. *Verify current Microsoft
  guidance on permanent-admin counts in your tenant.*
- Tier your roles and match the policy to the risk. The most powerful roles (Global Administrator,
  Privileged Role Administrator, Security Administrator) get approval + short duration + MFA +
  justification; broadly used lower-risk roles can be MFA + justification with a longer window.
- Always require MFA and justification on activation. MFA at the moment of elevation blocks stolen-token
  reuse; the justification creates the audit narrative.
- Require approval for Tier-0. A second human in the loop for the crown-jewel roles turns a single
  stolen credential into a blocked request.
- Keep activation windows short. Right-size the maximum duration to the task; a role that auto-expires
  in hours has a far smaller blast radius than one that lingers a full day.
- Govern Azure resource roles too. An Azure `Owner` can be as dangerous as a directory admin — put
  Owner/Contributor/User Access Administrator under PIM, not just Entra roles.
- Review eligibility on a cadence. Run the quarterly access review so eligibility that is no longer
  needed is removed; eligibility drifts as people change teams.
- Turn on and watch the PIM alerts. Too many admins, activations without MFA, roles assigned outside
  PIM, and stale assignments are early warnings — review them, don't just enable them.
- Stage and preview every removal. Removing standing access can lock out a real admin — always run the
  conversion in `-WhatIf` preview, confirm each account has an eligible assignment, then apply.
- Make it recurring, not one-time. Re-run discovery and the report monthly so new standing assignments
  are caught and activations stay audited.

## Where to go next
- **Conditional Access** — pair PIM with CA policies that require compliant devices and phishing-
  resistant MFA for admin activation (see the Entra Conditional Access solutions).
- **Enterprise App & Service Principal Governance** — apps and service principals are the *other*
  privileged-access path; govern their consent and application permissions alongside human admins.
- **Identity Protection / risk-based access** — feed sign-in and user-risk signals into admin access
  decisions.
- **Access reviews at scale (Identity Governance)** — extend recurring review beyond privileged roles
  to group and app access.
