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
