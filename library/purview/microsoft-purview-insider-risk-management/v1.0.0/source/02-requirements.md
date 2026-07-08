# Requirements — Microsoft Purview Insider Risk Management

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to Insider Risk Management**, especially its **role separation** and **privacy**
prerequisites.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> Insider Risk Management is **HR/privacy-sensitive**. Several requirements below are **organizational,
> not technical** (HR/legal engagement, lawful basis, works-council consultation). Treat those as
> hard gates: they must be satisfied before you enable a policy, and their determination is **not
> yours to make** — see `global-requirements-purview.md` §5.

---

## R1. Insider Risk Management licensing (E5 / E5 Compliance / IRM add-on)

**Description:** Microsoft 365 **E5**, the **E5 Compliance** add-on, or the standalone **Insider Risk
Management** add-on assigned to the users who will be **in scope** of policies (and to the priority
users if used). Some capabilities — **forensic evidence**, **Adaptive Protection**, healthcare
(**patient data misuse**) — carry additional or preview requirements.
**Why:** IRM is a premium, plan-gated compliance capability; without the right licence the policies and
several indicators/connectors are unavailable, and scored users must be licensed.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** — confirm E5 / E5 Compliance / IRM.
In the Purview portal, **Insider Risk Management** appears in the left navigation and lets you open
**Settings**. Cross-check any advanced feature against the *Microsoft Purview service description* —
**verify against your licensing/tenant**, do not assume.
**Implement if missing:** Acquire and assign the appropriate SKU/add-on to in-scope (and priority)
users before authoring policies.

## R2. The Insider Risk Management role groups — configured for STRICT SEPARATION

**Description:** The purpose-built IRM role groups assigned so that **duties are separated**, not
concentrated in one account:
- **Insider Risk Management Admins** — create/configure **policies and settings**; **cannot** see
  alert/case user activity.
- **Insider Risk Management Analysts** — **triage and investigate** alerts/cases; see the
  **anonymized** experience unless de-anonymization is justified and role-permitted.
- **Insider Risk Management Investigators** — full case investigation including **content/forensic
  detail and de-anonymized identity** where justified.
- **Insider Risk Management Auditors** — view the **IRM audit log** (who reviewed/unmasked what) —
  the independent watch on the reviewers.
- **Insider Risk Management** (the combined "everything" role group) — **avoid** assigning it to real
  operators in production; it defeats separation. Use the granular groups.
**Why:** Role separation is the core privacy control: the person who **defines** risk must not be the
person who **unmasks** identity, and both must be **independently audited**. Concentrating roles is a
governance failure and, in many regions, a compliance one.
**Verify:** Purview portal → **Settings → Roles & scopes → Permissions** (or **Roles & scopes**), or
run **`PURVIRM-Discovery.ps1`** — confirm each role group has the **right, minimal** membership and
that **no single person holds a conflicting combination** (e.g. Admin **and** Investigator).
**Implement if missing:** Assign the least-privilege IRM role groups under change control, mapping
named people to **one** function each. Record the mapping with HR/legal.

## R3. Privacy / anonymization posture agreed and configured

**Description:** A decision — **made with privacy/HR/legal** — on IRM **global privacy settings**,
specifically **anonymization (pseudonymization) of usernames** in the analyst experience, kept
**ON** by default, with de-anonymization treated as a justified, role-gated, audited exception.
**Why:** Anonymization is what lets you detect risk **without** exposing employee identity to reviewers
by default; turning it off changes the privacy and legal posture of the whole program.
**Verify:** Purview portal → **Insider Risk Management → Settings → Privacy** — confirm **"Show
anonymized versions of usernames"** is selected. `PURVIRM-Discovery.ps1` flags the posture to confirm
in-portal (the privacy setting is portal-managed).
**Implement if missing:** Set anonymization **on** and document who may de-anonymize, on what basis,
with what approval. Do **not** disable anonymization without written privacy/legal agreement.

## R4. In-scope indicators turned on globally

**Description:** The **indicators** the three policies need, enabled under **Settings → Policy
indicators**: **Office indicators** (SharePoint download, file sharing, email exfiltration),
**Device indicators** (copy to USB/personal cloud, print, etc. — requires endpoint prerequisites),
**cloud service** indicators, and **Microsoft Defender for Endpoint** indicators (for security-policy
violations).
**Why:** A policy can only detect activities whose **indicators are enabled**; indicators are a
**global** switch that policies then draw from.
**Verify:** **Settings → Policy indicators** — confirm the needed families are checked. Device
indicators additionally require the endpoint prerequisites in R5.
**Implement if missing:** Enable the indicator families your chosen templates require (see
`03-implementation.md` for the exact set per policy).

## R5. Endpoint (device) prerequisites for device indicators

**Description:** For **device/endpoint indicators**, devices **onboarded** to Microsoft Purview
(endpoint DLP onboarding, which uses the same onboarding as Microsoft Defender for Endpoint) and
running a supported OS.
**Why:** Device indicators (USB copy, print, copy-to-cloud) only fire from **onboarded** devices;
un-onboarded endpoints are invisible to IRM.
**Verify:** Purview portal → **Settings → Device onboarding** shows onboarded devices; a test device
appears in endpoint DLP activity. `PURVIRM-Test-Readiness.ps1` reports whether device indicators are
enabled and points you to the onboarding check.
**Implement if missing:** Onboard the in-scope devices before relying on device indicators. Until then,
device-based detections will not fire.

## R6. HR connector (for departing-user / job-change triggers)

**Description:** The **Microsoft 365 HR connector** importing **resignation/termination dates** (and,
optionally, job-level changes and performance signals) from your HR system — the **triggering event**
for **Data theft by departing users**.
**Why:** The departing-user template scopes a user for detection based on their **leaver date**;
without the HR connector (or Entra account deletion) there is no trigger and the policy scores no one.
**Verify:** Purview portal → **Settings → Data connectors** (or **Data connectors** in the M365 admin
center) — the HR connector shows **recent successful uploads**. `PURVIRM-Test-Readiness.ps1` reports
connector presence/freshness where readable.
**Implement if missing:** Create the HR connector (Entra app registration + the CSV/API upload Microsoft
documents) and schedule regular uploads. **Alternative trigger:** Entra **account deletion** can trigger
the departing-user policy without an HR feed, at coarser fidelity.

## R7. (Optional) Physical badging connector

**Description:** The **physical badging connector** importing **badge access** events, used to correlate
physical access (e.g. after-hours or post-resignation building entry) with digital exfiltration signals.
**Why:** Some departing-user / data-theft scenarios are strengthened by physical-access indicators;
these require the badging feed.
**Verify:** **Settings → Data connectors** shows the physical badging connector with recent uploads;
**Settings → Policy indicators** shows physical-access indicators available.
**Implement if missing:** Only configure if your scenario needs physical correlation and you have a
badging system that can export the required schema. It is **optional**; the core three policies do not
depend on it.

## R8. Priority user groups and/or physical assets (if used)

**Description:** Where risk is concentrated in specific populations (executives, admins, R&D) or assets,
**priority user groups** (and priority physical assets) defined under **Settings**, so higher-sensitivity
templates or scoping can target them.
**Why:** Priority-user templates and boosted scoring depend on these groups existing; they also help you
scope narrowly (privacy).
**Verify:** **Settings → Priority user groups** — confirm the groups and their membership are correct.
**Implement if missing:** Define priority user groups **with HR/legal** (membership in a "priority"
group is itself sensitive) before using priority-user templates.

## R9. HR, legal, privacy (and works-council / employee-relations) engagement and lawful basis

**Description:** Named, engaged stakeholders from **HR, legal, privacy**, and — where applicable —
**works councils / employee representatives**, plus a documented **lawful basis / notice / consultation**
for monitoring employee activity in your jurisdiction(s).
**Why:** IRM monitors people. In many regions this **requires** notice, consultation, or a specific
lawful basis **before** you switch it on; the **applicability is a legal determination**, and case
outcomes are **HR/legal's**, not the administrator's.
**Verify:** Confirm the named stakeholders, the recorded lawful basis / notice, and the agreed
anonymization and de-anonymization rules **in writing** before enabling any policy.
**Implement if missing:** **Stop** and obtain them. This is a hard gate — do not enable IRM policies
without it. (See `global-requirements-purview.md` §5.)

## R10. Pilot scope, analytics, and change control

**Description:** A **named pilot scope** (a limited user group) and agreement to **run Insider Risk
analytics** and/or a limited-scope policy first, under a **change-control** process, before any
tenant-wide policy.
**Why:** IRM thresholds and exclusions need **tuning against real activity**; analytics and a pilot
prevent alert floods and false positives from undermining the program (and from unfairly flagging
people). Analytics is aggregate and requires **no policy**, making it the safest first look.
**Verify:** Confirm the pilot group, that **Analytics** is available in the portal, and a change window/
approval path. `PURVIRM-Set-Scope.ps1` (`-WhatIf`) previews pilot-group scoping.
**Implement if missing:** Define the pilot group and run **Analytics** first; agree change control
before expanding scope.
