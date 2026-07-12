# 1. Solution Overview — Self-Deploy: Multi-Factor Authentication & Conditional Access

## What this is

A complete, self-guided **self-deploy** that levels a team up on **Multi-Factor Authentication and
Conditional Access** in Microsoft Entra — MFA methods (including phishing-resistant), the Conditional
Access model, CA design patterns and personas, **report-only + What-If** testing, break-glass, and
troubleshooting sign-in and CA-evaluation failures. It is delivered as concepts, **guided hands-on
labs** (all in report-only), a **take-home runbook**, and a **knowledge-check**.

It is a **skills** product — the outcome is a team that can design, test, and troubleshoot MFA/CA
safely. It is deliberately **distinct from** the catalog's CA **implementation** solutions — the
**Zero Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access Integration** *deploy
and operate* a production, enforced baseline. This kit builds the *capability* and practices in
**report-only**; those products build the production system. The two are complementary and are
cross-referenced, not duplicated.

## How the technology works (the mental model)

### MFA — methods and strength

- **MFA adds a second factor** beyond the password. The methods are **not equal in strength**:
  - **SMS / voice** — better than nothing, but **phishable** and SIM-swap-prone.
  - **Microsoft Authenticator (push + number matching)** — strong and common; number matching resists
    MFA-fatigue attacks.
  - **Phishing-resistant methods — FIDO2 security keys, passkeys, Windows Hello for Business,
    certificate-based auth** — the strongest tier; they are bound to the device/origin and cannot be
    phished. *Passkey support and some methods may be in preview or licensing-gated — verify.*
- **The authentication-methods policy** (Entra -> Protection -> Authentication methods) controls
  which methods are enabled and for whom, and drives **registration** (including registration
  campaigns that nudge users to set up a stronger method).
- **Authentication strength** is a named requirement (e.g. "Phishing-resistant MFA") you can require
  in a Conditional Access grant control — the bridge between MFA methods and CA.

### Conditional Access — the if-then engine

A Conditional Access policy is an **if-then** statement evaluated on every sign-in **after**
authentication and **before** a token is issued:

- **The "if" — assignments and conditions:** which **users/groups** (and **exclusions**), which
  **target resources** (cloud apps / user actions), and conditions such as **device platform**,
  **location**, **client app**, **sign-in risk**, and **user risk**. *Risk conditions require Entra
  ID **P2** (Identity Protection) — verify.*
- **The "then" — controls:**
  - **Grant controls** — allow only if a requirement is met: **require MFA**, **require a specific
    authentication strength** (e.g. phishing-resistant), **require a compliant device**, **require a
    hybrid-joined device**, **require app-protection policy**, or **block**. Combine with AND/OR.
  - **Session controls** — shape the granted session: **sign-in frequency**, **persistent browser**,
    **app-enforced restrictions**, and CA app control.

Because a policy can target "all users" and "all cloud apps," it is powerful enough to lock everyone —
including admins — out in one save. The whole method below exists to prevent that.

### The two safety features every learner must master

- **Report-only mode.** A policy set to **Report-only** is fully evaluated and logged on every sign-in
  ("would have granted / would have blocked / would have required MFA") **without enforcing
  anything**. You read the impact in **Conditional Access -> Insights and reporting** and in the
  sign-in logs. *Every lab policy in this kit is report-only.*
- **What-If.** A simulator (**Conditional Access -> What If**) where you pick a user, app, device
  state, and conditions and see exactly which policies would apply and which controls would fire —
  with no real sign-in. It is how you sanity-check a policy against each persona before it is ever
  enforced.

### Break-glass — the anti-lockout discipline

Two cloud-only emergency-access (break-glass) accounts are **excluded from every CA policy** (global
requirement **G4**) so a bad policy can never lock all admins out. The kit teaches this habit on every
lab policy, even though the lab policies are report-only.

### Design by persona

The clean way to think about CA is by **persona**, not one mega-policy: **admins** (highest value —
phishing-resistant MFA, tight session), **internal staff** (MFA + compliant/hybrid device),
**external/guest** (MFA + app-enforced restrictions), and **service accounts / workload identities**
(non-interactive — scoped out of interactive policies, governed separately). Personas map to security
groups, and policies target those groups.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the kit:

1. **Assess.** Confirm the cohort and tenant are ready — CA is available (P1), MFA methods are
   understood, break-glass exists (run `EKMFACA-Discovery.ps1` for the read-only picture).
2. **Configure.** Create the learner cohort `Grp-MfaCa-Cohort`, the lab **persona groups**, and the
   break-glass exclusion group — a small, cloud-only lab scope.
3. **Pilot.** Run the **guided labs** (Labs 1–6) — MFA methods & registration, CA anatomy, design
   patterns & personas, building **report-only** policies, **What-If** testing, and
   sign-in/CA-evaluation troubleshooting.
4. **Validate.** Run the **capstone** and score the **knowledge-check** `Check-MfaCa-Pilot`
   (`EKMFACA-Validate.ps1`); confirm every lab policy is report-only and excludes break-glass.
5. **Expand.** Take the capability into the **production** CA solutions (ENTZTCA, Conditional Access
   Integration) to design and roll out a real, enforced baseline safely.

## Scope — what this kit covers

- **MFA methods & registration** — the method tiers, phishing-resistant options, the
  authentication-methods policy, and registration.
- **Conditional Access anatomy** — assignments, conditions, grant and session controls, exclusions.
- **CA design patterns & personas** — admins, internals, guests, service accounts, and the common
  baseline patterns as *understanding*.
- **Report-only + What-If testing** — building and validating policies with **no lockouts**.
- **Break-glass** — the anti-lockout discipline on every policy.
- **Troubleshooting** — reading sign-in failures and CA-evaluation results to explain a decision.
- **A take-home runbook + knowledge-check** — so the skills persist and can be proven.

## Out of scope (handled elsewhere)

- **Designing and enforcing a production CA baseline.** That is the **Zero Trust Conditional Access
  Baseline (ENTZTCA)** and **Conditional Access Integration** solutions. This kit practices in
  **report-only** and never enforces.
- **Rolling out phishing-resistant methods at scale.** Deploying FIDO2/passkeys across the org is the
  **Passwordless & Passkey (ENTPASSKEY)** solution — introduced here, delivered there.
- **Risk-based access, PIM, governance, hybrid.** Identity Protection risk policies (P2), just-in-time
  admin (ENTPIM), access reviews (ENTIGA), and AD sync (Hybrid Identity) are cross-referenced, not
  built.
- **The business/security determinations.** Which MFA methods are mandated, which users are
  "privileged," how strict guest access must be, and every production enforcement decision are the
  customer's security/operations calls; this kit provides the skill and the labs.

## Benefits

- **No lockouts while learning** — every lab policy is report-only and validated with What-If;
  break-glass is protected throughout.
- **No gaps from timidity** — the team understands MFA/CA well enough to design and test confidently.
- **Troubleshooting skill** — the team can read a sign-in log and explain why a policy applied,
  cutting "MFA is broken" tickets.
- **A safe on-ramp to production** — the capability feeds directly into the enforced-baseline
  solutions.

## Limitations (be honest with buyers)

- This teaches **capability** and practices in **report-only**; it is not a production baseline (that
  is ENTZTCA / Conditional Access Integration).
- Conditional Access needs **Entra ID P1**; **risk-based conditions** and PIM need **P2**; some MFA
  methods (passkeys, CBA) or features may be in preview — *verify availability in your tenant*.
- Feature names, portal navigation, and licensing bundles evolve and can differ by cloud (Commercial
  vs GCC / GCC High) — *verify against your tenant*.

## Authentication and connections used

- **Microsoft Entra admin center** (`https://entra.microsoft.com`) for the interactive labs —
  Authentication methods, Conditional Access policies, What-If, Insights and reporting, and Sign-in
  logs.
- **Microsoft Graph PowerShell SDK** for the read-only discovery/validation/reporting helpers and the
  gated, preview-by-default **report-only** lab-policy builder (each script's header names its
  least-privilege scopes).
- **KQL** over Entra **sign-in logs** (via a Log Analytics workspace where exported, or the portal
  sign-in-log view) for the CA-evaluation and troubleshooting labs.
- Helpers authenticate **interactively** with an MFA-capable account; **no credentials are stored in
  code**. Government-cloud tenants pass the matching endpoints — *verify endpoints for your cloud*.
