# Executive Summary — Entra Privileged Identity Management (PIM): Just-in-Time Admin — Government (GCC High)

White-label · Entra ID Solutions · **US Government (GCC High) edition**

This is the **Government (GCC High)** edition for US public-sector and defense-industrial-base tenants
running in Microsoft's US Government national cloud (Azure Government / GCC High). It mirrors the
commercial just-in-time-admin method, adapted for the sovereign cloud — GCC High portals
(`entra.microsoft.us` / `portal.azure.us`) and US Gov script endpoints (`Connect-MgGraph -Environment
USGov`; DoD/IL5 uses `USGovDoD`). Privileged access management is a strong public-sector fit and directly
supports federal Zero Trust and least-privilege mandates. Because GCC High/DoD can lag commercial in
feature availability, every capability is flagged *"verify against current Microsoft Government
documentation"* — see `gcc-high-parity-notes.md` for endpoints, parity, and FedRAMP High / DoD IL4-IL5 /
CMMC context.

Every permanent Global Administrator in your tenant is a breach that has not happened yet. Standing
privileged access — an admin role that is always active, on an account that is always signed-in-able —
is the single richest target in Microsoft Entra: steal that one credential and the attacker owns the
directory, with no time limit, no approval, and no one watching. Most tenants accumulate far more
standing privilege than anyone realizes, because roles are handed out permanently "to be safe" and
never taken back.

This is a complete, deploy-it-today package for eliminating standing privileged access with Microsoft
Entra Privileged Identity Management (PIM), written for an administrator with no prior PIM experience.
It turns always-on admin roles into *eligible* assignments that a person must activate just-in-time —
with MFA, a business justification, approval where warranted, and an automatic expiry — and it puts
every activation under audit and access review.

## What you get
- A plain-language Solution Overview of the PIM model — eligible vs. active assignments, activation
  policy (MFA, approval, justification, max duration), Entra roles vs. Azure resource roles, access
  reviews, and break-glass design.
- A Requirements Guide with verify / implement-if-missing for every prerequisite (including the Entra
  ID P2 licensing PIM requires — *verify current availability for your GCC High / DoD tenant against
  current Microsoft Government documentation*).
- An Implementation Guide of precise, click-by-click steps in the required order — discover standing
  access, onboard roles to PIM, set activation policy, convert to eligible, add access reviews and
  alerts, pilot-first.
- Five PowerShell scripts (Microsoft.Graph) for standing-access discovery, activation-policy
  validation, an activation/audit report, safe conversion of active assignments to eligible, and an
  alerting/break-glass check.
- Testing and Troubleshooting guides for a confident, staged rollout with break-glass protection.

## What this delivers
Zero standing privilege — privileged roles are eligible-not-active, every admin action is activated
just-in-time with MFA, justification, and approval, time-bound so it auto-expires, reviewed on a
recurring cadence, and fully audited — with break-glass accounts kept ready so hardening the identity
plane never locks you out.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
The biggest identity risk in the tenant closed: no permanent admins, every privileged activation
approved, time-bound, and auditable — proven on a pilot cohort before you touch tenant-wide roles, and
protected end-to-end by break-glass accounts.
