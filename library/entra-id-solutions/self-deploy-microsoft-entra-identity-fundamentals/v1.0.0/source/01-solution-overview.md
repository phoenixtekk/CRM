# 1. Solution Overview — Self-Deploy: Microsoft Entra Identity Fundamentals

## What this is

A complete, self-guided **self-deploy** that takes a novice-but-competent admin from zero to a
solid working grounding in **Microsoft Entra identity fundamentals** — tenants, users, groups, roles
and RBAC, app registrations, the sign-in flow, MFA, and Conditional Access basics — plus the
licensing and admin-role model. It is delivered as concepts, **guided hands-on labs**, a **take-home
runbook and glossary**, and a **knowledge-check**.

It is a **skills** product — the outcome is people who can read and operate the tenant. It is
**adjacent to** the catalog's implementation solutions (Conditional Access baseline, PIM,
passwordless, governance, hybrid identity); those *deploy and operate* the advanced capabilities,
while this kit builds the fundamentals that make them make sense. The two are complementary and are
cross-referenced, not duplicated.

## How the technology works (the mental model)

- **The tenant is your identity boundary.** A **Microsoft Entra tenant** is a dedicated, isolated
  instance of the directory that Microsoft creates for your organization. It has an initial domain
  (`contoso.onmicrosoft.com`), zero or more verified custom domains (`contoso.com`), a tenant ID, and
  it holds every identity and configuration below. Everything else in this kit lives inside one
  tenant.
- **Identities are who can sign in.** Entra holds several kinds of **identity**: member **users**
  (your staff), **guest** users (external people invited via B2B), and **service principals /
  workload identities** (apps and automation, not people). Each user has a **User Principal Name**
  (UPN, e.g. `ana@contoso.com`), an object ID, and attributes.
- **Groups are how you manage people in bulk.** A **security group** grants access or targets policy
  to many users at once; a **Microsoft 365 group** additionally backs a mailbox/Team. Membership is
  either **assigned** (you add people) or **dynamic** (a rule such as `department eq "Sales"` adds
  them automatically). You target licenses, app access, and Conditional Access at groups, not
  individuals.
- **Roles + RBAC decide who can administer what.** Entra has built-in **directory roles** (Global
  Administrator, User Administrator, Helpdesk Administrator, Security Reader, and dozens more). A role
  is a bundle of permissions; assigning it to a user grants those permissions, ideally **scoped** and
  **least-privilege**. Global Administrator is all-powerful and should be rare; most day-to-day work
  needs a narrow role. (Azure RBAC on subscriptions/resources is a separate, related system — this
  kit focuses on the Entra directory roles.)
- **Apps come in two shapes.** An **app registration** is the *definition* of an application in your
  tenant (its identity, redirect URIs, API permissions, secrets/certificates). An **enterprise
  application** (service principal) is the *instance* of an app — yours or a third party's — that
  users actually sign in to and that you assign, consent, and govern. Understanding the registration
  vs enterprise-app distinction is a fundamental most new admins are missing.
- **Sign-in is an evaluated flow.** When a user signs in, Entra authenticates them (password,
  passwordless, or federated), then evaluates **Conditional Access** — an if-then engine that can
  require MFA, a compliant device, or block the sign-in based on who/what/where/risk — before issuing
  a token. **MFA** (Multi-Factor Authentication) adds a second factor; methods range from SMS (weak)
  to authenticator apps to **phishing-resistant** FIDO2/passkeys (strong).
- **Licensing gates the features.** Core directory, users, groups, and self-service basics are
  included with Microsoft 365. **Entra ID P1** adds Conditional Access, group-based licensing, and
  more; **Entra ID P2** adds Identity Protection risk policies and Privileged Identity Management
  (PIM). Identity Governance, Global Secure Access, and Verified ID are further add-ons. *Verify what
  your tenant is licensed for — bundles change, and availability differs by cloud.*

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the kit:

1. **Assess.** Confirm the learners and tenant are ready — an admin can open the Entra admin center,
   the operator holds least-privilege roles, and a safe lab posture is agreed (run
   `EKIDFUND-Discovery.ps1` for a read-only picture of the tenant fundamentals).
2. **Configure.** Create the learner cohort group `Grp-EntraFund-Cohort` and a small, cloud-only
   **lab sandbox** (`EKIDFUND-LabSetup.ps1`, preview by default) so labs never touch production
   objects.
3. **Pilot.** Run the **guided labs** (Labs 1–6) with the cohort — tenant tour, users, groups &
   dynamic membership, roles/RBAC, app registrations, and a **report-only** sign-in/MFA/Conditional
   Access lab — all read-only-first.
4. **Validate.** Run the **capstone** exercise and score the **knowledge-check** `Check-EntraFund-Pilot`
   (`EKIDFUND-Validate.ps1`).
5. **Expand.** Fold the grounding into confident day-to-day operation, tear down or keep the sandbox,
   and progress to the advanced identity solutions.

## Scope — what this kit covers

- **Tenant fundamentals** — what a tenant is, domains, tenant ID, the Entra admin center layout.
- **Identities** — member users, guests (B2B basics), service principals/workload identities, UPNs
  and attributes.
- **Groups** — security vs M365 groups, assigned vs dynamic membership, group-based targeting.
- **Roles & RBAC** — built-in directory roles, least privilege, Global Administrator hygiene, and how
  to read `Roles and administrators`.
- **App registrations vs enterprise applications** — the definition vs the instance, API permissions
  and consent at a conceptual level.
- **Sign-in, MFA & Conditional Access basics** — the sign-in flow, MFA methods (including
  phishing-resistant), and a first, safe, **report-only** Conditional Access policy.
- **Licensing & admin-role model overview** — what P1/P2 and the add-ons unlock.
- **A take-home runbook, glossary, and knowledge-check** — so the skills persist and can be proven.

## Out of scope (handled elsewhere)

- **Production Conditional Access design and rollout.** Building a full CA baseline is the **Zero
  Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access Integration** solutions. This
  kit builds *one report-only lab policy* to teach the concept; it does not design a production
  baseline.
- **Privileged access, passwordless, governance, hybrid.** Just-in-time admin (PIM), FIDO2/passkey
  rollout, access reviews/entitlement management, and AD-to-Entra sync are the **ENTPIM**,
  **ENTPASSKEY**, **ENTIGA**, and **Hybrid Identity** solutions — introduced here, delivered there.
- **App publishing at scale.** Standing up SAML/OIDC apps and governing the enterprise-app estate are
  the **SAML App Factory** and **Enterprise-App & Service-Principal Governance** solutions.
- **The business/security determinations.** Which roles are "privileged," what MFA methods are
  mandated, which apps are sanctioned, and every production change are the customer's
  security/operations decisions; this kit provides the skill and the labs, not the decisions.

## Benefits

- **Confidence** — new admins understand what they are looking at and can make safe changes instead
  of guessing.
- **Safety** — labs run in a cloud-only sandbox and any Conditional Access lab is **report-only**, so
  learning never risks a lock-out.
- **Repeatability** — a take-home runbook, glossary, and knowledge-check make onboarding the next new
  hire a repeatable exercise.
- **A foundation that compounds** — the grounding makes every advanced identity solution in the
  catalog land faster.

## Limitations (be honest with buyers)

- This teaches **fundamentals**; it is not a production configuration. The one CA lab policy is a
  teaching aid in report-only, not a baseline.
- Some concepts referenced (P2 risk policies, PIM, Identity Governance, Global Secure Access, Verified
  ID) need specific licensing or are in preview — *verify availability in your tenant*.
- Feature names, portal navigation, and licensing bundles evolve and can differ by cloud (Commercial
  vs GCC / GCC High) — *verify against your tenant*.

## Authentication and connections used

- **Microsoft Entra admin center** (`https://entra.microsoft.com`) for the interactive labs — users,
  groups, roles, app registrations, sign-in logs, and Conditional Access.
- **Microsoft Graph PowerShell SDK** for the read-only discovery/validation/reporting helpers and the
  gated, preview-by-default lab-sandbox setup (each script's header names its least-privilege scopes).
- **KQL** over Entra **sign-in and audit logs** (via the Graph audit-log endpoints, or a Log Analytics
  workspace where sign-in logs are exported) for the sign-in/MFA labs.
- Helpers authenticate **interactively** with an MFA-capable account; **no credentials are stored in
  code**. Government-cloud tenants pass the matching endpoints — *verify endpoints for your cloud*.
