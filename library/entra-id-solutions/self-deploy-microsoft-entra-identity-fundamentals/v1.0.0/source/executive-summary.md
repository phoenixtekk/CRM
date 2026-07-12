# Executive Summary — Self-Deploy: Microsoft Entra Identity Fundamentals

White-label · Entra ID Solutions

## The problem

A team inherits a Microsoft Entra tenant — users are already there, groups exist, someone set up
sign-in and some policies — but nobody on the team can confidently say how any of it works. New
admins are handed the keys to the identity plane, the single most dangerous surface in the whole
Microsoft cloud, without a mental model of tenants, users, groups, roles/RBAC, app registrations,
sign-in, MFA, or Conditional Access. The result is predictable: risky changes made by guesswork,
tickets that sit because no one knows where the setting lives, and a reluctance to touch anything for
fear of locking the company out of its own directory.

## The solution

This is a **self-guided self-deploy** — concepts, **guided hands-on labs**, a **take-home
runbook and glossary**, and a **knowledge-check** — that takes a novice-but-competent admin from
zero to a solid working grounding in Microsoft Entra identity fundamentals. It is deliberately a
**skills** product: the outcome is people who understand the tenant and can operate it safely, not
another policy someone else configured.

- **Teaches the model, not just the clicks** — what a tenant is, how users and groups and roles
  actually relate, what an app registration versus an enterprise application is, how a sign-in is
  evaluated, and where MFA and Conditional Access fit.
- **Ships guided, read-only-first labs** — every lab runs in a small, named **lab sandbox** with
  cloud-only test objects, so learners practice on real Entra without endangering production.
- **Ends in durable artifacts** — a take-home **fundamentals runbook**, a **glossary**, and a scored
  **knowledge-check** so you can prove the skills landed.

## What you get

- A plain-language **Solution Overview** of the Entra model — tenant, identities, groups, roles and
  RBAC, app registrations vs enterprise apps, the sign-in flow, MFA methods, Conditional Access
  basics, and the licensing / admin-role picture.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific
  prerequisite (on top of the shared category requirements).
- An **Implementation Guide** structured as guided labs — build the cohort and lab sandbox, then work
  through users/groups, roles/RBAC, app registrations, sign-in/MFA, and a **report-only** Conditional
  Access lab, then a capstone and knowledge-check.
- **Five lab helpers** — a read-only tenant-fundamentals discovery, a gated lab-sandbox setup
  (preview by default), a sign-in/audit **KQL lab pack**, a read-only validation/knowledge-check
  runner, and a cohort/fundamentals report.
- **Testing and Troubleshooting** guides so the team learns to verify and self-diagnose.

## What this delivers

New admins with a real working grounding in Microsoft Entra — able to read the directory, manage
users and groups, understand least-privilege admin roles, recognize an app registration, follow a
sign-in through MFA and Conditional Access, and make safe changes — plus a take-home runbook,
glossary, and a passed knowledge-check that proves the capability is there.

## The standard deployment model

Assess -> Configure -> Pilot -> Validate -> Expand — reframed for enablement: assess readiness,
configure the cohort and lab sandbox, run the guided labs (pilot), validate skills with a capstone
and knowledge-check, then expand into confident day-to-day operation and the advanced solutions.

## Outcome

A team grounded in Microsoft Entra fundamentals — ready to operate and secure the tenant and to
progress to the advanced identity solutions (Conditional Access, PIM, passwordless, governance)
without being lost.

## Important boundaries

This is a **skills / enablement** product — it teaches people the fundamentals and lets them practice
in a safe sandbox. It **cross-references, and deliberately does not duplicate**, the catalog's
**implementation** solutions — Conditional Access baseline (ENTZTCA), Conditional Access Integration,
Privileged Identity Management (ENTPIM), Passwordless & Passkey (ENTPASSKEY), Identity Governance &
Access Reviews (ENTIGA), Hybrid Identity, SAML App Factory, and Enterprise-App governance — which
*deploy and operate* those capabilities. This kit builds the grounding; those products build the
production systems. Any labs that touch Conditional Access run **report-only first**; break-glass
accounts are protected throughout. Where a feature needs a specific license (Entra ID P1/P2, Identity
Governance, Global Secure Access, Verified ID) or is in preview, this kit flags it — *verify current
availability and licensing in your tenant*, which can differ by cloud (Commercial vs GCC / GCC High).
