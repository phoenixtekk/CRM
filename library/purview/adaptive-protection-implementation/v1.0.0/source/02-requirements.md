# Requirements — Adaptive Protection in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to Adaptive Protection** and its three moving parts: the **Insider Risk
Management** source signal, **DLP** enforcement, and the **Conditional Access** integration.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> Adaptive Protection is **driven by Insider Risk Management**, so it inherits IRM's HR/privacy
> sensitivity. Several requirements below are **organizational, not technical** (HR/legal engagement,
> lawful basis). Treat those as hard gates: they must be satisfied before you enable enforcement, and
> their determination is **not yours to make** — see `global-requirements-purview.md` §5.

---

## R1. Licensing for IRM + DLP + (for the CA integration) Entra ID P2

**Description:** Microsoft 365 **E5** or the **E5 Compliance** add-on (for **Insider Risk Management**
and **Data Loss Prevention**), assigned to the users who will be **in scope**; and **Microsoft Entra
ID P2** (included in E5) for the **Conditional Access** insider-risk integration.
**Why:** Adaptive Protection is built on IRM (premium/plan-gated) and enforced through DLP; the CA
integration additionally needs Entra ID P2. Without the right licences the risk levels, the DLP
condition, or the CA condition will not be available, and in-scope users must be licensed.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** — confirm E5 / E5 Compliance and Entra
ID P2. In the Purview portal, **Insider Risk Management → Adaptive Protection** is present; the
adaptive-protection **risk-level condition** appears when authoring a DLP rule. Cross-check advanced
features against the *Microsoft Purview service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire and assign the required SKUs/add-ons before enabling Adaptive
Protection or authoring enforcement.

## R2. Least-privilege roles across IRM, DLP, and Conditional Access

**Description:** The least-privilege roles for each surface, mapped to **named** people:
- **Insider Risk Management Admins** (and the IRM Analysts/Investigators/Auditors separation) to own
  the source policy and Adaptive Protection setup — see the IRM role-separation discipline.
- **Compliance Administrator / Compliance Data Administrator** (or **DLP Compliance Management**) to
  author the DLP policy.
- **Conditional Access Administrator** (or Security Administrator) in Entra to author the CA policy;
  **Global Administrator** only where genuinely required.
**Why:** Each surface uses its own role model; configuring across three surfaces requires the matching
least-privilege role on each, without over-granting.
**Verify:** Purview → **Roles & scopes / Permissions** (IRM + DLP roles); Entra → **Roles &
admins** (CA role). `PURVAP-Discovery.ps1` reports the IRM/DLP role signals it can read.
**Implement if missing:** Assign the least-privilege role on each surface under change control; keep
IRM role separation intact (do not fold IRM admin into DLP/CA admin for convenience).

## R3. An Insider Risk Management source signal (policy + privacy posture)

**Description:** A working **IRM policy** whose scoring can drive risk levels (for **Quick setup**,
Microsoft's built-in default insider-risk policy; for **Custom setup**, one or more named insider-risk
policies), with IRM's **anonymization** on and **role separation** intact.
**Why:** Adaptive Protection does not generate its own signal — it **maps IRM scoring** onto Elevated/
Moderate/Minor. No scoring source, no risk levels, no adaptive behavior.
**Verify:** Purview → **Insider Risk Management → Policies** shows a policy that is **On** and scoring;
**Settings → Privacy** shows anonymization on. `PURVAP-Discovery.ps1` reports whether an IRM policy is
present/readable and prompts to confirm the privacy posture in-portal.
**Implement if missing:** Stand up (or reuse) an insider-risk policy — e.g. a **Data leaks** policy —
before enabling Adaptive Protection. Keep the IRM privacy guardrails on.

## R4. Adaptive Protection setup decision — Quick vs Custom (and the level→threshold mapping)

**Description:** A decision on **how risk levels are assigned**: **Quick setup** (Microsoft's
recommended default mapping to a built-in insider-risk policy) or **Custom setup** (map each level —
**Elevated / Moderate / Minor** — to specific insider-risk policies and thresholds, e.g. by alert
severity or number of exfiltration activities), agreed with HR/legal.
**Why:** The mapping determines **who** reaches which level and therefore **who** gets tighter
controls; it directly affects both protection and fairness, so it is a decision, not a default.
**Verify:** Purview → **Insider Risk Management → Adaptive Protection** shows the chosen setup and the
per-level definitions. **Verify the exact options against your tenant** (the setup UI evolves).
**Implement if missing:** Choose Quick setup to start (lowest effort, recommended default) and move to
Custom only when you need explicit control over the mapping. Record the mapping with HR/legal.

## R5. Sensitivity labels / classification for the DLP "label enforcement" rules

**Description:** The **sensitivity labels** (or other classification — sensitive info types, trainable
classifiers) that the adaptive DLP rules will key on, published and in use on the in-scope workloads,
so protection on **labeled** content can scale with the handler's risk level.
**Why:** "Label enforcement" here is a **DLP rule combining the risk-level condition with a
sensitivity-label condition** — the rule needs published labels applied to content to act on.
**Verify:** Purview → **Information Protection → Labels / Label policies** shows the labels published;
content in scope carries them (Activity explorer / Content explorer where available).
**Implement if missing:** Publish and adopt the needed sensitivity labels first (this can be a separate
labeling project). If you have no labels yet, the adaptive DLP policy can still key on **sensitive
info types**; add label conditions once labels are in use.

## R6. DLP coverage on the in-scope workloads

**Description:** DLP enabled and healthy on the **workloads** the adaptive policy will cover
(Exchange, SharePoint, OneDrive, Teams, and — for endpoint actions like USB/print/upload —
**onboarded devices** for **Endpoint DLP**).
**Why:** The adaptive DLP rule can only act where DLP itself operates; endpoint actions require device
onboarding exactly as Endpoint DLP does.
**Verify:** Purview → **Data Loss Prevention → Policies** shows healthy policies; **Settings → Device
onboarding** shows onboarded devices (for endpoint rules). `PURVAP-Test-Readiness.ps1` reports DLP
policy presence and whether the adaptive policy is in simulation/on.
**Implement if missing:** Enable DLP on the needed workloads and onboard devices for any endpoint
enforcement before relying on those actions.

## R7. Conditional Access readiness (for the Elevated-risk access control)

**Description:** Entra **Conditional Access** available (Entra ID P2), a break-glass/emergency-access
account **excluded** from any blocking policy, and agreement on the control for Elevated-risk users
(block, require MFA / password change, or a limited/monitored session).
**Why:** The CA integration lets access controls respond to insider risk; a blocking CA policy without
a break-glass exclusion can lock out administrators.
**Verify:** Entra → **Protection → Conditional Access**; confirm the **Insider risk** condition is
selectable and a break-glass account is excluded. `PURVAP-Discovery.ps1` (Graph) reports CA policy
presence where readable.
**Implement if missing:** Ensure Entra ID P2, define/confirm a break-glass account and its exclusion,
and agree the Elevated-risk control **before** authoring the CA policy. Deploy CA in **report-only**
first.

## R8. HR, legal, privacy (and works-council) engagement and lawful basis

**Description:** Named, engaged stakeholders from **HR, legal, privacy**, and — where applicable —
**works councils / employee representatives**, plus a documented **lawful basis / notice /
consultation** for the underlying insider-risk monitoring that drives Adaptive Protection.
**Why:** Adaptive Protection acts on **people-derived risk**. In many regions the underlying
monitoring **requires** notice, consultation, or a specific lawful basis before it runs; the
**applicability is a legal determination**, and any judgement about a user's conduct remains
**HR/legal's**, not the administrator's.
**Verify:** Confirm the named stakeholders, the recorded lawful basis / notice, and the agreed IRM
anonymization rules **in writing** before you enable enforcement.
**Implement if missing:** **Stop** and obtain them. This is a hard gate — do not enable enforcing DLP
or CA controls without it. (See `global-requirements-purview.md` §5.)

## R9. Pilot scope and change control (simulation / test / report-only)

**Description:** A **named pilot scope** (a limited user group, `SG-AP-Pilot`) and agreement to run
the DLP policy in **simulation/test** and the CA policy in **report-only** first, under a
**change-control** process, before any enforcing, tenant-wide control.
**Why:** DLP block actions and CA grant controls are high-impact; simulation/report-only prove the
risk levels are assigned and the rules *would* act **without** disrupting legitimate work, and let you
tune before enforcing.
**Verify:** Confirm the pilot group exists, that DLP **simulation mode** and CA **report-only** are
used, and a change window/approval path. `PURVAP-Set-Scope.ps1` (`-WhatIf`) previews pilot-group
scoping.
**Implement if missing:** Define the pilot group, deploy in simulation/report-only, and agree change
control before turning on enforcement.
