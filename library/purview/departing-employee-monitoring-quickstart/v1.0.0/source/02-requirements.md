# Requirements — Departing-Employee Data-Theft Monitoring Quickstart

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to a departing-user data-theft policy**, especially its **HR-connector trigger**,
its **role separation**, and its **privacy** prerequisites.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> This capability is **HR/privacy-sensitive**. Several requirements below are **organizational, not
> technical** (HR/legal engagement, lawful basis, works-council consultation). Treat those as hard
> gates: they must be satisfied before you enable the policy, and their determination is **not yours to
> make** — see `global-requirements-purview.md` §5.

---

## R1. Insider Risk Management licensing (E5 / E5 Compliance / IRM add-on)

**Description:** Microsoft 365 **E5**, the **E5 Compliance** add-on, or the standalone **Insider Risk
Management** add-on, assigned to the users who will be **in scope** of the departing-user policy.
**Why:** IRM is a premium, plan-gated compliance capability; without the right licence the *Data theft by
departing users* template, several indicators, and the HR connector are unavailable, and scored users
must be licensed.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; in the Purview portal, **Insider Risk
Management** appears in the left navigation and lets you open **Settings**. Cross-check against the
*Microsoft Purview service description* — **verify against your licensing/tenant**, do not assume.
**Implement if missing:** Acquire and assign the appropriate SKU/add-on to in-scope users before
authoring the policy.

## R2. The Insider Risk Management role groups — configured for STRICT SEPARATION

**Description:** The purpose-built IRM role groups assigned so **duties are separated**, not concentrated
in one account:
- **Insider Risk Management Admins** — create/configure the **policy and settings**; **cannot** see
  alert/case user activity.
- **Insider Risk Management Analysts** — **triage** alerts/cases; see the **anonymized** experience
  unless de-anonymization is justified and role-permitted.
- **Insider Risk Management Investigators** — full case investigation including **content/forensic
  detail and de-anonymized identity** where justified.
- **Insider Risk Management Auditors** — view the **IRM audit log** (who reviewed/unmasked what) — the
  independent watch on the reviewers.
- **Insider Risk Management** (the combined "everything" role group) — **avoid** assigning it to real
  operators in production; it defeats separation. Use the granular groups.
**Why:** Role separation is the core privacy control: the person who **defines** risk must not be the
person who **unmasks** identity, and both must be **independently audited**. Concentrating roles is a
governance failure and, in many regions, a compliance one.
**Verify:** Purview portal → **Settings → Roles & scopes → Permissions** (or **Roles & scopes**), or run
**`IRMDEPART-Discovery.ps1`** — confirm each role group has the **right, minimal** membership and that
**no single person holds a conflicting combination** (e.g. Admin **and** Investigator).
**Implement if missing:** Assign the least-privilege IRM role groups under change control, mapping named
people to **one** function each. Record the mapping with HR/legal.

## R3. Privacy / anonymization posture agreed and configured

**Description:** A decision — **made with privacy/HR/legal** — on the IRM **global privacy setting**,
specifically **anonymization (pseudonymization) of usernames** in the reviewer experience, kept **ON** by
default, with de-anonymization treated as a justified, role-gated, audited exception.
**Why:** Anonymization is what lets you detect leaver risk **without** exposing employee identity to
reviewers by default; turning it off changes the privacy and legal posture of the whole program.
**Verify:** Purview portal → **Insider Risk Management → Settings → Privacy** — confirm **"Show anonymized
versions of usernames"** is selected. `IRMDEPART-Discovery.ps1` flags the posture to confirm in-portal
(the privacy setting is portal-managed).
**Implement if missing:** Set anonymization **on** and document who may de-anonymize, on what basis, with
what approval. Do **not** disable anonymization without written privacy/legal agreement.

## R4. Exfiltration indicators turned on globally

**Description:** The **indicators** the departing-user policy needs, enabled under **Settings → Policy
indicators**: **Office indicators** (SharePoint/OneDrive download, file shared externally, email sent to
external/personal recipient) and **Device indicators** (file copied to USB/removable media, file copied
to personal cloud, file printed, file downloaded from cloud to device). **Cumulative exfiltration
detection** / sequence detection as a risk booster where agreed.
**Why:** The policy can only detect activities whose **indicators are enabled**; indicators are a
**global** switch the policy then draws from.
**Verify:** **Settings → Policy indicators** — confirm the Office and Device families are checked. Device
indicators additionally require the endpoint prerequisites in R5. `IRMDEPART-Test-HRConnector.ps1`
reminds you which families to confirm.
**Implement if missing:** Enable the Office and Device indicator families (see `03-implementation.md` for
the exact set).

## R5. Endpoint (device) prerequisites for device indicators

**Description:** For **device/endpoint indicators**, devices **onboarded** to Microsoft Purview (endpoint
DLP onboarding, which uses the same onboarding as Microsoft Defender for Endpoint) and running a
supported OS.
**Why:** Device indicators (USB copy, print, copy-to-personal-cloud) — the highest-signal exit-theft
activities — only fire from **onboarded** devices; un-onboarded endpoints are invisible to the policy.
**Verify:** Purview portal → **Settings → Device onboarding** shows onboarded devices; a test device
appears in endpoint DLP activity. `IRMDEPART-Test-HRConnector.ps1` reports whether the device path is
ready and points you to the onboarding check.
**Implement if missing:** Onboard the in-scope devices before relying on device indicators. Until then,
device-based detections will not fire (Office/email indicators still will).

## R6. The Microsoft 365 HR connector (the departing-user trigger)

**Description:** The **Microsoft 365 HR connector** importing **resignation/termination dates** (and,
optionally, job-level changes) from your HR system — the **triggering event** for *Data theft by
departing users*.
**Why:** The departing-user template scopes a user for detection based on their **leaver date**; without
the HR connector (or the Entra account-deletion fallback) there is **no trigger** and the policy scores
no one. This is the requirement most likely to be missing.
**Verify:** Purview portal → **Settings → Data connectors** (or **Data connectors** in the M365 admin
center) — the HR connector shows **recent successful uploads**. `IRMDEPART-Test-HRConnector.ps1` reports
connector presence/freshness where readable and confirms audit ingestion.
**Implement if missing:** Create the HR connector (Entra app registration + the CSV/API upload Microsoft
documents) and schedule regular uploads. **Alternative trigger:** Entra **account deletion** can trigger
the departing-user policy without an HR feed — coarser (it fires as the account is removed, i.e. usually
*after* the last day) but requires no connector. Prefer the HR feed so you catch theft **before** the
account is gone.

## R7. A named pilot scope group

**Description:** A named security group — `SG-Departing-Pilot` — holding the small set of users the
policy is scoped to for the pilot, before any broader rollout.
**Why:** IRM thresholds and exclusions need **tuning against real activity**; a small pilot scope
prevents alert floods, false positives, and over-collection — and keeps the privacy footprint minimal
while you validate.
**Verify:** Entra → **Groups** shows `SG-Departing-Pilot` with the agreed pilot members.
`IRMDEPART-Set-Scope.ps1 -WhatIf` previews membership changes.
**Implement if missing:** Create the group and populate it with the agreed pilot users (with HR/legal).
For production, this becomes the standing **monitored-leaver** population — expand deliberately (R10 /
Implementation Phase 7).

## R8. (Optional) Priority user group for high-risk leavers

**Description:** Where exit risk concentrates in specific populations (executives, R&D, privileged
admins), an optional **priority user group** — `PUG-HighRisk-Leavers` — so higher-sensitivity scoring can
target them.
**Why:** Priority-user scoring boosts detection for the roles whose departure is most damaging; it also
helps you scope narrowly (privacy).
**Verify:** **Settings → Priority user groups** — confirm the group and membership are correct.
**Implement if missing:** Define the priority group **with HR/legal** (membership in a "priority" group is
itself sensitive). It is **optional**; the core policy does not depend on it.

## R9. HR, legal, privacy (and works-council / employee-relations) engagement and lawful basis

**Description:** Named, engaged stakeholders from **HR, legal, privacy**, and — where applicable —
**works councils / employee representatives**, plus a documented **lawful basis / notice / consultation**
for monitoring departing-employee activity in your jurisdiction(s), and the **agreed anonymization /
de-anonymization rules**.
**Why:** The policy monitors people. In many regions this **requires** notice, consultation, or a
specific lawful basis **before** you switch it on; the **applicability is a legal determination**, and
case outcomes are **HR/legal's**, not the administrator's.
**Verify:** Confirm the named stakeholders, the recorded lawful basis / notice, and the agreed
anonymization rules **in writing** before enabling the policy.
**Implement if missing:** **Stop** and obtain them. This is a hard gate — do not enable the departing-user
policy without it. (See `global-requirements-purview.md` §5.)

## R10. Change control for scope expansion

**Description:** A **change-control** process for growing the policy scope from `SG-Departing-Pilot` to
the standing monitored-leaver population, after the pilot gates pass.
**Why:** Expanding who is monitored is privacy-sensitive and high-impact; it must be deliberate,
reversible, and agreed — not a one-click tenant-wide switch.
**Verify:** Confirm a change window/approval path and that expansion goes through it.
`IRMDEPART-Set-Scope.ps1` (`-WhatIf`) previews each expansion.
**Implement if missing:** Agree change control before expanding scope beyond the pilot.
