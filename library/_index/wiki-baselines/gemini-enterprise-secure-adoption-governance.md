# Gemini Enterprise — Secure Adoption, Guardrails & Data-Access Boundaries

> **Version 1.0.0** · Category: Google · Solution code: GEMGOV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Gemini Enterprise is only as safe as the data it can see — and it grounds its answers in everything
the signed-in user can reach in Google Workspace. Turn it on before you have fixed oversharing,
applied DLP/IRM to sensitive content, and bounded what Gemini may ground in, and it will happily
surface confidential files, HR data, and stale content to anyone who asks a question. The risk is not
a Gemini bug; it is your existing data estate, suddenly made searchable in natural language.

This is a complete, deploy-it-in-order package for adopting Gemini Enterprise securely, aligned to
your enterprise data-governance model and written for an administrator partnering with security and
legal. It gives you the repeatable way to assess and remediate oversharing, set the technical
guardrails and data-access boundaries Gemini honors, align each use case to the policy that permits
it, and prove it all on a controlled pilot before you scale.

## What you get
- A plain-language Solution Overview of how Gemini grounds in Workspace data (the user's permissions),
  why oversharing is the top risk, and how Drive sharing, Trust rules, DLP/IRM, CSE, and the
  data-access controls constrain what Gemini can surface.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — Gemini/Workspace
  licensing, a data-governance baseline (sharing, DLP, IRM/CSE), an oversharing assessment, the
  data-access boundary decision, a pilot scope, security/legal partnership, and named governance owners.
- An Implementation Guide of precise, ordered steps in the Workspace Admin console — assess,
  remediate, set guardrails and the data-access boundary, align use cases to policy, pilot, validate,
  expand.
- Five PowerShell scripts for AI-readiness / oversharing discovery, per-scope guardrail validation, an
  access-boundary and coverage report, safe remediation of oversharing, and a pilot scope-group builder.
- Testing and Troubleshooting guides with explicit validation gates and exposure probes for a
  confident rollout.

## What this delivers
Gemini Enterprise rolled out on a governed data estate — oversharing remediated, DLP/IRM and CSE
enforced so Gemini honors them, access tightened with Trust rules, data-access boundaries set so
Gemini grounds only in the right data, use cases aligned to governance policy, and security/legal
satisfied — proven on a controlled pilot before you expand.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate and a rollback at every stage.

## A note on Gemini's evolving surface
Gemini Enterprise capabilities, editions, and admin pages are evolving and partly in preview. Every
admin path in this package reflects Google's current public documentation and is flagged
**"verify in your tenant"** where it is not confirmed GA — Gemini specifics are cited or flagged,
never invented.

## Outcome
A secure Gemini adoption a single administrator can run and defend at audit: the top risk
(oversharing) assessed and fixed first, guardrails Gemini actually respects, data-access boundaries
enforced, and AI use governed and policy-aligned — validated on a pilot before the fleet ever gets
access.


---


# 1. Solution Overview — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

## What Gemini Enterprise is
Gemini Enterprise is Google's enterprise AI assistant and agent platform. In the Google Workspace
context, it answers questions and generates content by reasoning over your organization's Workspace
data — files in **Google Drive**, **Gmail**, and **Google Calendar** — a capability Google calls
**grounding**: tethering the model's output to verifiable data sources so answers are drawn from your
content rather than invented. The critical property to understand is the same one that governs any
retrieval-based AI: **Gemini only retrieves content the signed-in user already has access to**. It
does not grant new access — but it makes everything a user *can* reach instantly findable in plain
language.

> **Verify in your tenant.** Gemini Enterprise editions, admin surfaces, and connectors are evolving
> and some capabilities are preview / rolling out. The admin paths and control names below reflect
> Google's current public documentation (Workspace Admin console **Generative AI → Gemini
> Enterprise**), but you should confirm the exact editions, toggles, and connector availability that
> apply to *your* licensing before you rely on them. Where a capability is not confirmed GA in your
> tenant, treat it as "verify" rather than assumed.

## How it accesses data (and why oversharing is the top risk)
1. A user asks Gemini a question.
2. Gemini grounds its answer by retrieving Workspace content **as that user**, honoring existing
   Drive sharing, shared-drive membership, and Gmail/Calendar permissions.
3. It reasons over the retrieved content and returns an answer, drawn from data the user is permitted
   to see.
4. Because grounding respects — and is therefore limited only by — existing permissions, any file a
   user *could technically* open (even one they never knew existed, via a broad "anyone with the
   link", domain-wide, or stale-membership grant) can now be surfaced by a simple question. This is
   **oversharing**: broad or stale access that was survivable when nobody browsed for it becomes a
   live data-exposure path the moment Gemini makes it searchable.

The rule of thumb: `Gemini exposure = what the user can access`. Fix the access, and you fix the
exposure. That is why this solution assesses and remediates the data estate **before** enabling
Gemini Enterprise.

## What constrains Gemini (the guardrails this solution configures)
These are Google-native controls; the exact availability of each depends on your Workspace edition —
**verify in your tenant**.

- **Drive sharing and shared-drive permissions.** The primary control. Removing broad "anyone with
  the link", domain-wide ("anyone in your organization"), and stale external/guest access shrinks
  what Gemini can surface. This is the highest-leverage remediation.
- **Trust rules in Drive.** Restrict data sharing between internal and external parties, limiting what
  Gemini can retrieve across the trust boundary.
- **Data Loss Prevention (DLP) + Information Rights Management (IRM).** When a DLP policy applies IRM
  controls to a file (preventing download, printing, or copying), **Gemini does not retrieve those
  protected files to generate a response** — a policy-level guardrail on top of permissions.
- **Client-Side Encryption (CSE).** When CSE is enabled, the protected data is indecipherable to any
  unauthorized party, **including Google or its generative-AI assistants** — CSE content is not
  usable by Gemini.
- **Context-Aware Access (CAA).** Restrict access based on device compliance, location, and identity
  so the Gemini surface is only reachable from trusted contexts.
- **Admin data-access controls.** In the Workspace Admin console, the
  **"Allow Gemini Enterprise to access Google Workspace data"** setting governs whether Gemini can
  independently read Workspace data at all — scopable to an OU or configuration group so you can
  bound the pilot. (Exact edition sub-pages vary — verify in your tenant.)

## AI governance (the human controls)
- **Acceptable-use policy** for Gemini: what it may / may not be used for, data-handling
  expectations, and review of AI-generated output before it is trusted or shared.
- **Use-case-to-policy alignment.** Each approved use case is mapped to the data it may ground in and
  the policy that permits it — so "what Gemini is used for" and "what data governance allows" are the
  same list.
- **Admin service controls** in **Generative AI → Gemini Enterprise → Service status** (On/Off,
  scopable to OU / configuration group) decide who has Gemini at all and who is in the pilot.
- **Named owners** for data governance, DLP/IRM, and AI use — governance is a role, not a one-time task.

## How Google handles your data (what to tell security & legal)
Per Google's public documentation (**verify current terms for your contract/edition**): Workspace does
not use customer data to train models without permission; Gemini interactions stay within your
organization and are not human-reviewed for model training outside your domain without permission;
retention for Gemini in Workspace is admin-determined. Audit surfaces include **Gemini usage
reports**, the **Reports API** (when Gemini accessed Drive files), the **security investigation tool**
(query/investigate/export Gemini access to Drive), and **Google Vault** for eDiscovery of Gemini
conversations.

## Benefits
- **Data safety** — the top risk (oversharing) is assessed and fixed before Gemini can exploit it.
- **Guardrails Gemini respects** — DLP/IRM, CSE, trust rules, and permissions constrain what Gemini
  can ground in.
- **Controlled blast radius** — data-access toggles and a phased pilot mean a small, curated scope
  goes first, not the whole tenant.
- **Governed AI** — acceptable-use and use-case-to-policy alignment put humans in charge of how
  Gemini is used.
- **Repeatable and auditable** — a documented Assess → Configure → Pilot → Validate → Expand process.

## Limitations (be honest with buyers)
- Gemini honors permissions **as they are** — it will not fix oversharing for you; the remediation is
  the work, and this solution front-loads it.
- DLP/IRM and CSE only help where they are **actually applied**; unlabeled, unprotected files rely on
  sharing permissions alone until governance catches up.
- Gemini Enterprise capabilities, editions, and admin surfaces are **evolving / partly preview** —
  every admin path here is flagged "verify in your tenant"; volatile specifics are deferred to
  Google's documentation and never invented.
- Gemini Enterprise is a paid capability with edition prerequisites — confirm licensing before you
  begin.

## The deployment model
> **Assess oversharing and access → Configure guardrails, data-access boundaries, and AI governance →
> Pilot with a curated OU/group → Validate exposure and behavior → Expand.** The pattern is
> **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate and rollback.


---


# 2. Requirements Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`.

> **Vendor boundary.** Google Workspace Admin console paths are authored from Google's current public
> documentation. **Gemini Enterprise editions, admin sub-pages, and connectors are evolving / partly
> preview** — confirm the exact toggles and availability that apply to *your* licensing. Anything not
> confirmed GA in your tenant is flagged **"verify in your tenant."**

## 2.1 Gemini Enterprise licensing on Google Workspace
**Description:** Gemini Enterprise licensing on a qualifying Google Workspace plan for each pilot user.
**Why:** Gemini Enterprise only functions for licensed users; it is a paid capability with base-plan prerequisites, and the exact edition (Business / Standard / Plus / Frontline / Enterprise) determines which data-access controls apply.
**Verify:** Workspace Admin console (`https://admin.google.com`) → **Billing → Subscriptions**; confirm the Gemini/Workspace edition and license counts. Confirm the **Generative AI → Gemini Enterprise** page is present. *(Verify in your tenant — edition names and pages evolve.)*
**Implement:** Acquire Gemini Enterprise licensing through Google or an authorized reseller; do **not** turn Gemini on broadly yet — enablement is gated to the pilot OU/group in Implementation.

## 2.2 Google Workspace with Drive / Gmail / Calendar (the grounding estate)
**Description:** Google Workspace with Drive, shared drives, Gmail, and Calendar as the content estate Gemini will ground in.
**Why:** Drive/shared-drive sharing is the primary control surface for oversharing — the top risk.
**Verify:** Admin console loads; My Drives, shared drives, Gmail, and Calendar are provisioned for users.
**Implement:** Ensure Workspace with Drive/Gmail/Calendar is provisioned before assessing access.

## 2.3 Data-governance baseline (sharing, DLP, IRM)
**Description:** The governance surfaces Gemini honors: Drive external-sharing settings, **Trust rules in Drive**, **DLP** rules, and **IRM** (and, where used, **Client-Side Encryption**).
**Why:** These are the guardrails that constrain what Gemini can retrieve — DLP+IRM prevents Gemini from retrieving download/print/copy-protected files; CSE content is indecipherable to Gemini.
**Verify:** Admin console → **Apps → Google Workspace → Drive and Docs → Sharing settings**; **Security → Data protection** (DLP); confirm IRM/CSE posture. *(Feature availability depends on edition — verify in your tenant.)*
**Implement:** Confirm an edition that includes DLP/IRM (and CSE if required); assign the operator the Drive, Security, and DLP admin privileges.

## 2.4 Oversharing assessment (AI-readiness of the data estate)
**Description:** A completed review of broad Drive sharing: "anyone with the link" (public), domain-wide ("anyone in your organization"), and stale external/guest access, plus shared-drive membership.
**Why:** This is exactly what Gemini will surface; it must be assessed and remediated before enabling Gemini.
**Verify:** Run `GEMGOV-Discovery.ps1` (reports broad-sharing / external-access signals) and review `GEMGOV-Report.ps1` output. Cross-check with **Drive audit log** / **security investigation tool**.
**Implement:** Complete the access review in Implementation Steps 1–2 (assess, then remediate) before the pilot gate.

## 2.5 Data-access boundary decision (what Gemini may ground in)
**Description:** A decided position on the **"Allow Gemini Enterprise to access Google Workspace data"** control (per edition), scoped to the pilot OU/configuration group, so Gemini grounds only in the right data.
**Why:** This admin setting governs whether Gemini can independently read Workspace data at all; scoping it bounds the pilot's grounding surface.
**Verify:** Admin console → **Generative AI → Gemini Enterprise** → the relevant edition page shows the data-access setting and its scope. *(Exact sub-page varies by edition — verify in your tenant.)*
**Implement:** Set the data-access boundary for the pilot scope in Implementation Step 4; leave it off for everyone else until they are remediated and approved.

## 2.6 Governance roles / administrative access
**Description:** The operator holds the roles needed for Gemini service controls, Drive/sharing, DLP, and security changes.
**Why:** Enabling Gemini, editing sharing/trust rules, and publishing DLP require elevated, scoped rights.
**Verify:** Admin console → **Account → Admin roles**; confirm privileges for Generative AI / Gemini service management, Drive and Docs settings, Data protection (DLP), and Security (reserve Super Admin for tenant-wide toggles).
**Implement:** Assign least-privilege admin roles for each surface; record who owns data governance, DLP/IRM, and AI use.

## 2.7 Pilot scope (OU or group)
**Description:** A pilot **organizational unit or group** (e.g. `Gemini Adoption – Pilot Users – Pilot`) for the controlled rollout.
**Why:** Gemini must be validated on a small, curated scope before fleet expansion (pilot gate + rollback).
**Verify:** Admin console → **Directory → Groups** (or **Organizational units**); the pilot scope exists. Or run `GEMGOV-Set-ScopeTargeting.ps1`.
**Implement:** Create the group with `GEMGOV-Set-ScopeTargeting.ps1` (or Admin console → **Directory → Groups → Create group**), and add a few representative users.

## 2.8 AI governance / acceptable-use policy + use-case-to-policy map
**Description:** A documented acceptable-use policy for Gemini, named governance owners, and a mapping of each approved use case to the data it may ground in and the policy that permits it.
**Why:** AI use must be governed by humans — what Gemini may be used for, output review, data handling — and use cases must align to data-governance policy, not just technical defaults.
**Verify:** An acceptable-use policy and a use-case-to-policy map exist and are communicated to pilot users; owners are named.
**Implement:** Draft and publish the policy and the use-case map in Implementation Step 6 before pilot users get access.

## 2.9 Security & legal partnership + change control
**Description:** Engagement with **security (CISO)** and **legal/privacy** stakeholders, and a documented change/rollback process for sharing, DLP, data-access, and Gemini-enablement changes.
**Why:** Tightening access or changing DLP can block legitimate work; enabling Gemini changes the data-exposure surface. Data governance, retention, and how Google handles Gemini data must satisfy security and legal — a pilot gate and rollback are mandatory (see global requirement 6).
**Verify:** Applicable policies and named approvers are confirmed; a change ticket exists with an approver, a maintenance window, and a rollback step.
**Implement:** Identify the security/legal owners and obtain requirements; record the change, name the pilot scope, define the rollback (e.g. re-widen a link, disable the data-access toggle, turn Gemini off for the OU), and get approval before production.

---
## Checklist
- [ ] Gemini Enterprise licensing available on a qualifying Workspace plan (not yet broadly enabled)
- [ ] Workspace with Drive / shared drives / Gmail / Calendar provisioned
- [ ] Data-governance baseline available (Drive sharing, Trust rules, DLP, IRM/CSE) with operator roles
- [ ] Oversharing assessment run — `GEMGOV-Discovery.ps1` / `GEMGOV-Report.ps1`
- [ ] Data-access boundary decided and scoped to the pilot (verify in your tenant)
- [ ] Governance/admin roles assigned (Gemini service, Drive, DLP, Security)
- [ ] `Gemini Adoption – Pilot Users – Pilot` scope (OU/group) created
- [ ] Acceptable-use policy + use-case-to-policy map drafted; owners named
- [ ] Security & legal engaged; change control / rollback documented


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


# 3. Implementation Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Follow these steps **in order**, primarily in the **Google Workspace Admin console**
(`https://admin.google.com`), with checks in the **Drive audit log** / **security investigation
tool** and **Google Vault**.

> **Model:** Assess and remediate the data estate **first**, set the guardrails and data-access
> boundaries Gemini honors, align use cases to policy, govern AI use, then enable Gemini for a small
> curated pilot OU/group, validate exposure, and only then expand. Gemini exposure equals what the
> user can access — so access is fixed before Gemini is on.

> **Verify in your tenant.** Gemini Enterprise admin pages, edition sub-pages, and connector
> availability are evolving / partly preview. The paths below reflect Google's current public
> documentation; confirm the exact toggles for your edition before relying on them, and defer volatile
> specifics to Google's documentation. Never assume a control exists that you have not confirmed.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and reuse the names
verbatim across scripts, assignments, and reports.

## Step 1 — Assess oversharing and access (read-only)
1. Run `GEMGOV-Discovery.ps1` to enumerate broad Drive sharing and Gemini-readiness signals:
   files/folders shared "anyone with the link" (public) or domain-wide, external (guest) shares,
   shared-drive membership breadth, and whether DLP/IRM protection is in place.
2. Run `GEMGOV-Report.ps1` to produce the data-exposure and readiness summary (how much content is
   broadly shared, externally shared, and unprotected).
3. In the Admin console → **Apps → Google Workspace → Drive and Docs → Sharing settings**, note the
   tenant external-sharing posture. Use the **Drive audit log** / **security investigation tool** to
   find the widest-shared content.
4. Record the highest-risk files/shared drives as the remediation worklist. **Do not enable Gemini
   yet.**

## Step 2 — Remediate oversharing (restrict broad access)
1. Review the remediation worklist from Step 1 with the content/shared-drive owners (do not silently
   remove access people rely on).
2. Run `GEMGOV-Remediation.ps1` in its default `-WhatIf` mode to preview the changes it would make
   (removing public/"anyone with the link" and domain-wide link grants, and flagging broad shares).
   Review the preview with owners.
3. Re-run `GEMGOV-Remediation.ps1 -Apply` to remove public/anyone-with-the-link and domain-wide grants
   on the targeted scope. Broad group / shared-drive grants are **reported for owner action**, not
   silently deleted.
4. In the Admin console → **Drive and Docs → Sharing settings**, tighten the tenant default (e.g.
   restrict sharing outside the organization, disable "anyone with the link", set the default link to
   "restricted"/specific people) where policy allows. Apply **Trust rules in Drive** to bound
   internal/external sharing.
5. Clean up stale external/guest access via the sharing reports and shared-drive membership.

## Step 3 — Configure the guardrails Gemini honors (DLP / IRM / CSE / trust rules)
1. In the Admin console → **Security → Data protection**, create or confirm **DLP rules** that apply
   **IRM** (prevent download, print, copy) to your most sensitive content. Files protected this way
   are **not retrieved by Gemini** to generate a response.
2. Where required, confirm **Client-Side Encryption (CSE)** on the most sensitive content — CSE data
   is indecipherable to Gemini.
3. Confirm **Trust rules in Drive** restrict internal/external sharing consistently with policy.
4. (Optional, edition-dependent) Apply **Context-Aware Access** so the Gemini surface is only
   reachable from compliant devices/locations. *(Verify availability in your tenant.)*
5. Confirm intent: Gemini will not retrieve IRM/CSE-protected content, and its grounding is bounded by
   sharing + trust rules.

## Step 4 — Set the data-access boundary (ground only in the right data)
1. In the Admin console → **Generative AI → Gemini Enterprise**, open the sub-page for your edition
   (e.g. **Business edition**, or **Standard / Plus / Frontline**) and review
   **"Allow Gemini Enterprise to access Google Workspace data"**. Scope the decision to the pilot OU
   or configuration group only — leave it off for everyone else. *(Exact edition sub-page varies —
   verify in your tenant.)*
2. Where present, set **conversation sharing** options (Off / allowlisted domains / On) to the
   conservative pilot posture. *(Business edition; verify in your tenant.)*
3. Do **not** turn the Gemini service on for the org yet — service enablement is Step 7.

## Step 5 — Create the pilot scope
1. Run `GEMGOV-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview, then `-Apply` to create the
   `Gemini Adoption – Pilot Users – Pilot` group (reused if it already exists).
2. Add a few representative pilot users (mix of roles). Do not add the whole org. If you prefer to
   scope by OU, place the pilot users in the pilot OU instead and target settings there.

## Step 6 — Govern AI use (acceptable use + use-case-to-policy alignment)
1. Publish the **acceptable-use policy** for Gemini to the pilot users: permitted uses, the
   requirement to review AI-generated output before trusting/sharing it, and data-handling
   expectations. Name the governance owners.
2. Build the **use-case-to-policy map**: for each approved use case, record the data it may ground in
   and the governance policy that permits it — so what Gemini is used for aligns to what data
   governance allows.
3. Confirm the **security & legal** partnership has signed off on data handling, retention, and how
   Google processes Gemini data (see Solution Overview) for the pilot scope.

## Step 7 — Enable Gemini for the pilot
1. In the Admin console → **Generative AI → Gemini Enterprise → Service status**, turn Gemini
   **on for the pilot OU / configuration group only** (not "On for everyone"). *(Verify the exact
   toggle in your tenant.)*
2. Confirm the data-access boundary (Step 4), DLP/IRM/CSE guardrails (Step 3), and trust rules are
   active for the pilot scope.

## Step 8 — Validate the pilot
1. Run `GEMGOV-Validation.ps1` to confirm, per scope: broad-sharing links removed on the targeted
   content, DLP/IRM protection present, and Gemini enabled/data-access scoped to the pilot only.
2. Run `GEMGOV-Report.ps1` to confirm the data-exposure numbers moved in the right direction (fewer
   broadly/externally shared items, more protected content).
3. Perform the **exposure probes** in the Testing Guide (as a pilot user, ask Gemini for content it
   should **not** be able to surface, and confirm it cannot). Use the **security investigation tool**
   to review Gemini's Drive access. Complete the pilot gate.

## Step 9 — Expand to production
1. Only after the pilot passes: widen the remediated scope, extend the data-access boundary and DLP/IRM
   from the pilot to broader scopes, and turn Gemini on for additional OUs/groups in controlled waves.
2. Re-run `GEMGOV-Report.ps1` after each wave; grow the pilot scope (or add production groups).
3. Stand up recurring **access reviews** and re-run `GEMGOV-Discovery.ps1` on a schedule (and monitor
   the security investigation tool) so oversharing does not drift back after Gemini is live.

---
### Order of operations
`Assess oversharing → Remediate sharing → DLP/IRM/CSE + trust rules → Data-access boundary → Pilot
scope → AI governance (acceptable use + use-case-to-policy) → Enable Gemini (pilot) → Validate →
Expand`


---


# 5. Testing Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Run after the pilot is configured and Gemini is enabled for the pilot scope (Implementation Step 8),
and re-run after each expansion wave. The most important tests are the **exposure probes** — proving
Gemini cannot surface what it should not. Each guardrail below is a **validation gate**.

## Test 1 — Oversharing remediated on targeted content
**Do:** Run `GEMGOV-Discovery.ps1`; review the broad-sharing signals for the remediated files/shared drives.
**Expected:** Public "anyone with the link" and domain-wide grants are gone on the targeted content; remaining broad grants are only those owners explicitly approved.

## Test 2 — DLP / IRM protection present on sensitive content
**Do:** Admin console → **Security → Data protection**; confirm the DLP rules apply IRM to the sensitive scope. Run `GEMGOV-Validation.ps1`.
**Expected:** DLP rules are active; sensitive content carries IRM (prevent download/print/copy); CSE is applied where required.

## Test 3 — Gemini enablement and data-access scoped to the pilot
**Do:** Run `GEMGOV-Validation.ps1` (checks the pilot scope). In the Admin console, confirm **Service status** and the **data-access** setting are scoped to the pilot OU/group. *(Verify in your tenant.)*
**Expected:** Gemini is on and data-access is allowed **only** for `Gemini Adoption – Pilot Users – Pilot` — not the whole org.

## Test 4 — Exposure probe: restricted content is NOT surfaced
**Do:** As a **pilot user who should not have access**, ask Gemini for content in a restricted or non-shared location (e.g. "summarize the HR compensation files").
**Expected:** Gemini returns nothing from that content — it grounds only in what the user can access. No citations to content the user cannot open.

## Test 5 — Exposure probe: IRM-protected content is not retrieved
**Do:** As a pilot user, ask Gemini to summarize a file protected by a DLP/IRM rule (download/print/copy prevented).
**Expected:** Gemini does not retrieve the IRM-protected file to generate the response.

## Test 6 — Exposure probe: CSE content is not usable
**Do:** As a pilot user, ask Gemini to work with a **Client-Side Encrypted** document.
**Expected:** Gemini cannot use the CSE content — it is indecipherable to the assistant.

## Test 7 — Use-case-to-policy alignment holds
**Do:** For each approved pilot use case, confirm it grounds only in the data its policy permits (review the use-case-to-policy map against actual behavior).
**Expected:** Each use case stays within its permitted data; no approved use case grounds in out-of-scope content.

## Test 8 — Data-exposure numbers improved
**Do:** Run `GEMGOV-Report.ps1` and compare against the Step 1 baseline. Cross-check the **security investigation tool** for Gemini's Drive access.
**Expected:** Fewer broadly/externally shared items and more protected content than the pre-remediation baseline; Gemini access is confined to remediated, in-scope content.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass; the exposure probes (Tests 4–5) confirm restricted/IRM-protected content is not surfaced; enablement and data-access are pilot-only |
| **Expand pass** | Tests 1–3, 7, 8 pass for the newly remediated scope before the next enablement wave |


---


# 6. Troubleshooting Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Use `GEMGOV-Discovery.ps1` / `GEMGOV-Validation.ps1` for the current state, `GEMGOV-Report.ps1` for
the access-boundary picture, and `GEMGOV-Remediation.ps1` (default `-WhatIf`) for safe fixes. Cross-check
live behavior in the **security investigation tool** (Gemini access to Drive) and the **Drive audit
log**.

> **Verify in your tenant.** Gemini Enterprise admin pages and toggles are evolving / partly preview —
> confirm exact paths for your edition and defer volatile specifics to Google's documentation.

## A. Gemini surfaces content it shouldn't
| Symptom | Cause | Remediation |
|---|---|---|
| Gemini returns confidential/HR/stale files to a user | Oversharing — the user actually has access via a public "anyone with the link", domain-wide, or stale grant | Run `GEMGOV-Discovery.ps1` to find the broad grants; run `GEMGOV-Remediation.ps1 -Apply` to remove public/domain-wide links; tighten sharing + Trust rules |
| Sensitive file still surfaced during pilot | DLP/IRM not applied to that content, or remediation incomplete | Apply a DLP rule with IRM (prevent download/print/copy) so Gemini won't retrieve it; finish remediating the file's sharing |
| Guest surfaced internal content via Gemini | Stale external/guest access | Review sharing reports; remove stale external grants; tighten tenant external-sharing and Trust rules |

## B. Guardrails not honored
| Symptom | Cause | Remediation |
|---|---|---|
| Gemini uses content that should be blocked | The DLP/IRM rule isn't applied to that content, or it isn't CSE-protected | Confirm the DLP rule targets the content and applies IRM; apply CSE where the content must be indecipherable to any assistant; re-test per Testing Tests 5–6 |
| CSE document still readable by Gemini | CSE not actually enabled on that content | Confirm Client-Side Encryption is applied; CSE content is indecipherable to Gemini only where CSE is in force |

## C. Data-access boundary not taking effect
- Confirm the **"Allow Gemini Enterprise to access Google Workspace data"** setting is scoped to the
  correct OU / configuration group and saved. Confirm you are editing the correct **edition** sub-page
  under **Generative AI → Gemini Enterprise** (paths vary by edition — **verify in your tenant**). Allow
  time for settings to propagate before re-testing.

## D. Legitimate work is now blocked (over-remediation)
- If tightening sharing, Trust rules, or DLP blocked people who need access: re-grant via specific
  people/groups (not broad links), narrow the Trust rule/DLP scope, or relax an over-aggressive rule on
  the affected scope. Use the change-control rollback (global requirement 6).

## E. Gemini not working for a pilot user
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot user has no Gemini | Service off for the user's OU/group, or not licensed | Confirm **Generative AI → Gemini Enterprise → Service status** is on for the pilot scope and the user is licensed and in `Gemini Adoption – Pilot Users – Pilot` |
| Gemini answers with no Workspace grounding | Data-access setting off for the scope, or indexing not ready | Confirm **"Allow Gemini Enterprise to access Google Workspace data"** is on for the pilot scope; allow time after enablement |

## F. Diagnostics quick reference
```powershell
# Read-only signals and exposure baseline
.\GEMGOV-Discovery.ps1
.\GEMGOV-Report.ps1

# Confirm remediation held (broad links removed, DLP/IRM present, enablement pilot-only)
.\GEMGOV-Validation.ps1

# Preview safe remediation before applying
.\GEMGOV-Remediation.ps1 -WhatIf
```
Portal checks: Admin console → **Apps → Google Workspace → Drive and Docs → Sharing settings**;
**Security → Data protection** (DLP/IRM); **Generative AI → Gemini Enterprise** (Service status +
data-access, per edition); **security investigation tool** (Gemini access to Drive); **Google Vault**
(Gemini conversation eDiscovery). *(Verify exact paths in your tenant.)*

## G. When to escalate
If oversharing is remediated, DLP/IRM (and CSE where required) are applied and honored, the
data-access boundary and service enablement are pilot-only, and Gemini still surfaces content it
should not — capture the exact prompt, the cited item, and the user's effective permissions on that
item, review the security investigation tool logs, and open a Google Workspace support case. Volatile
Gemini Enterprise admin and connector specifics are deferred to Google's documentation.


---


# 7. Best Practices — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Field-proven recommendations for safe, compliant AI adoption.

- **Fix oversharing first, then turn on Gemini.** Gemini exposure equals what the user can access —
  remediating broad Drive sharing is the single most important thing you do, and it must come before
  enablement, not after.
- **Assess with data, not assumptions.** Run `GEMGOV-Discovery.ps1` and `GEMGOV-Report.ps1` to get a
  real baseline of broad, external, and unprotected content before you touch anything, and cross-check
  with the security investigation tool.
- **Remediate with owners, safely.** Preview every change with `-WhatIf`, review broad grants with the
  content owners, and remove public/domain-wide links — but don't silently strip access people depend on.
- **Protect the crown jewels with DLP + IRM.** DLP rules that apply IRM (prevent download/print/copy)
  stop Gemini from retrieving your most sensitive files; use **Client-Side Encryption** where content
  must be indecipherable to any assistant, including Google's.
- **Bound the grounding surface.** Use the **"Allow Gemini Enterprise to access Google Workspace
  data"** control and **Trust rules in Drive** so Gemini grounds only in the right data — scoped to the
  pilot first.
- **Always pilot with a curated OU/group.** A small `Gemini Adoption – Pilot Users – Pilot` scope with
  service and data-access targeting catches exposure problems before the whole org can hit them.
- **Prove it with exposure probes.** The pilot gate is not "Gemini works" — it is "Gemini cannot
  surface what it shouldn't." Test that explicitly, including IRM- and CSE-protected content.
- **Align use cases to policy.** Map each approved use case to the data it may ground in and the policy
  that permits it — so "what Gemini is used for" and "what governance allows" are the same list.
- **Govern the humans, not just the data.** Publish an acceptable-use policy, require review of
  AI-generated output, and name owners for governance, DLP/IRM, and AI use.
- **Partner with security and legal early.** Confirm data handling, retention, and how Google
  processes Gemini data (no training on your data without permission; interactions stay in your org)
  before pilot users get access — get sign-off, not surprises at audit.
- **Verify every Gemini specific in your tenant.** Gemini Enterprise editions, admin pages, and
  connectors are evolving / partly preview — confirm each toggle for your edition and defer volatile
  specifics to Google's documentation rather than assuming.
- **Stop the drift.** Stand up recurring access reviews, re-run discovery on a schedule, and monitor
  the security investigation tool so oversharing does not creep back after Gemini is live.
- **Document the cadence.** Record the remediated scope, DLP/IRM rules, the data-access boundary, the
  use-case-to-policy map, and the pilot → expansion waves for audits and repeatability.


---


# 8. Deliverables Summary — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How Gemini grounds in Workspace data, why oversharing is the top risk, and the guardrails Gemini honors |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess, remediate, DLP/IRM/CSE, data-access boundary, use-case-to-policy, pilot, expand |
| 5. Testing Guide | Validation gates with exposure probes and pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for safe, compliant AI adoption |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GEMGOV-Discovery.ps1` | Read-only: AI-readiness / oversharing discovery — broad Drive sharing, external access, shared-drive breadth, DLP/IRM signals |
| `GEMGOV-Validation.ps1` | Read-only: per-scope guardrail validation — broad links removed, DLP/IRM present, Gemini enablement/data-access scoped to the pilot |
| `GEMGOV-Report.ps1` | Read-only: access-boundary and coverage report (broadly/externally shared and unprotected content) for the baseline and gates |
| `GEMGOV-Remediation.ps1` | Safe remediation (default `-WhatIf`): removes public/domain-wide Drive sharing links; reports broad grants for owner action |
| `GEMGOV-Set-ScopeTargeting.ps1` | Creates the `Gemini Adoption – Pilot Users – Pilot` scope group (idempotent) for controlled rollout |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Gemini Enterprise adopted safely on a governed data estate — oversharing remediated first, DLP/IRM
and CSE enforced so Gemini respects them, data-access boundaries set so Gemini grounds only in the
right data, use cases aligned to policy, and security/legal satisfied — proven on a controlled pilot
with exposure probes before the fleet gets access. Gemini-specific admin controls are cited from
Google's current documentation or flagged "verify in your tenant," never invented.
