# Executive Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

White-label · Entra ID Solutions · Government (GCC High) edition

Standing admin rights and access that never gets reviewed are how breaches escalate and how audits
fail. Microsoft Entra ID Governance fixes both at once: Privileged Identity Management (PIM) makes
admin roles just-in-time and approval-gated, access reviews recertify who should keep access, and
entitlement management packages access with policies and expiry. The result is privilege that is
least, time-bound, and provable to an auditor — a direct fit for the least-privilege and
periodic-review objectives common to CMMC and NIST 800-171 in GCC High.

This is the **Government (GCC High)** edition: the same governance model, deployed on the **US
sovereign cloud**. The admin portals, sign-in, and Microsoft Graph endpoints are the `*.us` sovereign
URLs (`entra.microsoft.us`, `portal.azure.us`, `login.microsoftonline.us`, `graph.microsoft.us`), and
the scripts target US Gov Graph with `-Environment USGov`. It is written for an administrator with no
prior identity-governance experience, and it calls out where GCC High differs from Commercial so a
government tenant is configured correctly — not with Commercial steps that silently authenticate
against the wrong cloud.

## What you get
- A plain-language Solution Overview of PIM (eligible vs active roles, activation, approval, alerts), access reviews, and entitlement management (catalogs, access packages, policies, expiry) — with an explicit *Commercial vs GCC High — what's different* section.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, the sovereign endpoint table, and the Government licensing SKUs.
- An Implementation Guide of precise, ordered steps in the US Gov Entra admin center, with GCC-High caveats inline where they matter.
- Five PowerShell scripts (US Gov Graph) for governance discovery, privileged-access validation, a standing-privilege and coverage report, safe remediation of standing admin, and a governance-scope group builder.
- A cited GCC High Parity Notes reference, plus Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A governance baseline where privileged directory roles are onboarded to PIM as eligible (not
standing), activation is approval-gated and alerted, access reviews recertify roles, groups, and app
access on a schedule, and entitlement-management access packages grant access with a defined policy
and an expiry date — all on the sovereign plane. Break-glass emergency accounts are deliberately
excluded from PIM so a misconfiguration can never lock every administrator out.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Just-in-time, approval-gated admin, access recertified on a schedule, and entitlements packaged with
expiry — least privilege that is time-bound and provable — configured correctly on GCC High and
proven on a pilot before you scale.
